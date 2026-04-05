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
