#include "CpuStats.hpp"

#include "Sysfs.hpp"

#include <QStringList>

namespace {
constexpr auto CPU_ROOT = "/sys/devices/system/cpu";
const QStringList CPU_HWMON_NAMES = {QStringLiteral("coretemp"), QStringLiteral("k10temp"), QStringLiteral("zenpower")};
const QStringList CPU_TEMP_LABELS = {QStringLiteral("Package id 0"), QStringLiteral("Tctl"), QStringLiteral("Tdie")};
}

CpuStats::CpuStats(QObject* parent): QObject(parent) { this->readStatics(); }

void CpuStats::readStatics() {
    const auto cpuinfo = Sysfs::readText(QStringLiteral("/proc/cpuinfo"));
    if (cpuinfo) {
        for (const auto& line: cpuinfo->split('\n')) {
            if (this->bModel.isEmpty() && line.startsWith(QStringLiteral("model name"))) {
                this->bModel = line.section(':', 1).trimmed();
            }
            if (line.startsWith(QStringLiteral("processor"))) this->bThreads++;
        }
    }

    for (const auto& path: {QStringLiteral("/cpu0/cpufreq/cpuinfo_max_freq"), QStringLiteral("/cpu0/cpufreq/scaling_max_freq")}) {
        if (const auto khz = Sysfs::readDouble(QString::fromLatin1(CPU_ROOT) + path)) {
            this->bMaxFrequency = *khz / 1000000.0;
            break;
        }
    }

    this->temperatureHwmon = Sysfs::hwmonWithName(QStringLiteral("/sys/class/hwmon"), CPU_HWMON_NAMES);
    this->temperatureLabels = CPU_TEMP_LABELS;

    emit this->staticsChanged();
}

void CpuStats::refresh(int historyLength) {
    this->readUsage();
    this->readFrequency();
    this->readTemperature();

    this->bUsageHistory.append(this->bUsage);
    while (this->bUsageHistory.length() > historyLength) this->bUsageHistory.removeFirst();

    emit this->updated();
}

void CpuStats::readUsage() {
    const auto stat = Sysfs::readText(QStringLiteral("/proc/stat"));
    if (!stat) return;

    const auto fields = stat->section('\n', 0, 0).split(' ', Qt::SkipEmptyParts);
    if (fields.length() < 5) return;

    qint64 total = 0;
    for (qsizetype i = 1; i < fields.length(); i++) total += fields.at(i).toLongLong();
    const auto idle = fields.at(4).toLongLong() + (fields.length() > 5 ? fields.at(5).toLongLong() : 0);

    const auto totalDelta = total - this->lastTotal;
    const auto idleDelta = idle - this->lastIdle;
    this->lastTotal = total;
    this->lastIdle = idle;

    if (totalDelta > 0) this->bUsage = qBound(0.0, 1.0 - static_cast<double>(idleDelta) / static_cast<double>(totalDelta), 1.0);
}

void CpuStats::readFrequency() {
    double sum = 0;
    int count = 0;
    for (const auto& cpu: Sysfs::entries(QString::fromLatin1(CPU_ROOT), QStringLiteral("cpu[0-9]*"))) {
        if (const auto khz = Sysfs::readDouble(cpu + QStringLiteral("/cpufreq/scaling_cur_freq"))) {
            sum += *khz / 1000000.0;
            count++;
        }
    }

    if (count > 0) {
        this->bFrequency = sum / count;
        return;
    }

    const auto cpuinfo = Sysfs::readText(QStringLiteral("/proc/cpuinfo"));
    if (!cpuinfo) return;
    for (const auto& line: cpuinfo->split('\n')) {
        if (!line.startsWith(QStringLiteral("cpu MHz"))) continue;
        sum += line.section(':', 1).trimmed().toDouble() / 1000.0;
        count++;
    }
    if (count > 0) this->bFrequency = sum / count;
}

void CpuStats::readTemperature() {
    if (this->temperatureHwmon.isEmpty()) {
        this->bHasTemperature = false;
        return;
    }

    auto reading = Sysfs::labelledTemp(this->temperatureHwmon, this->temperatureLabels);
    if (!reading) reading = Sysfs::firstTemp(this->temperatureHwmon);

    this->bHasTemperature = reading.has_value();
    if (reading) this->bTemperature = *reading;
}
