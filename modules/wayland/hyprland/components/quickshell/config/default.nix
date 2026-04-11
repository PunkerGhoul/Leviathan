{ lib, pkgs }:
let
  layoutBlocks = import ../segments/ui/layout;
  panelBlocks = import ../segments/ui/panel;
  networkBlocks = import ../segments/utilities/network { inherit pkgs; };
  batteryBlocks = import ../segments/utilities/battery.nix { inherit pkgs; };

  joinQml = parts: lib.concatStringsSep "\n" (builtins.filter (part: part != "") parts);

  indentLines = spaces: text:
    let
      prefix = lib.fixedWidthString spaces " " "";
      trimmed = lib.removeSuffix "\n" text;
      lines = lib.splitString "\n" trimmed;
    in
    lib.concatStringsSep "\n" (builtins.map (line: if line == "" then "" else "${prefix}${line}") lines);

  fail = msg: builtins.throw "quickshell config: ${msg}";

  ensure = condition: msg:
    if condition then null else fail msg;

  isNumber = value: builtins.isInt value || builtins.isFloat value;

  requireString = where: name: value:
    if builtins.isString value then value else fail "${where}.${name} must be a string";

  requireNumber = where: name: value:
    if isNumber value then value else fail "${where}.${name} must be a number";

  requireBool = where: name: value:
    if builtins.isBool value then value else fail "${where}.${name} must be a bool";

  renderQmlValue = value:
    if builtins.isBool value then
      if value then "true" else "false"
    else if builtins.isInt value || builtins.isFloat value then
      toString value
    else if builtins.isString value then
      "\"${escapeQmlString value}\""
    else
      toString value;

  renderDeclarationValue = value:
    if builtins.isAttrs value then
      if value ? expr then value.expr
      else if value ? exprBlock then value.exprBlock
      else if value ? exprLines then lib.concatStringsSep "\n" value.exprLines
      else if value ? raw then value.raw
      else if value ? rawBlock then value.rawBlock
      else renderQmlValue value
    else
      renderQmlValue value;

  renderNamedDeclarations = keyword: entries:
    lib.mapAttrsToList (
      name: value:
      let
        renderedValue = renderDeclarationValue value;
      in
      if keyword == "" then "${name} = ${renderedValue}" else "${keyword} ${name} = ${renderedValue}"
    ) entries;

  renderJsValue = value:
    if builtins.isAttrs value then
      if value ? expr then value.expr
      else if value ? exprBlock then value.exprBlock
      else if value ? exprLines then lib.concatStringsSep "\n" value.exprLines
      else if value ? raw then value.raw
      else renderQmlValue value
    else if builtins.isList value then
      "[${lib.concatStringsSep ", " (builtins.map renderJsValue value)}]"
    else
      renderQmlValue value;

  renderStatement = stmt:
    if builtins.isAttrs stmt then
      if stmt ? assign then
        let
          assignment = stmt.assign;
          target = assignment.target or assignment.name;
          value = renderJsValue (assignment.value or "");
        in
        "${target} = ${value}"
      else if stmt ? call then
        let
          callSpec = stmt.call;
          args = lib.concatStringsSep ", " (builtins.map renderJsValue (callSpec.args or []));
        in
        "${callSpec.fn}(${args})"
      else if builtins.hasAttr "return" stmt then
        if builtins.isAttrs stmt."return" then
          if stmt."return" ? value then "return ${renderJsValue stmt."return".value}" else "return"
        else if builtins.isBool stmt."return" then
          if stmt."return" then "return" else ""
        else
          "return ${renderJsValue stmt."return"}"
      else if builtins.hasAttr "if" stmt then
        let
          ifSpec = stmt."if";
          thenRaw = renderStatements (if ifSpec ? "then" then ifSpec."then" else []);
          thenBody = if thenRaw == "" then "" else indentLines 4 thenRaw;
          elseRaw = renderStatements (if ifSpec ? "else" then ifSpec."else" else []);
          elseBody = if elseRaw == "" then "" else indentLines 4 elseRaw;
          elseClause = if elseRaw == "" then "" else "\n} else {\n${elseBody}";
        in
        ''
if (${ifSpec.condition}) {
${thenBody}${elseClause}
}
''
      else if stmt ? raw then
        if builtins.isList stmt.raw then lib.concatStringsSep "\n" stmt.raw else stmt.raw
      else if stmt ? rawBlock then
        stmt.rawBlock
      else
        ""
    else
      stmt;

  renderStatements = statements:
    let
      rendered = builtins.filter (line: line != "") (builtins.map renderStatement statements);
    in
    lib.concatStringsSep "\n" rendered;

  renderFunctionBodyPart = part:
    if part == "" then ""
    else indentLines 16 part;

  renderFunctionBlock = block:
    let
      constLines =
        if builtins.isAttrs (block.consts or {}) then
          renderNamedDeclarations "const" (block.consts or {})
        else
          [];
      letLines =
        if builtins.isAttrs (block.lets or {}) then
          renderNamedDeclarations "let" (block.lets or {})
        else
          [];
      declarationLines =
        if builtins.isAttrs (block.declarations or []) then
          renderNamedDeclarations "" (block.declarations or {})
        else
          builtins.map renderDeclaration (block.declarations or []);
      statementsRaw = renderStatements (block.statements or []);
      textRaw = block.text or "";
      pieces = builtins.filter (p: p != "") [
        (lib.concatStringsSep "\n" (constLines ++ letLines ++ declarationLines))
        statementsRaw
        textRaw
      ];
    in
    lib.concatStringsSep "\n\n" pieces;

  renderDeclaration = decl:
    if builtins.isAttrs decl then
      let
        keyword = decl.keyword or decl.kind or "const";
      in
      if decl ? value then "${keyword} ${decl.name} = ${renderDeclarationValue decl.value}" else "${keyword} ${decl.name}"
    else
      decl;

  renderFunction = name: fnDef:
    let
      args = lib.concatStringsSep ", " (fnDef.args or []);
      blocks = fnDef.blocks or [];
      functionBodyRaw =
        if blocks != [] then
          lib.concatStringsSep "\n\n" (builtins.map renderFunctionBlock blocks)
        else
          renderFunctionBlock {
            consts = fnDef.consts or {};
            lets = fnDef.lets or {};
            declarations = fnDef.declarations or [];
            statements = fnDef.statements or [];
            text = fnDef.text or "";
          };
      functionBody = renderFunctionBodyPart functionBodyRaw;
    in
    ''
            function ${name}(${args}) {
${functionBody}
            }
    '';

  renderFunctionsSlot = slot:
    if builtins.isAttrs slot then
      lib.concatStringsSep "\n\n" (lib.mapAttrsToList renderFunction slot)
    else
      slot;

  renderWindowConfigSlot = slot:
    if builtins.isAttrs slot then
      let
        _ = ensure (slot ? screen) "windowConfig.screen is required";
        __ = ensure (slot ? color) "windowConfig.color is required";
        ___ = ensure (slot ? implicitHeight) "windowConfig.implicitHeight is required";
        ____ = ensure (slot ? exclusiveZone) "windowConfig.exclusiveZone is required";

        screen = requireString "windowConfig" "screen" slot.screen;
        color = requireString "windowConfig" "color" slot.color;
        implicitHeight = requireNumber "windowConfig" "implicitHeight" slot.implicitHeight;
        exclusiveZone = requireNumber "windowConfig" "exclusiveZone" slot.exclusiveZone;

        anchors = slot.anchors or {};
        anchorTop = requireBool "windowConfig.anchors" "top" (anchors.top or false);
        anchorLeft = requireBool "windowConfig.anchors" "left" (anchors.left or false);
        anchorRight = requireBool "windowConfig.anchors" "right" (anchors.right or false);

        margins = slot.margins or {};
        marginTop = requireNumber "windowConfig.margins" "top" (margins.top or 0);
        marginLeft = requireNumber "windowConfig.margins" "left" (margins.left or 0);
        marginRight = requireNumber "windowConfig.margins" "right" (margins.right or 0);
      in
      ''
            screen: ${screen}
            color: "${escapeQmlString color}"
            implicitHeight: ${toString implicitHeight}
            exclusiveZone: ${toString exclusiveZone}

            anchors {
                top: ${if anchorTop then "true" else "false"}
                left: ${if anchorLeft then "true" else "false"}
                right: ${if anchorRight then "true" else "false"}
            }

            margins {
                top: ${toString marginTop}
                left: ${toString marginLeft}
                right: ${toString marginRight}
            }
      ''
    else
      slot;

  requireList = where: name: value:
    if builtins.isList value then value else fail "${where}.${name} must be a list";

  requireAttrs = where: name: value:
    if builtins.isAttrs value then value else fail "${where}.${name} must be an attrset";

  requireProcessCommand = where: cmd:
    let
      _ = ensure (builtins.isList cmd) "${where}.command must be a list";
      _items = builtins.map (item:
        if builtins.isString item then item else fail "${where}.command[] must be a string"
      ) cmd;
    in
    cmd;

  renderComponent = comp:
    let
      _ = ensure (builtins.isAttrs comp) "components[] must be an attrset";
      __ = ensure (comp ? name) "components[].name is required";
      ___ = ensure (comp ? base) "components[].base is required";
      ____ = ensure (comp ? body) "components[].body is required";
      name = requireString "components[]" "name" comp.name;
      base = requireString "components[]" "base" comp.base;
      body = requireString "components[]" "body" comp.body;
    in
    ''
            component ${name}: ${base} {
${indentLines 16 body}
            }
  '';

  renderComponentsSlot = slot:
    if builtins.isList slot then
      lib.concatStringsSep "\n\n" (builtins.map renderComponent slot)
    else
      slot;

  renderBlockSlot = slot:
    if builtins.isAttrs slot && slot ? text then
      slot.text
    else
      slot;

  inferPropertyType = value:
    if builtins.isBool value then "bool"
    else if builtins.isInt value then "int"
    else if builtins.isFloat value then "real"
    else if builtins.isString value then "string"
    else "var";

  renderProperty = prop:
    if builtins.isAttrs prop then
      let
        type = prop.type or (inferPropertyType (prop.value or null));
        renderedValue =
          if prop ? expr then prop.expr
          else if prop ? value then renderQmlValue prop.value
          else if prop ? raw then prop.raw
          else "undefined";
      in
      "            property ${type} ${prop.name}: ${renderedValue}"
    else
      prop;

  renderPropertiesSlot = slot:
    if builtins.isList slot then
      lib.concatStringsSep "\n" (builtins.map renderProperty slot)
    else if builtins.isAttrs slot then
      lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: renderProperty { inherit name value; }) slot)
    else
      slot;

  renderRequiredProperty = prop:
    if builtins.isAttrs prop then
      let
        _ = ensure (prop ? name) "shellRoot.requiredProperties[].name is required";
        propName = requireString "shellRoot.requiredProperties[]" "name" prop.name;
        propType = requireString "shellRoot.requiredProperties[]" "type" (prop.type or "var");
      in
      "            required property ${propType} ${propName}"
    else
      "            required property var ${requireString "shellRoot.requiredProperties[]" "name" prop}";

  renderShellRootOpen = slot:
    if builtins.isAttrs slot then
      let
        modelExpr = requireString "shellRoot" "modelExpr" (slot.modelExpr or "Quickshell.screens");
        panelId = requireString "shellRoot" "panelId" (slot.panelId or "panel");
        requiredProps = slot.requiredProperties or [];
        _ = ensure (builtins.isList requiredProps) "shellRoot.requiredProperties must be a list";
        requiredPropsRendered = lib.concatStringsSep "\n" (builtins.map renderRequiredProperty requiredProps);
      in
      ''
ShellRoot {
    Variants {
        model: ${modelExpr}

        PanelWindow {
            id: ${panelId}
${requiredPropsRendered}
      ''
    else
      slot;

  renderShellRootClose = slot:
    if builtins.isAttrs slot then
      ''
        }
    }
}
      ''
    else
      slot;

  escapeQmlString = value: lib.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] value;

  renderCommandList = cmd:
    let
      command = requireProcessCommand "process" cmd;
    in
    "[${lib.concatStringsSep ", " (builtins.map (v: "\"${escapeQmlString v}\"") command)}]";

  renderProcess = proc:
    let
      _ = ensure (builtins.isAttrs proc) "processes[] must be an attrset";
      __ = ensure (proc ? id) "processes[].id is required";
      ___ = ensure (proc ? command) "processes[].command is required";
      ____ = ensure (proc ? running) "processes[].running is required";
      id = requireString "processes[]" "id" proc.id;
      command = requireProcessCommand "processes[]" proc.command;
      running = requireBool "processes[]" "running" proc.running;
      stdoutOnStreamFinished =
        if proc ? stdoutOnStreamFinished then
          requireString "processes[]" "stdoutOnStreamFinished" proc.stdoutOnStreamFinished
        else
          null;
    in
    ''
            Process {
                id: ${id}
                command: ${renderCommandList command}
                running: ${if running then "true" else "false"}
${if stdoutOnStreamFinished != null then ''
                stdout: StdioCollector {
                    onStreamFinished: ${stdoutOnStreamFinished}
                }
'' else ""}
            }
  '';

  renderProcessesSlot = slot:
    if builtins.isList slot then
      lib.concatStringsSep "\n\n" (builtins.map renderProcess slot)
    else
      slot;

  renderText = item: ''
            Text {
                id: ${item.id}
                visible: ${if item.visible then "true" else "false"}
                text: "${escapeQmlString item.text}"
            }
  '';

  renderTextsSlot = slot:
    if builtins.isList slot then
      lib.concatStringsSep "\n\n" (builtins.map renderText slot)
    else
      slot;

  renderTimer = timer: ''
            Timer {
                interval: ${toString timer.interval}
                repeat: ${if timer.repeat then "true" else "false"}
                running: ${timer.runningExpr}
                onTriggered: ${timer.onTriggered}
            }
  '';

  renderTimersSlot = slot:
    if builtins.isList slot then
      lib.concatStringsSep "\n\n" (builtins.map renderTimer slot)
    else
      slot;

  framework = {
    imports = [
      "import QtQuick"
      "import QtQuick.Layouts"
      "import Quickshell"
      "import Quickshell.Io"
      "import Quickshell.Hyprland"
    ] ++ networkBlocks.qml.imports ++ batteryBlocks.qml.imports;

    properties = [
      layoutBlocks.qml.properties
      networkBlocks.qml.properties
      batteryBlocks.qml.properties
    ];

    functions = [
      layoutBlocks.qml.functions
      networkBlocks.qml.functions
      batteryBlocks.qml.functions
    ];
  };

  importsQml = joinQml framework.imports;
  propertiesQml = joinQml (builtins.map renderPropertiesSlot framework.properties);
  functionsQml = joinQml (builtins.map renderFunctionsSlot framework.functions);

  shellRoot = layoutBlocks.qml.shellRoot or null;
  shellRootOpenQml =
    if shellRoot != null then
      renderShellRootOpen shellRoot
    else
      layoutBlocks.qml.shellRootOpen;
  shellRootCloseQml =
    if shellRoot != null then
      renderShellRootClose shellRoot
    else
      layoutBlocks.qml.shellRootClose;

  shellRootTemplate = builtins.readFile ../segments/ui/shell/fragments/root.qml;
  shellRootRendered = lib.replaceStrings
    [
      "// @SHELLROOT_OPEN@"
      "// @PANEL_PROPERTIES@"
      "// @PANEL_FUNCTIONS@"
      "// @PANEL_WINDOW_CONFIG@"
      "// @PANEL_COMPONENTS@"
      "// @TOPBAR_UI@"
      "// @TOPBAR_ACTION_PROCESSES@"
      "// @NETWORK_PROCESSES@"
      "// @PANEL_HIDDEN_TEXTS@"
      "// @PANEL_STATUS_PROCESSES@"
      "// @PANEL_NETWORK_SLOT_PROCESSES@"
      "// @PANEL_DEVICE_PROCESSES@"
      "// @PANEL_TIMERS@"
      "// @NETWORK_POPUP_UI@"
      "// @BATTERY_POPUP_UI@"
      "// @SHELLROOT_CLOSE@"
    ]
    [
      shellRootOpenQml
      propertiesQml
      functionsQml
      (renderWindowConfigSlot panelBlocks.qml.windowConfig)
      (renderComponentsSlot panelBlocks.qml.components)
      (renderBlockSlot panelBlocks.qml.topbarUi)
      (renderProcessesSlot panelBlocks.qml.processes.action)
      (renderProcessesSlot (networkBlocks.qml.processes ++ batteryBlocks.qml.processes))
      (renderTextsSlot panelBlocks.qml.hiddenTexts)
      (renderProcessesSlot panelBlocks.qml.processes.status)
      (renderProcessesSlot panelBlocks.qml.processes.networkSlots)
      (renderProcessesSlot panelBlocks.qml.processes.device)
      (renderTimersSlot panelBlocks.qml.timers)
      (renderBlockSlot panelBlocks.qml.networkPopup)
      (renderBlockSlot panelBlocks.qml.batteryPopup)
      shellRootCloseQml
    ]
    shellRootTemplate;

  shellContent = lib.concatStringsSep "\n" [
    importsQml
    shellRootRendered
  ];
in
pkgs.writeText "shell.qml" shellContent
