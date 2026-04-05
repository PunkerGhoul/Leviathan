let
  qml = {
    shellRoot = {
      modelExpr = "Quickshell.screens";
      panelId = "panel";
      requiredProperties = [
        { type = "var"; name = "modelData"; }
      ];
    };
    properties = [ ];
    functions = {
      launchNow = {
        args = [ "proc" ];
        blocks = [
          {
            statements = [
              {
                assign = {
                  target = "proc.running";
                  value = false;
                };
              }
              {
                raw = [
                  "Qt.callLater(function() {"
                  "    proc.running = true"
                  "})"
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
