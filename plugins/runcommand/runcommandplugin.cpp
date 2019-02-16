/**
 * Copyright 2013 Albert Vaca <albertvaka@gmail.com>
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

#include "runcommandplugin.h"

#include <KPluginFactory>

#include <QDBusConnection>
#include <QProcess>
#include <QDir>
#include <QLoggingCategory>
#include <QSettings>
#include <QJsonDocument>
#include <KShell>
#include <kcmutils_version.h>

#include <core/networkpacket.h>
#include <core/device.h>

#define PACKET_TYPE_RUNCOMMAND QStringLiteral("kdeconnect.runcommand")

#ifdef Q_OS_WIN
#define COMMAND "cmd"
#define ARGS "/c"

#else
#define COMMAND "/bin/sh"
#define ARGS "-c"

#endif

K_PLUGIN_FACTORY_WITH_JSON( KdeConnectPluginFactory, "kdeconnect_runcommand.json", registerPlugin< RunCommandPlugin >(); )

Q_LOGGING_CATEGORY(KDECONNECT_PLUGIN_RUNCOMMAND, "kdeconnect.plugin.runcommand")

RunCommandPlugin::RunCommandPlugin(QObject* parent, const QVariantList& args)
    : KdeConnectPlugin(parent, args)
{
    connect(config(), &KdeConnectPluginConfig::configChanged, this, &RunCommandPlugin::configChanged);
}

RunCommandPlugin::~RunCommandPlugin()
{
}

bool RunCommandPlugin::receivePacket(const NetworkPacket& np)
{
    if (np.get<bool>(QStringLiteral("requestCommandList"), false)) {
        sendConfig();
        return true;
    }

    if (np.has(QStringLiteral("key"))) {
        QJsonDocument commandsDocument = QJsonDocument::fromJson(config()->getByteArray(QStringLiteral("commands"), "{}"));
        QJsonObject commands = commandsDocument.object();
        QString key = np.get<QString>(QStringLiteral("key"));
        QJsonValue value = commands[key];
        if (value == QJsonValue::Undefined) {
            qCWarning(KDECONNECT_PLUGIN_RUNCOMMAND) << key << "is not a configured command";
        }
        const QJsonObject commandJson = value.toObject();
        qCInfo(KDECONNECT_PLUGIN_RUNCOMMAND) << "Running:" << COMMAND << ARGS << commandJson[QStringLiteral("command")].toString();
        QProcess::startDetached(QStringLiteral(COMMAND), QStringList()<< QStringLiteral(ARGS) << commandJson[QStringLiteral("command")].toString());
        return true;
    } else if (np.has("setup")) {
        QProcess::startDetached(QStringLiteral("kcmshell5"), {QStringLiteral("kdeconnect"), QStringLiteral("--args"), QString(device()->id() + QStringLiteral(":kdeconnect_runcommand")) });
    }

    return false;
}

void RunCommandPlugin::connected()
{

    sendConfig();
}

void RunCommandPlugin::sendConfig()
{
    QString commands = config()->getString(QStringLiteral("commands"),QStringLiteral("{}"));
    NetworkPacket np(PACKET_TYPE_RUNCOMMAND, {{"commandList", commands}});

    #if KCMUTILS_VERSION >= QT_VERSION_CHECK(5, 45, 0)
        np.set<bool>(QStringLiteral("canAddCommand"), true);
    #endif

    sendPacket(np);
}

void RunCommandPlugin::configChanged() {
    sendConfig();
}

#include "runcommandplugin.moc"
