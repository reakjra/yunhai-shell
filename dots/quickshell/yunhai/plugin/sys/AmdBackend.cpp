#include "Backends.hpp"

#include "Sysfs.hpp"

#include <QStringList>

namespace {

const QStringList EDGE_LABELS = {QStringLiteral("edge")};
const QStringList JUNCTION_LABELS = {QStringLiteral("junction")};
const QStringList MEMORY_LABELS = {QStringLiteral("mem")};

class AmdBackend: public GpuBackend {
public:
    AmdBackend(QString devicePath, QString card, bool integrated)
        : devicePath(std::move(devicePath))
        , bCard(std::move(card))
        , bIntegrated(integrated) {
        this->hwmon = Sysfs::hwmonWithName(this->devicePath + QStringLiteral("/hwmon"), {QStringLiteral("amdgpu")});
        if (this->hwmon.isEmpty()) {
            const auto candidates = Sysfs::entries(this->devicePath + QStringLiteral("/hwmon"), QStringLiteral("hwmon*"));
            if (!candidates.isEmpty()) this->hwmon = candidates.first();
        }

        this->bName = PciIds::amdMarketingName(this->devicePath);
        if (this->bName.isEmpty()) {
            this->bName = PciIds::deviceName(this->devicePath, integrated ? QStringLiteral("AMD iGPU") : QStringLiteral("AMD GPU"));
        }
    }

    [[nodiscard]] QString name() const override { return this->bName; }
    [[nodiscard]] QString card() const override { return this->bCard; }
    [[nodiscard]] GpuDevice::Vendor vendor() const override { return GpuDevice::Amd; }
    [[nodiscard]] bool integrated() const override { return this->bIntegrated; }

    GpuSample sample() override {
        GpuSample out;

        if (const auto busy = Sysfs::readDouble(this->devicePath + QStringLiteral("/gpu_busy_percent"))) {
            out.usage = qBound(0.0, *busy / 100.0, 1.0);
        }

        this->readVram(out);
        if (this->hwmon.isEmpty()) return out;

        out.temperature = Sysfs::labelledTemp(this->hwmon, EDGE_LABELS);
        if (!out.temperature) out.temperature = Sysfs::firstTemp(this->hwmon);
        out.temperatureJunction = Sysfs::labelledTemp(this->hwmon, JUNCTION_LABELS);
        out.temperatureMemory = Sysfs::labelledTemp(this->hwmon, MEMORY_LABELS);

        for (const auto& fan: Sysfs::entries(this->hwmon, QStringLiteral("fan*_input"))) {
            if (const auto rpm = Sysfs::readDouble(fan)) {
                out.fanRpm = rpm;
                break;
            }
        }
        if (const auto pwm = Sysfs::readDouble(this->hwmon + QStringLiteral("/pwm1"))) {
            out.fanPercent = *pwm / 255.0 * 100.0;
        }

        auto power = Sysfs::readDouble(this->hwmon + QStringLiteral("/power1_average"));
        if (!power) power = Sysfs::readDouble(this->hwmon + QStringLiteral("/power1_input"));
        if (power) out.power = *power / 1000000.0;
        if (const auto cap = Sysfs::readDouble(this->hwmon + QStringLiteral("/power1_cap"))) {
            out.powerLimit = *cap / 1000000.0;
        }

        return out;
    }

private:
    void readVram(GpuSample& out) const {
        static const QList<std::pair<QString, QString>> SOURCES = {
            {QStringLiteral("/mem_info_vram_used"), QStringLiteral("/mem_info_vram_total")},
            {QStringLiteral("/mem_info_vis_vram_used"), QStringLiteral("/mem_info_vis_vram_total")},
            {QStringLiteral("/gtt_used"), QStringLiteral("/gtt_total")},
        };

        for (const auto& [usedFile, totalFile]: SOURCES) {
            const auto total = Sysfs::readDouble(this->devicePath + totalFile);
            if (!total || *total <= 0) continue;
            out.vramUsed = Sysfs::readDouble(this->devicePath + usedFile).value_or(0);
            out.vramTotal = *total;
            return;
        }
    }

    QString devicePath;
    QString bCard;
    QString hwmon;
    QString bName;
    bool bIntegrated;
};

}

std::unique_ptr<GpuBackend> makeAmdBackend(const QString& devicePath, const QString& card, bool integrated) {
    return std::make_unique<AmdBackend>(devicePath, card, integrated);
}
