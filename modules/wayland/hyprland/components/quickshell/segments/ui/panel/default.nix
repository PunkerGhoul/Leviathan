let
  qml = {
    windowConfig = {
      screen = "modelData";
      color = "transparent";
      implicitHeight = 56;
      exclusiveZone = 56;
      anchors = {
        top = true;
        left = true;
        right = true;
      };
      margins = {
        top = 10;
        left = 10;
        right = 10;
      };
    };

    components = [
      {
        name = "QuickButton";
        base = "Rectangle";
        body = builtins.readFile ./fragments/components/QuickButton.qml;
      }
      {
        name = "StatusPill";
        base = "Rectangle";
        body = builtins.readFile ./fragments/components/StatusPill.qml;
      }
      {
        name = "NetworkRow";
        base = "Rectangle";
        body = builtins.readFile ./fragments/components/NetworkRow.qml;
      }
    ];

    topbarUi = {
      text = builtins.readFile ./fragments/topbar-ui.qml;
    };

    hiddenTexts = [
      { id = "updatesText"; visible = false; text = "󰚰 0"; }
      { id = "networkText"; visible = false; text = "󰤯"; }
      { id = "bluetoothText"; visible = false; text = "󰂲"; }
      { id = "batteryText"; visible = false; text = "󰁹 100%"; }
      { id = "networkConnectedText"; visible = false; text = "Disconnected"; }
      { id = "networkSpeedText"; visible = false; text = "No traffic"; }
    ];

    processes = {
      action = [
        { id = "launchProc"; command = [ "sh" "-lc" "leviathan-launcher" ]; running = false; }
        { id = "terminalProc0"; command = [ "sh" "-lc" "setsid -f kitty >/dev/null 2>&1" ]; running = false; }
        { id = "terminalProc1"; command = [ "sh" "-lc" "setsid -f kitty >/dev/null 2>&1" ]; running = false; }
        { id = "terminalProc2"; command = [ "sh" "-lc" "setsid -f kitty >/dev/null 2>&1" ]; running = false; }
        { id = "filesProc0"; command = [ "sh" "-lc" "setsid -f thunar >/dev/null 2>&1" ]; running = false; }
        { id = "filesProc1"; command = [ "sh" "-lc" "setsid -f thunar >/dev/null 2>&1" ]; running = false; }
        { id = "filesProc2"; command = [ "sh" "-lc" "setsid -f thunar >/dev/null 2>&1" ]; running = false; }
        { id = "bluetoothOpenProc"; command = [ "sh" "-lc" "setsid -f blueman-manager >/dev/null 2>&1 || setsid -f blueberry >/dev/null 2>&1" ]; running = false; }
        { id = "browserProc0"; command = [ "sh" "-lc" "setsid -f librewolf >/dev/null 2>&1" ]; running = false; }
        { id = "browserProc1"; command = [ "sh" "-lc" "setsid -f librewolf >/dev/null 2>&1" ]; running = false; }
        { id = "browserProc2"; command = [ "sh" "-lc" "setsid -f librewolf >/dev/null 2>&1" ]; running = false; }
        { id = "wallpaperProc"; command = [ "sh" "-lc" "leviathan-wallpaper-picker" ]; running = false; }
        { id = "screenshotProc"; command = [ "sh" "-lc" "leviathan-screenshot" ]; running = false; }
        { id = "settingsProc"; command = [ "sh" "-lc" "leviathan-settings" ]; running = false; }
        { id = "powerMenuProc"; command = [ "sh" "-lc" "leviathan-power-menu" ]; running = false; }
        { id = "updatesRunProc"; command = [ "sh" "-lc" "leviathan-run-updates" ]; running = false; }
      ];

      status = [
        {
          id = "clockProc";
          command = [ "sh" "-lc" "date '+%m/%d/%Y  %I:%M %p'" ];
          running = true;
          stdoutOnStreamFinished = "clockText.text = this.text.trim()";
        }
        {
          id = "updatesProc";
          command = [ "sh" "-lc" "leviathan-updates" ];
          running = true;
          stdoutOnStreamFinished = "updatesText.text = this.text.trim()";
        }
        {
          id = "networkProc";
          command = [ "sh" "-lc" "network-status icon" ];
          running = true;
          stdoutOnStreamFinished = ''{
                        const icon = this.text.trim();
                        networkText.text = icon.length > 0 ? icon : "󰤮";
                    }'';
        }
        {
          id = "networkConnectedProc";
          command = [ "sh" "-lc" "network-status connected" ];
          running = true;
          stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        networkConnectedText.text = value.length > 0 ? value : "Disconnected";
                    }'';
        }
        {
          id = "networkSpeedProc";
          command = [ "sh" "-lc" "network-status speed" ];
          running = true;
          stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        networkSpeedText.text = value.length > 0 ? value : "No traffic";
                    }'';
        }
        {
          id = "networkKnownListProc";
          command = [ "sh" "-lc" "network-status known" ];
          running = true;
          stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        panel.knownEntries = value.length > 0 ? value.split("\n") : [];
                    }'';
        }
        {
          id = "networkAvailableListProc";
          command = [ "sh" "-lc" "network-status available" ];
          running = true;
          stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        panel.availableEntries = value.length > 0 ? value.split("\n") : [];
                    }'';
        }
        {
          id = "networkCacheScanProc";
          command = [ "sh" "-lc" "network-status scan-cache" ];
          running = false;
          stdoutOnStreamFinished = ''{
                        const result = this.text.trim();
                        if (result === "changed") {
                            panel.refreshNetworkPopupHeavy();
                        }
                    }'';
        }
      ];

      networkSlots = [ ];

      device = [
        {
          id = "bluetoothProc";
          command = [ "sh" "-lc" "leviathan-bluetooth-status" ];
          running = true;
          stdoutOnStreamFinished = ''{
                        const icon = this.text.trim();
                        bluetoothText.text = icon.length > 0 ? icon : "󰂲";
                    }'';
        }
        {
          id = "batteryProc";
          command = [ "sh" "-lc" "leviathan-battery" ];
          running = true;
          stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        batteryText.text = value.length > 0 ? value : "󰁹 100%";
                    }'';
        }
      ];
    };

    timers = [
      {
        interval = 1000;
        repeat = true;
        runningExpr = "true";
        onTriggered = "clockProc.running = true";
      }
      {
        interval = 10000;
        repeat = true;
        runningExpr = "true";
        onTriggered = ''{
                    updatesProc.running = true
                    networkProc.running = true
                    bluetoothProc.running = true
                    batteryProc.running = true
                }'';
      }
      {
        interval = 4000;
        repeat = true;
        runningExpr = "panel.networkPopupOpen";
        onTriggered = "panel.refreshNetworkPopup()";
      }
      {
        interval = 5000;
        repeat = true;
        runningExpr = "panel.networkPopupOpen";
        onTriggered = "panel.requestNetworkCacheScan(false)";
      }
    ];

    networkPopup = {
      text = builtins.readFile ./fragments/network-popup.qml;
    };
  };
in
{
  inherit qml;
}
