property alias text: label.text
property bool warning: false
signal clicked

radius: 6
border.width: 1
border.color: warning ? Qt.rgba(0.74, 0.58, 0.98, 0.90) : Qt.rgba(0.74, 0.58, 0.98, 0.64)
color: warning ? Qt.rgba(0.20, 0.12, 0.30, 0.64) : Qt.rgba(0.08, 0.06, 0.14, 0.42)
Layout.preferredHeight: 32
Layout.preferredWidth: Math.max(44, label.implicitWidth + 16)

Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: 1
    radius: 1
    color: Qt.rgba(0.74, 0.58, 0.98, warning ? 0.96 : 0.84)
}

Text {
    id: label
    anchors.centerIn: parent
    color: "#f1f5fd"
    font.pixelSize: 12
    font.family: "Maple Mono NF"
}

MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: parent.clicked()
}
