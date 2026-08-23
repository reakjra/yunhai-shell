#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

class MemoryStats: public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("owned by SysMon")

    Q_PROPERTY(double total READ total NOTIFY updated)
    Q_PROPERTY(double used READ used NOTIFY updated)
    Q_PROPERTY(double free READ free NOTIFY updated)
    Q_PROPERTY(double usage READ usage NOTIFY updated)
    Q_PROPERTY(double swapTotal READ swapTotal NOTIFY updated)
    Q_PROPERTY(double swapUsed READ swapUsed NOTIFY updated)
    Q_PROPERTY(double swapFree READ swapFree NOTIFY updated)
    Q_PROPERTY(double swapUsage READ swapUsage NOTIFY updated)
    Q_PROPERTY(QList<double> usageHistory READ usageHistory NOTIFY updated)
    Q_PROPERTY(QList<double> swapUsageHistory READ swapUsageHistory NOTIFY updated)

public:
    explicit MemoryStats(QObject* parent = nullptr): QObject(parent) {}

    [[nodiscard]] double total() const { return this->bTotal; }
    [[nodiscard]] double used() const { return this->bUsed; }
    [[nodiscard]] double free() const { return this->bFree; }
    [[nodiscard]] double usage() const { return this->bTotal > 0 ? this->bUsed / this->bTotal : 0; }
    [[nodiscard]] double swapTotal() const { return this->bSwapTotal; }
    [[nodiscard]] double swapUsed() const { return this->bSwapUsed; }
    [[nodiscard]] double swapFree() const { return this->bSwapFree; }
    [[nodiscard]] double swapUsage() const { return this->bSwapTotal > 0 ? this->bSwapUsed / this->bSwapTotal : 0; }
    [[nodiscard]] QList<double> usageHistory() const { return this->bUsageHistory; }
    [[nodiscard]] QList<double> swapUsageHistory() const { return this->bSwapUsageHistory; }

    void refresh(int historyLength);

signals:
    void updated();

private:
    double bTotal = 0;
    double bUsed = 0;
    double bFree = 0;
    double bSwapTotal = 0;
    double bSwapUsed = 0;
    double bSwapFree = 0;
    QList<double> bUsageHistory;
    QList<double> bSwapUsageHistory;
};
