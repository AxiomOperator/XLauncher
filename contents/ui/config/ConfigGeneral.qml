/*****************************************************************************
 *   Copyright (C) 2013-2014 by Eike Hein <hein@kde.org>                     *
 *   Copyright (C) 2021 by Prateek SU <pankajsunal123@gmail.com>             *
 *   Copyright (C) 2022 by Friedrich Schriewer <friedrich.schriewer@gmx.net> *
 *                                                                           *
 *   This program is free software; you can redistribute it and/or modify    *
 *   it under the terms of the GNU General Public License as published by    *
 *   the Free Software Foundation; either version 2 of the License, or       *
 *   (at your option) any later version.                                     *
 *                                                                           *
 *   This program is distributed in the hope that it will be useful,         *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *
 *   GNU General Public License for more details.                            *
 *                                                                           *
 *   You should have received a copy of the GNU General Public License       *
 *   along with this program; if not, write to the                           *
 *   Free Software Foundation, Inc.,                                         *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .          *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import org.kde.draganddrop as DragDrop
import org.kde.iconthemes as KIconThemes
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: configGeneral

    property string cfg_icon: Plasmoid.configuration.icon
    property bool cfg_useCustomButtonImage: Plasmoid.configuration.useCustomButtonImage
    property string cfg_customButtonImage: Plasmoid.configuration.customButtonImage
    property alias cfg_activationIndicator: activationIndicatorCheck.checked
    property color cfg_indicatorColor: Plasmoid.configuration.indicatorColor
    property alias cfg_enableGreeting: enableGreetingCheck.checked
    property int cfg_defaultPage: Plasmoid.configuration.defaultPage
    property alias cfg_pinnedModel: pinnedModel.currentIndex

    property alias cfg_customGreeting: customGreeting.text
    property alias cfg_floating: floating.checked
    property alias cfg_launcherPosition: launcherPosition.currentIndex
    property alias cfg_offsetX: screenOffset.value
    property alias cfg_offsetY: panelOffset.value

    property alias cfg_enableGlow: enableGlowCheck.checked
    property alias cfg_glowColor: glowColor.currentIndex

    property alias cfg_useSystemFontSettings: useSystemFontSettings.checked

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        Button {
            id: iconButton

            Kirigami.FormData.label: i18n("Icon:")

            implicitWidth: previewFrame.width + Kirigami.Units.smallSpacing * 2
            implicitHeight: previewFrame.height + Kirigami.Units.smallSpacing * 2

            // Just to provide some visual feedback when dragging;
            // cannot have checked without checkable enabled
            checkable: true
            checked: dropArea.containsAcceptableDrag

            onPressed: iconMenu.opened ? iconMenu.close() : iconMenu.open()

            DragDrop.DropArea {
                id: dropArea

                property bool containsAcceptableDrag: false

                anchors.fill: parent

                onDragEnter: event => {
                    // Cannot use string operations (e.g. indexOf()) on "url" basic type.
                    const urlString = event.mimeData.url.toString();

                    // This list is also hardcoded in KIconDialog.
                    const extensions = [".png", ".xpm", ".svg", ".svgz"];
                    dropArea.containsAcceptableDrag = urlString.startsWith("file:///")
                        && extensions.some(extension => urlString.endsWith(extension));

                    if (!dropArea.containsAcceptableDrag) {
                        event.ignore();
                    }
                }
                onDragLeave: event => dropArea.containsAcceptableDrag = false

                onDrop: event => {
                    if (dropArea.containsAcceptableDrag) {
                        // Strip file:// prefix, we already verified in onDragEnter that we have only local URLs.
                        iconDialog.setCustomButtonImage(event.mimeData.url.toString().substr("file://".length));
                    }
                    dropArea.containsAcceptableDrag = false;
                }
            }

            KIconThemes.IconDialog {
                id: iconDialog

                function setCustomButtonImage(image: string): void {
                    configGeneral.cfg_customButtonImage = image || configGeneral.cfg_icon || "start-here-kde-symbolic";
                    configGeneral.cfg_useCustomButtonImage = true;
                }

                onIconNameChanged: iconDialog.setCustomButtonImage(iconDialog.iconName)
            }

            KSvg.FrameSvgItem {
                id: previewFrame

                anchors.centerIn: parent
                imagePath: Plasmoid.formFactor === PlasmaCore.Types.Vertical || Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                        ? "widgets/panel-background" : "widgets/background"
                width: Kirigami.Units.iconSizes.large + previewFrame.fixedMargins.left + previewFrame.fixedMargins.right
                height: Kirigami.Units.iconSizes.large + previewFrame.fixedMargins.top + previewFrame.fixedMargins.bottom

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.large
                    height: width
                    source: configGeneral.cfg_useCustomButtonImage ? configGeneral.cfg_customButtonImage : configGeneral.cfg_icon
                }
            }

            Menu {
                id: iconMenu

                // Appear below the button
                y: iconButton.height

                onClosed: iconButton.checked = false

                MenuItem {
                    text: i18nc("@item:inmenu Open icon chooser dialog", "Choose…")
                    icon.name: "document-open-folder"
                    onClicked: iconDialog.open()
                }
                MenuItem {
                    text: i18nc("@item:inmenu Reset icon to default", "Clear Icon")
                    icon.name: "edit-clear"
                    onClicked: {
                        configGeneral.cfg_icon = "start-here-kde-symbolic";
                        configGeneral.cfg_useCustomButtonImage = false;
                    }
                }
            }
        }

        CheckBox {
            id: activationIndicatorCheck

            Kirigami.FormData.label: i18n("Indicator:")
            text: i18n("Enabled")
        }

        Button {
            id: colorButton

            Kirigami.FormData.label: i18n("Indicator Color:")
            width: Kirigami.Units.iconSizes.small
            height: colorButton.width

            onPressed: colorDialog.visible ? colorDialog.close() : colorDialog.open()

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: configGeneral.cfg_indicatorColor
            }

            ColorDialog {
                id: colorDialog

                title: i18n("Please choose a color")
                selectedColor: configGeneral.cfg_indicatorColor
                onAccepted: configGeneral.cfg_indicatorColor = colorDialog.selectedColor
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            id: enableGreetingCheck

            Kirigami.FormData.label: i18n("Greeting:")
            text: i18n("Enabled")
        }

        TextField {
            id: customGreeting

            Kirigami.FormData.label: i18n("Custom Greeting Text:")
            enabled: enableGreetingCheck.checked
            placeholderText: i18n("No custom greeting set")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            id: enableGlowCheck

            Kirigami.FormData.label: i18n("Glow")
            text: i18n("Enabled")
        }

        ComboBox {
            id: glowColor

            Kirigami.FormData.label: i18n("Glow color:")
            visible: enableGlowCheck.checked
            model: [
                i18n("Purple (Default)"),
                i18n("Blue"),
                i18n("Red"),
            ]
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        ComboBox {
            id: launcherPosition

            Kirigami.FormData.label: i18n("Launcher Positioning:")
            model: [
                i18n("Default"),
                i18n("Horizontal Center"),
                i18n("Screen Center"),
            ]

            // Screen center always floats
            onActivated: index => {
                if (index === 2) {
                    floating.checked = true;
                }
            }
        }

        CheckBox {
            id: floating

            text: i18n("Floating")
            enabled: launcherPosition.currentIndex !== 2
        }

        Slider {
            id: screenOffset

            Kirigami.FormData.label: i18n("Offset Screen Edge (0 is Default):")
            visible: floating.checked
            from: 0
            to: 100
            stepSize: 1

            ToolTip.visible: screenOffset.hovered || screenOffset.pressed
            ToolTip.text: screenOffset.value
        }

        Slider {
            id: panelOffset

            Kirigami.FormData.label: i18n("Offset Panel (0 is Default):")
            visible: floating.checked
            from: 0
            to: 250
            stepSize: 1

            ToolTip.visible: panelOffset.hovered || panelOffset.pressed
            ToolTip.text: panelOffset.value
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        ComboBox {
            id: pinnedModel

            Kirigami.FormData.label: i18n("Pinned applications Page:")
            model: [
                i18n("Favorites (Default)"),
                i18n("Recent Applications")
            ]
        }

        ComboBox {
            id: defaultPage

            // Fallback names, used only until the launcher has published its categories
            readonly property list<string> fallbackNames: [
                i18n("All Applications (Default)"),
                i18n("Development"),
                i18n("Games"),
                i18n("Graphics"),
                i18n("Internet"),
                i18n("Multimedia"),
                i18n("Office"),
                i18n("Science & Math"),
                i18n("Settings"),
                i18n("System"),
                i18n("Utilities"),
                i18n("Lost & Found"),
            ]

            Kirigami.FormData.label: i18n("Default Page:")

            // Published by the launcher from the live menu, so indexes match the All Apps pages
            model: Plasmoid.configuration.categoryNames.length > 0 ? Plasmoid.configuration.categoryNames : defaultPage.fallbackNames
            currentIndex: Math.min(configGeneral.cfg_defaultPage, defaultPage.count - 1)
            onActivated: index => configGeneral.cfg_defaultPage = index
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            id: useSystemFontSettings

            Kirigami.FormData.label: i18n("Use system font settings")
            text: i18n("Enabled")
        }
    }
}
