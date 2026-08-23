#include "Sysfs.hpp"

#include <QDir>
#include <QFile>

namespace Sysfs {

std::optional<QString> readText(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return std::nullopt;
    return QString::fromUtf8(file.readAll()).trimmed();
}

std::optional<qint64> readInt(const QString& path) {
    const auto text = readText(path);
    if (!text) return std::nullopt;
    bool ok = false;
    const auto value = text->toLongLong(&ok);
    if (!ok) return std::nullopt;
    return value;
}

std::optional<double> readDouble(const QString& path) {
    const auto text = readText(path);
    if (!text) return std::nullopt;
    bool ok = false;
    const auto value = text->toDouble(&ok);
    if (!ok) return std::nullopt;
    return value;
}

QStringList entries(const QString& dir, const QString& glob) {
    QDir directory(dir);
    QStringList out;
    for (const auto& name: directory.entryList({glob}, QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot, QDir::Name)) {
        out.append(directory.filePath(name));
    }
    return out;
}

QString hwmonWithName(const QString& dir, const QStringList& names) {
    for (const auto& hwmon: entries(dir, QStringLiteral("hwmon*"))) {
        const auto name = readText(hwmon + QStringLiteral("/name"));
        if (name && names.contains(*name, Qt::CaseInsensitive)) return hwmon;
    }
    return {};
}

std::optional<double> labelledTemp(const QString& hwmon, const QStringList& labels) {
    for (const auto& labelPath: entries(hwmon, QStringLiteral("temp*_label"))) {
        const auto label = readText(labelPath);
        if (!label || !labels.contains(*label, Qt::CaseInsensitive)) continue;
        auto inputPath = labelPath;
        inputPath.replace(QStringLiteral("_label"), QStringLiteral("_input"));
        if (const auto millidegrees = readDouble(inputPath)) return *millidegrees / 1000.0;
    }
    return std::nullopt;
}

std::optional<double> firstTemp(const QString& hwmon) {
    for (const auto& inputPath: entries(hwmon, QStringLiteral("temp*_input"))) {
        if (const auto millidegrees = readDouble(inputPath)) return *millidegrees / 1000.0;
    }
    return std::nullopt;
}

}

namespace {

constexpr auto PCI_IDS = "/usr/share/hwdata/pci.ids";
constexpr auto AMDGPU_IDS = "/usr/share/libdrm/amdgpu.ids";

struct Names {
    QString device;
    QString subsystem;
};

Names lookup(const QString& devicePath) {
    const auto vendorId = PciIds::field(devicePath, QStringLiteral("vendor"));
    const auto deviceId = PciIds::field(devicePath, QStringLiteral("device"));
    const auto subPrefix = PciIds::field(devicePath, QStringLiteral("subsystem_vendor")) + ' '
        + PciIds::field(devicePath, QStringLiteral("subsystem_device"));

    const auto ids = Sysfs::readText(QString::fromLatin1(PCI_IDS));
    if (!ids || vendorId.isEmpty() || deviceId.isEmpty()) return {};

    Names out;
    auto inVendor = false;
    auto inDevice = false;

    for (const auto& line: ids->split('\n')) {
        if (line.isEmpty() || line.startsWith('#')) continue;

        if (!line.startsWith('\t')) {
            if (inVendor) break;
            inVendor = line.startsWith(vendorId);
            continue;
        }
        if (!inVendor) continue;

        if (!line.startsWith(QStringLiteral("\t\t"))) {
            if (inDevice) break;
            const auto entry = QStringView(line).mid(1);
            if (!entry.startsWith(deviceId)) continue;
            out.device = entry.mid(deviceId.length()).trimmed().toString();
            inDevice = true;
            continue;
        }

        if (!inDevice) continue;
        const auto entry = QStringView(line).mid(2);
        if (entry.startsWith(subPrefix)) {
            out.subsystem = entry.mid(subPrefix.length()).trimmed().toString();
            break;
        }
    }

    return out;
}

QString bracketed(const QString& raw) {
    const auto open = raw.indexOf('[');
    const auto close = raw.lastIndexOf(']');
    return open >= 0 && close > open ? raw.mid(open + 1, close - open - 1).trimmed() : raw;
}

}

namespace PciIds {

QString field(const QString& devicePath, const QString& file) {
    const auto raw = Sysfs::readText(devicePath + '/' + file);
    if (!raw) return {};
    return raw->startsWith(QStringLiteral("0x")) ? raw->mid(2).toLower() : raw->toLower();
}

QString deviceName(const QString& devicePath, const QString& fallback) {
    const auto names = lookup(devicePath);
    if (!names.subsystem.isEmpty()) return bracketed(names.subsystem);
    if (!names.device.isEmpty()) return bracketed(names.device);
    return fallback;
}

QString amdMarketingName(const QString& devicePath) {
    const auto deviceId = field(devicePath, QStringLiteral("device"));
    const auto revision = field(devicePath, QStringLiteral("revision"));
    const auto ids = Sysfs::readText(QString::fromLatin1(AMDGPU_IDS));
    if (!ids || deviceId.isEmpty() || revision.isEmpty()) return {};

    for (const auto& line: ids->split('\n')) {
        const auto fields = line.split(',');
        if (fields.length() < 3) continue;
        if (fields.at(0).trimmed().compare(deviceId, Qt::CaseInsensitive) != 0) continue;
        if (fields.at(1).trimmed().compare(revision, Qt::CaseInsensitive) != 0) continue;
        return fields.at(2).trimmed();
    }

    return {};
}

}
