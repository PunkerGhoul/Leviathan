let
  qml = {
    shellRoot = {
      modelExpr = "Quickshell.screens";
      panelId = "panel";
      requiredProperties = [
        { type = "var"; name = "modelData"; }
      ];
    };
    properties = [
      {
        name = "_launchQueues";
        type = "var";
        expr = "({})";
      }
      {
        name = "terminalProcSlot";
        type = "int";
        value = 0;
      }
      {
        name = "filesProcSlot";
        type = "int";
        value = 0;
      }
      {
        name = "browserProcSlot";
        type = "int";
        value = 0;
      }
    ];
    functions = {
      launchNow = {
        args = [ "proc" ];
        blocks = [
          {
            declarations = [
              "if (!panel._launchQueues) panel._launchQueues = ({})"
              "const key = proc.objectName && proc.objectName.length > 0 ? proc.objectName : proc.command.join(\" \")"
              "const queue = panel._launchQueues[key] || ({ pending: 0, pumping: false })"
            ];
            statements = [
              {
                raw = "panel._launchQueues[key] = queue";
              }
              {
                raw = "queue.pending += 1";
              }
              {
                "if" = {
                  condition = "queue.pumping";
                  "then" = [
                    { "return" = true; }
                  ];
                };
              }
              {
                raw = "queue.pumping = true";
              }
              {
                raw = [
                  "const pump = function() {"
                  "    if (queue.pending <= 0) {"
                  "        queue.pumping = false"
                  "        return"
                  "    }"
                  ""
                  "    queue.pending -= 1"
                  "    proc.running = false"
                  "    Qt.callLater(function() {"
                  "        proc.running = true"
                  "        Qt.callLater(pump)"
                  "    })"
                  "}"
                  ""
                  "pump()"
                ];
              }
            ];
          }
        ];
      };
    };
  };
in
{
  inherit qml;
}
