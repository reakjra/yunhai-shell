#include "SysMon.hpp"

#include "GpuBackend.hpp"

SysMon::SysMon(QObject* parent)
    : QObject(parent)
    , bCpu(new CpuStats(this))
    , bMemory(new MemoryStats(this)) {
    for (auto& backend: GpuBackend::discover()) {
        this->bGpus.append(new GpuDevice(std::move(backend), this));
    }

    this->timer.setInterval(3000);
    QObject::connect(&this->timer, &QTimer::timeout, this, &SysMon::refresh);
    this->refresh();
    this->timer.start();
}

void SysMon::setInterval(int interval) {
    if (interval == this->timer.interval()) return;
    this->timer.setInterval(interval);
    emit this->intervalChanged();
}

void SysMon::setHistoryLength(int length) {
    if (length == this->bHistoryLength) return;
    this->bHistoryLength = length;
    emit this->historyLengthChanged();
}

void SysMon::setRunning(bool running) {
    if (running == this->timer.isActive()) return;
    if (running) this->timer.start();
    else this->timer.stop();
    emit this->runningChanged();
}

void SysMon::setPollCpu(bool poll) {
    if (poll == this->bPollCpu) return;
    this->bPollCpu = poll;
    emit this->pollCpuChanged();
}

void SysMon::setPollMemory(bool poll) {
    if (poll == this->bPollMemory) return;
    this->bPollMemory = poll;
    emit this->pollMemoryChanged();
}

void SysMon::setPollGpu(bool poll) {
    if (poll == this->bPollGpu) return;
    this->bPollGpu = poll;
    emit this->pollGpuChanged();
}

void SysMon::refresh() {
    if (this->bPollCpu) this->bCpu->refresh(this->bHistoryLength);
    if (this->bPollMemory) this->bMemory->refresh(this->bHistoryLength);
    if (this->bPollGpu) {
        for (auto* gpu: this->bGpus) gpu->refresh(this->bHistoryLength);
    }
}
