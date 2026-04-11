{
    imports = [];
    properties = [
      { name = "batteryPopupOpen"; type = "bool"; value = false; }
      { name = "batteryPopupWidth"; type = "real"; value = 360; }
      { name = "batteryPopupHeight"; type = "real"; value = 460; }
      { name = "batteryPopupPosX"; type = "real"; value = 0; }
      { name = "batteryPopupPosY"; type = "real"; value = 0; }
      { name = "batteryActionFeedback"; type = "string"; value = ""; }
      { name = "batteryActionFailed"; type = "bool"; value = false; }
      { name = "batteryAdvancedCollapsed"; type = "bool"; value = true; }
      { name = "batteryThresholdEditing"; type = "bool"; value = false; }
      { name = "batteryStartThresholdValue"; type = "int"; value = 40; }
      { name = "batteryStopThresholdValue"; type = "int"; value = 80; }
    ];
    functions = {
      ensureBatteryPopupBounds = {
        args = [];
        blocks = [
          {
            statements = [
              {
                "if" = {
                  condition = "!panel.screen";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                assign = {
                  target = "batteryPopupWidth";
                  value = { expr = "Math.max(320, Math.min(Math.max(320, panel.width - 20), batteryPopupWidth))"; };
                };
              }
              {
                assign = {
                  target = "batteryPopupHeight";
                  value = { expr = "Math.max(220, Math.min(Math.max(220, panel.screen.height - 20), batteryPopupHeight))"; };
                };
              }
              {
                assign = {
                  target = "batteryPopupPosX";
                  value = { expr = "Math.max(10, Math.min(Math.max(10, panel.width - batteryPopupWidth - 10), batteryPopupPosX))"; };
                };
              }
              {
                assign = {
                  target = "batteryPopupPosY";
                  value = { expr = "Math.max(panel.height + 8, Math.min(Math.max(panel.height + 8, panel.screen.height - batteryPopupHeight - 10), batteryPopupPosY))"; };
                };
              }
            ];
          }
        ];
      };

      positionPopupUnderBatteryButton = {
        args = [];
        blocks = [
          {
            statements = [
              {
                "if" = {
                  condition = "!panel.screen";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                assign = {
                  target = "batteryPopupWidth";
                  value = { expr = "Math.max(320, Math.min(Math.max(320, panel.width - 20), Math.min(520, Math.round(panel.screen.width * 0.34))))"; };
                };
              }
              {
                assign = {
                  target = "batteryPopupPosY";
                  value = { expr = "batteryStatusButton.mapToItem(panelRoot, 0, 0).y + batteryStatusButton.height + 8"; };
                };
              }
              {
                assign = {
                  target = "batteryPopupHeight";
                  value = { expr = "Math.max(220, Math.min(Math.max(220, panel.screen.height - batteryPopupPosY - 10), batteryPopupHeight))"; };
                };
              }
              {
                assign = {
                  target = "batteryPopupPosX";
                  value = { expr = "batteryStatusButton.mapToItem(panelRoot, 0, 0).x + batteryStatusButton.width - batteryPopupWidth"; };
                };
              }
              {
                call = {
                  fn = "ensureBatteryPopupBounds";
                };
              }
            ];
          }
        ];
      };

      fitBatteryPopupHeightToContent = {
        args = [ "contentHeight" ];
        blocks = [
          {
            statements = [
              {
                "if" = {
                  condition = "!panel.screen";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                assign = {
                  target = "batteryPopupHeight";
                  value = { expr = "Math.max(220, Math.min(Math.max(220, panel.screen.height - batteryPopupPosY - 10), contentHeight))"; };
                };
              }
              {
                call = {
                  fn = "ensureBatteryPopupBounds";
                };
              }
            ];
          }
        ];
      };

      refreshBatteryPopup = {
        args = [];
        blocks = [
          {
            statements = [
              {
                call = {
                  fn = "refreshBatteryThresholds";
                };
              }
              {
                "if" = {
                  condition = "batteryDetailsProc.running";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                assign = {
                  target = "batteryDetailsProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };

      refreshBatteryThresholds = {
        args = [];
        blocks = [
          {
            statements = [
              {
                "if" = {
                  condition = "batteryThresholdsProc.running";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                assign = {
                  target = "batteryThresholdsProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };

      stopBatteryRealtime = {
        args = [];
        blocks = [
          {
            statements = [
              {
                assign = {
                  target = "batteryDetailsProc.running";
                  value = false;
                };
              }
              {
                assign = {
                  target = "batteryThresholdsProc.running";
                  value = false;
                };
              }
            ];
          }
        ];
      };

      evaluateAutoProfile = {
        args = [];
        blocks = [
          {
            statements = [
              {
                "if" = {
                  condition = "batteryProfileText.text !== \"auto\"";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                "if" = {
                  condition = "autoProfileEvalProc.running";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                assign = {
                  target = "autoProfileEvalProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };

      applyPowerProfile = {
        args = [ "profile" ];
        blocks = [
          {
            statements = [
              {
                assign = {
                  target = "batteryActionFeedback";
                  value = { expr = "\"Applying \" + profile + \" profile...\""; };
                };
              }
              {
                assign = {
                  target = "batteryActionFailed";
                  value = false;
                };
              }
              {
                assign = {
                  target = "batteryProfileApplyProc.command";
                  value = [
                    "sh"
                    "-lc"
                    { expr = "\"leviathan-power-profile \" + profile"; }
                  ];
                };
              }
              {
                assign = {
                  target = "batteryProfileApplyProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };

      applyChargeThreshold = {
        args = [ "kind" "value" ];
        blocks = [
          {
            statements = [
              {
                assign = {
                  target = "batteryPopupOpen";
                  value = false;
                };
              }
              {
                assign = {
                  target = "batteryActionFeedback";
                  value = { expr = "\"Applying \" + kind + \" threshold...\""; };
                };
              }
              {
                assign = {
                  target = "batteryActionFailed";
                  value = false;
                };
              }
              {
                assign = {
                  target = "batteryThresholdApplyProc.command";
                  value = [
                    "sh"
                    "-lc"
                    { expr = "\"leviathan-battery-threshold \" + kind + \" \" + value"; }
                  ];
                };
              }
              {
                assign = {
                  target = "batteryThresholdApplyProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };

      applyChargeThresholdPair = {
        args = [ "startValue" "stopValue" ];
        blocks = [
          {
            statements = [
              {
                assign = {
                  target = "batteryPopupOpen";
                  value = false;
                };
              }
              {
                assign = {
                  target = "batteryActionFeedback";
                  value = "Applying start/stop thresholds...";
                };
              }
              {
                assign = {
                  target = "batteryActionFailed";
                  value = false;
                };
              }
              {
                assign = {
                  target = "batteryThresholdPairApplyProc.command";
                  value = [
                    "sh"
                    "-lc"
                    { expr = "\"leviathan-battery-threshold-pair \" + startValue + \" \" + stopValue"; }
                  ];
                };
              }
              {
                assign = {
                  target = "batteryThresholdPairApplyProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };
    };

    processes = [
      {
        id = "batteryProfileApplyProc";
        command = [ "sh" "-lc" "true" ];
        running = false;
        stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        if (value.startsWith("ok:")) {
                            panel.batteryActionFailed = false;
                            panel.batteryActionFeedback = value.slice(3).trim();
                            panel.refreshBatteryPopup();
                            return;
                        }

                        if (value.startsWith("error:")) {
                            panel.batteryActionFailed = true;
                            panel.batteryActionFeedback = value.slice(6).trim();
                            return;
                        }

                        panel.batteryActionFailed = false;
                        panel.batteryActionFeedback = value;
                    }'';
      }
      {
        id = "batteryThresholdApplyProc";
        command = [ "sh" "-lc" "true" ];
        running = false;
        stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        if (value.startsWith("ok:")) {
                            panel.batteryActionFailed = false;
                            panel.batteryActionFeedback = value.slice(3).trim();
                            panel.refreshBatteryPopup();
                            return;
                        }

                        if (value.startsWith("error:")) {
                            panel.batteryActionFailed = true;
                            panel.batteryActionFeedback = value.slice(6).trim();
                            return;
                        }

                        panel.batteryActionFailed = false;
                        panel.batteryActionFeedback = value;
                    }'';
      }
                {
                id = "batteryThresholdPairApplyProc";
                command = [ "sh" "-lc" "true" ];
                running = false;
                stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        if (value.startsWith("ok:")) {
                          panel.batteryActionFailed = false;
                          panel.batteryActionFeedback = value.slice(3).trim();
                          panel.refreshBatteryPopup();
                          return;
                        }

                        if (value.startsWith("error:")) {
                          panel.batteryActionFailed = true;
                          panel.batteryActionFeedback = value.slice(6).trim();
                          return;
                        }

                        panel.batteryActionFailed = false;
                        panel.batteryActionFeedback = value;
                      }'';
                }
      {
        id = "autoProfileEvalProc";
        command = [ "sh" "-lc" "leviathan-auto-profile-eval" ];
        running = false;
        stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        if (value.startsWith("ok:auto:")) {
                            panel.refreshBatteryPopup();
                        }
                    }'';
      }
    ];
  }
