#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

#include <pipewire/pipewire.h>
#include <pipewire/extensions/metadata.h>
#include <spa/param/param.h>
#include <spa/param/props.h>
#include <spa/pod/iter.h>
#include <spa/pod/pod.h>
#include <spa/utils/dict.h>
#include <spa/utils/hook.h>

#define MAX_NODES 256

struct state;

struct node_watch {
  struct state *st;
  uint32_t id;
  bool is_sink;
  bool subscribed;
  char name[256];

  struct pw_node *node;
  struct spa_hook listener;
};

struct state {
  struct pw_main_loop *loop;
  struct pw_context *context;
  struct pw_core *core;
  struct pw_registry *registry;
  struct pw_metadata *metadata;

  struct spa_hook core_listener;
  struct spa_hook registry_listener;
  struct spa_hook metadata_listener;

  struct node_watch nodes[MAX_NODES];
  size_t node_count;

  char default_sink_name[256];

  int sync_seq;
  bool armed;
  bool printed;
};

static int to_percent(float linear) {
  if (linear < 0.0f) linear = 0.0f;
  if (linear > 1.5f) linear = 1.5f;

  // Match wpctl UI semantics: convert linear amplitude to cubic percentage.
  float ui = cbrtf(linear);
  if (ui < 0.0f) ui = 0.0f;
  if (ui > 1.5f) ui = 1.5f;
  return (int)(ui * 100.0f + 0.5f);
}

static void print_volume(bool muted, int percent) {
  const char *icon;
  if (muted) {
    puts("󰝟 0%");
    fflush(stdout);
    return;
  }

  if (percent >= 67) icon = "󰕾";
  else if (percent >= 34) icon = "󰖀";
  else icon = "󰕿";

  printf("%s %d%%\n", icon, percent);
  fflush(stdout);
}

static void try_subscribe_default_sink(struct state *st) {
  if (st->default_sink_name[0] == '\0') {
    return;
  }

  for (size_t i = 0; i < st->node_count; i++) {
    struct node_watch *w = &st->nodes[i];
    if (!w->is_sink || w->subscribed) {
      continue;
    }

    if (strcmp(w->name, st->default_sink_name) == 0) {
      uint32_t ids[] = { SPA_PARAM_Props };
      pw_node_subscribe_params(w->node, ids, 1);
      pw_node_enum_params(w->node, 0, SPA_PARAM_Props, 0, UINT32_MAX, NULL);
      w->subscribed = true;
      return;
    }
  }
}

static bool parse_default_sink_name(const char *value, char *out, size_t out_size) {
  const char *k = "\"name\":\"";
  const char *p;
  const char *e;
  size_t n;

  if (!value || !out || out_size == 0) {
    return false;
  }

  p = strstr(value, k);
  if (!p) {
    return false;
  }

  p += strlen(k);
  e = strchr(p, '"');
  if (!e || e <= p) {
    return false;
  }

  n = (size_t)(e - p);
  if (n >= out_size) {
    n = out_size - 1;
  }

  memcpy(out, p, n);
  out[n] = '\0';
  return n > 0;
}

static void on_node_param(void *data, int seq, uint32_t id, uint32_t index,
                          uint32_t next, const struct spa_pod *param) {
  (void)seq;
  (void)index;
  (void)next;

  struct node_watch *w = data;
  struct state *st = w->st;
  if (!st->armed || st->printed || id != SPA_PARAM_Props || param == NULL) {
    return;
  }

  if (!w->subscribed) {
    return;
  }

  bool mute = false;
  float avg = 0.0f;

  const struct spa_pod_prop *p_mute = spa_pod_find_prop(param, NULL, SPA_PROP_mute);
  if (p_mute) {
    bool v = false;
    if (spa_pod_get_bool(&p_mute->value, &v) == 0) {
      mute = v;
    }
  }

  const struct spa_pod_prop *p_vol = spa_pod_find_prop(param, NULL, SPA_PROP_channelVolumes);
  if (p_vol) {
    uint32_t n_vals = 0;
    uint32_t child_size = 0;
    uint32_t child_type = 0;
    const void *vals = spa_pod_get_array_full(&p_vol->value, &n_vals, &child_size, &child_type);
    if (vals != NULL && child_type == SPA_TYPE_Float && child_size == sizeof(float) && n_vals > 0) {
      const float *f = (const float *)vals;
      float sum = 0.0f;
      for (uint32_t i = 0; i < n_vals; i++) {
        sum += f[i];
      }
      avg = sum / (float)n_vals;
    }
  }

  int percent = to_percent(avg);
  print_volume(mute, percent);
  st->printed = true;
  pw_main_loop_quit(st->loop);
}

static void on_node_info(void *data, const struct pw_node_info *info) {
  struct node_watch *w = data;
  const char *media_class;
  const char *node_name;

  if (!info || !info->props) {
    return;
  }

  media_class = spa_dict_lookup(info->props, PW_KEY_MEDIA_CLASS);
  node_name = spa_dict_lookup(info->props, PW_KEY_NODE_NAME);

  w->is_sink = media_class && strcmp(media_class, "Audio/Sink") == 0;
  if (node_name && node_name[0] != '\0') {
    strncpy(w->name, node_name, sizeof(w->name) - 1);
    w->name[sizeof(w->name) - 1] = '\0';
  }

  if (w->is_sink) {
    try_subscribe_default_sink(w->st);
  }
}

static const struct pw_node_events node_events = {
  PW_VERSION_NODE_EVENTS,
  .info = on_node_info,
  .param = on_node_param,
};

static int on_metadata_property(void *data, uint32_t subject,
                                const char *key, const char *type,
                                const char *value) {
  (void)subject;
  (void)type;

  struct state *st = data;
  char name[256] = { 0 };

  if (!key || strcmp(key, "default.audio.sink") != 0) {
    return 0;
  }

  if (parse_default_sink_name(value, name, sizeof(name))) {
    strncpy(st->default_sink_name, name, sizeof(st->default_sink_name) - 1);
    st->default_sink_name[sizeof(st->default_sink_name) - 1] = '\0';
    try_subscribe_default_sink(st);
  }
  return 0;
}

static const struct pw_metadata_events metadata_events = {
  PW_VERSION_METADATA_EVENTS,
  .property = on_metadata_property,
};

static void on_core_done(void *data, uint32_t id, int seq) {
  (void)id;
  struct state *st = data;
  if (seq == st->sync_seq) {
    st->armed = true;
  }
}

static const struct pw_core_events core_events = {
  PW_VERSION_CORE_EVENTS,
  .done = on_core_done,
};

static void on_registry_global(void *data, uint32_t id, uint32_t permissions,
                               const char *type, uint32_t version,
                               const struct spa_dict *props) {
  (void)permissions;
  struct state *st = data;
  if (type == NULL) {
    return;
  }

  if (strcmp(type, PW_TYPE_INTERFACE_Metadata) == 0 && st->metadata == NULL) {
    const char *name = props ? spa_dict_lookup(props, PW_KEY_METADATA_NAME) : NULL;
    if (name && strcmp(name, "default") == 0) {
      st->metadata = pw_registry_bind(
        st->registry,
        id,
        type,
        version < PW_VERSION_METADATA ? version : PW_VERSION_METADATA,
        0
      );

      if (st->metadata) {
        pw_metadata_add_listener(st->metadata, &st->metadata_listener, &metadata_events, st);
      }
    }
    return;
  }

  if (strcmp(type, PW_TYPE_INTERFACE_Node) != 0 || st->node_count >= MAX_NODES) {
    return;
  }

  struct pw_node *node = pw_registry_bind(
    st->registry,
    id,
    type,
    version < PW_VERSION_NODE ? version : PW_VERSION_NODE,
    0
  );
  if (!node) {
    return;
  }

  struct node_watch *w = &st->nodes[st->node_count++];
  memset(w, 0, sizeof(*w));
  w->st = st;
  w->id = id;
  w->node = node;
  pw_node_add_listener(w->node, &w->listener, &node_events, w);
}

static const struct pw_registry_events registry_events = {
  PW_VERSION_REGISTRY_EVENTS,
  .global = on_registry_global,
};

int main(void) {
  struct state st = { 0 };

  pw_init(NULL, NULL);

  st.loop = pw_main_loop_new(NULL);
  if (!st.loop) goto fail;
  st.context = pw_context_new(pw_main_loop_get_loop(st.loop), NULL, 0);
  if (!st.context) goto fail;
  st.core = pw_context_connect(st.context, NULL, 0);
  if (!st.core) goto fail;

  pw_core_add_listener(st.core, &st.core_listener, &core_events, &st);

  st.registry = pw_core_get_registry(st.core, PW_VERSION_REGISTRY, 0);
  if (!st.registry) goto fail;
  pw_registry_add_listener(st.registry, &st.registry_listener, &registry_events, &st);

  st.sync_seq = pw_core_sync(st.core, PW_ID_CORE, 0);
  pw_main_loop_run(st.loop);

  if (!st.printed) {
    puts("󰕾 0%");
  }

  for (size_t i = 0; i < st.node_count; i++) {
    if (st.nodes[i].node) {
      pw_proxy_destroy((struct pw_proxy *)st.nodes[i].node);
    }
  }
  if (st.metadata) pw_proxy_destroy((struct pw_proxy *)st.metadata);
  if (st.registry) pw_proxy_destroy((struct pw_proxy *)st.registry);
  if (st.core) pw_core_disconnect(st.core);
  if (st.context) pw_context_destroy(st.context);
  if (st.loop) pw_main_loop_destroy(st.loop);
  pw_deinit();
  return 0;

fail:
  puts("󰕾 0%");
  if (st.registry) pw_proxy_destroy((struct pw_proxy *)st.registry);
  if (st.core) pw_core_disconnect(st.core);
  if (st.context) pw_context_destroy(st.context);
  if (st.loop) pw_main_loop_destroy(st.loop);
  pw_deinit();
  return 0;
}