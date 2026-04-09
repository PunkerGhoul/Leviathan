            HyprlandFocusGrab {
                windows: [panel]
                active: true
            }

            Rectangle {
                id: panelRoot
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
                            onClicked: {
                                const procs = [terminalProc0, terminalProc1, terminalProc2]
                                panel.launchNow(procs[panel.terminalProcSlot])
                                panel.terminalProcSlot = (panel.terminalProcSlot + 1) % procs.length
                            }
                        }

                        QuickButton {
                            text: "󰉋"
                            onClicked: {
                                const procs = [filesProc0, filesProc1, filesProc2]
                                panel.launchNow(procs[panel.filesProcSlot])
                                panel.filesProcSlot = (panel.filesProcSlot + 1) % procs.length
                            }
                        }

                        QuickButton {
                            text: "󰖟"
                            onClicked: {
                                const procs = [browserProc0, browserProc1, browserProc2]
                                panel.launchNow(procs[panel.browserProcSlot])
                                panel.browserProcSlot = (panel.browserProcSlot + 1) % procs.length
                            }
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
