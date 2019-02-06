/*
 * Copyright 2019 Nicolas Fella <nicolas.fella@gmx.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License or (at your option) version 3 or any later version
 * accepted by the membership of KDE e.V. (or its successor approved
 * by the membership of KDE e.V.), which shall act as a proxy
 * defined in Section 14 of version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.2
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.0 as Kirigami
import org.kde.kdeconnect 1.0

Kirigami.ScrollablePage
{
    id: root
    title: i18n("Plugin settings")
    property string device

    ListView {
        id: sinkList

        Component {
            id: pluginInfo
            PluginInfoPage {}
        }

        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        model: PluginModel {
            deviceId: device
        }

        delegate: Kirigami.SwipeListItem {
            width: parent.width
            enabled: true
            supportsMouseEvents: false

            CheckBox {
                checked: isChecked
                text: name
                onClicked: {
                    isChecked = checked
                }
            }

            actions: [
                Kirigami.Action {
                    icon.name: "settings-configure"
                    visible: configSource != ""
                    onTriggered: {
                        pageStack.push(pluginInfo, {
                            title: name,
                            configFile: configSource,
                            device: root.device
                        })
                    }
                }
            ]
        }
    }

}


