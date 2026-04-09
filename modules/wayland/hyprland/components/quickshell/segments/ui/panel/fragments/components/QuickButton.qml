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

HoverHandler {
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
