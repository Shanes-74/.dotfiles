import QtQuick 2.15

Item {
    id: clock

    property string backgroundSource: ""
    property color defaultHoursColor: "#AED68A"
    property color defaultMinutesColor: "#D4E4BC"
    property string fontFamily: "Google Sans Flex Freeze"
    property color baseAccent: config.accentColor
    property real dp: 1.0  // recebe do pai

    property color smartHoursColor: defaultHoursColor
    property color smartMinutesColor: defaultMinutesColor
    property string timeStr: Qt.formatTime(new Date(), "HHmm")

    function updateColors() {
        var base = clock.baseAccent;
        if (base.hsvValue < 0.3) {
            clock.smartHoursColor   = Qt.hsva(base.hsvHue, 0.6,  0.9,  1.0);
            clock.smartMinutesColor = Qt.hsva(base.hsvHue, 0.35, 0.85, 1.0);
        } else if (base.hsvValue > 0.8 && base.hsvSaturation < 0.2) {
            clock.smartHoursColor   = Qt.hsva(base.hsvHue, 0.8,  0.7,  1.0);
            clock.smartMinutesColor = Qt.hsva(base.hsvHue, 0.5,  0.75, 1.0);
        } else {
            clock.smartHoursColor   = Qt.hsva(base.hsvHue, Math.min(1.0, base.hsvSaturation * 1.3),  0.95, 1.0);
            clock.smartMinutesColor = Qt.hsva(base.hsvHue, Math.min(1.0, base.hsvSaturation * 0.75), 0.92, 1.0);
        }
    }

    onBaseAccentChanged: updateColors()
    Component.onCompleted: updateColors()

    // Tamanho intrínseco para o pai poder se dimensionar
    width: clockRow.width
    height: clockRow.height

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 0

        // Coluna 1: dezenas da hora / dezenas dos minutos
        Column {
            spacing: Math.round(-45 * dp)
            Text {
                text: clock.timeStr.charAt(0)
                color: clock.smartHoursColor
                font.pixelSize: Math.round(200 * dp)
                font.family: clock.fontFamily
                font.weight: Font.Medium
                width: Math.round(130 * dp)
                horizontalAlignment: Text.AlignHCenter
                antialiasing: true
            }
            Text {
                text: clock.timeStr.charAt(2)
                color: clock.smartMinutesColor
                font.pixelSize: Math.round(200 * dp)
                font.family: clock.fontFamily
                font.weight: Font.Medium
                width: Math.round(130 * dp)
                horizontalAlignment: Text.AlignHCenter
                antialiasing: true
            }
        }

        // Coluna 2: unidades da hora / unidades dos minutos
        Column {
            spacing: Math.round(-45 * dp)
            Text {
                text: clock.timeStr.charAt(1)
                color: clock.smartHoursColor
                font.pixelSize: Math.round(200 * dp)
                font.family: clock.fontFamily
                font.weight: Font.Medium
                width: Math.round(130 * dp)
                horizontalAlignment: Text.AlignHCenter
                antialiasing: true
            }
            Text {
                text: clock.timeStr.charAt(3)
                color: clock.smartMinutesColor
                font.pixelSize: Math.round(200 * dp)
                font.family: clock.fontFamily
                font.weight: Font.Medium
                width: Math.round(130 * dp)
                horizontalAlignment: Text.AlignHCenter
                antialiasing: true
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.timeStr = Qt.formatTime(new Date(), "HHmm")
    }
}