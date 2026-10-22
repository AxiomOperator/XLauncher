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
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.kicker as Kicker

Item {
    id: header

    required property LauncherState launcher
    required property real iconSize

    width: header.iconSize * 3.55
    height: header.iconSize

    // System actions (lock, log out, restart, ...) for the leave menu
    Kicker.SystemModel {
        id: systemModel

        favoritesModel: header.launcher.systemFavorites
    }

    PC3.RoundButton {
        id: settingsButton

        flat: true
        height: header.iconSize * 1.5
        width: settingsButton.height
        anchors.left: parent.left

        onClicked: {
            KCM.KCMLauncher.openSystemSettings("kcm_landingpage");
            header.launcher.close();
        }

        Kirigami.Icon {
            id: settingsImage

            anchors.fill: parent
            source: Qt.resolvedUrl("icons/feather/stngs.svg")
            isMask: true
            color: Kirigami.Theme.textColor
        }
    }

    PC3.RoundButton {
        id: leaveButton

        Accessible.role: Accessible.ButtonMenu
        anchors.right: parent.right
        flat: true
        height: header.iconSize * 1.5
        width: leaveButton.height
        // Look pressed while the menu is open
        down: contextMenu.status === PlasmaExtras.Menu.Open || leaveButton.pressed

        Keys.onLeftPressed: event => {
            if (Application.layoutDirection === Qt.LeftToRight) {
                leaveButton.nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason);
            }
        }
        Keys.onRightPressed: event => {
            if (Application.layoutDirection === Qt.RightToLeft) {
                leaveButton.nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason);
            }
        }

        onPressed: contextMenu.openRelative()

        Kirigami.Icon {
            id: powerImage

            anchors.fill: parent
            source: Qt.resolvedUrl("icons/feather/pwr.svg")
            isMask: true
            color: Kirigami.Theme.textColor
        }
    }

    Instantiator {
        model: systemModel

        delegate: PlasmaExtras.MenuItem {
            id: menuItem

            required property int index
            required property var model

            text: menuItem.model.display
            icon: menuItem.model.decoration

            onClicked: {
                header.launcher.close();
                systemModel.trigger(menuItem.index, "", null);
            }
        }

        onObjectAdded: (index, object) => contextMenu.addMenuItem(object as PlasmaExtras.MenuItem)
        onObjectRemoved: (index, object) => contextMenu.removeMenuItem(object as PlasmaExtras.MenuItem)
    }

    PlasmaExtras.Menu {
        id: contextMenu

        visualParent: leaveButton
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
    }
}
