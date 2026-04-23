import QtQuick 2.15

Row {
    id: powerBarRoot
    spacing: Math.round(12 * dp)
    height: Math.round(36 * dp)   // mesma altura da sessionPill

    property color textColor: "white"
    property real dp: 1.0

    // Bateria
    Row {
        spacing: Math.round(5 * dp)
        visible: typeof battery !== "undefined" && battery.percent !== undefined
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: (typeof battery !== "undefined" ? battery.percent : "0") + "%"
            color: textColor
            font.pixelSize: Math.round(14 * dp)
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: (typeof battery !== "undefined" && battery.charging) ? "⚡" : "🔋"
            color: textColor
            font.pixelSize: Math.round(18 * dp)
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Layout de teclado
    Text {
        text: (typeof keyboard !== "undefined" && keyboard.layouts[keyboard.currentLayout])
              ? keyboard.layouts[keyboard.currentLayout].shortName : "US"
        color: textColor
        font.pixelSize: Math.round(14 * dp)
        font.capitalization: Font.AllUppercase
        visible: typeof keyboard !== "undefined" && keyboard.layouts.length > 1
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
        }
    }

    // Suspender
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(28 * dp); height: Math.round(28 * dp); radius: width / 2
        color: suspendHover.containsMouse
            ? Qt.rgba(textColor.r, textColor.g, textColor.b, 0.18) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
            anchors.centerIn: parent
            text: "󰤄"
            color: textColor
            font.pixelSize: Math.round(20 * dp)
        }
        MouseArea {
            id: suspendHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sddm.suspend()
        }
    }

    // Reiniciar
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(28 * dp); height: Math.round(28 * dp); radius: width / 2
        color: rebootHover.containsMouse
            ? Qt.rgba(textColor.r, textColor.g, textColor.b, 0.18) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
            anchors.centerIn: parent
            text: "󰑐"
            color: textColor
            font.pixelSize: Math.round(20 * dp)
        }
        MouseArea {
            id: rebootHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sddm.reboot()
        }
    }

    // Desligar
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(28 * dp); height: Math.round(28 * dp); radius: width / 2
        color: powerHover.containsMouse
            ? Qt.rgba(textColor.r, textColor.g, textColor.b, 0.18) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
            anchors.centerIn: parent
            text: "󰐥"
            color: textColor
            font.pixelSize: Math.round(20 * dp)
        }
        MouseArea {
            id: powerHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sddm.powerOff()
        }
    }
}