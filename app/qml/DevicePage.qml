/*
 * Copyright 2015 Aleix Pol Gonzalez <aleixpol@kde.org>
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
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.0
import org.kde.kirigami 2.0 as Kirigami
import org.kde.kdeconnect 1.0

Kirigami.Page
{
    id: deviceView
    property QtObject currentDevice
    title: currentDevice.name

    actions.contextualActions: deviceLoader.item.actions
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    Loader {
        id: deviceLoader
        anchors.fill: parent
        Layout.fillHeight: true
        Layout.fillWidth: true

        sourceComponent: {
            if (deviceView.currentDevice.hasPairingRequests) {
                return pairDevice;
            }

            if (deviceView.currentDevice.isReachable) {
                if (deviceView.currentDevice.isTrusted) {
                    return trustedDevice;
                } else {
                    return untrustedDevice;
                }
            } else {
                return notReachableDevice;
            }
        }

        Component {
            id: trustedDevice
            ColumnLayout {
                property list<QtObject> actions: [
                    Kirigami.Action {
                        onTriggered: deviceView.currentDevice.unpair()
                        text: i18n("Unpair")
                    },
                    Kirigami.Action {
                        text: i18n("Send Ping")
                        onTriggered: {
                            deviceView.currentDevice.pluginCall("ping", "sendPing");
                        }
                    },
                    Kirigami.Action {
                        text: i18n("Plugin settings")
                        onTriggered: {
                            pageStack.push(
                                deviceComp,
                                {device: currentDevice.id()}
                            );
                        }
                    }
                ]

                id: trustedView
                spacing: 0
                Layout.fillHeight: true
                Layout.fillWidth: true

                PluginItem {
                    label: i18n("Multimedia control")
                    interfaceFactory: MprisDbusInterfaceFactory
                    component: "qrc:/qml/mpris.qml"
                    pluginName: "mprisremote"
                }
                PluginItem {
                    label: i18n("Remote input")
                    interfaceFactory: RemoteControlDbusInterfaceFactory
                    component: "qrc:/qml/mousepad.qml"
                    pluginName: "remotecontrol"
                }
                PluginItem {
                    label: i18n("Presentation Remote")
                    interfaceFactory: RemoteKeyboardDbusInterfaceFactory
                    component: "qrc:/qml/presentationRemote.qml"
                    pluginName: "remotecontrol"
                }
                PluginItem {
                    readonly property var lockIface: LockDeviceDbusInterfaceFactory.create(deviceView.currentDevice.id())
                    pluginName: "lockdevice"
                    label: lockIface.isLocked ? i18n("Unlock") : i18n("Lock")
                    onClicked: {
                        lockIface.isLocked = !lockIface.isLocked;
                    }
                }
                PluginItem {
                    readonly property var findmyphoneIface: FindMyPhoneDbusInterfaceFactory.create(deviceView.currentDevice.id())
                    pluginName: "findmyphone"
                    label: i18n("Find Device")
                    onClicked: {
                        findmyphoneIface.ring()
                    }
                }
                PluginItem {
                    label: i18n("Run command")
                    interfaceFactory: RemoteCommandsDbusInterfaceFactory
                    component: "qrc:/qml/runcommand.qml"
                    pluginName: "remotecommands"
                }
                PluginItem {
                    readonly property var shareIface: ShareDbusInterfaceFactory.create(deviceView.currentDevice.id())
                    pluginName: "share"
                    label: i18n("Share File")
                    onClicked: {
                        fileDialog.open()
                        shareIface.shareUrl(fileDialog.fileUrl)
                    }
                }
                PluginItem {
                    label: i18n("Volume control")
                    interfaceFactory: RemoteSystemVolumeDbusInterfaceFactory
                    component: "qrc:/qml/volume.qml"
                    pluginName: "remotesystemvolume"
                }

                Item { Layout.fillHeight: true }
            }
        }
        Component {
            id: untrustedDevice
            Item {
                readonly property var actions: []
                Button {
                    anchors.centerIn: parent

                    text: i18n("Pair")
                    onClicked: deviceView.currentDevice.requestPair()
                }
            }
        }
        Component {
            id: pairDevice
            Item {
                readonly property var actions: []
                RowLayout {
                        anchors.centerIn: parent
                    Button {
                        text: i18n("Accept")
                        onClicked: deviceView.currentDevice.acceptPairing()
                    }

                    Button {
                        text: i18n("Reject")
                        onClicked: deviceView.currentDevice.rejectPairing()
                    }
                }
            }
        }

        Component {
            id: notReachableDevice
            Item {
                property var actions: []

                Label {
                    anchors.centerIn: parent
                    text: i18n("This device is not reachable")
                }
            }
        }
    }

    Component {
        id: deviceComp
        PluginSettings {}
    }

    FileDialog {
        id: fileDialog
        title: i18n("Please choose a file")
        folder: shortcuts.home
    }
}
