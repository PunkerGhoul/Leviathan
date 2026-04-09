            HyprlandFocusGrab {
                windows: [panel]
                active: true
            }

            Rectangle {
                id: panelRoot
                property int calendarPopupWidth: 320
                property int calendarPopupHeight: 360
                property real calendarAnchorX: 10
                property real calendarAnchorY: 10
                property var todayDate: new Date()
                property var selectedDate: new Date()
                property int calendarViewMonth: selectedDate.getMonth()
                property int calendarViewYear: selectedDate.getFullYear()
                property bool monthPickerOpen: false
                property bool yearPickerOpen: false
                property color chromeBorder: Qt.rgba(0.74, 0.58, 0.98, 0.86)
                property color chromeBorderSoft: Qt.rgba(0.74, 0.58, 0.98, 0.70)
                property color chromeFill: Qt.rgba(0.06, 0.05, 0.14, 0.64)
                property color chromeFillSoft: Qt.rgba(0.07, 0.06, 0.14, 0.54)
                property color chromeSeparator: Qt.rgba(0.74, 0.58, 0.98, 0.70)
                anchors.fill: parent
                radius: 16
                border.width: 0
                border.color: "transparent"
                function updateCalendarAnchor() {
                    calendarAnchorX = Math.max(10, Math.min(panel.width - calendarPopupWidth - 10, clockWidget.mapToItem(panelRoot, 0, 0).x + clockWidget.width - calendarPopupWidth))
                    calendarAnchorY = clockWidget.mapToItem(panelRoot, 0, 0).y + clockWidget.height + 8
                }
                function monthName(index) {
                    const names = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
                    return names[index]
                }
                function daysInMonth(year, month) {
                    return new Date(year, month + 1, 0).getDate()
                }
                function firstWeekdayOffset(year, month) {
                    const jsDay = new Date(year, month, 1).getDay()
                    return (jsDay + 6) % 7
                }
                function dateForCell(index) {
                    const offset = firstWeekdayOffset(calendarViewYear, calendarViewMonth)
                    return new Date(calendarViewYear, calendarViewMonth, index - offset + 1)
                }
                function isSameDate(a, b) {
                    return a.getFullYear() === b.getFullYear()
                        && a.getMonth() === b.getMonth()
                        && a.getDate() === b.getDate()
                }
                function shiftMonth(delta) {
                    const next = new Date(calendarViewYear, calendarViewMonth + delta, 1)
                    calendarViewYear = next.getFullYear()
                    calendarViewMonth = next.getMonth()
                }
                function today() {
                    const now = new Date()
                    todayDate = now
                    selectedDate = now
                    calendarViewYear = now.getFullYear()
                    calendarViewMonth = now.getMonth()
                }
                color: "transparent"

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 0
                    anchors.leftMargin: 0
                    anchors.rightMargin: 0
                    spacing: 10

                    Rectangle {
                        id: leftGroupBar
                        radius: 8
                        border.width: 1
                        border.color: panelRoot.chromeBorder
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(0.08, 0.06, 0.16, 0.78) }
                            GradientStop { position: 1.0; color: Qt.rgba(0.05, 0.04, 0.12, 0.66) }
                        }
                        Layout.preferredHeight: 38
                        Layout.preferredWidth: leftGroupRow.implicitWidth + 5

                        // Flatten top-left corner for cyber notch mix.
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            width: 10
                            height: 10
                            color: Qt.rgba(0.08, 0.06, 0.16, 0.78)
                        }

                        // Flatten bottom-right corner for asymmetry.
                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: 10
                            height: 10
                            color: Qt.rgba(0.05, 0.04, 0.12, 0.66)
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            width: parent.width - 36
                            height: 1
                            color: Qt.rgba(0.74, 0.58, 0.98, 0.96)
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            width: 24
                            height: 2
                            color: Qt.rgba(0.74, 0.58, 0.98, 0.74)
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            width: 42
                            height: 2
                            color: Qt.rgba(0.74, 0.58, 0.98, 0.88)
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            width: 20
                            height: 1
                            color: Qt.rgba(0.74, 0.58, 0.98, 0.56)
                        }

                        RowLayout {
                            id: leftGroupRow
                            anchors.left: parent.left
                            anchors.leftMargin: 0
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            QuickButton {
                                text: "󰣇"
                                accent: true
                                onClicked: panel.launchNow(launchProc)
                            }

                            Rectangle {
                                width: 1
                                height: 18
                                radius: 1
                                color: panelRoot.chromeSeparator
                            }

                            QuickButton {
                                text: "󰆍"
                                flatUntilHover: true
                                onClicked: {
                                    const procs = [terminalProc0, terminalProc1, terminalProc2]
                                    panel.launchNow(procs[panel.terminalProcSlot])
                                    panel.terminalProcSlot = (panel.terminalProcSlot + 1) % procs.length
                                }
                            }

                            QuickButton {
                                text: "󰉋"
                                flatUntilHover: true
                                onClicked: {
                                    const procs = [filesProc0, filesProc1, filesProc2]
                                    panel.launchNow(procs[panel.filesProcSlot])
                                    panel.filesProcSlot = (panel.filesProcSlot + 1) % procs.length
                                }
                            }

                            QuickButton {
                                text: "󰖟"
                                flatUntilHover: true
                                onClicked: {
                                    const procs = [browserProc0, browserProc1, browserProc2]
                                    panel.launchNow(procs[panel.browserProcSlot])
                                    panel.browserProcSlot = (panel.browserProcSlot + 1) % procs.length
                                }
                            }

                            QuickButton {
                                text: "󰸉"
                                flatUntilHover: true
                                onClicked: panel.launchNow(wallpaperProc)
                            }

                            QuickButton {
                                text: "󰄀"
                                flatUntilHover: true
                                onClicked: panel.launchNow(screenshotProc)
                            }

                            QuickButton {
                                text: "󰒓"
                                flatUntilHover: true
                                onClicked: panel.launchNow(settingsProc)
                            }

                            Rectangle {
                                width: 1
                                height: 18
                                radius: 1
                                color: panelRoot.chromeSeparator
                            }

                            Row {
                                id: workspaceIconsRow
                                spacing: 5

                                Repeater {
                                    model: {
                                        const raw = workspaceListText.text.trim()
                                        const tokens = raw.length > 0 ? raw.split(/\s+/) : []
                                        const wsNums = []

                                        for (const token of tokens) {
                                            const n = parseInt(token, 10)
                                            if (!Number.isNaN(n) && n > 0 && wsNums.indexOf(n) === -1) {
                                                wsNums.push(n)
                                            }
                                        }

                                        for (let i = 1; i <= 5; i += 1) {
                                            if (wsNums.indexOf(i) === -1) {
                                                wsNums.push(i)
                                            }
                                        }

                                        wsNums.sort(function(a, b) { return a - b })
                                        return wsNums.map(function(n) { return String(n) })
                                    }

                                    Item {
                                        readonly property var defaultIcons: ["󰚌", "󰖟", "󰆍", "󰍹"]
                                        readonly property int wsNum: parseInt(String(modelData), 10)
                                        readonly property string wsIcon: {
                                            if (Number.isNaN(wsNum) || wsNum <= 0) {
                                                return defaultIcons[0]
                                            }
                                            return defaultIcons[(wsNum - 1) % defaultIcons.length]
                                        }

                                        width: 18
                                        height: 18

                                        Text {
                                            anchors.centerIn: parent
                                            text: wsIcon
                                            color: workspaceText.text === String(modelData) ? "#bd93f9" : "#b7c0df"
                                            font.pixelSize: workspaceText.text === String(modelData) ? 15 : 12
                                            font.bold: workspaceText.text === String(modelData)
                                            font.family: "Symbols Nerd Font"
                                        }

                                        TapHandler {
                                            acceptedButtons: Qt.LeftButton
                                            gesturePolicy: TapHandler.ReleaseWithinBounds
                                            onTapped: {
                                                workspaceSwitchProc.command = ["sh", "-lc", "hyprctl dispatch workspace " + modelData]
                                                workspaceSwitchProc.running = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        radius: 8
                        border.width: 1
                        border.color: panelRoot.chromeBorderSoft
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(0.08, 0.06, 0.15, 0.68) }
                            GradientStop { position: 1.0; color: Qt.rgba(0.05, 0.05, 0.13, 0.60) }
                        }
                        Layout.preferredHeight: 38
                        Layout.preferredWidth: rightGroup.implicitWidth + 14

                        // Flatten top-right corner for cyber notch mix.
                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            width: 10
                            height: 10
                            color: Qt.rgba(0.05, 0.05, 0.13, 0.60)
                        }

                        // Flatten bottom-left corner for asymmetry.
                        Rectangle {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            width: 10
                            height: 10
                            color: Qt.rgba(0.08, 0.06, 0.15, 0.68)
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            width: parent.width - 34
                            height: 1
                            color: Qt.rgba(0.74, 0.58, 0.98, 0.92)
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            width: 22
                            height: 2
                            color: Qt.rgba(0.74, 0.58, 0.98, 0.70)
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: 46
                            height: 2
                            color: Qt.rgba(0.74, 0.58, 0.98, 0.84)
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            width: 18
                            height: 1
                            color: Qt.rgba(0.74, 0.58, 0.98, 0.56)
                        }

                        RowLayout {
                            id: rightGroup
                            anchors.centerIn: parent
                            spacing: 6

                            StatusPill {
                                text: vpnText.text
                                visible: vpnText.text.length > 0
                            }

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
                                text: volumeText.text
                                onClicked: volumeOpenProc.running = true
                            }

                            StatusPill {
                                text: batteryText.text
                            }

                            Rectangle {
                                id: clockWidget
                                radius: 7
                                border.width: 1
                                border.color: panelRoot.chromeBorderSoft
                                color: Qt.rgba(0.05, 0.03, 0.11, 0.30)
                                Layout.preferredHeight: 32
                                Layout.preferredWidth: panel.clockExpanded ? 82 : 86

                                Column {
                                    anchors.centerIn: parent
                                    spacing: panel.clockExpanded ? 1 : 0

                                    Text {
                                        text: clockText.text
                                        color: "#e5e9f0"
                                        font.pixelSize: panel.clockExpanded ? 9 : 13
                                        font.family: "Maple Mono NF"
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Text {
                                        visible: panel.clockExpanded
                                        text: clockDateText.text
                                        color: "#b8c2df"
                                        font.pixelSize: 9
                                        font.family: "Maple Mono NF"
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                TapHandler {
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    gesturePolicy: TapHandler.ReleaseWithinBounds

                                    onTapped: function(eventPoint, button) {
                                        if (button === Qt.LeftButton) {
                                            if (panel.calendarPopupOpen) {
                                                panel.calendarPopupOpen = false
                                            }
                                            panel.clockExpanded = !panel.clockExpanded
                                            return
                                        }

                                        if (button === Qt.RightButton) {
                                            if (panel.calendarPopupOpen) {
                                                panel.calendarPopupOpen = false
                                            } else {
                                                panelRoot.todayDate = new Date()
                                                panelRoot.calendarViewYear = panelRoot.selectedDate.getFullYear()
                                                panelRoot.calendarViewMonth = panelRoot.selectedDate.getMonth()
                                                panelRoot.monthPickerOpen = false
                                                panelRoot.yearPickerOpen = false
                                                panelRoot.updateCalendarAnchor()
                                                panel.calendarPopupOpen = true
                                            }
                                        }
                                    }
                                }
                            }

                            QuickButton {
                                text: "󰐥"
                                danger: true
                                onClicked: powerMenuProc.running = true
                            }
                        }
                    }
                }

                LazyLoader {
                    active: panel.calendarPopupOpen
                    loading: panel.calendarPopupOpen

                    PopupWindow {
                        id: calendarPopup
                        visible: panel.calendarPopupOpen
                        color: "transparent"
                        anchor.window: panel
                        anchor.rect.x: panelRoot.calendarAnchorX
                        anchor.rect.y: panelRoot.calendarAnchorY
                        implicitWidth: panelRoot.calendarPopupWidth
                        implicitHeight: panelRoot.calendarPopupHeight

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            border.width: 1
                            border.color: "#6f7899"
                            color: "#262d3c"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8
                                enabled: !panelRoot.monthPickerOpen && !panelRoot.yearPickerOpen

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Rectangle {
                                        width: 28
                                        height: 26
                                        radius: 8
                                        color: "#2f3650"
                                        border.width: 1
                                        border.color: "#58628a"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "◀"
                                            color: "#e5e9f0"
                                            font.pixelSize: 11
                                        }

                                        TapHandler {
                                            acceptedButtons: Qt.LeftButton
                                            onTapped: panelRoot.shiftMonth(-1)
                                        }
                                    }

                                    Rectangle {
                                        width: 150
                                        height: 26
                                        radius: 8
                                        color: "#2b3145"
                                        border.width: 1
                                        border.color: panelRoot.monthPickerOpen ? "#bd93f9" : "#58628a"

                                        Text {
                                            anchors.centerIn: parent
                                            text: panelRoot.monthName(panelRoot.calendarViewMonth)
                                            color: "#f3f7ff"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        TapHandler {
                                            acceptedButtons: Qt.LeftButton
                                            onTapped: {
                                                panelRoot.monthPickerOpen = !panelRoot.monthPickerOpen
                                                panelRoot.yearPickerOpen = false
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 70
                                        height: 26
                                        radius: 8
                                        color: "#2b3145"
                                        border.width: 1
                                        border.color: panelRoot.yearPickerOpen ? "#bd93f9" : "#58628a"

                                        Text {
                                            anchors.centerIn: parent
                                            text: String(panelRoot.calendarViewYear)
                                            color: "#f3f7ff"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        TapHandler {
                                            acceptedButtons: Qt.LeftButton
                                            onTapped: {
                                                panelRoot.yearPickerOpen = !panelRoot.yearPickerOpen
                                                panelRoot.monthPickerOpen = false
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 28
                                        height: 26
                                        radius: 8
                                        color: "#2f3650"
                                        border.width: 1
                                        border.color: "#58628a"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "▶"
                                            color: "#e5e9f0"
                                            font.pixelSize: 11
                                        }

                                        TapHandler {
                                            acceptedButtons: Qt.LeftButton
                                            onTapped: panelRoot.shiftMonth(1)
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: "#46506b"
                                }

                                Row {
                                    width: parent.width
                                    spacing: 2

                                    Repeater {
                                        model: ["L", "M", "X", "J", "V", "S", "D"]

                                        Rectangle {
                                            width: 40
                                            height: 20
                                            radius: 6
                                            color: "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: "#8fa0ca"
                                                font.pixelSize: 11
                                                font.bold: true
                                            }
                                        }
                                    }
                                }

                                Grid {
                                    width: parent.width
                                    columns: 7
                                    rowSpacing: 4
                                    columnSpacing: 2

                                    Repeater {
                                        model: 42

                                        Rectangle {
                                            readonly property var cellDate: panelRoot.dateForCell(index)
                                            readonly property bool inCurrentMonth: cellDate.getMonth() === panelRoot.calendarViewMonth
                                            readonly property bool isToday: panelRoot.isSameDate(cellDate, panelRoot.todayDate)
                                            readonly property bool isSelected: panelRoot.isSameDate(cellDate, panelRoot.selectedDate)

                                            width: 40
                                            height: 30
                                            radius: 8
                                            border.width: isSelected || isToday ? 1 : 0
                                            border.color: isSelected ? "#bd93f9" : "#5f6f9f"
                                            color: isSelected ? "#3a2f55" : (inCurrentMonth ? "#2b3145" : "#222839")

                                            Text {
                                                anchors.centerIn: parent
                                                text: String(parent.cellDate.getDate())
                                                color: parent.inCurrentMonth ? "#f3f7ff" : "#7380a9"
                                                font.pixelSize: 12
                                                font.bold: parent.isSelected
                                            }

                                            TapHandler {
                                                acceptedButtons: Qt.LeftButton
                                                onTapped: {
                                                    panelRoot.selectedDate = parent.cellDate
                                                    panelRoot.calendarViewYear = parent.cellDate.getFullYear()
                                                    panelRoot.calendarViewMonth = parent.cellDate.getMonth()
                                                }
                                            }
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Rectangle {
                                        width: 70
                                        height: 26
                                        radius: 8
                                        color: "#2f3650"
                                        border.width: 1
                                        border.color: "#58628a"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Hoy"
                                            color: "#e5e9f0"
                                            font.pixelSize: 12
                                        }

                                        TapHandler {
                                            acceptedButtons: Qt.LeftButton
                                            onTapped: panelRoot.today()
                                        }
                                    }

                                    Text {
                                        verticalAlignment: Text.AlignVCenter
                                        text: Qt.formatDate(panelRoot.selectedDate, "dd/MM/yyyy")
                                        color: "#b8c2df"
                                        font.pixelSize: 11
                                        font.family: "Maple Mono NF"
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: panelRoot.monthPickerOpen
                                radius: 14
                                color: "#1f2533"
                                border.width: 1
                                border.color: "#6f7899"
                                z: 20

                                Grid {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    columns: 3
                                    rowSpacing: 8
                                    columnSpacing: 8

                                    Repeater {
                                        model: 12

                                        Rectangle {
                                            width: (parent.width - (parent.columns - 1) * parent.columnSpacing) / parent.columns
                                            height: (parent.height - 3 * parent.rowSpacing) / 4
                                            radius: 8
                                            border.width: panelRoot.calendarViewMonth === index ? 1 : 0
                                            border.color: "#bd93f9"
                                            color: panelRoot.calendarViewMonth === index ? "#3a2f55" : "#2b3145"

                                            Text {
                                                anchors.centerIn: parent
                                                text: panelRoot.monthName(index).slice(0, 3)
                                                color: "#e8ecf8"
                                                font.pixelSize: 12
                                            }

                                            TapHandler {
                                                acceptedButtons: Qt.LeftButton
                                                onTapped: {
                                                    panelRoot.calendarViewMonth = index
                                                    panelRoot.monthPickerOpen = false
                                                }
                                            }
                                        }
                                    }
                                }

                                TapHandler {
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onTapped: function() {}
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: panelRoot.yearPickerOpen
                                radius: 14
                                color: "#1f2533"
                                border.width: 1
                                border.color: "#6f7899"

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    Row {
                                        width: parent.width
                                        spacing: 8

                                        Rectangle {
                                            width: 28
                                            height: 24
                                            radius: 8
                                            color: "#2f3650"
                                            border.width: 1
                                            border.color: "#58628a"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "◀"
                                                color: "#e5e9f0"
                                                font.pixelSize: 10
                                            }

                                            TapHandler {
                                                acceptedButtons: Qt.LeftButton
                                                onTapped: panelRoot.calendarViewYear -= 12
                                            }
                                        }

                                        Text {
                                            readonly property int y0: Math.floor(panelRoot.calendarViewYear / 12) * 12
                                            width: parent.width - 72
                                            text: String(y0) + " - " + String(y0 + 11)
                                            color: "#f3f7ff"
                                            font.pixelSize: 12
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Rectangle {
                                            width: 28
                                            height: 24
                                            radius: 8
                                            color: "#2f3650"
                                            border.width: 1
                                            border.color: "#58628a"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "▶"
                                                color: "#e5e9f0"
                                                font.pixelSize: 10
                                            }

                                            TapHandler {
                                                acceptedButtons: Qt.LeftButton
                                                onTapped: panelRoot.calendarViewYear += 12
                                            }
                                        }
                                    }

                                    Grid {
                                        columns: 4
                                        rowSpacing: 6
                                        columnSpacing: 6

                                        Repeater {
                                            model: 12

                                            Rectangle {
                                                readonly property int y0: Math.floor(panelRoot.calendarViewYear / 12) * 12
                                                readonly property int yVal: y0 + index
                                                width: 68
                                                height: 30
                                                radius: 8
                                                border.width: panelRoot.calendarViewYear === yVal ? 1 : 0
                                                border.color: "#bd93f9"
                                                color: panelRoot.calendarViewYear === yVal ? "#3a2f55" : "#2b3145"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: String(parent.yVal)
                                                    color: "#e8ecf8"
                                                    font.pixelSize: 12
                                                }

                                                TapHandler {
                                                    acceptedButtons: Qt.LeftButton
                                                    onTapped: {
                                                        panelRoot.calendarViewYear = parent.yVal
                                                        panelRoot.yearPickerOpen = false
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            TapHandler {
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onTapped: function() {}
                            }
                        }
                    }
                }

                Connections {
                    target: Hyprland

                    function onRawEvent(event, maybeData) {
                        let name = ""
                        let data = ""

                        if (typeof event === "string") {
                            name = event
                            data = maybeData !== undefined && maybeData !== null ? String(maybeData) : ""
                        } else {
                            name = event && event.name ? String(event.name) : ""
                            data = event && event.data ? String(event.data) : ""
                        }

                        if (name.length === 0) {
                            return
                        }

                        if (name === "workspace" || name === "workspacev2" || name === "focusedmon" || name === "focusedmonv2") {
                            const match = data.match(/\d+/)
                            if (match && match.length > 0) {
                                workspaceText.text = match[0]
                            } else {
                                workspaceProc.running = true
                            }
                        }

                        if (name.indexOf("workspace") !== -1 || name === "moveworkspace" || name === "moveworkspacev2") {
                            workspaceListProc.running = true
                        }
                    }
                }

            }
