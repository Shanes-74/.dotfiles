import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
    id: clock

    property string backgroundSource: ""
    property color defaultHoursColor: "#AED68A"
    property color defaultMinutesColor: "#D4E4BC"
    property string fontFamily: "Google Sans Flex Freeze"
    property color baseAccent: config.accentColor
    property real dp: 1.0 

    property color smartHoursColor: defaultHoursColor
    property color smartMinutesColor: defaultMinutesColor
    property string timeStr: Qt.formatTime(new Date(), "HHmm")

    function updateColors() {
        var base = clock.baseAccent;
        if (base.hsvValue < 0.3) {
            clock.smartHoursColor   = Qt.hsva(base.hsvHue, 0.6,  0.9,  1.0);
            clock.smartMinutesColor = Qt.hsva(base.hsvHue, 0.35, 0.85, 1.0);
        } else {
            clock.smartHoursColor   = Qt.hsva(base.hsvHue, Math.min(1.0, base.hsvSaturation * 1.3),  0.95, 1.0);
            clock.smartMinutesColor = Qt.hsva(base.hsvHue, Math.min(1.0, base.hsvSaturation * 0.75), 0.92, 1.0);
        }
    }

    onBaseAccentChanged: updateColors()
    Component.onCompleted: updateColors()

    width: mainColumn.width
    height: mainColumn.height

    Column {
        id: mainColumn
        anchors.centerIn: parent
        spacing: Math.round(-85 * dp) 

        // --- HORAS ---
        Item {
            width: txtHours.implicitWidth + (80 * dp)
            height: txtHours.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter
            
            DropShadow {
                anchors.fill: txtHours
                source: txtHours
                radius: 30 * dp       
                samples: 48           
                color: "#FF000000"    // PRETO TOTAL (100% OPACO)
                horizontalOffset: 0
                verticalOffset: 0
                spread: 0.1           
                transparentBorder: true
            }

            Text {
                id: txtHours
                anchors.centerIn: parent
                text: clock.timeStr.substring(0, 2)
                color: clock.smartHoursColor
                font { family: clock.fontFamily; pixelSize: Math.round(260 * dp); weight: Font.Bold }
                antialiasing: true
                renderType: Text.NativeRendering 
            }
        }

        // --- MINUTOS ---
        Item {
            width: txtMins.implicitWidth + (80 * dp)
            height: txtMins.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter

            DropShadow {
                anchors.fill: txtMins
                source: txtMins
                radius: 30 * dp       
                samples: 48
                color: "#FF000000"    // PRETO TOTAL (100% OPACO)
                horizontalOffset: 0
                verticalOffset: 0
                spread: 0.1           
                transparentBorder: true
            }

            Text {
                id: txtMins
                anchors.centerIn: parent
                text: clock.timeStr.substring(2, 4)
                color: clock.smartMinutesColor
                font { family: clock.fontFamily; pixelSize: Math.round(260 * dp); weight: Font.Bold }
                antialiasing: true
                renderType: Text.NativeRendering
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