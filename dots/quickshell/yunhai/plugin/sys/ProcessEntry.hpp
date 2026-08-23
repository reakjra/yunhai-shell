#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

class ProcessEntry: public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("owned by ProcessTable")

    Q_PROPERTY(QString pid READ pid CONSTANT)
    Q_PROPERTY(QString name READ name NOTIFY updated)
    Q_PROPERTY(QString fullCommand READ fullCommand NOTIFY updated)
    Q_PROPERTY(QString user READ user NOTIFY updated)
    Q_PROPERTY(double cpuPercent READ cpuPercent NOTIFY updated)
    Q_PROPERTY(double memPercent READ memPercent NOTIFY updated)
    Q_PROPERTY(double memoryKb READ memoryKb NOTIFY updated)
    Q_PROPERTY(QString memoryFormatted READ memoryFormatted NOTIFY updated)

public:
    ProcessEntry(int pid, QObject* parent): QObject(parent), bPid(pid) {}

    [[nodiscard]] QString pid() const { return QString::number(this->bPid); }
    [[nodiscard]] int pidValue() const { return this->bPid; }
    [[nodiscard]] QString name() const { return this->bName; }
    [[nodiscard]] QString fullCommand() const { return this->bFullCommand; }
    [[nodiscard]] QString user() const { return this->bUser; }
    [[nodiscard]] double cpuPercent() const { return this->bCpuPercent; }
    [[nodiscard]] double memPercent() const { return this->bMemPercent; }
    [[nodiscard]] double memoryKb() const { return this->bMemoryKb; }
    [[nodiscard]] QString memoryFormatted() const { return this->bMemoryFormatted; }

    void update(const QString& name, const QString& fullCommand, const QString& user, double cpuPercent, double memPercent, double memoryKb);

    [[nodiscard]] quint64 cpuTicks() const { return this->bCpuTicks; }
    void setCpuTicks(quint64 ticks) { this->bCpuTicks = ticks; }

    [[nodiscard]] bool seen() const { return this->bSeen; }
    void setSeen(bool seen) { this->bSeen = seen; }

signals:
    void updated();

private:
    QString bName;
    QString bFullCommand;
    QString bUser;
    QString bMemoryFormatted;
    double bCpuPercent = 0;
    double bMemPercent = 0;
    double bMemoryKb = 0;
    quint64 bCpuTicks = 0;
    int bPid;
    bool bSeen = false;
};
