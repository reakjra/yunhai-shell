// writing this shit blind, if it works might as well become linbus goorball

#include "Backends.hpp"

#include "Sysfs.hpp"

#include <QElapsedTimer>
#include <QStringList>
#include <linux/perf_event.h>
#include <sys/syscall.h>
#include <unistd.h>

namespace {

constexpr auto PMU_ROOT = "/sys/bus/event_source/devices";
const QStringList GPU_TEMP_LABELS = {QStringLiteral("gpu"), QStringLiteral("gt"), QStringLiteral("package")};

std::optional<quint64> pmuEventConfig(const QString& pmu, const QString& event) {
    const auto text = Sysfs::readText(QString::fromLatin1(PMU_ROOT) + '/' + pmu + QStringLiteral("/events/") + event);
    if (!text) return std::nullopt;

    for (const auto& field: text->split(',')) {
        if (!field.startsWith(QStringLiteral("config="))) continue;
        bool ok = false;
        const auto value = field.mid(7).toULongLong(&ok, 0);
        if (ok) return value;
    }

    return std::nullopt;
}

std::optional<double> packageTemp() {
    for (const auto& zone: Sysfs::entries(QStringLiteral("/sys/class/thermal"), QStringLiteral("thermal_zone*"))) {
        const auto type = Sysfs::readText(zone + QStringLiteral("/type"));
        if (!type || *type != QStringLiteral("x86_pkg_temp")) continue;
        if (const auto millidegrees = Sysfs::readDouble(zone + QStringLiteral("/temp"))) return *millidegrees / 1000.0;
    }

    const auto coretemp = Sysfs::hwmonWithName(QStringLiteral("/sys/class/hwmon"), {QStringLiteral("coretemp")});
    return coretemp.isEmpty() ? std::nullopt : Sysfs::firstTemp(coretemp);
}

int openBusyCounter(const QString& pmu) {
    const auto type = Sysfs::readInt(QString::fromLatin1(PMU_ROOT) + '/' + pmu + QStringLiteral("/type"));
    const auto config = pmuEventConfig(pmu, QStringLiteral("rcs0-busy"));
    if (!type || !config) return -1;

    perf_event_attr attr {};
    attr.size = sizeof(attr);
    attr.type = static_cast<quint32>(*type);
    attr.config = *config;
    attr.read_format = 0;

    return static_cast<int>(syscall(SYS_perf_event_open, &attr, -1, 0, -1, 0));
}

class IntelBackend: public GpuBackend {
public:
    IntelBackend(QString devicePath, QString card, bool integrated)
        : devicePath(std::move(devicePath))
        , bCard(std::move(card))
        , bIntegrated(integrated) {
        this->hwmon = Sysfs::hwmonWithName(this->devicePath + QStringLiteral("/hwmon"), {QStringLiteral("i915"), QStringLiteral("xe")});
        if (this->hwmon.isEmpty()) {
            const auto candidates = Sysfs::entries(this->devicePath + QStringLiteral("/hwmon"), QStringLiteral("hwmon*"));
            if (!candidates.isEmpty()) this->hwmon = candidates.first();
        }

        this->bName = PciIds::deviceName(this->devicePath, integrated ? QStringLiteral("Intel iGPU") : QStringLiteral("Intel GPU"));

        this->busyFd = openBusyCounter(QStringLiteral("i915"));
        if (this->busyFd < 0) this->busyFd = openBusyCounter(QStringLiteral("xe"));
        this->elapsed.start();
    }

    ~IntelBackend() override {
        if (this->busyFd >= 0) close(this->busyFd);
    }

    [[nodiscard]] QString name() const override { return this->bName; }
    [[nodiscard]] QString card() const override { return this->bCard; }
    [[nodiscard]] GpuDevice::Vendor vendor() const override { return GpuDevice::Intel; }
    [[nodiscard]] bool integrated() const override { return this->bIntegrated; }

    GpuSample sample() override {
        GpuSample out;

        const auto nanoseconds = this->elapsed.nsecsElapsed();
        this->elapsed.restart();

        this->readBusy(out, nanoseconds);
        this->readVram(out);
        this->readPower(out, nanoseconds);

        if (!this->hwmon.isEmpty()) {
            out.temperature = Sysfs::labelledTemp(this->hwmon, GPU_TEMP_LABELS);
            if (!out.temperature) out.temperature = Sysfs::firstTemp(this->hwmon);
        }
        if (!out.temperature && this->bIntegrated) out.temperature = packageTemp();

        return out;
    }

private:
    void readBusy(GpuSample& out, qint64 nanoseconds) {
        if (this->busyFd < 0 || nanoseconds <= 0) return;

        quint64 busy = 0;
        if (read(this->busyFd, &busy, sizeof(busy)) != sizeof(busy)) return;

        if (this->lastBusy > 0 && busy >= this->lastBusy) {
            out.usage = qBound(0.0, static_cast<double>(busy - this->lastBusy) / static_cast<double>(nanoseconds), 1.0);
        }
        this->lastBusy = busy;
    }

    void readVram(GpuSample& out) const {
        const auto total = Sysfs::readDouble(this->devicePath + QStringLiteral("/lmem_total_bytes"));
        if (!total || *total <= 0) return;
        out.vramUsed = Sysfs::readDouble(this->devicePath + QStringLiteral("/lmem_used_bytes")).value_or(0);
        out.vramTotal = *total;
    }

    void readPower(GpuSample& out, qint64 nanoseconds) {
        if (this->hwmon.isEmpty() || nanoseconds <= 0) return;

        if (const auto watts = Sysfs::readDouble(this->hwmon + QStringLiteral("/power1_input"))) {
            out.power = *watts / 1000000.0;
            return;
        }

        const auto microjoules = Sysfs::readDouble(this->hwmon + QStringLiteral("/energy1_input"));
        if (!microjoules) return;
        if (this->lastEnergy > 0 && *microjoules >= this->lastEnergy) {
            out.power = (*microjoules - this->lastEnergy) / 1000000.0 / (static_cast<double>(nanoseconds) / 1e9);
        }
        this->lastEnergy = *microjoules;
    }

    QString devicePath;
    QString bCard;
    QString hwmon;
    QString bName;
    QElapsedTimer elapsed;
    quint64 lastBusy = 0;
    double lastEnergy = 0;
    int busyFd = -1;
    bool bIntegrated;
};

}

std::unique_ptr<GpuBackend> makeIntelBackend(const QString& devicePath, const QString& card, bool integrated) {
    return std::make_unique<IntelBackend>(devicePath, card, integrated);
}
