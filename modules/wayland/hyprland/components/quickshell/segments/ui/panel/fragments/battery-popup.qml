            LazyLoader {
                active: panel.batteryPopupOpen
                loading: panel.batteryPopupOpen

                PopupWindow {
                    id: batteryPopup
                    visible: panel.batteryPopupOpen
                    color: "transparent"
                    anchor.window: panel
                    anchor.rect.x: panel.batteryPopupPosX
                    anchor.rect.y: panel.batteryPopupPosY
                    implicitWidth: panel.batteryPopupWidth
                    implicitHeight: panel.batteryPopupHeight

                    Component.onCompleted: {
                        panel.positionPopupUnderBatteryButton()
                        panel.ensureBatteryPopupBounds()
                        Qt.callLater(function() {
                            panel.fitBatteryPopupHeightToContent(batteryPopupColumn.implicitHeight + 24)
                        })
                    }

                    onVisibleChanged: {
                        if (visible) {
                            panel.positionPopupUnderBatteryButton()
                            panel.refreshBatteryPopup()
                            Qt.callLater(function() {
                                panel.fitBatteryPopupHeightToContent(batteryPopupColumn.implicitHeight + 24)
                            })
                        } else {
                            panel.stopBatteryRealtime()
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        border.width: 1
                        border.color: "#6f7899"
                        color: "#262d3c"

                        Flickable {
                            id: batteryPopupScroll
                            anchors.fill: parent
                            clip: true
                            contentWidth: width
                            contentHeight: batteryPopupColumn.implicitHeight + 24
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: contentHeight > height

                            ColumnLayout {
                                id: batteryPopupColumn
                                x: 12
                                y: 12
                                width: Math.max(0, batteryPopupScroll.width - 24)
                                spacing: 8
                                onImplicitHeightChanged: panel.fitBatteryPopupHeightToContent(implicitHeight + 24)

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Battery"
                                    color: "#f3f7ff"
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }

                                QuickButton {
                                    text: "󰅖"
                                    onClicked: panel.batteryPopupOpen = false
                                }
                            }

                            Rectangle {
                                id: batteryProfileCard
                                Layout.fillWidth: true
                                radius: 10
                                border.width: 1
                                border.color: "#59617e"
                                color: "#323a4f"
                                implicitHeight: 238 + thermalTableRow.height + 6

                                Column {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    anchors.topMargin: 10
                                    anchors.bottomMargin: 24
                                    spacing: 5

                                    Text {
                                        text: batteryText.text + "  " + batteryStatusText.text
                                        color: "#f1f5fd"
                                        font.pixelSize: 16
                                        font.bold: true
                                        font.family: "Maple Mono NF"
                                    }

                                    Text {
                                        text: "AC: " + batteryAcStateText.text
                                        color: "#b9c3de"
                                        font.pixelSize: 11
                                        font.family: "Maple Mono NF"
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: "#4f5875"
                                    }

                                    Grid {
                                        width: parent.width
                                        columns: 2
                                        rowSpacing: 6
                                        columnSpacing: 12

                                        Rectangle {
                                            width: (parent.width - parent.columnSpacing) / 2
                                            height: 24
                                            radius: 6
                                            color: "#2c3346"

                                            Row {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                spacing: 6

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "Voltage"
                                                    color: "#9fb1de"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: batteryVoltageText.text
                                                    color: "#eef3ff"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: (parent.width - parent.columnSpacing) / 2
                                            height: 24
                                            radius: 6
                                            color: "#2c3346"

                                            Row {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                spacing: 6

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "Cycles"
                                                    color: "#9fb1de"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: batteryCyclesText.text
                                                    color: "#eef3ff"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: (parent.width - parent.columnSpacing) / 2
                                            height: 24
                                            radius: 6
                                            color: "#2c3346"

                                            Row {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                spacing: 6

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "Charge rate"
                                                    color: "#9fb1de"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: batteryRateText.text
                                                    color: "#eef3ff"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: (parent.width - parent.columnSpacing) / 2
                                            height: 24
                                            radius: 6
                                            color: "#2c3346"

                                            Row {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                spacing: 6

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "Remaining"
                                                    color: "#9fb1de"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: batteryTimeRemainingText.text
                                                    color: "#eef3ff"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                    elide: Text.ElideRight
                                                    width: parent.width - 80
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: (parent.width - parent.columnSpacing) / 2
                                            height: 24
                                            radius: 6
                                            color: "#2c3346"

                                            Row {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                spacing: 6

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "CPU temp"
                                                    color: "#9fb1de"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: batteryCpuTempText.text
                                                    color: "#eef3ff"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: (parent.width - parent.columnSpacing) / 2
                                            height: 24
                                            radius: 6
                                            color: "#2c3346"

                                            Row {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                spacing: 6

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "GPU temp"
                                                    color: "#9fb1de"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: batteryGpuTempText.text
                                                    color: "#eef3ff"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: (parent.width - parent.columnSpacing) / 2
                                            height: 24
                                            radius: 6
                                            color: "#2c3346"

                                            Row {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                spacing: 6

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "Thermal"
                                                    color: "#9fb1de"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: batteryThermalStateText.text
                                                    color: batteryThermalStateText.text === "Hot" || batteryThermalStateText.text === "Critical" ? "#ffbe9b" : "#eef3ff"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        id: batteryFansRow
                                        width: parent.width
                                        height: Math.max(26, fanFlow.implicitHeight + 10)
                                        radius: 6
                                        color: "#2c3346"
                                        property var fanEntries: {
                                            if (batteryFansText.text.length === 0 || batteryFansText.text === "N/A") {
                                                return [];
                                            }
                                            return batteryFansText.text.split(" | ");
                                        }

                                        Flow {
                                            id: fanFlow
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            anchors.topMargin: 5
                                            anchors.bottomMargin: 5
                                            spacing: 10

                                            Text {
                                                text: "Fans"
                                                color: "#9fb1de"
                                                font.pixelSize: 10
                                                font.family: "Maple Mono NF"
                                            }

                                            Repeater {
                                                model: batteryFansRow.fanEntries
                                                delegate: Row {
                                                    spacing: 4

                                                    Text {
                                                        id: fanIcon
                                                        text: "󰈐"
                                                        color: "#b9c3de"
                                                        font.pixelSize: 11
                                                        font.family: "Maple Mono NF"
                                                        property int rpmValue: {
                                                            const match = modelData.match(/-\s*(\d+)/);
                                                            return match ? parseInt(match[1], 10) : 1400;
                                                        }

                                                        NumberAnimation on rotation {
                                                            from: 0
                                                            to: 360
                                                            duration: Math.max(350, 2200 - Math.min(1700, fanIcon.rpmValue * 0.2))
                                                            loops: Animation.Infinite
                                                            running: panel.batteryPopupOpen
                                                        }
                                                    }

                                                    Text {
                                                        text: modelData
                                                        color: "#eef3ff"
                                                        font.pixelSize: 10
                                                        font.family: "Maple Mono NF"
                                                    }
                                                }
                                            }

                                            Text {
                                                visible: batteryFansRow.fanEntries.length === 0
                                                text: "N/A"
                                                color: "#eef3ff"
                                                font.pixelSize: 10
                                                font.family: "Maple Mono NF"
                                            }
                                        }
                                    }

                                    Rectangle {
                                        id: thermalTableRow
                                        width: parent.width
                                        radius: 6
                                        color: "#2c3346"
                                        property var thermalEntries: {
                                            if (batteryThermalZonesText.text.length === 0 || batteryThermalZonesText.text === "N/A") {
                                                return [];
                                            }
                                            return batteryThermalZonesText.text.split(" | ");
                                        }
                                        property int thermalColumns: 3
                                        property int thermalRows: Math.ceil(thermalEntries.length / thermalColumns)
                                        property real tileHeight: 26
                                        function parseTemp(entry) {
                                            const match = entry.match(/([0-9]+(?:\.[0-9]+)?)\s*°C/);
                                            return match ? parseFloat(match[1]) : NaN;
                                        }
                                        function colorForTemp(tempC) {
                                            if (Number.isNaN(tempC)) {
                                                return "#9fb1de";
                                            }
                                            if (tempC >= 85) {
                                                return "#ff6b6b";
                                            }
                                            if (tempC >= 70) {
                                                return "#ff9f40";
                                            }
                                            if (tempC >= 50) {
                                                return "#ffd166";
                                            }
                                            return "#6ec6ff";
                                        }
                                        height: thermalBody.implicitHeight + 12

                                        Column {
                                            id: thermalBody
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            anchors.topMargin: 6
                                            anchors.bottomMargin: 6
                                            spacing: 6

                                            Text {
                                                text: "Thermal: " + batteryThermalStateText.text
                                                color: batteryThermalStateText.text === "Critical"
                                                    ? "#ff6b6b"
                                                    : (batteryThermalStateText.text === "Hot"
                                                        ? "#ff9f40"
                                                        : (batteryThermalStateText.text === "Warm" ? "#ffd166" : "#9fb1de"))
                                                font.pixelSize: 10
                                                font.family: "Maple Mono NF"
                                            }

                                            Grid {
                                                id: thermalGrid
                                                width: parent.width
                                                columns: thermalTableRow.thermalColumns
                                                columnSpacing: 8
                                                rowSpacing: 6
                                                visible: thermalTableRow.thermalEntries.length > 0

                                                Repeater {
                                                    model: thermalTableRow.thermalEntries
                                                    delegate: Rectangle {
                                                        width: (thermalGrid.width - (thermalGrid.columnSpacing * (thermalGrid.columns - 1))) / thermalGrid.columns
                                                        height: thermalTableRow.tileHeight
                                                        radius: 5
                                                        color: "#39435a"

                                                        Row {
                                                            anchors.fill: parent
                                                            anchors.leftMargin: 6
                                                            anchors.rightMargin: 6
                                                            spacing: 4

                                                            Text {
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: "󰔏"
                                                                color: thermalTableRow.colorForTemp(thermalTableRow.parseTemp(modelData))
                                                                font.pixelSize: 11
                                                                font.family: "Maple Mono NF"
                                                            }

                                                            Text {
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: modelData
                                                                color: "#eef3ff"
                                                                font.pixelSize: 9
                                                                font.family: "Maple Mono NF"
                                                                horizontalAlignment: Text.AlignLeft
                                                                verticalAlignment: Text.AlignVCenter
                                                                wrapMode: Text.NoWrap
                                                                elide: Text.ElideRight
                                                                width: parent.width - 24
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.rightMargin: 10
                                    anchors.bottomMargin: 6
                                    visible: batteryBackendText.text.length > 0
                                    text: batteryBackendText.text
                                    color: "#7f89a8"
                                    font.pixelSize: 9
                                    font.family: "Maple Mono NF"
                                }
                            }

                            Rectangle {
                                id: powerProfileCard
                                Layout.fillWidth: true
                                radius: 10
                                border.width: 1
                                border.color: "#59617e"
                                color: "#323a4f"
                                implicitHeight: 116
                                property bool turboAvailable: batteryAcStateText.text === "Connected"

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    Text {
                                        text: "Power Profile"
                                        color: "#b9c3de"
                                        font.pixelSize: 11
                                        font.family: "Maple Mono NF"
                                    }

                                    RowLayout {
                                        width: parent.width
                                        spacing: 6

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 28
                                            radius: 7
                                            border.width: 1
                                            border.color: batteryProfileText.text === "auto" ? "#8db1ff" : "#59617e"
                                            color: batteryProfileText.text === "auto" ? "#3a496f" : "#2f374b"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Auto"
                                                color: "#dfe8ff"
                                                font.pixelSize: 11
                                                font.family: "Maple Mono NF"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: panel.applyPowerProfile("auto")
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 28
                                            radius: 7
                                            border.width: 1
                                            border.color: batteryProfileText.text === "power-saver" ? "#8db1ff" : "#59617e"
                                            color: batteryProfileText.text === "power-saver" ? "#3a496f" : "#2f374b"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Saver"
                                                color: "#dfe8ff"
                                                font.pixelSize: 11
                                                font.family: "Maple Mono NF"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: panel.applyPowerProfile("power-saver")
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 28
                                            radius: 7
                                            border.width: 1
                                            border.color: batteryProfileText.text === "balanced" ? "#8db1ff" : "#59617e"
                                            color: batteryProfileText.text === "balanced" ? "#3a496f" : "#2f374b"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Balanced"
                                                color: "#dfe8ff"
                                                font.pixelSize: 11
                                                font.family: "Maple Mono NF"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: panel.applyPowerProfile("balanced")
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 28
                                            radius: 7
                                            border.width: 1
                                            border.color: batteryProfileText.text === "performance" ? "#8db1ff" : "#59617e"
                                            color: batteryProfileText.text === "performance" ? "#3a496f" : "#2f374b"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Performance"
                                                color: "#dfe8ff"
                                                font.pixelSize: 11
                                                font.family: "Maple Mono NF"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: panel.applyPowerProfile("performance")
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 28
                                            radius: 7
                                            border.width: 1
                                            border.color: batteryProfileText.text === "turbo" ? "#ffb36d" : (powerProfileCard.turboAvailable ? "#59617e" : "#4c556e")
                                            color: batteryProfileText.text === "turbo" ? "#5a3a28" : (powerProfileCard.turboAvailable ? "#2f374b" : "#2a3142")
                                            opacity: (powerProfileCard.turboAvailable || batteryProfileText.text === "turbo") ? 1 : 0.55

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Turbo"
                                                color: batteryProfileText.text === "turbo" ? "#ffe8d2" : "#dfe8ff"
                                                font.pixelSize: 11
                                                font.family: "Maple Mono NF"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: powerProfileCard.turboAvailable
                                                cursorShape: powerProfileCard.turboAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                onClicked: panel.applyPowerProfile("turbo")
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Current: " + batteryProfileText.text
                                        color: "#aeb9d6"
                                        font.pixelSize: 11
                                        font.family: "Maple Mono NF"
                                    }

                                    Text {
                                        visible: batteryProfileText.text === "auto" && batteryAutoTargetText.text !== "N/A"
                                        text: "Auto target: " + batteryAutoTargetText.text + " (source: " + batteryAutoSourceText.text + ")"
                                        color: "#9ea8c4"
                                        font.pixelSize: 10
                                        font.family: "Maple Mono NF"
                                    }

                                    Text {
                                        text: powerProfileCard.turboAvailable ? "Performance is thermal-safe. Turbo is aggressive (AC only)." : "Turbo requires AC connection."
                                        color: "#9ea8c4"
                                        font.pixelSize: 10
                                        font.family: "Maple Mono NF"
                                    }
                                }
                            }

                            Rectangle {
                                id: advancedChargingCard
                                Layout.fillWidth: true
                                radius: 10
                                border.width: 1
                                border.color: "#59617e"
                                color: "#323a4f"
                                implicitHeight: panel.batteryAdvancedCollapsed ? 38 : 330
                                clip: true
                                property int draftStartThreshold: panel.batteryStartThresholdValue
                                property int draftStopThreshold: panel.batteryStopThresholdValue

                                function snap5(v) {
                                    return Math.round(v / 5) * 5
                                }

                                function clampStart(v) {
                                    return Math.max(0, Math.min(100, v))
                                }

                                function clampStop(v) {
                                    return Math.max(0, Math.min(100, v))
                                }

                                function fromPos(mouseX, width, min, max) {
                                    if (max <= min || width <= 1) {
                                        return min
                                    }
                                    const ratio = Math.max(0, Math.min(1, mouseX / width))
                                    return snap5(min + ratio * (max - min))
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Rectangle {
                                        width: parent.width
                                        height: 22
                                        color: "transparent"

                                        Row {
                                            anchors.fill: parent
                                            spacing: 6

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: panel.batteryAdvancedCollapsed ? "▸" : "▾"
                                                color: "#b9c3de"
                                                font.pixelSize: 12
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Advanced Charging"
                                                color: "#b9c3de"
                                                font.pixelSize: 11
                                                font.family: "Maple Mono NF"
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: panel.batteryAdvancedCollapsed = !panel.batteryAdvancedCollapsed
                                        }
                                    }

                                    RowLayout {
                                        visible: !panel.batteryAdvancedCollapsed
                                        width: parent.width

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: parent.width
                                            implicitHeight: 276
                                            radius: 8
                                            border.width: 1
                                            border.color: "#546086"
                                            color: "#2a3146"

                                            Column {
                                                anchors.fill: parent
                                                anchors.margins: 10
                                                spacing: 10

                                                RowLayout {
                                                    width: parent.width

                                                    Text {
                                                        text: "Thresholds"
                                                        color: "#9fb1de"
                                                        font.pixelSize: 11
                                                        font.family: "Maple Mono NF"
                                                        font.italic: true
                                                    }

                                                    Item { Layout.fillWidth: true }

                                                    QuickButton {
                                                        text: "󰏫"
                                                        onClicked: {
                                                            if (!panel.batteryThresholdEditing) {
                                                                advancedChargingCard.draftStartThreshold = panel.batteryStartThresholdValue
                                                                advancedChargingCard.draftStopThreshold = panel.batteryStopThresholdValue
                                                            }
                                                            panel.batteryThresholdEditing = !panel.batteryThresholdEditing
                                                        }
                                                    }
                                                }

                                                RowLayout {
                                                    width: parent.width

                                                    Text {
                                                        text: "Start"
                                                        color: "#dbe6ff"
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        font.family: "Maple Mono NF"
                                                    }

                                                    Item { Layout.fillWidth: true }

                                                    Rectangle {
                                                        width: 70
                                                        height: 28
                                                        radius: 7
                                                        border.width: 1
                                                        border.color: panel.batteryThresholdEditing ? "#62719a" : "#4f5874"
                                                        color: "#232a3d"

                                                        TextInput {
                                                            anchors.fill: parent
                                                            anchors.leftMargin: 8
                                                            anchors.rightMargin: 18
                                                            horizontalAlignment: TextInput.AlignHCenter
                                                            verticalAlignment: TextInput.AlignVCenter
                                                            color: "#edf2ff"
                                                            font.pixelSize: 12
                                                            font.family: "Maple Mono NF"
                                                            readOnly: !panel.batteryThresholdEditing
                                                            text: String(panel.batteryThresholdEditing ? advancedChargingCard.draftStartThreshold : panel.batteryStartThresholdValue)
                                                            validator: IntValidator { bottom: 0; top: 100 }
                                                            onEditingFinished: {
                                                                let parsed = parseInt(text, 10)
                                                                if (Number.isNaN(parsed)) {
                                                                    parsed = panel.batteryThresholdEditing ? advancedChargingCard.draftStartThreshold : panel.batteryStartThresholdValue
                                                                }
                                                                if (panel.batteryThresholdEditing) {
                                                                    advancedChargingCard.draftStartThreshold = advancedChargingCard.clampStart(parsed)
                                                                }
                                                            }
                                                        }

                                                        Text {
                                                            anchors.right: parent.right
                                                            anchors.rightMargin: 6
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: "%"
                                                            color: "#9fb1de"
                                                            font.pixelSize: 10
                                                            font.family: "Maple Mono NF"
                                                        }
                                                    }

                                                    Row {
                                                        visible: panel.batteryThresholdEditing
                                                        spacing: 4

                                                        Text {
                                                            text: "-"
                                                            color: "#d9e6ff"
                                                            font.pixelSize: 15
                                                            font.family: "Maple Mono NF"
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: advancedChargingCard.draftStartThreshold = advancedChargingCard.clampStart(advancedChargingCard.draftStartThreshold - 1)
                                                            }
                                                        }

                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: "/"
                                                            color: "#8ea0c9"
                                                            font.pixelSize: 12
                                                            font.family: "Maple Mono NF"
                                                        }

                                                        Text {
                                                            text: "+"
                                                            color: "#d9e6ff"
                                                            font.pixelSize: 15
                                                            font.family: "Maple Mono NF"
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: advancedChargingCard.draftStartThreshold = advancedChargingCard.clampStart(advancedChargingCard.draftStartThreshold + 1)
                                                            }
                                                        }
                                                    }
                                                }

                                                Text {
                                                    text: "Visual range"
                                                    color: "#9fb1de"
                                                    font.pixelSize: 10
                                                    font.family: "Maple Mono NF"
                                                }

                                                Column {
                                                    width: parent.width
                                                    spacing: 6

                                                    Rectangle {
                                                        id: startTrack
                                                        width: parent.width
                                                        height: 18
                                                        radius: 9
                                                        color: "#1f2637"
                                                        border.width: 1
                                                        border.color: "#4d5673"

                                                        Rectangle {
                                                            width: (parent.width * (panel.batteryThresholdEditing ? advancedChargingCard.draftStartThreshold : panel.batteryStartThresholdValue)) / 100
                                                            height: parent.height
                                                            radius: parent.radius
                                                            color: "#3f5e96"
                                                        }

                                                        Repeater {
                                                            model: 21
                                                            delegate: Rectangle {
                                                                property int tickValue: index * 5
                                                                width: 1
                                                                height: tickValue % 25 === 0 ? 10 : 5
                                                                color: tickValue % 25 === 0 ? "#8ea0c9" : "#5f6b8e"
                                                                x: Math.round((startTrack.width - 13) * (tickValue / 100.0) + 6)
                                                                anchors.verticalCenter: parent.verticalCenter
                                                            }
                                                        }

                                                        Rectangle {
                                                            width: 10
                                                            height: 10
                                                            radius: 5
                                                            y: 4
                                                            x: Math.max(1, Math.min(startTrack.width - width - 1, ((startTrack.width - 12) * (panel.batteryThresholdEditing ? advancedChargingCard.draftStartThreshold : panel.batteryStartThresholdValue)) / 100 + 1))
                                                            color: "#c9dcff"
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            enabled: panel.batteryThresholdEditing
                                                            onPressed: {
                                                                const usable = Math.max(1, width - 12)
                                                                const ratio = Math.max(0, Math.min(1, (mouse.x - 6) / usable))
                                                                advancedChargingCard.draftStartThreshold = advancedChargingCard.clampStart(advancedChargingCard.snap5(ratio * 100))
                                                            }
                                                            onPositionChanged: if (pressed) {
                                                                const usable = Math.max(1, width - 12)
                                                                const ratio = Math.max(0, Math.min(1, (mouse.x - 6) / usable))
                                                                advancedChargingCard.draftStartThreshold = advancedChargingCard.clampStart(advancedChargingCard.snap5(ratio * 100))
                                                            }
                                                        }
                                                    }

                                                    Item {
                                                        width: parent.width
                                                        height: 12
                                                        Repeater {
                                                            model: [0, 25, 50, 75, 100]
                                                            delegate: Text {
                                                                text: String(modelData)
                                                                color: "#8ea0c9"
                                                                font.pixelSize: 9
                                                                font.family: "Maple Mono NF"
                                                                x: Math.round((startTrack.width - 13) * (modelData / 100.0) + 6 - width / 2)
                                                            }
                                                        }
                                                    }

                                                    RowLayout {
                                                        width: parent.width

                                                        Text {
                                                            text: "Stop"
                                                            color: "#dbe6ff"
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            font.family: "Maple Mono NF"
                                                        }

                                                        Item { Layout.fillWidth: true }

                                                        Rectangle {
                                                            width: 70
                                                            height: 28
                                                            radius: 7
                                                            border.width: 1
                                                            border.color: panel.batteryThresholdEditing ? "#62719a" : "#4f5874"
                                                            color: "#232a3d"

                                                            TextInput {
                                                                anchors.fill: parent
                                                                anchors.leftMargin: 8
                                                                anchors.rightMargin: 18
                                                                horizontalAlignment: TextInput.AlignHCenter
                                                                verticalAlignment: TextInput.AlignVCenter
                                                                color: "#edf2ff"
                                                                font.pixelSize: 12
                                                                font.family: "Maple Mono NF"
                                                                readOnly: !panel.batteryThresholdEditing
                                                                text: String(panel.batteryThresholdEditing ? advancedChargingCard.draftStopThreshold : panel.batteryStopThresholdValue)
                                                                validator: IntValidator { bottom: 0; top: 100 }
                                                                onEditingFinished: {
                                                                    let parsed = parseInt(text, 10)
                                                                    if (Number.isNaN(parsed)) {
                                                                        parsed = panel.batteryThresholdEditing ? advancedChargingCard.draftStopThreshold : panel.batteryStopThresholdValue
                                                                    }
                                                                    if (panel.batteryThresholdEditing) {
                                                                        advancedChargingCard.draftStopThreshold = advancedChargingCard.clampStop(parsed)
                                                                    }
                                                                }
                                                            }

                                                            Text {
                                                                anchors.right: parent.right
                                                                anchors.rightMargin: 6
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: "%"
                                                                color: "#9fb1de"
                                                                font.pixelSize: 10
                                                                font.family: "Maple Mono NF"
                                                            }
                                                        }

                                                        Row {
                                                            visible: panel.batteryThresholdEditing
                                                            spacing: 4

                                                            Text {
                                                                text: "-"
                                                                color: "#d9e6ff"
                                                                font.pixelSize: 15
                                                                font.family: "Maple Mono NF"
                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: advancedChargingCard.draftStopThreshold = advancedChargingCard.clampStop(advancedChargingCard.draftStopThreshold - 1)
                                                                }
                                                            }

                                                            Text {
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: "/"
                                                                color: "#8ea0c9"
                                                                font.pixelSize: 12
                                                                font.family: "Maple Mono NF"
                                                            }

                                                            Text {
                                                                text: "+"
                                                                color: "#d9e6ff"
                                                                font.pixelSize: 15
                                                                font.family: "Maple Mono NF"
                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: advancedChargingCard.draftStopThreshold = advancedChargingCard.clampStop(advancedChargingCard.draftStopThreshold + 1)
                                                                }
                                                            }
                                                        }
                                                    }

                                                    Rectangle {
                                                        id: stopTrack
                                                        width: parent.width
                                                        height: 18
                                                        radius: 9
                                                        color: "#1f2637"
                                                        border.width: 1
                                                        border.color: "#4d5673"

                                                        Rectangle {
                                                            width: (parent.width * (panel.batteryThresholdEditing ? advancedChargingCard.draftStopThreshold : panel.batteryStopThresholdValue)) / 100
                                                            height: parent.height
                                                            radius: parent.radius
                                                            color: "#5879ad"
                                                        }

                                                        Repeater {
                                                            model: 21
                                                            delegate: Rectangle {
                                                                property int tickValue: index * 5
                                                                width: 1
                                                                height: tickValue % 25 === 0 ? 10 : 5
                                                                color: tickValue % 25 === 0 ? "#8ea0c9" : "#5f6b8e"
                                                                x: Math.round((stopTrack.width - 13) * (tickValue / 100.0) + 6)
                                                                anchors.verticalCenter: parent.verticalCenter
                                                            }
                                                        }

                                                        Rectangle {
                                                            width: 10
                                                            height: 10
                                                            radius: 5
                                                            y: 4
                                                            x: Math.max(1, Math.min(stopTrack.width - width - 1, ((stopTrack.width - 12) * (panel.batteryThresholdEditing ? advancedChargingCard.draftStopThreshold : panel.batteryStopThresholdValue)) / 100 + 1))
                                                            color: "#e1ecff"
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            enabled: panel.batteryThresholdEditing
                                                            onPressed: {
                                                                const usable = Math.max(1, width - 12)
                                                                const ratio = Math.max(0, Math.min(1, (mouse.x - 6) / usable))
                                                                advancedChargingCard.draftStopThreshold = advancedChargingCard.clampStop(advancedChargingCard.snap5(ratio * 100))
                                                            }
                                                            onPositionChanged: if (pressed) {
                                                                const usable = Math.max(1, width - 12)
                                                                const ratio = Math.max(0, Math.min(1, (mouse.x - 6) / usable))
                                                                advancedChargingCard.draftStopThreshold = advancedChargingCard.clampStop(advancedChargingCard.snap5(ratio * 100))
                                                            }
                                                        }
                                                    }

                                                    Item {
                                                        width: parent.width
                                                        height: 12
                                                        Repeater {
                                                            model: [0, 25, 50, 75, 100]
                                                            delegate: Text {
                                                                text: String(modelData)
                                                                color: "#8ea0c9"
                                                                font.pixelSize: 9
                                                                font.family: "Maple Mono NF"
                                                                x: Math.round((stopTrack.width - 13) * (modelData / 100.0) + 6 - width / 2)
                                                            }
                                                        }
                                                    }
                                                }

                                                RowLayout {
                                                    width: parent.width

                                                    Text {
                                                        text: (advancedChargingCard.draftStartThreshold <= advancedChargingCard.draftStopThreshold - 5)
                                                            ? "Ready to save thresholds"
                                                            : "Invalid values: Start must be at least 5% lower than Stop."
                                                        color: (advancedChargingCard.draftStartThreshold <= advancedChargingCard.draftStopThreshold - 5) ? "#8ea0c9" : "#ffbe9b"
                                                        font.pixelSize: 10
                                                        font.family: "Maple Mono NF"
                                                    }

                                                    Item { Layout.fillWidth: true }

                                                    QuickButton {
                                                        visible: panel.batteryThresholdEditing
                                                        Layout.preferredWidth: 78
                                                        text: "Save"
                                                        onClicked: {
                                                            if (advancedChargingCard.draftStartThreshold > advancedChargingCard.draftStopThreshold - 5) {
                                                                panel.batteryActionFailed = true
                                                                panel.batteryActionFeedback = "Invalid thresholds: Start must be at least 5% lower than Stop."
                                                                return
                                                            }

                                                            panel.batteryStartThresholdValue = advancedChargingCard.clampStart(advancedChargingCard.draftStartThreshold)
                                                            panel.batteryStopThresholdValue = advancedChargingCard.clampStop(advancedChargingCard.draftStopThreshold)
                                                            panel.applyChargeThresholdPair(panel.batteryStartThresholdValue, panel.batteryStopThresholdValue)
                                                            panel.batteryThresholdEditing = false
                                                        }
                                                    }

                                                    Rectangle {
                                                        visible: panel.batteryThresholdEditing
                                                        width: 78
                                                        height: 32
                                                        radius: 6
                                                        border.width: 1
                                                        border.color: Qt.rgba(0.74, 0.58, 0.98, 0.64)
                                                        color: Qt.rgba(0.74, 0.58, 0.98, 0.64)

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "Cancel"
                                                            color: "#f1f5fd"
                                                            font.pixelSize: 13
                                                            font.family: "Symbols Nerd Font"
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                panel.batteryThresholdEditing = false
                                                                advancedChargingCard.draftStartThreshold = panel.batteryStartThresholdValue
                                                                advancedChargingCard.draftStopThreshold = panel.batteryStopThresholdValue
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                visible: panel.batteryActionFeedback.length > 0
                                radius: 8
                                border.width: 1
                                border.color: panel.batteryActionFailed ? "#8a4a58" : "#4a8a66"
                                color: panel.batteryActionFailed ? "#4d2b33" : "#274635"
                                implicitHeight: 34

                                Text {
                                    anchors.centerIn: parent
                                    text: panel.batteryActionFeedback
                                    color: "#e7ecfb"
                                    font.pixelSize: 11
                                    font.family: "Maple Mono NF"
                                    elide: Text.ElideRight
                                    width: parent.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            }
                        }
                    }
                }
            }
