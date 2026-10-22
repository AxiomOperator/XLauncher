/*****************************************************************************
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

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

import "js/colorType.js" as ColorType

Item {
    id: main

    required property LauncherState launcher
    required property PlasmaCore.Dialog dialog

    property bool showAllApps: false

    readonly property bool searching: searchBar.textField.text !== ""
    readonly property bool isTop: Plasmoid.location === PlasmaCore.Types.TopEdge
                                  && Plasmoid.configuration.launcherPosition !== 2
                                  && !Plasmoid.configuration.floating
    readonly property bool isDarkTheme: ColorType.isDark(Kirigami.Theme.backgroundColor)
    readonly property color contrastBgColor: main.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.25)
    readonly property bool glowVisible: Plasmoid.configuration.enableGlow && !main.searching
    readonly property int pinnedModel: Plasmoid.configuration.pinnedModel
    readonly property int itemSpacing: 8

    // Height needed for the header, the grid rows and the search bar
    readonly property real contentHeight: headerLabelRow.height
                                          + searchBar.height
                                          + backdrop.y
                                          + main.itemSpacing * 3
                                          + main.launcher.cellSizeHeight * main.launcher.rows

    readonly property LauncherPage currentPage: stack.currentItem as LauncherPage
    readonly property AllAppsList allAppsPage: stack.currentItem as AllAppsList

    // Title and icon of the main page, which shows favorites, recent apps or recent files
    readonly property string pinnedTitle: {
        switch (main.pinnedModel) {
        case 1: return i18n("Recent Apps");
        case 2: return i18n("Recent Files");
        default: return i18n("Favorite Apps");
        }
    }
    readonly property var pinnedIcon: {
        switch (main.pinnedModel) {
        case 1: return "document-open-recent-symbolic";
        case 2: return Qt.resolvedUrl("icons/feather/file-text.svg");
        default: return Qt.resolvedUrl("icons/feather/star.svg");
        }
    }

    // Whether the current drag is an app that can be added to favorites
    readonly property bool dragCanBeFavorited: {
        const id = main.launcher.dragSource.favoriteId;
        return id !== "" && main.launcher.globalFavorites !== null && !main.launcher.globalFavorites.isFavorite(id);
    }

    function reset(): void {
        main.showAllApps = false;
        searchBar.textField.clear();
        searchBar.textField.forceActiveFocus();
        stack.replace(pinnedAppsComponent);
    }

    onSearchingChanged: {
        if (main.searching) {
            stack.replace(searchComponent);
        } else if (main.showAllApps) {
            stack.replace(allAppsComponent);
        } else {
            stack.replace(pinnedAppsComponent);
        }
    }

    // Where the page area starts, below the avatar and greeting
    Item {
        id: backdrop

        y: main.isTop ? 125 : 90
        width: main.width
        height: main.isTop ? main.height - backdrop.y - Kirigami.Units.largeSpacing : main.height - backdrop.y
    }

    FloatingAvatar {
        id: floatingAvatar

        launcher: main.launcher
        anchorWindow: main.dialog
        avatarWidth: 110
        visible: main.dialog.visible && !main.isTop
    }

    // Avatar, settings and power
    RowLayout {
        id: headerBar

        width: main.width

        Item {
            Layout.fillWidth: true

            UserAvatar {
                width: 80
                height: width
                visible: !floatingAvatar.visible
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: width / 2

                launcher: main.launcher
            }
        }

        Header {
            id: powerSettings

            launcher: main.launcher
            iconSize: 20

            Layout.fillHeight: false
            Layout.alignment: Qt.AlignRight | Qt.AlignTop
        }
    }

    Greeting {
        id: greeting

        x: main.width / 2 - greeting.textWidth / 2 // Centers the text
        y: main.isTop ? 95 : 50

        launcher: main.launcher
        textSize: 20
    }

    ColumnLayout {
        anchors {
            top: backdrop.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        spacing: main.itemSpacing

        // Favorites / all apps label
        RowLayout {
            id: headerLabelRow

            visible: !main.searching

            Kirigami.Icon {
                id: headerLabel

                source: main.pinnedIcon
                visible: !main.showAllApps
                isMask: true
                color: Kirigami.Theme.textColor

                Layout.preferredHeight: 15
                Layout.preferredWidth: 15
                Layout.fillHeight: false
            }

            Kirigami.Icon {
                id: sortingImage

                source: main.allAppsPage && main.allAppsPage.currentCategory ? main.allAppsPage.currentCategory.icon : ""
                visible: main.showAllApps

                Layout.preferredHeight: 15
                Layout.preferredWidth: 15
                Layout.fillHeight: false
            }

            PlasmaComponents.Label {
                id: mainLabelGrid

                text: {
                    if (!main.showAllApps) {
                        return main.pinnedTitle;
                    }
                    return main.allAppsPage && main.allAppsPage.currentCategory ? main.allAppsPage.currentCategory.name : "";
                }
                font.family: main.launcher.textFont
                font.pointSize: main.launcher.textSize

                // In All Apps: cycles through the categories. Otherwise: picks what the main page shows.
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    enabled: !main.searching
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: mouse => {
                        const appList = main.allAppsPage;
                        if (!main.showAllApps || !appList) {
                            pageMenu.popup(mainLabelGrid, 0, mainLabelGrid.height);
                            return;
                        }
                        if (mouse.button === Qt.LeftButton) {
                            appList.incrementCurrentStateIndex();
                        } else if (mouse.button === Qt.RightButton) {
                            appList.decrementCurrentStateIndex();
                        } else if (mouse.button === Qt.MiddleButton) {
                            appList.resetCurrentStateIndex();
                        }
                    }
                }
            }

            Kirigami.Icon {
                source: "arrow-down-symbolic"
                visible: !main.showAllApps
                isMask: true
                color: Kirigami.Theme.textColor
                opacity: 0.7

                Layout.preferredHeight: 12
                Layout.preferredWidth: 12
            }

            Item {
                Layout.fillWidth: true
            }

            PlasmaComponents.Menu {
                id: pageMenu

                component PageMenuItem: PlasmaComponents.MenuItem {
                    id: pageMenuItem

                    required property int page

                    checkable: true
                    checked: main.pinnedModel === pageMenuItem.page
                    onTriggered: Plasmoid.configuration.pinnedModel = pageMenuItem.page
                }

                PageMenuItem {
                    page: 0
                    text: i18n("Favorite Apps")
                }
                PageMenuItem {
                    page: 1
                    text: i18n("Recent Apps")
                }
                PageMenuItem {
                    page: 2
                    text: i18n("Recent Files")
                }
            }

            PlasmaComponents.Button {
                id: allAppsButton

                text: {
                    if (favoriteDropArea.containsDrag && main.dragCanBeFavorited) {
                        return i18n("Add to Favorites");
                    }
                    return main.showAllApps ? i18n("Back") : i18n("All apps");
                }
                flat: false

                topPadding: 6
                bottomPadding: allAppsButton.topPadding
                leftPadding: 10
                rightPadding: 10

                icon.height: 15
                icon.width: 15

                font.pointSize: main.launcher.textSize
                font.family: main.launcher.textFont

                LayoutMirroring.enabled: true
                LayoutMirroring.childrenInherit: !main.showAllApps
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                onClicked: {
                    main.showAllApps = !main.showAllApps;
                    stack.replace(main.showAllApps ? allAppsComponent : pinnedAppsComponent);
                    searchBar.textField.forceActiveFocus(Qt.BacktabFocusReason);
                }

                background: Item {
                    Rectangle {
                        id: buttonBackground

                        anchors.fill: parent
                        color: main.contrastBgColor
                        border.width: 1
                        border.color: main.contrastBgColor
                        radius: buttonBackground.height / 2

                        // Glow fill; the rounded Rectangle clips its own gradient
                        Rectangle {
                            anchors.fill: parent
                            radius: buttonBackground.radius
                            visible: main.glowVisible
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: main.launcher.glowColor2 }
                                GradientStop { position: 1.0; color: main.launcher.glowColor1 }
                            }
                        }
                    }

                    MultiEffect {
                        anchors.fill: buttonBackground
                        source: buttonBackground
                        visible: main.glowVisible
                        shadowEnabled: true
                        shadowColor: main.launcher.glowColor1
                        shadowBlur: 0.7
                        blurMax: 16
                    }

                    // Shown while an app is dragged over the button
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: "transparent"
                        border.width: 2
                        border.color: Kirigami.Theme.highlightColor
                        visible: favoriteDropArea.containsDrag && main.dragCanBeFavorited
                    }
                }

                // In All Apps, dropping an app on the Back button adds it to favorites
                DropArea {
                    id: favoriteDropArea

                    anchors.fill: parent
                    enabled: main.showAllApps

                    onEntered: drag => {
                        if (drag.source !== main.launcher.dragSource || !main.dragCanBeFavorited) {
                            drag.accepted = false;
                        }
                    }
                    onDropped: drop => {
                        if (drop.source === main.launcher.dragSource && main.dragCanBeFavorited) {
                            main.launcher.globalFavorites.addFavorite(main.launcher.dragSource.favoriteId);
                            drop.accept(Qt.CopyAction);
                        }
                    }
                }
            }
        }

        StackView {
            id: stack

            initialItem: pinnedAppsComponent

            Layout.fillWidth: true
            Layout.preferredHeight: main.launcher.cellSizeHeight * main.launcher.rows

            Keys.priority: Keys.AfterItem
            Keys.forwardTo: [searchBar.textField]
        }

        Component {
            id: pinnedAppsComponent

            PinnedApps {
                launcher: main.launcher
                searchField: searchBar.textField
            }
        }

        Component {
            id: allAppsComponent

            AllAppsList {
                launcher: main.launcher
            }
        }

        Component {
            id: searchComponent

            RunnerList {
                launcher: main.launcher
                model: main.launcher.runnerModel.count ? main.launcher.runnerModel.modelForRow(0) : null
            }
        }

        SearchBar {
            id: searchBar

            launcher: main.launcher
            searching: main.searching
            color: main.contrastBgColor

            Layout.fillWidth: true
            Layout.preferredHeight: 45
            Layout.maximumHeight: searchBar.Layout.preferredHeight
            Layout.alignment: Qt.AlignBottom

            Keys.priority: Keys.AfterItem
            Keys.forwardTo: main.currentPage && main.currentPage.viewItem ? [main.currentPage.viewItem] : []
        }
    }
}
