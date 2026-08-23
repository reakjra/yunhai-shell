#pragma once

#include "ProcessEntry.hpp"

#include <QHash>
#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class ProcessTable: public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum SortKey { Cpu, Memory, Name };
    Q_ENUM(SortKey)

private:
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(int interval READ interval WRITE setInterval NOTIFY intervalChanged)
    Q_PROPERTY(QList<ProcessEntry*> processes READ processes NOTIFY processesChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY processesChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(SortKey sortKey READ sortKey WRITE setSortKey NOTIFY sortChanged)
    Q_PROPERTY(bool sortDescending READ sortDescending WRITE setSortDescending NOTIFY sortChanged)

public:
    explicit ProcessTable(QObject* parent = nullptr);

    [[nodiscard]] bool active() const { return this->timer.isActive(); }
    void setActive(bool active);

    [[nodiscard]] int interval() const { return this->timer.interval(); }
    void setInterval(int interval);

    [[nodiscard]] QList<ProcessEntry*> processes() const { return this->bProcesses; }
    [[nodiscard]] int totalCount() const { return static_cast<int>(this->allProcesses.length()); }

    [[nodiscard]] QString filter() const { return this->bFilter; }
    void setFilter(const QString& filter);

    [[nodiscard]] SortKey sortKey() const { return this->bSortKey; }
    void setSortKey(SortKey key);

    [[nodiscard]] bool sortDescending() const { return this->bSortDescending; }
    void setSortDescending(bool descending);

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void kill(int pid);
    Q_INVOKABLE void forceKill(int pid);

signals:
    void activeChanged();
    void intervalChanged();
    void processesChanged();
    void filterChanged();
    void sortChanged();

private:
    [[nodiscard]] quint64 totalCpuTicks() const;
    [[nodiscard]] QString userName(uint uid);
    void rebuildView();

    QTimer timer;
    QHash<int, ProcessEntry*> entries;
    QHash<uint, QString> userNames;
    QList<ProcessEntry*> allProcesses;
    QList<ProcessEntry*> bProcesses;
    QString bFilter;
    SortKey bSortKey = ProcessTable::Cpu;
    bool bSortDescending = true;
    quint64 lastTotalTicks = 0;
    double memoryTotalKb = 0;
    long ticksPerSecond = 100;
    long pageSizeKb = 4;
};
