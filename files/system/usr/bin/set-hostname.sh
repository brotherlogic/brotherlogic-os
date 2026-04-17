#!/bin/bash
# Detect chassis type and set hostname accordingly
# laptop -> rst
# desktop/others -> rosieroo

CHASSIS=$(hostnamectl chassis)

if [ "$CHASSIS" == "laptop" ]; then
    echo "Detected laptop, setting hostname to rst"
    hostnamectl set-hostname rst
    
    # Apply recommended laptop power and stability optimizations for Framework 13 AMD
    # rtc_cmos.use_acpi_alarm=1: Improves sleep stability
    # nvme.noacpi=1: Fixes high battery drain on WD SN770 SSD
    # amdgpu.sg_display=0: Fixes "frozen desktop" issue on wake for AMD hardware
    echo "Applying laptop power optimizations..."
    rpm-ostree kargs --append-if-missing="rtc_cmos.use_acpi_alarm=1" --append-if-missing="nvme.noacpi=1" --append-if-missing="amdgpu.sg_display=0"
else
    echo "Detected $CHASSIS, setting hostname to rosieroo"
    hostnamectl set-hostname rosieroo
fi
