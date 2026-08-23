#pragma once

#include <QString>
#include <QStringList>
#include <optional>

namespace Sysfs {

std::optional<QString> readText(const QString& path);
std::optional<qint64> readInt(const QString& path);
std::optional<double> readDouble(const QString& path);

QStringList entries(const QString& dir, const QString& glob);

QString hwmonWithName(const QString& dir, const QStringList& names);
std::optional<double> labelledTemp(const QString& hwmon, const QStringList& labels);
std::optional<double> firstTemp(const QString& hwmon);

}

namespace PciIds {

QString field(const QString& devicePath, const QString& file);
QString deviceName(const QString& devicePath, const QString& fallback);
QString amdMarketingName(const QString& devicePath);

}
