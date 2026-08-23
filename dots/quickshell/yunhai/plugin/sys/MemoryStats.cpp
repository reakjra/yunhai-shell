#include "MemoryStats.hpp"

#include "Sysfs.hpp"

#include <QHash>

void MemoryStats::refresh(int historyLength) {
    const auto meminfo = Sysfs::readText(QStringLiteral("/proc/meminfo"));
    if (!meminfo) return;

    QHash<QString, double> values;
    for (const auto& line: meminfo->split('\n')) {
        const auto key = line.section(':', 0, 0).trimmed();
        if (key.isEmpty()) continue;
        values.insert(key, line.section(':', 1).trimmed().section(' ', 0, 0).toDouble() * 1024.0);
    }

    this->bTotal = values.value(QStringLiteral("MemTotal"));
    this->bFree = values.value(QStringLiteral("MemAvailable"), values.value(QStringLiteral("MemFree")));
    this->bUsed = this->bTotal - this->bFree;

    this->bSwapTotal = values.value(QStringLiteral("SwapTotal"));
    this->bSwapFree = values.value(QStringLiteral("SwapFree"));
    this->bSwapUsed = this->bSwapTotal - this->bSwapFree;

    this->bUsageHistory.append(this->usage());
    this->bSwapUsageHistory.append(this->swapUsage());
    while (this->bUsageHistory.length() > historyLength) this->bUsageHistory.removeFirst();
    while (this->bSwapUsageHistory.length() > historyLength) this->bSwapUsageHistory.removeFirst();

    emit this->updated();
}
