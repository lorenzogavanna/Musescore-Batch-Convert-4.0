import QtQuick
import QtQuick.Controls

Button {
    id: customButton
    background: Rectangle {
        color:"grey"
        border.color: "black"
        radius: 5
    }
    contentItem: Text {
        text: customButton.text
        color: "black"
        font: customButton.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
