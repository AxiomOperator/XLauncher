import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    id: greeting

    required property LauncherState launcher

    property real textSize
    readonly property real textWidth: nameLabel.width

    Text {
        id: nameLabel

        text: {
            const config = Plasmoid.configuration;
            const user = greeting.launcher.user;
            if (config.enableGreeting && config.customGreeting) {
                return config.customGreeting;
            }
            return config.enableGreeting ? i18n("Hi, %1", user.fullName) : i18n("%1@%2", user.loginName, user.host);
        }
        color: Kirigami.Theme.textColor
        font.family: greeting.launcher.textFont
        font.pixelSize: greeting.textSize
        font.bold: true
    }

    // Text glow
    MultiEffect {
        anchors.fill: nameLabel
        source: nameLabel
        visible: Plasmoid.configuration.enableGlow
        shadowEnabled: true
        shadowColor: greeting.launcher.glowColor1
        shadowBlur: 0.6
        blurMax: 16
    }
}
