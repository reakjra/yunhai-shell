#include "GpuDevice.hpp"

#include "GpuBackend.hpp"

GpuDevice::GpuDevice(std::unique_ptr<GpuBackend> backend, QObject* parent)
    : QObject(parent)
    , backend(std::move(backend)) {}

GpuDevice::~GpuDevice() = default;

QString GpuDevice::name() const { return this->backend->name(); }
QString GpuDevice::card() const { return this->backend->card(); }
GpuDevice::Vendor GpuDevice::vendor() const { return this->backend->vendor(); }
bool GpuDevice::integrated() const { return this->backend->integrated(); }

void GpuDevice::refresh(int historyLength) {
    this->sample = this->backend->sample();

    this->bUsageHistory.append(this->sample.usage);
    while (this->bUsageHistory.length() > historyLength) this->bUsageHistory.removeFirst();

    emit this->updated();
}
