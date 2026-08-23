#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>
#include <memory>
#include <optional>

class GpuBackend;

struct GpuSample {
    double usage = 0;
    double vramUsed = 0;
    double vramTotal = 0;
    std::optional<double> temperature;
    std::optional<double> temperatureJunction;
    std::optional<double> temperatureMemory;
    std::optional<double> fanRpm;
    std::optional<double> fanPercent;
    std::optional<double> power;
    std::optional<double> powerLimit;
};

class GpuDevice: public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("owned by SysMon")

public:
    enum Vendor { Unknown, Amd, Intel, Nvidia };
    Q_ENUM(Vendor)

private:
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString card READ card CONSTANT)
    Q_PROPERTY(Vendor vendor READ vendor CONSTANT)
    Q_PROPERTY(bool integrated READ integrated CONSTANT)
    Q_PROPERTY(double usage READ usage NOTIFY updated)
    Q_PROPERTY(double vramUsed READ vramUsed NOTIFY updated)
    Q_PROPERTY(double vramTotal READ vramTotal NOTIFY updated)
    Q_PROPERTY(double vramUsage READ vramUsage NOTIFY updated)
    Q_PROPERTY(double temperature READ temperature NOTIFY updated)
    Q_PROPERTY(double temperatureJunction READ temperatureJunction NOTIFY updated)
    Q_PROPERTY(double temperatureMemory READ temperatureMemory NOTIFY updated)
    Q_PROPERTY(double fanRpm READ fanRpm NOTIFY updated)
    Q_PROPERTY(double fanPercent READ fanPercent NOTIFY updated)
    Q_PROPERTY(double power READ power NOTIFY updated)
    Q_PROPERTY(double powerLimit READ powerLimit NOTIFY updated)
    Q_PROPERTY(bool hasTemperatureJunction READ hasTemperatureJunction NOTIFY updated)
    Q_PROPERTY(bool hasTemperatureMemory READ hasTemperatureMemory NOTIFY updated)
    Q_PROPERTY(bool hasFanRpm READ hasFanRpm NOTIFY updated)
    Q_PROPERTY(bool hasFanPercent READ hasFanPercent NOTIFY updated)
    Q_PROPERTY(bool hasPower READ hasPower NOTIFY updated)
    Q_PROPERTY(QList<double> usageHistory READ usageHistory NOTIFY updated)

public:
    GpuDevice(std::unique_ptr<GpuBackend> backend, QObject* parent);
    ~GpuDevice() override;
    Q_DISABLE_COPY_MOVE(GpuDevice);

    [[nodiscard]] QString name() const;
    [[nodiscard]] QString card() const;
    [[nodiscard]] Vendor vendor() const;
    [[nodiscard]] bool integrated() const;

    [[nodiscard]] double usage() const { return this->sample.usage; }
    [[nodiscard]] double vramUsed() const { return this->sample.vramUsed; }
    [[nodiscard]] double vramTotal() const { return this->sample.vramTotal; }
    [[nodiscard]] double vramUsage() const {
        return this->sample.vramTotal > 0 ? this->sample.vramUsed / this->sample.vramTotal : 0;
    }
    [[nodiscard]] double temperature() const { return this->sample.temperature.value_or(0); }
    [[nodiscard]] double temperatureJunction() const { return this->sample.temperatureJunction.value_or(0); }
    [[nodiscard]] double temperatureMemory() const { return this->sample.temperatureMemory.value_or(0); }
    [[nodiscard]] double fanRpm() const { return this->sample.fanRpm.value_or(0); }
    [[nodiscard]] double fanPercent() const { return this->sample.fanPercent.value_or(0); }
    [[nodiscard]] double power() const { return this->sample.power.value_or(0); }
    [[nodiscard]] double powerLimit() const { return this->sample.powerLimit.value_or(0); }

    [[nodiscard]] bool hasTemperatureJunction() const { return this->sample.temperatureJunction.has_value(); }
    [[nodiscard]] bool hasTemperatureMemory() const { return this->sample.temperatureMemory.has_value(); }
    [[nodiscard]] bool hasFanRpm() const { return this->sample.fanRpm.has_value(); }
    [[nodiscard]] bool hasFanPercent() const { return this->sample.fanPercent.has_value(); }
    [[nodiscard]] bool hasPower() const { return this->sample.power.has_value(); }
    [[nodiscard]] QList<double> usageHistory() const { return this->bUsageHistory; }

    void refresh(int historyLength);

signals:
    void updated();

private:
    std::unique_ptr<GpuBackend> backend;
    GpuSample sample;
    QList<double> bUsageHistory;
};
