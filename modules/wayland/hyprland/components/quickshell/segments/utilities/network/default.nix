{ pkgs }:
let
  networkConnectUiScript = pkgs.writeShellScriptBin "leviathan-network-connect-ui" ''
    group="$1"
    ui_index="$2"

    emit_error() {
      printf 'error:%s\n' "$1"
      exit 1
    }

    emit_ok() {
      printf 'ok:%s\n' "$1"
      exit 0
    }

    [ -n "$group" ] || group="available"
    [ -n "$ui_index" ] || ui_index="0"

    case "$group" in
      known|available) ;;
      *) emit_error "Invalid network group" ;;
    esac

    case "$ui_index" in
      ""|*[!0-9]*) emit_error "Invalid network index" ;;
    esac

    ssid="$(network-status ssid "$group" "$ui_index")"

    if [ -z "$ssid" ]; then
      emit_error "Network entry not found"
    fi

    if [ "$group" = "known" ]; then
      output="$(${pkgs.networkmanager}/bin/nmcli connection up id "$ssid" 2>&1)"
      if [ $? -eq 0 ]; then
        emit_ok "Connected to $ssid"
      fi

      output="$(printf '%s' "$output" | tr '\n' ' ')"
      if [ -n "$output" ]; then
        emit_error "$output"
      fi

      emit_error "Failed to connect to $ssid"
    fi

    had_profile=0
    ${pkgs.networkmanager}/bin/nmcli -t -f NAME connection show | ${pkgs.gnugrep}/bin/grep -Fx "$ssid" >/dev/null 2>&1 && had_profile=1

    output="$(${pkgs.networkmanager}/bin/nmcli dev wifi connect "$ssid" 2>&1)"
    if [ $? -eq 0 ]; then
      emit_ok "Connected to $ssid"
    fi

    if [ "$had_profile" -eq 0 ]; then
      ${pkgs.networkmanager}/bin/nmcli connection delete id "$ssid" >/dev/null 2>&1 || true
    fi

    if printf '%s' "$output" | grep -Eqi 'secret|password'; then
      emit_error "Wrong password or password required for $ssid"
    fi

    output="$(printf '%s' "$output" | tr '\n' ' ')"
    if [ -n "$output" ]; then
      emit_error "$output"
    fi

    emit_error "Failed to connect to $ssid"
  '';

  networkForgetUiScript = pkgs.writeShellScriptBin "leviathan-network-forget-ui" ''
    ui_index="$1"

    emit_error() {
      printf 'error:%s\n' "$1"
      exit 1
    }

    emit_ok() {
      printf 'ok:%s\n' "$1"
      exit 0
    }

    case "$ui_index" in
      ""|*[!0-9]*) emit_error "Invalid network index" ;;
    esac

    ssid="$(network-status ssid known "$ui_index")"
    if [ -z "$ssid" ]; then
      emit_error "Preferred network not found"
    fi

    output="$(${pkgs.networkmanager}/bin/nmcli connection delete id "$ssid" 2>&1)"
    if [ $? -eq 0 ]; then
      emit_ok "Forgot $ssid"
    fi

    output="$(printf '%s' "$output" | tr '\n' ' ')"
    if [ -n "$output" ]; then
      emit_error "$output"
    fi

    emit_error "Failed to forget $ssid"
  '';

  qml = {
    imports = [];
    properties = [
      { name = "networkPopupOpen"; type = "bool"; value = false; }
      { name = "statusCollapsed"; type = "bool"; value = false; }
      { name = "preferredCollapsed"; type = "bool"; value = false; }
      { name = "availableCollapsed"; type = "bool"; value = false; }
      { name = "networkConnectFeedback"; type = "string"; value = ""; }
      { name = "networkConnectFailed"; type = "bool"; value = false; }
      { name = "forgetConfirmIndex"; type = "int"; value = -1; }
      { name = "forgetConfirmLabel"; type = "string"; value = ""; }
      { name = "knownEntries"; type = "var"; expr = "[]"; }
      { name = "availableEntries"; type = "var"; expr = "[]"; }
      { name = "popupWidth"; type = "real"; value = 340; }
      { name = "popupHeight"; type = "real"; value = 560; }
      { name = "popupPosX"; type = "real"; value = 0; }
      { name = "popupPosY"; type = "real"; value = 0; }
    ];
    functions = {
      ensurePopupBounds = {
        args = [];
        blocks = [
          {
            text = ''
if (!panel.screen) {
    return
}

popupWidth = Math.max(320, Math.min(Math.max(320, panel.width - 20), popupWidth))
popupHeight = Math.max(180, Math.min(Math.max(180, panel.screen.height - 20), popupHeight))
popupPosX = Math.max(10, Math.min(Math.max(10, panel.width - popupWidth - 10), popupPosX))
popupPosY = Math.max(panel.height + 8, Math.min(Math.max(panel.height + 8, panel.screen.height - popupHeight - 10), popupPosY))
'';
          }
        ];
      };

      connectNetwork = {
        args = [ "group" "index" "label" ];
        blocks = [
          {
            statements = [
              {
                assign = {
                  target = "networkConnectProc.command";
                  value = [
                    "sh"
                    "-lc"
                    { expr = "\"leviathan-network-connect-ui \" + group + \" \" + index"; }
                  ];
                };
              }
              {
                assign = {
                  target = "networkConnectFailed";
                  value = false;
                };
              }
              {
                assign = {
                  target = "networkConnectFeedback";
                  value = { expr = "\"Connecting to \" + label + \"...\""; };
                };
              }
              {
                assign = {
                  target = "networkConnectProc.running";
                  value = true;
                };
              }
              {
                assign = {
                  target = "forgetConfirmIndex";
                  value = -1;
                };
              }
              {
                assign = {
                  target = "forgetConfirmLabel";
                  value = "";
                };
              }
              {
                call = {
                  fn = "panel.refreshNetworkPopup";
                };
              }
            ];
          }
        ];
      };

      requestForgetPreferredNetwork = {
        args = [ "index" "label" ];
        blocks = [
          {
            statements = [
              {
                "if" = {
                  condition = "forgetConfirmIndex !== index";
                  "then" = [
                    {
                      assign = {
                        target = "forgetConfirmIndex";
                        value = { expr = "index"; };
                      };
                    }
                    {
                      assign = {
                        target = "forgetConfirmLabel";
                        value = { expr = "label"; };
                      };
                    }
                    {
                      "return" = true;
                    }
                  ];
                };
              }
              {
                assign = {
                  target = "networkForgetProc.command";
                  value = [
                    "sh"
                    "-lc"
                    { expr = "\"leviathan-network-forget-ui \" + index"; }
                  ];
                };
              }
              {
                assign = {
                  target = "networkForgetProc.running";
                  value = true;
                };
              }
              {
                assign = {
                  target = "forgetConfirmIndex";
                  value = -1;
                };
              }
              {
                assign = {
                  target = "forgetConfirmLabel";
                  value = "";
                };
              }
            ];
          }
        ];
      };

      refreshNetworkPopup = {
        args = [];
        blocks = [
          {
            statements = [
              {
                assign = {
                  target = "networkConnectedProc.running";
                  value = true;
                };
              }
              {
                assign = {
                  target = "networkSpeedProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };

      refreshNetworkPopupHeavy = {
        args = [];
        blocks = [
          {
            statements = [
              {
                assign = {
                  target = "networkKnownListProc.running";
                  value = true;
                };
              }
              {
                assign = {
                  target = "networkAvailableListProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };

      requestNetworkCacheScan = {
        args = [ "force" ];
        blocks = [
          {
            statements = [
              {
                assign = {
                  target = "networkCacheScanProc.command";
                  value = [
                    "sh"
                    "-lc"
                    { expr = "force ? \"network-status scan-cache force\" : \"network-status scan-cache\""; }
                  ];
                };
              }
              {
                assign = {
                  target = "networkCacheScanProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };

      positionPopupUnderNetworkButton = {
        args = [];
        blocks = [
          {
            text = ''
if (!panel.screen) {
    return
}

const pos = networkStatusButton.mapToItem(panelRoot, 0, 0)
const preferredW = Math.round(panel.screen.width * 0.34)

popupWidth = Math.max(320, Math.min(Math.max(320, panel.width - 20), Math.min(520, preferredW)))
popupPosY = pos.y + networkStatusButton.height + 8

const maxH = Math.max(120, panel.screen.height - popupPosY - 10)
popupHeight = Math.max(120, Math.min(maxH, popupHeight))
popupPosX = pos.x + networkStatusButton.width - popupWidth

ensurePopupBounds()
'';
          }
        ];
      };

      fitPopupHeightToContent = {
        args = [ "contentHeight" ];
        blocks = [
          {
            text = ''
if (!panel.screen) {
    return
}

const maxH = Math.max(120, panel.screen.height - popupPosY - 10)
popupHeight = Math.max(120, Math.min(maxH, contentHeight))
ensurePopupBounds()
'';
          }
        ];
      };
    };
    processes = [
      {
        id = "networkMoreProc";
        command = [ "sh" "-lc" "nm-connection-editor" ];
        running = false;
      }
      {
        id = "networkForgetProc";
        command = [ "sh" "-lc" "true" ];
        running = false;
        stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        if (value.startsWith("ok:")) {
                            panel.refreshNetworkPopupHeavy();
                            panel.requestNetworkCacheScan(true);
                            return;
                        }
                    }'';
      }
      {
        id = "networkConnectProc";
        command = [ "sh" "-lc" "true" ];
        running = false;
        stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        if (value.startsWith("ok:")) {
                            panel.networkConnectFailed = false;
                            panel.networkConnectFeedback = value.slice(3).trim();
                            panel.refreshNetworkPopup();
                            panel.requestNetworkCacheScan(true);
                            return;
                        }

                        if (value.startsWith("error:")) {
                            panel.networkConnectFailed = true;
                            panel.networkConnectFeedback = value.slice(6).trim();
                            return;
                        }

                        panel.networkConnectFailed = false;
                        panel.networkConnectFeedback = value;
                    }'';
      }
    ];
  };
in
{
  inherit qml;

  inherit networkConnectUiScript;
  inherit networkForgetUiScript;
}
