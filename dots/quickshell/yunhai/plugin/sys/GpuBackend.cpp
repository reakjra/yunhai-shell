#include "GpuBackend.hpp"

#include "Backends.hpp"
#include "Sysfs.hpp"

#include <QFileInfo>

namespace {

constexpr auto DRM_ROOT = "/sys/class/drm";

bool suspended(const QString& devicePath) {
    const auto state = Sysfs::readText(devicePath + QStringLiteral("/power_state"));
    return state && state->compare(QStringLiteral("d3cold"), Qt::CaseInsensitive) == 0;
}

std::unique_ptr<GpuBackend> backendFor(const QString& devicePath, const QString& card) {
    const auto vendorId = PciIds::field(devicePath, QStringLiteral("vendor"));

    if (vendorId == QStringLiteral("1002")) {
        const auto vram = Sysfs::readDouble(devicePath + QStringLiteral("/mem_info_vram_total")).value_or(0);
        return makeAmdBackend(devicePath, card, vram <= 0);
    }
    if (vendorId == QStringLiteral("10de")) {
        return makeNvidiaBackend(devicePath, card);
    }
    if (vendorId == QStringLiteral("8086")) {
        const auto lmem = Sysfs::readDouble(devicePath + QStringLiteral("/lmem_total_bytes")).value_or(0);
        return makeIntelBackend(devicePath, card, lmem <= 0);
    }

    return nullptr;
}

}

std::vector<std::unique_ptr<GpuBackend>> GpuBackend::discover() {
    std::vector<std::unique_ptr<GpuBackend>> backends;

    for (const auto& card: Sysfs::entries(QString::fromLatin1(DRM_ROOT), QStringLiteral("card[0-9]*"))) {
        const auto devicePath = QFileInfo(card + QStringLiteral("/device")).canonicalFilePath();
        if (devicePath.isEmpty() || suspended(devicePath)) continue;

        if (auto backend = backendFor(devicePath, QFileInfo(card).fileName())) {
            backends.push_back(std::move(backend));
        }
    }

    return backends;
}
