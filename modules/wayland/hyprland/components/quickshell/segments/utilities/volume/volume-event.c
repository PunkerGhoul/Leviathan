#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include <pipewire/pipewire.h>
#include <spa/param/param.h>
#include <spa/utils/dict.h>
#include <spa/utils/hook.h>

#define MAX_NODES 256

struct node_watch {
  uint32_t global_id;
  struct pw_node *node;
  struct spa_hook listener;
};

struct state {
  struct pw_main_loop *loop;
  struct pw_context *context;
  struct pw_core *core;
  struct pw_registry *registry;

  struct spa_hook core_listener;
  struct spa_hook registry_listener;

  struct node_watch nodes[MAX_NODES];
  size_t node_count;

  int sync_seq;
  bool armed;
  bool triggered;
};

static void trigger_event(struct state *st) {
  if (st->triggered || !st->armed) {
    return;
  }

  st->triggered = true;
  puts("volume-event");
  fflush(stdout);
  pw_main_loop_quit(st->loop);
}

static void on_node_info(void *data, const struct pw_node_info *info) {
  (void)data;
  (void)info;
}

static void on_node_param(void *data, int seq, uint32_t id, uint32_t index,
                          uint32_t next, const struct spa_pod *param) {
  (void)seq;
  (void)index;
  (void)next;
  (void)param;

  struct state *st = data;
  if (id == SPA_PARAM_Props) {
    trigger_event(st);
  }
}

static const struct pw_node_events node_events = {
  PW_VERSION_NODE_EVENTS,
  .info = on_node_info,
  .param = on_node_param,
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

static bool is_audio_node(const struct spa_dict *props) {
  const char *media_class = props ? spa_dict_lookup(props, PW_KEY_MEDIA_CLASS) : NULL;
  if (!media_class) {
    return false;
  }

  return strcmp(media_class, "Audio/Sink") == 0;
}

static bool already_bound_node(const struct state *st, uint32_t id) {
  for (size_t i = 0; i < st->node_count; i++) {
    if (st->nodes[i].global_id == id) {
      return true;
    }
  }
  return false;
}

static void on_registry_global(void *data, uint32_t id, uint32_t permissions,
                               const char *type, uint32_t version,
                               const struct spa_dict *props) {
  (void)permissions;

  struct state *st = data;
  if (!type || st->node_count >= MAX_NODES) {
    return;
  }

  if (strcmp(type, PW_TYPE_INTERFACE_Node) == 0) {
    if (!is_audio_node(props) || already_bound_node(st, id)) {
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

    struct node_watch *watch = &st->nodes[st->node_count++];
    watch->global_id = id;
    watch->node = node;
    pw_node_add_listener(node, &watch->listener, &node_events, st);

    uint32_t ids[] = { SPA_PARAM_Props };
    pw_node_subscribe_params(node, ids, 1);
  }
}

static const struct pw_registry_events registry_events = {
  PW_VERSION_REGISTRY_EVENTS,
  .global = on_registry_global,
};

int main(void) {
  struct state st = { 0 };

  pw_init(NULL, NULL);

  st.loop = pw_main_loop_new(NULL);
  if (!st.loop) {
    pw_deinit();
    return 1;
  }

  st.context = pw_context_new(pw_main_loop_get_loop(st.loop), NULL, 0);
  if (!st.context) {
    pw_main_loop_destroy(st.loop);
    pw_deinit();
    return 1;
  }

  st.core = pw_context_connect(st.context, NULL, 0);
  if (!st.core) {
    pw_context_destroy(st.context);
    pw_main_loop_destroy(st.loop);
    pw_deinit();
    return 1;
  }

  pw_core_add_listener(st.core, &st.core_listener, &core_events, &st);

  st.registry = pw_core_get_registry(st.core, PW_VERSION_REGISTRY, 0);
  if (!st.registry) {
    pw_core_disconnect(st.core);
    pw_context_destroy(st.context);
    pw_main_loop_destroy(st.loop);
    pw_deinit();
    return 1;
  }

  pw_registry_add_listener(st.registry, &st.registry_listener, &registry_events, &st);
  st.sync_seq = pw_core_sync(st.core, PW_ID_CORE, 0);

  pw_main_loop_run(st.loop);

  for (size_t i = 0; i < st.node_count; i++) {
    if (st.nodes[i].node) {
      pw_proxy_destroy((struct pw_proxy *)st.nodes[i].node);
    }
  }

  if (st.registry) {
    pw_proxy_destroy((struct pw_proxy *)st.registry);
  }
  if (st.core) {
    pw_core_disconnect(st.core);
  }
  if (st.context) {
    pw_context_destroy(st.context);
  }
  if (st.loop) {
    pw_main_loop_destroy(st.loop);
  }

  pw_deinit();
  return 0;
}