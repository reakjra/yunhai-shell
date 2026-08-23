#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

class CpuStats: public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("owned by SysMon")

    Q_PROPERTY(QString model READ model NOTIFY staticsChanged)
    Q_PROPERTY(int threads READ threads NOTIFY staticsChanged)
    Q_PROPERTY(double maxFrequency READ maxFrequency NOTIFY staticsChanged)
    Q_PROPERTY(double usage READ usage NOTIFY updated)
    Q_PROPERTY(double frequency READ frequency NOTIFY updated)
    Q_PROPERTY(double temperature READ temperature NOTIFY updated)
    Q_PROPERTY(bool hasTemperature READ hasTemperature NOTIFY updated)
    Q_PROPERTY(QList<double> usageHistory READ usageHistory NOTIFY updated)

public:
    explicit CpuStats(QObject* parent = nullptr);

    [[nodiscard]] QString model() const { return this->bModel; }
    [[nodiscard]] int threads() const { return this->bThreads; }
    [[nodiscard]] double maxFrequency() const { return this->bMaxFrequency; }
    [[nodiscard]] double usage() const { return this->bUsage; }
    [[nodiscard]] double frequency() const { return this->bFrequency; }
    [[nodiscard]] double temperature() const { return this->bTemperature; }
    [[nodiscard]] bool hasTemperature() const { return this->bHasTemperature; }
    [[nodiscard]] QList<double> usageHistory() const { return this->bUsageHistory; }

    void refresh(int historyLength);

signals:
    void staticsChanged();
    void updated();

private:
    void readStatics();
    void readUsage();
    void readFrequency();
    void readTemperature();

    QString bModel;
    QString temperatureHwmon;
    QStringList temperatureLabels;
    int bThreads = 0;
    double bMaxFrequency = 0;
    double bUsage = 0;
    double bFrequency = 0;
    double bTemperature = 0;
    bool bHasTemperature = false;
    QList<double> bUsageHistory;
    qint64 lastTotal = 0;
    qint64 lastIdle = 0;
};
