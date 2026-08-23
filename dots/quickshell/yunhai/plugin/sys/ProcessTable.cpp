#include "ProcessTable.hpp"

#include "Sysfs.hpp"

#include <QDir>
#include <QFileInfo>
#include <QStringList>
#include <pwd.h>
#include <signal.h>
#include <unistd.h>

namespace {

const QStringList INTERPRETERS = {
    QStringLiteral("python"),  QStringLiteral("python2"), QStringLiteral("python3"), QStringLiteral("node"),
    QStringLiteral("bash"),    QStringLiteral("sh"),      QStringLiteral("perl"),    QStringLiteral("ruby"),
    QStringLiteral("java"),    QStringLiteral("exe"),     QStringLiteral("php"),     QStringLiteral("lua"),
    QStringLiteral("luajit"),  QStringLiteral("dotnet"),  QStringLiteral("mono"),    QStringLiteral("swift"),
    QStringLiteral("nim"),     QStringLiteral("wine"),
};

QString commandLine(const QString& procDir, const QString& comm) {
    QFile file(procDir + QStringLiteral("/cmdline"));
    if (!file.open(QIODevice::ReadOnly)) return QStringLiteral("[%1]").arg(comm);

    auto raw = file.readAll();
    if (raw.isEmpty()) return QStringLiteral("[%1]").arg(comm);

    raw.replace('\0', ' ');
    return QString::fromUtf8(raw).trimmed();
}

QString displayName(const QString& command) {
    if (command.startsWith('[') && command.endsWith(']')) return command;

    const auto parts = command.split(' ', Qt::SkipEmptyParts);
    if (parts.isEmpty()) return command;

    const auto baseName = parts.first().section('/', -1);
    if (!INTERPRETERS.contains(baseName) || parts.length() < 2) return baseName;

    qsizetype index = 1;
    while (index < parts.length() && parts.at(index).startsWith('-')) index++;
    if (index >= parts.length()) return baseName;

    return baseName + QStringLiteral(": ") + parts.at(index).section('/', -1);
}

}

ProcessTable::ProcessTable(QObject* parent): QObject(parent) {
    this->ticksPerSecond = sysconf(_SC_CLK_TCK);
    if (this->ticksPerSecond <= 0) this->ticksPerSecond = 100;
    this->pageSizeKb = sysconf(_SC_PAGESIZE) / 1024;

    const auto meminfo = Sysfs::readText(QStringLiteral("/proc/meminfo"));
    if (meminfo) {
        for (const auto& line: meminfo->split('\n')) {
            if (!line.startsWith(QStringLiteral("MemTotal"))) continue;
            this->memoryTotalKb = line.section(':', 1).trimmed().section(' ', 0, 0).toDouble();
            break;
        }
    }

    this->timer.setInterval(2000);
    QObject::connect(&this->timer, &QTimer::timeout, this, &ProcessTable::refresh);
}

void ProcessTable::setActive(bool active) {
    if (active == this->timer.isActive()) return;
    if (active) {
        this->refresh();
        this->timer.start();
    } else {
        this->timer.stop();
    }
    emit this->activeChanged();
}

void ProcessTable::setInterval(int interval) {
    if (interval == this->timer.interval()) return;
    this->timer.setInterval(interval);
    emit this->intervalChanged();
}

quint64 ProcessTable::totalCpuTicks() const {
    const auto stat = Sysfs::readText(QStringLiteral("/proc/stat"));
    if (!stat) return 0;

    const auto fields = stat->section('\n', 0, 0).split(' ', Qt::SkipEmptyParts);
    quint64 total = 0;
    for (qsizetype i = 1; i < fields.length(); i++) total += fields.at(i).toULongLong();
    return total;
}

QString ProcessTable::userName(uint uid) {
    if (const auto cached = this->userNames.constFind(uid); cached != this->userNames.constEnd()) return *cached;

    const auto* entry = getpwuid(uid);
    const auto name = entry ? QString::fromLocal8Bit(entry->pw_name) : QString::number(uid);
    this->userNames.insert(uid, name);
    return name;
}

void ProcessTable::refresh() {
    const auto totalTicks = this->totalCpuTicks();
    const auto totalDelta = totalTicks > this->lastTotalTicks ? totalTicks - this->lastTotalTicks : 0;

    for (auto* entry: std::as_const(this->entries)) entry->setSeen(false);

    QDir proc(QStringLiteral("/proc"));
    for (const auto& dirName: proc.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::NoSort)) {
        bool isPid = false;
        const auto pid = dirName.toInt(&isPid);
        if (!isPid) continue;

        const auto procDir = QStringLiteral("/proc/") + dirName;
        const auto stat = Sysfs::readText(procDir + QStringLiteral("/stat"));
        if (!stat) continue;

        const auto commEnd = stat->lastIndexOf(')');
        const auto commStart = stat->indexOf('(');
        if (commStart < 0 || commEnd < commStart) continue;

        const auto comm = stat->mid(commStart + 1, commEnd - commStart - 1);
        const auto fields = QStringView(*stat).mid(commEnd + 2).split(u' ', Qt::SkipEmptyParts);
        if (fields.length() < 22) continue;

        const auto ticks = fields.at(11).toULongLong() + fields.at(12).toULongLong();
        const auto rssKb = static_cast<double>(fields.at(21).toLongLong()) * this->pageSizeKb;

        auto* entry = this->entries.value(pid);
        if (!entry) {
            entry = new ProcessEntry(pid, this);
            entry->setCpuTicks(ticks);
            this->entries.insert(pid, entry);
        }

        const auto ticksDelta = ticks > entry->cpuTicks() ? ticks - entry->cpuTicks() : 0;
        const auto cpuPercent = totalDelta > 0 ? static_cast<double>(ticksDelta) / static_cast<double>(totalDelta) * 100.0 : 0.0;
        entry->setCpuTicks(ticks);
        entry->setSeen(true);

        const auto command = commandLine(procDir, comm);
        entry->update(
            displayName(command),
            command,
            this->userName(QFileInfo(procDir).ownerId()),
            qBound(0.0, cpuPercent, 100.0),
            this->memoryTotalKb > 0 ? rssKb / this->memoryTotalKb * 100.0 : 0.0,
            rssKb
        );
    }

    this->lastTotalTicks = totalTicks;

    this->allProcesses.clear();
    this->allProcesses.reserve(this->entries.size());
    for (auto it = this->entries.begin(); it != this->entries.end();) {
        if ((*it)->seen()) {
            this->allProcesses.append(*it);
            ++it;
        } else {
            (*it)->deleteLater();
            it = this->entries.erase(it);
        }
    }

    this->rebuildView();
}

void ProcessTable::rebuildView() {
    QList<ProcessEntry*> view;
    view.reserve(this->allProcesses.length());

    for (auto* entry: std::as_const(this->allProcesses)) {
        if (!this->bFilter.isEmpty()
            && !entry->name().contains(this->bFilter, Qt::CaseInsensitive)
            && !entry->fullCommand().contains(this->bFilter, Qt::CaseInsensitive)
            && !entry->pid().contains(this->bFilter)) {
            continue;
        }
        view.append(entry);
    }

    const auto key = this->bSortKey;
    const auto descending = this->bSortDescending;
    const auto less = [key](const ProcessEntry* a, const ProcessEntry* b) {
        switch (key) {
            case ProcessTable::Name: return a->name().compare(b->name(), Qt::CaseInsensitive) < 0;
            case ProcessTable::Memory: return a->memoryKb() < b->memoryKb();
            default: return a->cpuPercent() < b->cpuPercent();
        }
    };

    std::sort(view.begin(), view.end(), [&less, descending](const ProcessEntry* a, const ProcessEntry* b) {
        return descending ? less(b, a) : less(a, b);
    });

    this->bProcesses = view;
    emit this->processesChanged();
}

void ProcessTable::setFilter(const QString& filter) {
    if (filter == this->bFilter) return;
    this->bFilter = filter;
    emit this->filterChanged();
    this->rebuildView();
}

void ProcessTable::setSortKey(SortKey key) {
    if (key == this->bSortKey) return;
    this->bSortKey = key;
    emit this->sortChanged();
    this->rebuildView();
}

void ProcessTable::setSortDescending(bool descending) {
    if (descending == this->bSortDescending) return;
    this->bSortDescending = descending;
    emit this->sortChanged();
    this->rebuildView();
}

void ProcessTable::kill(int pid) {
    if (pid > 0) ::kill(pid, SIGTERM);
    this->refresh();
}

void ProcessTable::forceKill(int pid) {
    if (pid > 0) ::kill(pid, SIGKILL);
    this->refresh();
}
