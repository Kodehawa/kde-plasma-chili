import "components"

import QtQuick 2.0
import QtQuick.Layouts 1.2
import QtQuick.Controls.Styles 1.4

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

SessionManagementScreen {
    property bool showUsernamePrompt: !showUserList
    property int usernameFontSize
    property string usernameFontColor
    property string lastUserName
    property bool passwordFieldOutlined: config.PasswordFieldOutlined == "true"
    property bool hidePasswordRevealIcon: config.HidePasswordRevealIcon == "false"
    property string customTextColor: config.TextColor
    property string customRectangleColor: config.RectangleColor
    property string customBorderColor: config.BorderColor
    property string customBorderWidth: config.BorderWidth
    property string customRadius: config.RectangleRadius
    property string customMinimumHeight: config.RectangleHeight

    //the y position that should be ensured visible when the on screen keyboard is visible
    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + units.smallSpacing

    signal loginRequest(string username, string password)

    onShowUsernamePromptChanged: {
        if (!showUsernamePrompt) {
            lastUserName = ""
        }
    }

    /*
    * Login has been requested with the following username and password
    * If username field is visible, it will be taken from that, otherwise from the "name" property of the currentIndex
    */
    function startLogin() {
        var username = showUsernamePrompt ? userNameInput.text : userList.selectedUser
        var password = passwordBox.text

        //this is partly because it looks nicer
        //but more importantly it works round a Qt bug that can trigger if the app is closed with a TextField focussed
        //DAVE REPORT THE FRICKING THING AND PUT A LINK
        loginButton.forceActiveFocus();
        loginRequest(username, password);
    }

    PlasmaComponents.TextField {
        id: userNameInput
        Layout.fillWidth: true
        Layout.minimumHeight: customMinimumHeight
        implicitHeight: root.height / 28
        font.family: config.Font || "Noto Sans"
        font.pointSize: usernameFontSize
        opacity: 0.7
        text: lastUserName
        visible: showUsernamePrompt
        focus: showUsernamePrompt && !lastUserName //if there's a username prompt it gets focus first, otherwise password does
        placeholderText: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Username")

        style: TextFieldStyle {
            textColor: customTextColor
            background: Rectangle {
                radius: customRadius
            }
        }
    }

    PlasmaComponents.TextField {
        id: passwordBox
        
        Layout.fillWidth: true
        Layout.minimumHeight: customMinimumHeight
        implicitHeight: usernameFontSize * 2.85
        font.pointSize: usernameFontSize * 0.8
        opacity: config.Opacity ? config.Opacity : (passwordFieldOutlined ? 0.5 : 0.75)
        font.family: config.Font || "Noto Sans"
        placeholderText: config.PasswordFieldPlaceholderText == "Password" ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Password") : config.PasswordFieldPlaceholderText
        focus: !showUsernamePrompt || lastUserName
        echoMode: TextInput.Password
        revealPasswordButtonShown: hidePasswordRevealIcon
        onAccepted: startLogin()

        style: TextFieldStyle {
            textColor: customTextColor
            placeholderTextColor: customTextColor
            passwordCharacter: config.PasswordFieldCharacter == "" ? "●" : config.PasswordFieldCharacter
            background: Rectangle {
                color: customRectangleColor
                radius: customRadius
                border.color: customBorderColor
                border.width: customBorderWidth
            }
        }

        Keys.onEscapePressed: {
            mainStack.currentItem.forceActiveFocus();
        }

        //if empty and left or right is pressed change selection in user switch
        //this cannot be in keys.onLeftPressed as then it doesn't reach the password box
        Keys.onPressed: {
            if (event.key == Qt.Key_Left && !text) {
                userList.decrementCurrentIndex();
                event.accepted = true
            }
            if (event.key == Qt.Key_Right && !text) {
                userList.incrementCurrentIndex();
                event.accepted = true
            }
        }

        Keys.onReleased: {
            if (loginButton.opacity == 0 && length > 0) {
                showLoginButton.start()
            }
            if (loginButton.opacity > 0 && length == 0) {
                hideLoginButton.start()
            }
        }

        Connections {
            target: sddm
            function onLoginFailed() {
                passwordBox.selectAll()
                passwordBox.forceActiveFocus()
            }
        }
    }

    Image {
        id: loginButton
        source: "components/artwork/login.svgz"
        smooth: true
        sourceSize: Qt.size(passwordBox.height, passwordBox.height)        
        anchors {
            left: passwordBox.right
            verticalCenter: passwordBox.verticalCenter
        }
        
        anchors.leftMargin: 12
        visible: opacity > 0
        opacity: 0
        MouseArea {
            anchors.fill: parent
            onClicked: startLogin();
        }
        PropertyAnimation {
            id: showLoginButton
            target: loginButton
            properties: "opacity"
            to: 0.75
            duration: 100
        }
        PropertyAnimation {
            id: hideLoginButton
            target: loginButton
            properties: "opacity"
            to: 0
            duration: 80
        }
    }
}
