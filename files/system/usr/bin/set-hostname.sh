#!/bin/bash
# Detect chassis type and set hostname accordingly
# laptop -> rst
# desktop/others -> rosieroo

CHASSIS=$(hostnamectl chassis)

if [ "$CHASSIS" == "laptop" ]; then
    echo "Detected laptop, setting hostname to rst"
    hostnamectl set-hostname rst
    
    # Optmize battery drain for Framework 13 AMD
    # nvme.noacpi=1: fixes WD SN770 sleep drain
    # rtc_cmos.use_acpi_alarm=1: helps with AMD sleep stability
    echo "Applying laptop power optimizations..."
    rpm-ostree kargs --append-if-missing="nvme.noacpi=1" --append-if-missing="rtc_cmos.use_acpi_alarm=1"
else
    echo "Detected $CHASSIS, setting hostname to rosieroo"
    hostnamectl set-hostname rosieroo
fi
