#pragma once

#include "CpuStats.hpp"
#include "GpuDevice.hpp"
#include "MemoryStats.hpp"

#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class SysMon: public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int interval READ interval WRITE setInterval NOTIFY intervalChanged)
    Q_PROPERTY(int historyLength READ historyLength WRITE setHistoryLength NOTIFY historyLengthChanged)
    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)
    Q_PROPERTY(bool pollCpu READ pollCpu WRITE setPollCpu NOTIFY pollCpuChanged)
    Q_PROPERTY(bool pollMemory READ pollMemory WRITE setPollMemory NOTIFY pollMemoryChanged)
    Q_PROPERTY(bool pollGpu READ pollGpu WRITE setPollGpu NOTIFY pollGpuChanged)
    Q_PROPERTY(CpuStats* cpu READ cpu CONSTANT)
    Q_PROPERTY(MemoryStats* memory READ memory CONSTANT)
    Q_PROPERTY(QList<GpuDevice*> gpus READ gpus CONSTANT)

public:
    explicit SysMon(QObject* parent = nullptr);

    [[nodiscard]] int interval() const { return this->timer.interval(); }
    void setInterval(int interval);

    [[nodiscard]] int historyLength() const { return this->bHistoryLength; }
    void setHistoryLength(int length);

    [[nodiscard]] bool running() const { return this->timer.isActive(); }
    void setRunning(bool running);

    [[nodiscard]] bool pollCpu() const { return this->bPollCpu; }
    void setPollCpu(bool poll);

    [[nodiscard]] bool pollMemory() const { return this->bPollMemory; }
    void setPollMemory(bool poll);

    [[nodiscard]] bool pollGpu() const { return this->bPollGpu; }
    void setPollGpu(bool poll);

    [[nodiscard]] CpuStats* cpu() const { return this->bCpu; }
    [[nodiscard]] MemoryStats* memory() const { return this->bMemory; }
    [[nodiscard]] QList<GpuDevice*> gpus() const { return this->bGpus; }

    Q_INVOKABLE void refresh();

signals:
    void intervalChanged();
    void historyLengthChanged();
    void runningChanged();
    void pollCpuChanged();
    void pollMemoryChanged();
    void pollGpuChanged();

private:
    QTimer timer;
    CpuStats* bCpu;
    MemoryStats* bMemory;
    QList<GpuDevice*> bGpus;
    int bHistoryLength = 60;
    bool bPollCpu = true;
    bool bPollMemory = true;
    bool bPollGpu = true;
};
