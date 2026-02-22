import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "components"

Rectangle {
    id: container
    width: 1920
    height: 1080
    color: config.backgroundColor
    focus: !loginState.visible

    property int userIndex: 0
    property int sessionIndex: 0
    property bool isLoggingIn: false
    property color extractedAccent: config.primaryColor ? config.primaryColor : "#A9C78F"

    Component.onCompleted: {
        if (typeof userModel !== "undefined" && userModel.lastIndex >= 0) userIndex = userModel.lastIndex;
        if (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) sessionIndex = sessionModel.lastIndex;
    }

    function cleanName(name) {
        if (!name) return "";
        var s = name.toString();
        if (s.endsWith("/")) s = s.substring(0, s.length - 1);
        if (s.indexOf("/") !== -1) s = s.substring(s.lastIndexOf("/") + 1);
        if (s.indexOf(".desktop") !== -1) s = s.substring(0, s.indexOf(".desktop"));
        s = s.replace(/[-_]/g, ' ');
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    function doLogin() {
        if (!loginState.visible || isLoggingIn) return;
        var user = "";
        if (typeof userModel !== "undefined" && userModel.count > 0) {
            var idx = container.userIndex;
            if (idx < 0 || idx >= userModel.count) idx = 0;
            var edit = userModel.data(userModel.index(idx, 0), Qt.EditRole);
            var nameRole = userModel.data(userModel.index(idx, 0), Qt.UserRole + 1);
            var display = userModel.data(userModel.index(idx, 0), Qt.DisplayRole);
            user = edit ? edit.toString() : (nameRole ? nameRole.toString() : (display ? display.toString() : ""));
        }
        if (!user || user === "" || user === "User") user = sddm.lastUser;
        if (!user && typeof userModel !== "undefined" && userModel.count > 0) {
            var firstEdit = userModel.data(userModel.index(0, 0), Qt.EditRole);
            user = firstEdit ? firstEdit.toString() : "";
        }
        if (!user) return;
        container.isLoggingIn = true;
        var pass = passwordField.text;
        var sess = container.sessionIndex;
        if (typeof sessionModel !== "undefined") {
            if (sess < 0 || sess >= sessionModel.count) sess = 0;
        } else { sess = 0; }
        sddm.login(user.trim(), pass, sess);
        loginTimeout.start();
    }

    Timer {
        id: loginTimeout
        interval: 5000
        onTriggered: container.isLoggingIn = false
    }

    Connections {
        target: sddm
        onLoginFailed: {
            container.isLoggingIn = false
            loginTimeout.stop()
            loginState.isError = true
            shakeAnimation.start()
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
        onLoginSucceeded: loginTimeout.stop()
    }

    Timer {
        id: colorDelay
        interval: 1000 
        repeat: true   
        running: false 
        onTriggered: colorExtractor.requestPaint()
    }

    Canvas {
        id: colorExtractor
        width: 60; height: 60
        x: -100; y: -100 
        z: -1
        renderTarget: Canvas.Image
        property bool processed: true 
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, 60, 60);
            ctx.drawImage(backgroundImage, 0, 0, 60, 60);
        }
    }

    FontLoader { id: fontRegular; source: "assets/fonts/FlexRounded-R.ttf" }
    FontLoader { id: fontMedium; source: "assets/fonts/FlexRounded-M.ttf" }
    FontLoader { id: fontBold; source: "assets/fonts/FlexRounded-B.ttf" }

    Image {
        id: backgroundImage
        source: config.background
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        layer.enabled: true
    }

    FastBlur {
        id: backgroundBlur
        anchors.fill: parent
        source: backgroundImage
        radius: config.blurRadius
        opacity: loginState.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: loginState.visible ? 0.4 : 0.2
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    // --- Pílula de Status Centralizada (80% Transparência) ---
    Rectangle {
        id: topStatusPill
        height: 48
        width: statusLayout.width + 40 
        anchors {
            top: parent.top
            topMargin: 30
            horizontalCenter: parent.horizontalCenter
        }
        color: loginState.isError ? config.errorColor : (config.surfaceContainer ? config.surfaceContainer : "#1a1a1a")
        opacity: 0.90
        radius: 999
        z: 100

        RowLayout {
            id: statusLayout
            anchors.centerIn: parent
            spacing: 20
            Text {
                text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                color: container.extractedAccent
                font.pixelSize: 15
                font.family: config.fontFamily
                font.weight: Font.Medium
            }
            Rectangle { width: 1; height: 16; color: container.extractedAccent; opacity: 0.3 }
            PowerBar {
                textColor: container.extractedAccent
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    Item {
        id: lockState
        anchors.fill: parent
        visible: !loginState.visible
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Clock {
            id: mainClock
            anchors.centerIn: parent
            backgroundSource: config.background
            baseAccent: container.extractedAccent
            fontFamily: config.fontFamily
            opacity: colorExtractor.processed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }
        
        Text {
            text: "Press any key to unlock"
            color: "white"
            font.pixelSize: 20
            font.family: config.fontFamily
            
            // Aqui entra o contorno (estilo legenda)
            style: Text.Outline
            styleColor: "black" 
            
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 100
            }
            opacity: 0.8
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                loginState.visible = true;
                passwordField.forceActiveFocus();
            }
        }
    }

    Item {
        id: loginState
        anchors.fill: parent
        visible: false
        opacity: visible ? 1 : 0
        z: 10
        Behavior on opacity { NumberAnimation { duration: 400 } }

        onVisibleChanged: if (visible) passwordField.forceActiveFocus();

        property bool isError: false
        SequentialAnimation {
            id: shakeAnimation
            loops: 2
            PropertyAnimation { target: loginCard; property: "x"; from: (container.width - loginCard.width)/2; to: (container.width - loginCard.width)/2 - 10; duration: 50; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: loginCard; property: "x"; from: (container.width - loginCard.width)/2 - 10; to: (container.width - loginCard.width)/2 + 10; duration: 50; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: loginCard; property: "x"; from: (container.width - loginCard.width)/2 + 10; to: (container.width - loginCard.width)/2; duration: 50; easing.type: Easing.InOutQuad }
            onStopped: isError = false
        }

        Rectangle {
            id: loginCard
            width: 380
            height: 480
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            color: loginState.isError ? config.errorColor : (config.surfaceContainer ? config.surfaceContainer : "#EEEBE3")
            opacity: 0.90 // Opacidade em 80% como solicitado
            radius: 32
            Behavior on color { ColorAnimation { duration: 200 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 50
                spacing: -10
                Item { Layout.preferredHeight: 32 } 

                Item {
                    id: avatarContainer
                    Layout.preferredWidth: 180; Layout.preferredHeight: 180
                    Layout.alignment: Qt.AlignHCenter
                    
                    Rectangle {
                        id: avatarFallback
                        anchors.fill: parent
                        color: config.onSurfaceColor
                        opacity: 0.2
                        radius: width / 2
                        visible: avatar.status !== Image.Ready
                        Text {
                            anchors.centerIn: parent
                            text: {
                                var n = "";
                                if (typeof userModel !== "undefined" && userModel.count > 0) {
                                    var d = userModel.data(userModel.index(container.userIndex, 0), Qt.DisplayRole);
                                    var nr = userModel.data(userModel.index(container.userIndex, 0), Qt.UserRole + 1);
                                    n = d ? d.toString() : (nr ? nr.toString() : "U");
                                } else { n = sddm.lastUser ? sddm.lastUser : "U"; }
                                return n.charAt(0).toUpperCase();
                            }
                            color: container.extractedAccent
                            font.pixelSize: 48; font.family: fontBold.name; font.weight: Font.Bold
                        }
                    }

                    Image {
                        id: avatar
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        smooth: true; visible: false 
                        property string userIcon: {
                            if (typeof userModel !== "undefined" && userModel.count > 0) {
                                var icon = userModel.data(userModel.index(container.userIndex, 0), Qt.UserRole + 3);
                                return (icon && icon !== "") ? icon : "assets/avatar.jpg";
                            }
                            return "assets/avatar.jpg";
                        }
                        source: userIcon
                        onStatusChanged: if (status === Image.Error && source != "assets/avatar.jpg") source = "assets/avatar.jpg";
                    }

                    Rectangle { id: avatarMask; anchors.fill: parent; radius: width / 2; visible: false }
                    OpacityMask { anchors.fill: parent; source: avatar; maskSource: avatarMask; visible: avatar.status === Image.Ready }
                }

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: userNameLabel.width + 40
                    Layout.preferredHeight: userNameLabel.height + 20
                    Rectangle { anchors.fill: parent; color: config.onSurfaceColor; opacity: userClickArea.pressed ? 0.2 : 0; radius: 12 }
                    Text {
                        id: userNameLabel
                        anchors.centerIn: parent
                        text: (typeof userModel !== "undefined" && userModel.count > 0) ? userModel.data(userModel.index(container.userIndex, 0), Qt.DisplayRole) : "Shane"
                        color: config.onSurfaceColor
                        font.pixelSize: 24; font.weight: Font.Bold; font.family: config.fontFamily
                    }
                    MouseArea { id: userClickArea; anchors.fill: parent; onClicked: userPopup.open() }
                    scale: userClickArea.pressed ? 0.95 : 1.0
                }

                Rectangle {
                    id: sessionPill
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 180; Layout.preferredHeight: 36
                    color: Qt.rgba(config.onSurfaceColor.r, config.onSurfaceColor.g, config.onSurfaceColor.b, 0.15)
                    radius: 9999
                    
                    RowLayout {
                        anchors.centerIn: parent; spacing: 15
                        Text { 
                            text: "󰟀"; 
                            color: container.extractedAccent; 
                            font.pixelSize: 16 
                            opacity: 0.8
                        }
                        Text {
                            text: {
                                if (typeof sessionModel !== "undefined" && sessionModel.count > 0) {
                                    var idx = container.sessionIndex;
                                    var mIdx = sessionModel.index(idx, 0);
                                    var n = sessionModel.data(mIdx, Qt.UserRole + 4);
                                    var f = sessionModel.data(mIdx, Qt.UserRole + 2);
                                    var d = sessionModel.data(mIdx, Qt.DisplayRole);
                                    var finalName = n ? n.toString() : (f ? f.toString() : (d ? d.toString() : "Session " + (idx + 1)));
                                    return cleanName(finalName) + (sessionModel.count > 1 ? " ▾" : "");
                                }
                                return "Hyprland";
                            }
                            color: container.extractedAccent;
                            font.pixelSize: 13; 
                            font.weight: Font.Medium;
                        }
                    }
                    MouseArea { id: sessionClickArea; anchors.fill: parent; onClicked: sessionPopup.open() }
                }

                Item { Layout.fillHeight: true }

                TextField {
                    id: passwordField
                    echoMode: TextInput.Password
                    Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 18
                    color: config.onSurfaceColor 
                    focus: loginState.visible; enabled: !container.isLoggingIn
                    background: Rectangle {
                        color: config.onSurfaceColor
                        opacity: 0.10
                        radius: 9999; border.width: parent.activeFocus ? 2 : 0; border.color: container.extractedAccent
                    }
                    Text {
                        text: "Enter Password"
                        color: container.extractedAccent 
                        font.pixelSize: 16
                        visible: !parent.text
                        anchors.centerIn: parent
                        opacity: 0.8
                    }
                    onAccepted: container.doLogin()
                }

                Text {
                    id: numLockIndicator
                    text: "Num Lock is on"; color: container.extractedAccent; font.pixelSize: 14
                    font.family: config.fontFamily; font.weight: Font.Medium; Layout.alignment: Qt.AlignHCenter
                    visible: (typeof keyboard !== "undefined" && typeof keyboard.numLock !== "undefined") ? keyboard.numLock : false
                }

                Item { Layout.fillHeight: true }

                RoundButton {
                    id: loginButton
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    Layout.bottomMargin: -25
                    
                    focusPolicy: Qt.NoFocus
                    enabled: !container.isLoggingIn
                    
                    contentItem: Item {
                        Text {
                            anchors.centerIn: parent
                            text: container.isLoggingIn ? "⋯" : "→"
                            color: (container.extractedAccent.r * 0.299 + container.extractedAccent.g * 0.587 + container.extractedAccent.b * 0.114) > 0.6 ? "#000000" : "#FFFFFF"
                            font.pixelSize: 32
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    background: Rectangle {
                        color: container.isLoggingIn ? config.outlineColor : (loginButton.pressed ? Qt.darker(container.extractedAccent, 1.1) : container.extractedAccent)
                        radius: 9999
                    }
                    
                    onClicked: container.doLogin()
                }
            }
        }
    }

    Keys.onPressed: function(event) {
        if (!loginState.visible) {
            loginState.visible = true;
            passwordField.forceActiveFocus();
            event.accepted = true;
        }
    }

    Shortcut { sequence: "Escape"; enabled: loginState.visible; onActivated: { loginState.visible = false; passwordField.text = ""; container.focus = true; } }
    Shortcut { sequences: ["Return", "Enter"]; enabled: loginState.visible; onActivated: container.doLogin() }

    Popup {
        id: userPopup
        width: 260; height: (typeof userModel !== "undefined") ? Math.min(300, userModel.count * 50 + 20) : 100
        x: (parent.width - width) / 2; y: (parent.height - height) / 2 - 50; modal: true
        background: Rectangle { color: config.surfaceContainer; radius: 24; opacity: 0.95; border.color: config.outlineColor }
        ListView {
            id: userList; anchors.fill: parent; anchors.margins: 10
            model: (typeof userModel !== "undefined") ? userModel : null
            delegate: ItemDelegate {
                width: parent.width; height: 40
                background: Rectangle { color: (index === userList.currentIndex) ? config.onSurfaceColor : (hovered ? config.onSurfaceColor : "transparent"); opacity: (hovered || index === userList.currentIndex) ? 0.2 : 0; radius: 12 }
                contentItem: RowLayout {
                    spacing: 15
                    Item { Layout.preferredWidth: 8 }
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: (index === userList.currentIndex) ? container.extractedAccent : config.outlineColor
                        Text { anchors.centerIn: parent; text: "U"; color: config.onPrimaryColor; font.pixelSize: 12 }
                    }
                    Text { text: cleanName(model.display); color: config.onSurfaceColor; Layout.fillWidth: true }
                }
                onClicked: { container.userIndex = index; userPopup.close(); }
            }
        }
    }

    Popup {
        id: sessionPopup
        width: 260; height: (typeof sessionModel !== "undefined") ? Math.min(250, sessionModel.count * 50 + 20) : 100
        x: (parent.width - width) / 2; y: (parent.height - height) / 2 + 80; modal: true
        background: Rectangle { color: config.surfaceContainer; radius: 24; opacity: 0.95; border.color: config.outlineColor }
        ListView {
            id: sessionList; anchors.fill: parent; anchors.margins: 10
            model: (typeof sessionModel !== "undefined") ? sessionModel : null
            delegate: ItemDelegate {
                width: parent.width; height: 40
                background: Rectangle { color: (index === sessionList.currentIndex) ? config.onSurfaceColor : (hovered ? config.onSurfaceColor : "transparent"); opacity: (hovered || index === sessionList.currentIndex) ? 0.2 : 0; radius: 12 }
                contentItem: Text { text: cleanName(model.name); color: config.onSurfaceColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: { container.sessionIndex = index; sessionPopup.close(); }
            }
        }
    }
}