// writing this shit blind, if it works might as well become linbus goorball

#include "Backends.hpp"

#include "Sysfs.hpp"

#include <QFileInfo>
#include <QLibrary>

namespace {

using NvmlDevice = void*;

struct NvmlUtilization {
    unsigned int gpu;
    unsigned int memory;
};

struct NvmlMemory {
    unsigned long long total;
    unsigned long long free;
    unsigned long long used;
};

class Nvml {
public:
    static Nvml& instance() {
        static Nvml nvml;
        return nvml;
    }

    [[nodiscard]] bool ready() const { return this->initialised; }

    int (*handleByPciBusId)(const char*, NvmlDevice*) = nullptr;
    int (*deviceName)(NvmlDevice, char*, unsigned int) = nullptr;
    int (*utilization)(NvmlDevice, NvmlUtilization*) = nullptr;
    int (*memoryInfo)(NvmlDevice, NvmlMemory*) = nullptr;
    int (*temperature)(NvmlDevice, int, unsigned int*) = nullptr;
    int (*powerUsage)(NvmlDevice, unsigned int*) = nullptr;
    int (*powerLimit)(NvmlDevice, unsigned int*) = nullptr;
    int (*fanSpeed)(NvmlDevice, unsigned int*) = nullptr;

private:
    Nvml() {
        this->library.setFileName(QStringLiteral("libnvidia-ml.so.1"));
        if (!this->library.load()) return;

        auto* init = reinterpret_cast<int (*)()>(this->library.resolve("nvmlInit_v2"));
        if (!init || init() != 0) return;

        this->handleByPciBusId = reinterpret_cast<decltype(this->handleByPciBusId)>(this->library.resolve("nvmlDeviceGetHandleByPciBusId_v2"));
        this->deviceName = reinterpret_cast<decltype(this->deviceName)>(this->library.resolve("nvmlDeviceGetName"));
        this->utilization = reinterpret_cast<decltype(this->utilization)>(this->library.resolve("nvmlDeviceGetUtilizationRates"));
        this->memoryInfo = reinterpret_cast<decltype(this->memoryInfo)>(this->library.resolve("nvmlDeviceGetMemoryInfo"));
        this->temperature = reinterpret_cast<decltype(this->temperature)>(this->library.resolve("nvmlDeviceGetTemperature"));
        this->powerUsage = reinterpret_cast<decltype(this->powerUsage)>(this->library.resolve("nvmlDeviceGetPowerUsage"));
        this->powerLimit = reinterpret_cast<decltype(this->powerLimit)>(this->library.resolve("nvmlDeviceGetEnforcedPowerLimit"));
        this->fanSpeed = reinterpret_cast<decltype(this->fanSpeed)>(this->library.resolve("nvmlDeviceGetFanSpeed"));

        this->initialised = this->handleByPciBusId != nullptr;
    }

    QLibrary library;
    bool initialised = false;
};

QString nvmlBusId(const QString& devicePath) {
    const auto bdf = QFileInfo(devicePath).fileName();
    const auto domain = bdf.section(':', 0, 0);
    if (domain.isEmpty()) return bdf;
    return domain.rightJustified(8, '0') + ':' + bdf.section(':', 1);
}

class NvidiaBackend: public GpuBackend {
public:
    NvidiaBackend(QString devicePath, QString card)
        : devicePath(std::move(devicePath))
        , bCard(std::move(card)) {
        this->hwmon = Sysfs::hwmonWithName(this->devicePath + QStringLiteral("/hwmon"), {QStringLiteral("nvidia"), QStringLiteral("nouveau")});

        auto& nvml = Nvml::instance();
        if (nvml.ready()) {
            const auto busId = nvmlBusId(this->devicePath).toLatin1();
            if (nvml.handleByPciBusId(busId.constData(), &this->device) != 0) this->device = nullptr;
        }

        if (this->device && nvml.deviceName) {
            std::array<char, 96> buffer {};
            if (nvml.deviceName(this->device, buffer.data(), buffer.size()) == 0) {
                this->bName = QString::fromLatin1(buffer.data());
            }
        }
        if (this->bName.isEmpty()) this->bName = PciIds::deviceName(this->devicePath, QStringLiteral("NVIDIA GPU"));
    }

    [[nodiscard]] QString name() const override { return this->bName; }
    [[nodiscard]] QString card() const override { return this->bCard; }
    [[nodiscard]] GpuDevice::Vendor vendor() const override { return GpuDevice::Nvidia; }
    [[nodiscard]] bool integrated() const override { return false; }

    GpuSample sample() override {
        GpuSample out;
        auto& nvml = Nvml::instance();

        if (!this->device) {
            if (!this->hwmon.isEmpty()) out.temperature = Sysfs::firstTemp(this->hwmon);
            return out;
        }

        if (NvmlUtilization util {}; nvml.utilization && nvml.utilization(this->device, &util) == 0) {
            out.usage = qBound(0.0, util.gpu / 100.0, 1.0);
        }
        if (NvmlMemory memory {}; nvml.memoryInfo && nvml.memoryInfo(this->device, &memory) == 0) {
            out.vramUsed = static_cast<double>(memory.used);
            out.vramTotal = static_cast<double>(memory.total);
        }
        if (unsigned int celsius = 0; nvml.temperature && nvml.temperature(this->device, 0, &celsius) == 0) {
            out.temperature = celsius;
        }
        if (unsigned int milliwatts = 0; nvml.powerUsage && nvml.powerUsage(this->device, &milliwatts) == 0) {
            out.power = milliwatts / 1000.0;
        }
        if (unsigned int milliwatts = 0; nvml.powerLimit && nvml.powerLimit(this->device, &milliwatts) == 0) {
            out.powerLimit = milliwatts / 1000.0;
        }
        if (unsigned int percent = 0; nvml.fanSpeed && nvml.fanSpeed(this->device, &percent) == 0) {
            out.fanPercent = percent;
        }

        return out;
    }

private:
    QString devicePath;
    QString bCard;
    QString hwmon;
    QString bName;
    NvmlDevice device = nullptr;
};

}

std::unique_ptr<GpuBackend> makeNvidiaBackend(const QString& devicePath, const QString& card) {
    return std::make_unique<NvidiaBackend>(devicePath, card);
}
