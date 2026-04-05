property alias text: label.text
property int networkIndex: -1
property bool showForgetButton: false
property bool forgetPending: false
signal clicked
signal forgetClicked

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
    anchors.rightMargin: showForgetButton ? 44 : 10
    color: "#f1f5fd"
    font.pixelSize: 12
    font.family: "Maple Mono NF"
    elide: Text.ElideRight
}

Rectangle {
    visible: showForgetButton
    width: 22
    height: 22
    radius: 6
    anchors.verticalCenter: parent.verticalCenter
    anchors.right: parent.right
    anchors.rightMargin: 6
    color: forgetPending ? "#5a2f3a" : "#2b3142"
    border.width: 1
    border.color: forgetPending ? "#cf8ca0" : "#59617e"

    Text {
        anchors.centerIn: parent
        text: "󰆴"
        color: "#e7edf9"
        font.pixelSize: 11
        font.family: "Symbols Nerd Font"
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: parent.parent.forgetClicked()
    }
}

MouseArea {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.rightMargin: showForgetButton ? 30 : 0
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: parent.clicked()
}
