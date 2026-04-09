property alias text: label.text
property bool accent: false
property bool danger: false
property bool flatUntilHover: false
signal clicked

property bool showChrome: !flatUntilHover || hoverHandler.hovered || accent || danger

radius: 6
border.width: showChrome ? 1 : 0
border.color: danger
    ? (hoverHandler.hovered ? Qt.rgba(1.00, 0.22, 0.24, 1.00) : Qt.rgba(0.86, 0.35, 0.44, 0.90))
    : (accent
        ? (hoverHandler.hovered ? Qt.rgba(0.86, 0.74, 1.00, 1.00) : Qt.rgba(0.74, 0.58, 0.98, 0.92))
        : Qt.rgba(0.74, 0.58, 0.98, 0.64))
color: showChrome
    ? (danger
        ? (hoverHandler.hovered ? Qt.rgba(0.58, 0.05, 0.08, 0.88) : Qt.rgba(0.30, 0.06, 0.12, 0.70))
        : (accent
            ? (hoverHandler.hovered ? Qt.rgba(0.35, 0.20, 0.52, 0.82) : Qt.rgba(0.20, 0.12, 0.30, 0.66))
            : Qt.rgba(0.08, 0.06, 0.14, 0.42)))
    : "transparent"
Layout.preferredHeight: 32
Layout.preferredWidth: flatUntilHover ? 30 : 34

Rectangle {
    visible: hoverHandler.hovered && (accent || danger)
    anchors.fill: parent
    anchors.margins: -3
    radius: parent.radius + 3
    border.width: 1
    border.color: danger ? Qt.rgba(1.00, 0.24, 0.28, 0.78) : Qt.rgba(0.74, 0.58, 0.98, 0.72)
    color: "transparent"
}

Rectangle {
    visible: hoverHandler.hovered && (accent || danger)
    anchors.fill: parent
    anchors.margins: -6
    radius: parent.radius + 6
    border.width: 1
    border.color: danger ? Qt.rgba(1.00, 0.24, 0.28, 0.34) : Qt.rgba(0.74, 0.58, 0.98, 0.30)
    color: "transparent"
}

Rectangle {
    visible: parent.showChrome
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: 1
    radius: 1
    color: danger
        ? (hoverHandler.hovered ? Qt.rgba(1.00, 0.28, 0.30, 0.96) : Qt.rgba(0.86, 0.35, 0.44, 0.86))
        : (hoverHandler.hovered ? Qt.rgba(0.88, 0.77, 1.00, 0.95) : Qt.rgba(0.74, 0.58, 0.98, 0.88))
}

Text {
    id: label
    anchors.centerIn: parent
    color: "#f1f5fd"
    font.pixelSize: 13
    font.family: "Symbols Nerd Font"
}

HoverHandler {
    id: hoverHandler
    cursorShape: Qt.PointingHandCursor
}

TapHandler {
    acceptedButtons: Qt.LeftButton
    gesturePolicy: TapHandler.ReleaseWithinBounds

    onPressedChanged: {
        if (!pressed) {
            return
        }
        parent.clicked()
    }
}
