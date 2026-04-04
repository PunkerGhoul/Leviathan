import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            property bool networkPopupOpen: false
            property bool connectPromptOpen: false
            property bool statusCollapsed: false
            property bool preferredCollapsed: false
            property bool availableCollapsed: false
            property string selectedNetworkGroup: ""
            property int selectedNetworkIndex: -1
            property string selectedNetworkLabel: ""
            property string selectedNetworkPassword: ""
            property var knownEntries: []
            property var availableEntries: []
            property real popupWidth: 340
            property real popupHeight: 560
            property real popupPosX: 0
            property real popupPosY: 0

            function ensurePopupBounds() {
                if (!panel.screen) {
                    return
                }

                const minW = 320
                const minH = 180
                const maxW = Math.max(minW, panel.screen.width - 20)
                const maxH = Math.max(minH, panel.screen.height - 20)

                popupWidth = Math.max(minW, Math.min(maxW, popupWidth))
                popupHeight = Math.max(minH, Math.min(maxH, popupHeight))

                const minX = 10
                const minY = 10
                const maxX = Math.max(10, panel.screen.width - popupWidth - 10)
                const maxY = Math.max(10, panel.screen.height - popupHeight - 10)

                popupPosX = Math.max(minX, Math.min(maxX, popupPosX))
                popupPosY = Math.max(minY, Math.min(maxY, popupPosY))
            }

            function shellEscape(value) {
                return value
                    .replace(/\\/g, "\\\\")
                    .replace(/"/g, "\\\"")
                    .replace(/\$/g, "\\$")
                    .replace(/`/g, "\\`")
            }

            function promptConnection(group, index, label) {
                selectedNetworkGroup = group
                selectedNetworkIndex = index
                selectedNetworkLabel = label
                selectedNetworkPassword = ""
                connectPromptOpen = true
            }

            function cancelConnectionPrompt() {
                connectPromptOpen = false
                selectedNetworkGroup = ""
                selectedNetworkIndex = -1
                selectedNetworkLabel = ""
                selectedNetworkPassword = ""
            }

            function confirmConnection() {
                if (selectedNetworkGroup === "" || selectedNetworkIndex < 0) {
                    return
                }

                const passwordPart = selectedNetworkPassword.length > 0
                    ? " \"" + shellEscape(selectedNetworkPassword) + "\""
                    : ""

                networkConnectProc.command = [
                    "sh",
                    "-lc",
                    "leviathan-network-connect-ui " + selectedNetworkGroup + " " + selectedNetworkIndex + passwordPart
                ]
                networkConnectProc.running = true
                cancelConnectionPrompt()
                panel.refreshNetworkPopup()
            }

            function refreshNetworkPopup() {
                networkConnectedProc.running = true
                networkSpeedProc.running = true
            }

            function refreshNetworkPopupHeavy() {
                networkKnownListProc.running = true
                networkAvailableListProc.running = true
            }

            function requestNetworkCacheScan(force) {
                networkCacheScanProc.command = [
                    "sh",
                    "-lc",
                    force ? "network-status scan-cache force" : "network-status scan-cache"
                ]
                networkCacheScanProc.running = true
            }

            function launchNow(proc) {
                proc.running = false
                Qt.callLater(function() {
                    proc.running = true
                })
            }

            function positionPopupUnderNetworkButton() {
                if (!panel.screen) {
                    return
                }

                const pos = panel.itemPosition(networkStatusButton)

                const minW = 320
                const preferredW = Math.round(panel.screen.width * 0.34)
                const maxW = Math.max(minW, panel.screen.width - 20)
                popupWidth = Math.max(minW, Math.min(maxW, Math.min(520, preferredW)))

                popupPosY = pos.y + networkStatusButton.height + 8

                const availableBelow = panel.screen.height - popupPosY - 10
                const minH = 120
                const maxH = Math.max(minH, availableBelow)
                popupHeight = Math.max(minH, Math.min(maxH, popupHeight))

                popupPosX = pos.x + networkStatusButton.width - popupWidth
                ensurePopupBounds()
            }

            function fitPopupHeightToContent(contentHeight) {
                if (!panel.screen) {
                    return
                }

                const minH = 120
                const maxH = Math.max(minH, panel.screen.height - popupPosY - 10)
                popupHeight = Math.max(minH, Math.min(maxH, contentHeight))
                ensurePopupBounds()
            }

            screen: modelData
            color: "transparent"
            implicitHeight: 56
            exclusiveZone: 56

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top: 10
                left: 10
                right: 10
            }

            component QuickButton: Rectangle {
                property alias text: label.text
                property bool accent: false
                property bool danger: false
                signal clicked

                radius: 10
                border.width: 1
                border.color: danger ? "#a34f59" : (accent ? "#7a84ac" : "#626a87")
                color: danger ? "#7a2f39" : (accent ? "#6a7396" : "#343b50")
                Layout.preferredHeight: 34
                Layout.preferredWidth: 36

                Text {
                    id: label
                    anchors.centerIn: parent
                    color: "#f1f5fd"
                    font.pixelSize: 16
                    font.family: "Symbols Nerd Font"
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    preventStealing: true
                    onPressed: function(mouse) {
                        parent.clicked()
                        mouse.accepted = false
                    }
                }
            }

            component StatusPill: Rectangle {
                property alias text: label.text
                property bool warning: false
                signal clicked

                radius: 10
                border.width: 1
                border.color: warning ? "#8a778f" : "#626a87"
                color: warning ? "#4a3f58" : "#343b50"
                Layout.preferredHeight: 34
                Layout.preferredWidth: Math.max(44, label.implicitWidth + 16)

                Text {
                    id: label
                    anchors.centerIn: parent
                    color: "#f1f5fd"
                    font.pixelSize: 13
                    font.family: "Maple Mono NF"
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.clicked()
                }
            }

            component NetworkRow: Rectangle {
                property alias text: label.text
                property int networkIndex: -1
                signal clicked

                radius: 8
                border.width: 1
                border.color: "#59617e"
                color: "#30374a"
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                implicitHeight: 32
                height: 32

                Text {
                    id: label
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    color: "#f1f5fd"
                    font.pixelSize: 12
                    font.family: "Maple Mono NF"
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.clicked()
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 16
                border.width: 1
                border.color: "#595f75"
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "#2f3445" }
                    GradientStop { position: 1.0; color: "#222836" }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    RowLayout {
                        id: leftGroup
                        spacing: 8

                        QuickButton {
                            text: "󰣇"
                            accent: true
                            onClicked: panel.launchNow(launchProc)
                        }

                        QuickButton {
                            text: "󰆍"
                            onClicked: panel.launchNow(terminalProc)
                        }

                        QuickButton {
                            text: "󰉋"
                            onClicked: panel.launchNow(filesProc)
                        }

                        QuickButton {
                            text: "󰖟"
                            onClicked: panel.launchNow(browserProc)
                        }

                        QuickButton {
                            text: "󰸉"
                            onClicked: panel.launchNow(wallpaperProc)
                        }

                        QuickButton {
                            text: "󰄀"
                            onClicked: panel.launchNow(screenshotProc)
                        }

                        QuickButton {
                            text: "󰒓"
                            onClicked: panel.launchNow(settingsProc)
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        radius: 10
                        border.width: 1
                        border.color: "#6a7396"
                        color: "#2b3142"
                        Layout.preferredHeight: 34
                        Layout.preferredWidth: 230

                        Text {
                            id: clockText
                            anchors.centerIn: parent
                            color: "#e5e9f0"
                            font.pixelSize: 14
                            font.family: "Maple Mono NF"
                            text: "--/--/---- --:-- --"
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        id: rightGroup
                        spacing: 8

                        StatusPill {
                            text: updatesText.text
                            warning: true
                            onClicked: updatesRunProc.running = true
                        }

                        StatusPill {
                            id: networkStatusButton
                            text: networkText.text
                            onClicked: {
                                panel.networkPopupOpen = !panel.networkPopupOpen
                                if (panel.networkPopupOpen) {
                                    panel.refreshNetworkPopup()
                                    panel.refreshNetworkPopupHeavy()
                                    panel.requestNetworkCacheScan(false)
                                    panel.positionPopupUnderNetworkButton()
                                }
                            }
                        }

                        StatusPill {
                            text: bluetoothText.text
                            onClicked: bluetoothOpenProc.running = true
                        }

                        StatusPill {
                            text: batteryText.text
                        }

                        QuickButton {
                            text: "󰐥"
                            danger: true
                            onClicked: powerMenuProc.running = true
                        }
                    }
                }
            }

            Process {
                id: launchProc
                command: ["sh", "-lc", "leviathan-launcher"]
                running: false
            }

            Process {
                id: terminalProc
                command: ["sh", "-lc", "setsid -f kitty >/dev/null 2>&1"]
                running: false
            }

            Process {
                id: filesProc
                command: ["sh", "-lc", "setsid -f thunar >/dev/null 2>&1"]
                running: false
            }

            Process {
                id: bluetoothOpenProc
                command: ["sh", "-lc", "setsid -f blueman-manager >/dev/null 2>&1 || setsid -f blueberry >/dev/null 2>&1"]
                running: false
            }

            Process {
                id: browserProc
                command: ["sh", "-lc", "setsid -f librewolf >/dev/null 2>&1"]
                running: false
            }

            Process {
                id: wallpaperProc
                command: ["sh", "-lc", "leviathan-wallpaper-picker"]
                running: false
            }

            Process {
                id: screenshotProc
                command: ["sh", "-lc", "leviathan-screenshot"]
                running: false
            }

            Process {
                id: settingsProc
                command: ["sh", "-lc", "leviathan-settings"]
                running: false
            }

            Process {
                id: powerMenuProc
                command: ["sh", "-lc", "leviathan-power-menu"]
                running: false
            }

            Process {
                id: updatesRunProc
                command: ["sh", "-lc", "leviathan-run-updates"]
                running: false
            }

            Process {
                id: networkMoreProc
                command: ["sh", "-lc", "nm-connection-editor"]
                running: false
            }

            Process {
                id: networkConnectProc
                command: ["sh", "-lc", "true"]
                running: false
            }

            Process {
                id: networkScrollProc
                command: ["sh", "-lc", "true"]
                running: false
            }

            Process {
                id: networkResetProc
                command: ["sh", "-lc", "leviathan-network-scroll-reset"]
                running: false
            }

            Text {
                id: updatesText
                visible: false
                text: "󰚰 0"
            }

            Text {
                id: networkText
                visible: false
                text: "󰤯"
            }

            Text {
                id: bluetoothText
                visible: false
                text: "󰂲"
            }

            Text {
                id: batteryText
                visible: false
                text: "󰁹 100%"
            }

            Text {
                id: networkConnectedText
                visible: false
                text: "Disconnected"
            }

            Text {
                id: networkSpeedText
                visible: false
                text: "No traffic"
            }

            Text {
                id: known0Text
                visible: false
                text: "-"
            }

            Text {
                id: known1Text
                visible: false
                text: "-"
            }

            Text {
                id: known2Text
                visible: false
                text: "-"
            }

            Text {
                id: known3Text
                visible: false
                text: "-"
            }

            Text {
                id: avail0Text
                visible: false
                text: "-"
            }

            Text {
                id: avail1Text
                visible: false
                text: "-"
            }

            Text {
                id: avail2Text
                visible: false
                text: "-"
            }

            Text {
                id: avail3Text
                visible: false
                text: "-"
            }

            Text {
                id: avail4Text
                visible: false
                text: "-"
            }

            Text {
                id: avail5Text
                visible: false
                text: "-"
            }

            Process {
                id: clockProc
                command: ["sh", "-lc", "date '+%m/%d/%Y  %I:%M %p'"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: clockText.text = this.text.trim()
                }
            }

            Process {
                id: updatesProc
                command: ["sh", "-lc", "leviathan-updates"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: updatesText.text = this.text.trim()
                }
            }

            Process {
                id: networkProc
                command: ["sh", "-lc", "network-status icon"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        const icon = this.text.trim();
                        networkText.text = icon.length > 0 ? icon : "󰤮";
                    }
                }
            }

            Process {
                id: networkConnectedProc
                command: ["sh", "-lc", "network-status connected"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        const value = this.text.trim();
                        networkConnectedText.text = value.length > 0 ? value : "Disconnected";
                    }
                }
            }

            Process {
                id: networkSpeedProc
                command: ["sh", "-lc", "network-status speed"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        const value = this.text.trim();
                        networkSpeedText.text = value.length > 0 ? value : "No traffic";
                    }
                }
            }

            Process {
                id: networkKnownListProc
                command: ["sh", "-lc", "network-status known"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        const value = this.text.trim();
                        panel.knownEntries = value.length > 0 ? value.split("\n") : [];
                    }
                }
            }

            Process {
                id: networkAvailableListProc
                command: ["sh", "-lc", "network-status available"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        const value = this.text.trim();
                        panel.availableEntries = value.length > 0 ? value.split("\n") : [];
                    }
                }
            }

            Process {
                id: networkCacheScanProc
                command: ["sh", "-lc", "network-status scan-cache"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        const result = this.text.trim();
                        if (result === "changed") {
                            panel.refreshNetworkPopupHeavy();
                        }
                    }
                }
            }

            Process {
                id: networkKnown0Proc
                command: ["sh", "-lc", "leviathan-network-slot-ui known 0"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: known0Text.text = this.text.trim()
                }
            }

            Process {
                id: networkKnown1Proc
                command: ["sh", "-lc", "leviathan-network-slot-ui known 1"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: known1Text.text = this.text.trim()
                }
            }

            Process {
                id: networkKnown2Proc
                command: ["sh", "-lc", "leviathan-network-slot-ui known 2"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: known2Text.text = this.text.trim()
                }
            }

            Process {
                id: networkKnown3Proc
                command: ["sh", "-lc", "leviathan-network-slot-ui known 3"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: known3Text.text = this.text.trim()
                }
            }

            Process {
                id: networkAvail0Proc
                command: ["sh", "-lc", "leviathan-network-slot-ui available 0"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: avail0Text.text = this.text.trim()
                }
            }

            Process {
                id: networkAvail1Proc
                command: ["sh", "-lc", "leviathan-network-slot-ui available 1"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: avail1Text.text = this.text.trim()
                }
            }

            Process {
                id: networkAvail2Proc
                command: ["sh", "-lc", "leviathan-network-slot-ui available 2"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: avail2Text.text = this.text.trim()
                }
            }

            Process {
                id: networkAvail3Proc
                command: ["sh", "-lc", "leviathan-network-slot-ui available 3"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: avail3Text.text = this.text.trim()
                }
            }

            Process {
                id: networkAvail4Proc
                command: ["sh", "-lc", "leviathan-network-slot-ui available 4"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: avail4Text.text = this.text.trim()
                }
            }

            Process {
                id: networkAvail5Proc
                command: ["sh", "-lc", "leviathan-network-slot-ui available 5"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: avail5Text.text = this.text.trim()
                }
            }

            Process {
                id: bluetoothProc
                command: ["sh", "-lc", "leviathan-bluetooth-status"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        const icon = this.text.trim();
                        bluetoothText.text = icon.length > 0 ? icon : "󰂲";
                    }
                }
            }

            Process {
                id: batteryProc
                command: ["sh", "-lc", "leviathan-battery"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        const value = this.text.trim();
                        batteryText.text = value.length > 0 ? value : "󰁹 100%";
                    }
                }
            }

            Timer {
                interval: 1000
                repeat: true
                running: true
                onTriggered: clockProc.running = true
            }

            Timer {
                interval: 10000
                repeat: true
                running: true
                onTriggered: {
                    updatesProc.running = true
                    networkProc.running = true
                    bluetoothProc.running = true
                    batteryProc.running = true
                }
            }

            Timer {
                interval: 4000
                repeat: true
                running: panel.networkPopupOpen
                onTriggered: panel.refreshNetworkPopup()
            }

            Timer {
                interval: 5000
                repeat: true
                running: panel.networkPopupOpen
                onTriggered: panel.requestNetworkCacheScan(false)
            }

            LazyLoader {
                active: panel.networkPopupOpen
                loading: panel.networkPopupOpen

                PopupWindow {
                    id: networkPopup
                    visible: panel.networkPopupOpen
                    color: "transparent"
                    anchor.window: panel
                    anchor.rect.x: panel.popupPosX
                    anchor.rect.y: panel.popupPosY
                    width: panel.popupWidth
                    height: panel.popupHeight

                    Component.onCompleted: {
                        panel.ensurePopupBounds()
                        Qt.callLater(function() {
                            panel.fitPopupHeightToContent(popupColumn.implicitHeight + 24)
                        })
                    }

                    Rectangle {
                        id: popupBody
                        anchors.fill: parent
                        radius: 14
                        border.width: 1
                        border.color: "#6f7899"
                        color: "#262d3c"

                        ColumnLayout {
                            id: popupColumn
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            onImplicitHeightChanged: panel.fitPopupHeightToContent(implicitHeight + 24)

                            RowLayout {
                                Layout.fillWidth: true
                                id: popupTitleBar

                                Text {
                                    text: "Network"
                                    color: "#f3f7ff"
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }

                                QuickButton {
                                    id: closePopupButton
                                    text: "󰅖"
                                    onClicked: panel.networkPopupOpen = false
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: 10
                                border.width: 1
                                border.color: "#59617e"
                                color: "#323a4f"
                                implicitHeight: panel.statusCollapsed ? 38 : 78

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6

                                    Rectangle {
                                        width: parent.width
                                        height: 22
                                        color: "transparent"

                                        Row {
                                            anchors.fill: parent
                                            spacing: 6

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: panel.statusCollapsed ? "▸" : "▾"
                                                color: "#b9c3de"
                                                font.pixelSize: 12
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Connection Status"
                                                color: "#b9c3de"
                                                font.pixelSize: 11
                                                font.family: "Maple Mono NF"
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: panel.statusCollapsed = !panel.statusCollapsed
                                        }
                                    }

                                    Column {
                                        id: statusDetails
                                        visible: !panel.statusCollapsed
                                        spacing: 2
                                        width: parent.width
                                        clip: true

                                        Text {
                                            text: networkConnectedText.text
                                            color: "#f1f5fd"
                                            font.pixelSize: 12
                                            font.family: "Maple Mono NF"
                                            wrapMode: Text.NoWrap
                                            maximumLineCount: 1
                                            elide: Text.ElideRight
                                            width: statusDetails.width
                                        }

                                        Text {
                                            text: networkSpeedText.text
                                            color: "#b9c3de"
                                            font.pixelSize: 11
                                            font.family: "Maple Mono NF"
                                            wrapMode: Text.NoWrap
                                            maximumLineCount: 1
                                            elide: Text.ElideRight
                                            width: statusDetails.width
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.maximumHeight: panel.preferredCollapsed ? 38 : 220
                                radius: 10
                                border.width: 1
                                border.color: "#59617e"
                                color: "#323a4f"
                                implicitHeight: panel.preferredCollapsed ? 38 : preferredHeader.height + knownFlick.height + 20
                                clip: true

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6

                                    Rectangle {
                                        id: preferredHeader
                                        width: parent.width
                                        height: 22
                                        color: "transparent"

                                        Row {
                                            anchors.fill: parent
                                            spacing: 6

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: panel.preferredCollapsed ? "▸" : "▾"
                                                color: "#b9c3de"
                                                font.pixelSize: 12
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Preferred Networks"
                                                color: "#b9c3de"
                                                font.pixelSize: 11
                                                font.family: "Maple Mono NF"
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: panel.preferredCollapsed = !panel.preferredCollapsed
                                        }
                                    }

                                    Flickable {
                                        id: knownFlick
                                        visible: !panel.preferredCollapsed
                                        width: parent.width
                                        height: panel.preferredCollapsed
                                            ? 0
                                            : Math.min(knownColumn.implicitHeight, 160)
                                        clip: true
                                        contentWidth: width
                                        contentHeight: knownColumn.implicitHeight
                                        interactive: contentHeight > height

                                        WheelHandler {
                                            target: knownFlick
                                            onWheel: function(event) {
                                                const maxY = Math.max(0, knownFlick.contentHeight - knownFlick.height)
                                                knownFlick.contentY = Math.max(0, Math.min(maxY, knownFlick.contentY - event.angleDelta.y))
                                                event.accepted = true
                                            }
                                        }

                                        Column {
                                            id: knownColumn
                                            width: knownFlick.width
                                            spacing: 6

                                            Repeater {
                                                model: panel.knownEntries

                                                NetworkRow {
                                                    width: knownColumn.width
                                                    networkIndex: index
                                                    text: modelData
                                                    visible: text !== "-" && text.length > 0
                                                    enabled: true
                                                    onClicked: panel.promptConnection("known", networkIndex, modelData)
                                                }
                                            }

                                            Text {
                                                visible: panel.knownEntries.length === 0
                                                text: "No preferred networks in range"
                                                color: "#aeb9d6"
                                                font.pixelSize: 11
                                                font.family: "Maple Mono NF"
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.minimumHeight: panel.availableCollapsed ? 38 : 160
                                Layout.maximumHeight: panel.availableCollapsed ? 38 : 100000
                                radius: 10
                                border.width: 1
                                border.color: "#59617e"
                                color: "#323a4f"
                                implicitHeight: panel.availableCollapsed ? 38 : 200
                                clip: true

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6

                                    Rectangle {
                                        id: availableHeader
                                        width: parent.width
                                        height: 22
                                        color: "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 6

                                            Text {
                                                Layout.alignment: Qt.AlignVCenter
                                                text: panel.availableCollapsed ? "▸" : "▾"
                                                color: "#b9c3de"
                                                font.pixelSize: 12
                                            }

                                            Text {
                                                Layout.alignment: Qt.AlignVCenter
                                                text: "Available Networks (" + panel.availableEntries.length + ")"
                                                color: "#b9c3de"
                                                font.pixelSize: 11
                                                font.family: "Maple Mono NF"
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                id: availableRefreshButton
                                                width: 22
                                                height: 22
                                                radius: 6
                                                border.width: 1
                                                border.color: "#59617e"
                                                color: "#2f374b"
                                                Layout.alignment: Qt.AlignVCenter

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰑐"
                                                    color: "#d7def3"
                                                    font.pixelSize: 12
                                                    font.family: "Symbols Nerd Font"
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: panel.requestNetworkCacheScan(true)
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.right: parent.right
                                            anchors.rightMargin: 30
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: panel.availableCollapsed = !panel.availableCollapsed
                                        }
                                    }

                                    Flickable {
                                        id: availableFlick
                                        visible: !panel.availableCollapsed
                                        width: parent.width
                                        height: panel.availableCollapsed
                                            ? 0
                                            : Math.max(80, parent.height - availableHeader.height - 8)
                                        clip: true
                                        contentWidth: width
                                        contentHeight: availableColumn.implicitHeight
                                        interactive: contentHeight > height

                                        WheelHandler {
                                            target: availableFlick
                                            onWheel: function(event) {
                                                const maxY = Math.max(0, availableFlick.contentHeight - availableFlick.height)
                                                availableFlick.contentY = Math.max(0, Math.min(maxY, availableFlick.contentY - event.angleDelta.y))
                                                event.accepted = true
                                            }
                                        }

                                        Column {
                                            id: availableColumn
                                            width: availableFlick.width
                                            spacing: 6

                                            Repeater {
                                                model: panel.availableEntries

                                                NetworkRow {
                                                    width: availableColumn.width
                                                    networkIndex: index
                                                    text: modelData
                                                    visible: text !== "-" && text.length > 0
                                                    enabled: true
                                                    onClicked: panel.promptConnection("available", networkIndex, modelData)
                                                }
                                            }

                                            Text {
                                                visible: panel.availableEntries.length === 0
                                                text: "No available networks found"
                                                color: "#aeb9d6"
                                                font.pixelSize: 11
                                                font.family: "Maple Mono NF"
                                            }
                                        }
                                    }
                                }
                            }

                            StatusPill {
                                Layout.alignment: Qt.AlignHCenter
                                text: "More Options"
                                onClicked: networkMoreProc.running = true
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: panel.connectPromptOpen
                            color: "#80161b27"
                            radius: 14
                            z: 50

                            Rectangle {
                                width: Math.min(parent.width - 24, 300)
                                anchors.centerIn: parent
                                radius: 10
                                border.width: 1
                                border.color: "#7a84ac"
                                color: "#2d3447"
                                implicitHeight: confirmColumn.implicitHeight + 16

                                ColumnLayout {
                                    id: confirmColumn
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Connect to: " + panel.selectedNetworkLabel
                                        color: "#f1f5fd"
                                        font.pixelSize: 12
                                        font.family: "Maple Mono NF"
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        radius: 8
                                        border.width: 1
                                        border.color: "#59617e"
                                        color: "#1f2534"

                                        TextInput {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            color: "#f1f5fd"
                                            font.pixelSize: 12
                                            font.family: "Maple Mono NF"
                                            echoMode: TextInput.Password
                                            text: panel.selectedNetworkPassword
                                            onTextChanged: panel.selectedNetworkPassword = text
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Password optional for known networks"
                                        color: "#aeb9d6"
                                        font.pixelSize: 10
                                        font.family: "Maple Mono NF"
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true

                                        StatusPill {
                                            text: "Cancel"
                                            onClicked: panel.cancelConnectionPrompt()
                                        }

                                        Item { Layout.fillWidth: true }

                                        StatusPill {
                                            warning: true
                                            text: "Connect"
                                            onClicked: panel.confirmConnection()
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
