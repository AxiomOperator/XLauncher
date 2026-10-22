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

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Item {
    id: root

    required property LauncherState launcher

    readonly property bool useCustomButtonImage: Plasmoid.configuration.useCustomButtonImage
                                                 && String(Plasmoid.configuration.customButtonImage).length > 0

    Plasmoid.status: root.launcher.menuOpen ? PlasmaCore.Types.RequiresAttentionStatus : PlasmaCore.Types.PassiveStatus

    Plasmoid.onActivated: root.launcher.toggle()

    Kirigami.Icon {
        id: buttonIcon

        width: Plasmoid.configuration.activationIndicator ? root.width * 0.65 : root.width
        height: Plasmoid.configuration.activationIndicator ? root.height * 0.65 : root.height
        anchors.centerIn: parent

        source: root.useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon
        active: mouseArea.containsMouse
        smooth: true

        Rectangle {
            id: indicator

            anchors.horizontalCenter: parent.horizontalCenter
            y: buttonIcon.height + indicator.height
            width: root.launcher.menuOpen ? buttonIcon.width * 0.65 : 0
            height: 3
            radius: 10
            color: Plasmoid.configuration.indicatorColor
            visible: Plasmoid.configuration.activationIndicator

            Behavior on width {
                NumberAnimation { duration: 60 }
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true

        onClicked: root.launcher.toggle()
    }

    MenuRepresentation {
        launcher: root.launcher
        anchorItem: root
    }
}
