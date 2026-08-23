#pragma once

#include "GpuBackend.hpp"

std::unique_ptr<GpuBackend> makeAmdBackend(const QString& devicePath, const QString& card, bool integrated);
std::unique_ptr<GpuBackend> makeIntelBackend(const QString& devicePath, const QString& card, bool integrated);
std::unique_ptr<GpuBackend> makeNvidiaBackend(const QString& devicePath, const QString& card);
