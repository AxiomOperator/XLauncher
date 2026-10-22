/*****************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>                   *
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                     *
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
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmaCore.Dialog {
    id: root

    required property LauncherState launcher
    // The panel button the launcher opens from
    required property Item anchorItem

    objectName: "popupWindow"
    flags: Qt.WindowStaysOnTopHint

    location: Plasmoid.configuration.floating || Plasmoid.configuration.launcherPosition === 2 ? PlasmaCore.Types.Floating : Plasmoid.location
    hideOnWindowDeactivate: true
    visible: root.launcher.menuOpen

    onVisibleChanged: {
        // The window also hides itself when it loses focus
        root.launcher.menuOpen = root.visible;
        if (!root.visible) {
            mainView.reset();
        } else {
            root.updatePosition();
            root.requestActivate();
        }
    }

    onHeightChanged: root.updatePosition()
    onWidthChanged: root.updatePosition()

    function updatePosition(): void {
        const pos = root.popupPosition(root.width, root.height);
        root.x = pos.x;
        root.y = pos.y;
    }

    function popupPosition(width: real, height: real): point {
        const screen = root.launcher.plasmoidItem.screenGeometry;
        const anchor = root.anchorItem;
        const panelMargins = root.launcher.panelSvg.margins;

        let offset = 0;

        if (Plasmoid.configuration.offsetX > 0 && Plasmoid.configuration.floating) {
            offset = Plasmoid.configuration.offsetX;
        } else {
            offset = Plasmoid.configuration.floating ? anchor.height * 0.35 : 0;
        }

        let x = offset;
        let y = screen.height - height - offset;
        const horizMidPoint = screen.x + (screen.width / 2);
        const vertMidPoint = screen.y + (screen.height / 2);
        const appletTopLeft = anchor.mapToGlobal(0, 0);

        // Vertical panels: open beside the panel instead of over it
        if (Plasmoid.configuration.launcherPosition !== 2
            && (Plasmoid.location === PlasmaCore.Types.LeftEdge || Plasmoid.location === PlasmaCore.Types.RightEdge)) {
            if (Plasmoid.location === PlasmaCore.Types.LeftEdge) {
                x = appletTopLeft.x + anchor.width + panelMargins.right + offset;
            } else {
                x = appletTopLeft.x - width - panelMargins.left - offset;
            }
            if (Plasmoid.configuration.launcherPosition === 1) {
                y = vertMidPoint - height / 2;
            } else {
                y = Math.max(screen.y, Math.min(appletTopLeft.y, screen.y + screen.height - height));
            }
            return Qt.point(x, y);
        }

        if (Plasmoid.configuration.launcherPosition !== 0) {
            x = horizMidPoint - width / 2;
        } else {
            x = (appletTopLeft.x < horizMidPoint) ? screen.x : (screen.x + screen.width) - width;
            if (Plasmoid.configuration.floating) {
                if (appletTopLeft.x < horizMidPoint) {
                    x += offset;
                } else {
                    x -= offset;
                }
            }
        }

        if (Plasmoid.configuration.launcherPosition !== 2) {
            if (Plasmoid.location === PlasmaCore.Types.TopEdge) {
                if (Plasmoid.configuration.floating) {
                    // Leave room for the floating avatar (125 px wide) above the menu
                    if (Plasmoid.configuration.offsetY > 0) {
                        offset = 125 / 2 + Plasmoid.configuration.offsetY;
                    } else {
                        offset = 125 / 2 + anchor.height * 0.125;
                    }
                }
                y = screen.y + anchor.height + panelMargins.bottom + offset;
            } else {
                // Gap above the panel when floating: offsetY in pixels (as on top panels),
                // otherwise a default proportional to the panel height
                let panelGap = 0;
                if (Plasmoid.configuration.floating) {
                    panelGap = Plasmoid.configuration.offsetY > 0 ? Plasmoid.configuration.offsetY : anchor.height * 0.875;
                }
                y = screen.y + screen.height - anchor.height - height - panelMargins.top - panelGap;
            }
        } else {
            y = vertMidPoint - height / 2;
        }

        return Qt.point(x, y);
    }

    FocusScope {
        id: content

        // A uniform margin around MainView across Plasma themes
        readonly property real innerPadding: 15

        focus: true
        // Sized up front (not only via Layout) so the dialog never sees empty content when first shown
        width: content.Layout.minimumWidth
        height: content.Layout.minimumHeight

        Layout.minimumWidth: root.launcher.cellSizeWidth * Plasmoid.configuration.numberColumns
                             + root.launcher.scrollBarWidth
                             + content.innerPadding * 2
        Layout.minimumHeight: mainView.contentHeight + content.innerPadding / 2
        Layout.maximumWidth: content.Layout.minimumWidth
        Layout.maximumHeight: content.Layout.minimumHeight

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.launcher.close();
            }
        }

        Connections {
            target: root.launcher

            function onReset(): void {
                mainView.reset();
            }
        }

        // Extends over the dialog's frame margins, so the padding above is all MainView gets
        Item {
            x: -root.launcher.dialogSvg.margins.left
            y: -root.launcher.dialogSvg.margins.top
            width: content.width + root.launcher.dialogSvg.margins.left + root.launcher.dialogSvg.margins.right
            height: content.height + root.launcher.dialogSvg.margins.top + root.launcher.dialogSvg.margins.bottom

            MainView {
                id: mainView

                anchors.fill: parent
                anchors.margins: content.innerPadding

                launcher: root.launcher
                dialog: root
            }
        }
    }
}
