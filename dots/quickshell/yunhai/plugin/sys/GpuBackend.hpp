#pragma once

#include "GpuDevice.hpp"

#include <QString>
#include <memory>
#include <vector>

class GpuBackend {
public:
    GpuBackend() = default;
    virtual ~GpuBackend() = default;
    Q_DISABLE_COPY_MOVE(GpuBackend);

    [[nodiscard]] virtual QString name() const = 0;
    [[nodiscard]] virtual QString card() const = 0;
    [[nodiscard]] virtual GpuDevice::Vendor vendor() const = 0;
    [[nodiscard]] virtual bool integrated() const = 0;
    virtual GpuSample sample() = 0;

    static std::vector<std::unique_ptr<GpuBackend>> discover();
};
