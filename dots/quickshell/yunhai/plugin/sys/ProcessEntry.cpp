#include "ProcessEntry.hpp"

namespace {

QString formatMemory(double kb) {
    if (kb < 1024) return QStringLiteral("%1KB").arg(kb, 0, 'f', 0);

    if (kb < 1024 * 1024) {
        const auto mb = kb / 1024;
        return QStringLiteral("%1MB").arg(mb, 0, 'f', mb >= 100 ? 0 : 1);
    }

    const auto gb = kb / (1024 * 1024);
    return QStringLiteral("%1GB").arg(gb, 0, 'f', gb >= 10 ? 1 : 2);
}

}

void ProcessEntry::update(const QString& name, const QString& fullCommand, const QString& user, double cpuPercent, double memPercent, double memoryKb) {
    const auto changed = this->bName != name || this->bFullCommand != fullCommand || this->bUser != user
        || !qFuzzyCompare(this->bCpuPercent, cpuPercent) || !qFuzzyCompare(this->bMemPercent, memPercent)
        || !qFuzzyCompare(this->bMemoryKb, memoryKb);

    this->bName = name;
    this->bFullCommand = fullCommand;
    this->bUser = user;
    this->bCpuPercent = cpuPercent;
    this->bMemPercent = memPercent;
    this->bMemoryKb = memoryKb;
    this->bMemoryFormatted = formatMemory(memoryKb);

    if (changed) emit this->updated();
}
