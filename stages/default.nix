{ pkgs }:
let
  declaredStages = {
    updates = import ./updates {
      inherit pkgs;
    };
  };

  stageNames = builtins.attrNames declaredStages;

  mergeAttrsList = attrsList:
    builtins.foldl' (acc: attrs: acc // attrs) { } attrsList;

  packages = mergeAttrsList (map
    (stageName:
      let
        stage = declaredStages.${stageName};
      in
      (stage.packages or { }) // {
        "${stageName}-install" = stage.install.package;
        "${stageName}-uninstall" = stage.uninstall.package;
        "${stageName}-status" = stage.status.package;
      }
    )
    stageNames);

  apps = mergeAttrsList (map
    (stageName:
      let
        stage = declaredStages.${stageName};
      in
      {
        "${stageName}-install" = {
          type = "app";
          program = "${stage.install.package}/bin/${stage.install.binary}";
          meta.description = stage.install.description;
        };
        "${stageName}-uninstall" = {
          type = "app";
          program = "${stage.uninstall.package}/bin/${stage.uninstall.binary}";
          meta.description = stage.uninstall.description;
        };
        "${stageName}-status" = {
          type = "app";
          program = "${stage.status.package}/bin/${stage.status.binary}";
          meta.description = stage.status.description;
        };
      }
    )
    stageNames);
in
{
  inherit declaredStages packages apps;
}
