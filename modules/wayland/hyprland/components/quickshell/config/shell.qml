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

            function refreshNetworkPopup() {
                networkConnectedProc.running = true
                networkSpeedProc.running = true
                networkKnown0Proc.running = true
                networkKnown1Proc.running = true
                networkKnown2Proc.running = true
                networkKnown3Proc.running = true
                networkAvail0Proc.running = true
                networkAvail1Proc.running = true
                networkAvail2Proc.running = true
                networkAvail3Proc.running = true
                networkAvail4Proc.running = true
                networkAvail5Proc.running = true
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
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.clicked()
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
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.clicked()
                }
            }

            component NetworkRow: Rectangle {
                property alias text: label.text
                signal clicked

                radius: 8
                border.width: 1
                border.color: "#59617e"
                color: "#30374a"
                Layout.fillWidth: true
                Layout.preferredHeight: 32

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
                            onClicked: launchProc.running = true
                        }

                        QuickButton {
                            text: "󰆍"
                            onClicked: terminalProc.running = true
                        }

                        QuickButton {
                            text: "󰉋"
                            onClicked: filesProc.running = true
                        }

                        QuickButton {
                            text: "󰖟"
                            onClicked: browserProc.running = true
                        }

                        QuickButton {
                            text: "󰸉"
                            onClicked: wallpaperProc.running = true
                        }

                        QuickButton {
                            text: "󰄀"
                            onClicked: screenshotProc.running = true
                        }

                        QuickButton {
                            text: "󰒓"
                            onClicked: settingsProc.running = true
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
                            text: networkText.text
                            onClicked: {
                                panel.networkPopupOpen = !panel.networkPopupOpen
                                if (panel.networkPopupOpen) {
                                    networkResetProc.running = true
                                    panel.refreshNetworkPopup()
                                }
                            }
                        }

                        StatusPill {
                            text: bluetoothText.text
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
                command: ["sh", "-lc", "kitty"]
                running: false
            }

            Process {
                id: filesProc
                command: ["sh", "-lc", "thunar"]
                running: false
            }

            Process {
                id: browserProc
                command: ["sh", "-lc", "librewolf"]
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

            LazyLoader {
                active: panel.networkPopupOpen
                loading: panel.networkPopupOpen

                PanelWindow {
                    id: networkPopup
                    screen: panel.screen
                    color: "transparent"
                    width: 340
                    height: Math.min(620, popupColumn.implicitHeight + 24)
                    exclusiveZone: 0

                    anchors {
                        top: true
                        right: true
                    }

                    margins {
                        top: 74
                        right: 10
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

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Network"
                                    color: "#f3f7ff"
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }

                                QuickButton {
                                    text: "󰅖"
                                    onClicked: panel.networkPopupOpen = false
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52
                                radius: 10
                                color: "#323a4f"
                                border.width: 1
                                border.color: "#59617e"

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 2

                                    Text {
                                        text: networkConnectedText.text
                                        color: "#f1f5fd"
                                        font.pixelSize: 12
                                        font.family: "Maple Mono NF"
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: networkSpeedText.text
                                        color: "#b9c3de"
                                        font.pixelSize: 11
                                        font.family: "Maple Mono NF"
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Text {
                                text: "Preferred Networks"
                                color: "#b9c3de"
                                font.pixelSize: 11
                                font.family: "Maple Mono NF"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                QuickButton {
                                    text: "▲"
                                    onClicked: {
                                        networkScrollProc.command = ["sh", "-lc", "leviathan-network-scroll known up 4"]
                                        networkScrollProc.running = true
                                        panel.refreshNetworkPopup()
                                    }
                                }

                                QuickButton {
                                    text: "▼"
                                    onClicked: {
                                        networkScrollProc.command = ["sh", "-lc", "leviathan-network-scroll known down 4"]
                                        networkScrollProc.running = true
                                        panel.refreshNetworkPopup()
                                    }
                                }
                            }

                            NetworkRow {
                                text: known0Text.text
                                onClicked: {
                                    networkConnectProc.command = ["sh", "-lc", "leviathan-network-connect-ui known 0"]
                                    networkConnectProc.running = true
                                    panel.refreshNetworkPopup()
                                }
                            }

                            NetworkRow {
                                text: known1Text.text
                                onClicked: {
                                    networkConnectProc.command = ["sh", "-lc", "leviathan-network-connect-ui known 1"]
                                    networkConnectProc.running = true
                                    panel.refreshNetworkPopup()
                                }
                            }

                            NetworkRow {
                                text: known2Text.text
                                onClicked: {
                                    networkConnectProc.command = ["sh", "-lc", "leviathan-network-connect-ui known 2"]
                                    networkConnectProc.running = true
                                    panel.refreshNetworkPopup()
                                }
                            }

                            NetworkRow {
                                text: known3Text.text
                                onClicked: {
                                    networkConnectProc.command = ["sh", "-lc", "leviathan-network-connect-ui known 3"]
                                    networkConnectProc.running = true
                                    panel.refreshNetworkPopup()
                                }
                            }

                            Text {
                                text: "Available Networks"
                                color: "#b9c3de"
                                font.pixelSize: 11
                                font.family: "Maple Mono NF"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                QuickButton {
                                    text: "▲"
                                    onClicked: {
                                        networkScrollProc.command = ["sh", "-lc", "leviathan-network-scroll available up 6"]
                                        networkScrollProc.running = true
                                        panel.refreshNetworkPopup()
                                    }
                                }

                                QuickButton {
                                    text: "▼"
                                    onClicked: {
                                        networkScrollProc.command = ["sh", "-lc", "leviathan-network-scroll available down 6"]
                                        networkScrollProc.running = true
                                        panel.refreshNetworkPopup()
                                    }
                                }
                            }

                            NetworkRow {
                                text: avail0Text.text
                                onClicked: {
                                    networkConnectProc.command = ["sh", "-lc", "leviathan-network-connect-ui available 0"]
                                    networkConnectProc.running = true
                                    panel.refreshNetworkPopup()
                                }
                            }

                            NetworkRow {
                                text: avail1Text.text
                                onClicked: {
                                    networkConnectProc.command = ["sh", "-lc", "leviathan-network-connect-ui available 1"]
                                    networkConnectProc.running = true
                                    panel.refreshNetworkPopup()
                                }
                            }

                            NetworkRow {
                                text: avail2Text.text
                                onClicked: {
                                    networkConnectProc.command = ["sh", "-lc", "leviathan-network-connect-ui available 2"]
                                    networkConnectProc.running = true
                                    panel.refreshNetworkPopup()
                                }
                            }

                            NetworkRow {
                                text: avail3Text.text
                                onClicked: {
                                    networkConnectProc.command = ["sh", "-lc", "leviathan-network-connect-ui available 3"]
                                    networkConnectProc.running = true
                                    panel.refreshNetworkPopup()
                                }
                            }

                            NetworkRow {
                                text: avail4Text.text
                                onClicked: {
                                    networkConnectProc.command = ["sh", "-lc", "leviathan-network-connect-ui available 4"]
                                    networkConnectProc.running = true
                                    panel.refreshNetworkPopup()
                                }
                            }

                            NetworkRow {
                                text: avail5Text.text
                                onClicked: {
                                    networkConnectProc.command = ["sh", "-lc", "leviathan-network-connect-ui available 5"]
                                    networkConnectProc.running = true
                                    panel.refreshNetworkPopup()
                                }
                            }

                            StatusPill {
                                Layout.alignment: Qt.AlignHCenter
                                text: "More Options"
                                onClicked: networkMoreProc.running = true
                            }
                        }
                    }
                }
            }
        }
    }
}
