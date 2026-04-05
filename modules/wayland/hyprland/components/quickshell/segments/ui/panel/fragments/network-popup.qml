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
                    implicitWidth: panel.popupWidth
                    implicitHeight: panel.popupHeight

                    Component.onCompleted: {
                        panel.positionPopupUnderNetworkButton()
                        panel.ensurePopupBounds()
                        Qt.callLater(function() {
                            panel.fitPopupHeightToContent(popupColumn.implicitHeight + 24)
                        })
                    }

                    onVisibleChanged: {
                        if (visible) {
                            panel.positionPopupUnderNetworkButton()
                            Qt.callLater(function() {
                                panel.fitPopupHeightToContent(popupColumn.implicitHeight + 24)
                            })
                        }
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
                                                    showForgetButton: true
                                                    forgetPending: panel.forgetConfirmIndex === networkIndex
                                                    onClicked: panel.connectNetwork("known", networkIndex, modelData)
                                                    onForgetClicked: panel.requestForgetPreferredNetwork(networkIndex, modelData)
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
                                Layout.preferredHeight: panel.availableCollapsed ? 38 : availableHeader.height + availableFlick.height + 20
                                radius: 10
                                border.width: 1
                                border.color: "#59617e"
                                color: "#323a4f"
                                implicitHeight: panel.availableCollapsed ? 38 : availableHeader.height + availableFlick.height + 20
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
                                            : Math.min(Math.max(availableColumn.implicitHeight, 80), 220)
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
                                                    showForgetButton: false
                                                    onClicked: panel.connectNetwork("available", networkIndex, modelData)
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
                    }
                }
            }
