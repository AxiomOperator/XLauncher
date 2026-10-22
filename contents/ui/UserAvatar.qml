import QtQuick
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents
import org.kde.plasma.plasmoid

Item {
    id: avatar

    required property LauncherState launcher

    readonly property color borderGradientColor1: {
        switch (Plasmoid.configuration.glowColor) {
        case 0: return "#FEAC5E";
        case 1: return "#a5fecb";
        case 3: return Qt.lighter(avatar.launcher.customGlowColor, 1.4);
        default: return "#ff005d";
        }
    }
    readonly property color borderGradientColor2: {
        switch (Plasmoid.configuration.glowColor) {
        case 0: return "#C779D0";
        case 1: return "#20bdff";
        case 3: return avatar.launcher.customGlowColor;
        default: return "#ff005c";
        }
    }
    readonly property color borderGradientColor3: {
        switch (Plasmoid.configuration.glowColor) {
        case 0: return "#4BC0C8";
        case 1: return "#5433ff";
        case 3: return Qt.darker(avatar.launcher.customGlowColor, 1.6);
        default: return "#ff8b26";
        }
    }

    KirigamiComponents.AvatarButton {
        id: mainFaceIcon

        anchors {
            fill: parent
            margins: Kirigami.Units.smallSpacing
        }
        source: avatar.launcher.user.faceIconUrl

        onClicked: {
            KCM.KCMLauncher.openSystemSettings("kcm_users");
            avatar.launcher.close();
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }

    // Gradient ring behind the avatar
    Rectangle {
        anchors.centerIn: mainFaceIcon
        width: avatar.width - 4 // Smaller than the avatar to prevent fringing
        height: width
        radius: width / 2
        visible: Plasmoid.configuration.enableGlow
        z: -1
        rotation: 270
        transformOrigin: Item.Center

        gradient: Gradient {
            GradientStop { position: 0.0; color: avatar.borderGradientColor1 }
            GradientStop { position: 0.33; color: avatar.borderGradientColor2 }
            GradientStop { position: 1.0; color: avatar.borderGradientColor3 }
        }
    }
}
