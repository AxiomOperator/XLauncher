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
import org.kde.plasma.plasmoid

LauncherPage {
    id: allApps

    // The All Apps pages: one per menu category, starting with "All Applications"
    // (rootModel rows 0-1 are the recents models)
    readonly property var appsCategoriesList: {
        const model = allApps.launcher.rootModel;
        const categories = [];
        for (let i = 2; i < model.count; i++) {
            const modelIndex = model.index(i, 0);
            categories.push({
                name: model.data(modelIndex, Qt.DisplayRole),
                index: i,
                icon: model.data(modelIndex, Qt.DecorationRole)
            });
        }
        return categories;
    }

    property int currentStateIndex: allApps.defaultStateIndex()

    // The model shown by the current view
    property var shownModel: allApps.launcher.rootModel.modelForRow(2)

    readonly property bool showItemsInGrid: Plasmoid.configuration.showItemsInGrid

    // The configured page may not exist on this system (category lists differ between installs)
    function defaultStateIndex(): int {
        const page = Plasmoid.configuration.defaultPage;
        return (page >= 0 && page < allApps.appsCategoriesList.length) ? page : 0;
    }

    function updateShowedModel(index: int): void {
        allApps.shownModel = allApps.launcher.rootModel.modelForRow(index);
    }

    function incrementCurrentStateIndex(): void {
        allApps.currentStateIndex += 1;
        if (allApps.currentStateIndex > allApps.appsCategoriesList.length - 1) {
            allApps.currentStateIndex = 0;
        }
    }

    function decrementCurrentStateIndex(): void {
        allApps.currentStateIndex -= 1;
        if (allApps.currentStateIndex < 0) {
            allApps.currentStateIndex = allApps.appsCategoriesList.length - 1;
        }
    }

    function resetCurrentStateIndex(): void {
        allApps.currentStateIndex = allApps.defaultStateIndex();
    }

    function getCurrentCategory(): var {
        if (allApps.currentStateIndex < 0 || allApps.currentStateIndex >= allApps.appsCategoriesList.length) {
            allApps.currentStateIndex = allApps.defaultStateIndex();
        }
        return allApps.appsCategoriesList[allApps.currentStateIndex];
    }

    viewItem: appViewLoader.item as Item

    Connections {
        target: allApps.launcher

        function onMenuOpenChanged(): void {
            allApps.resetCurrentStateIndex();
        }
    }

    Loader {
        id: appViewLoader

        anchors.fill: parent
        sourceComponent: allApps.showItemsInGrid ? applicationsGridViewComponent : applicationsListViewComponent
    }

    Component {
        id: applicationsListViewComponent

        AppListView {
            launcher: allApps.launcher
            showSectionSeparator: false
            model: allApps.shownModel
        }
    }

    Component {
        id: applicationsGridViewComponent

        AppGridView {
            launcher: allApps.launcher
            model: allApps.shownModel
        }
    }
}
