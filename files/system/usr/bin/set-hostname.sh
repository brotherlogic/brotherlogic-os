#!/bin/bash
# Detect chassis type and set hostname accordingly
# laptop -> rst
# desktop/others -> rosieroo

CHASSIS=$(hostnamectl chassis)

if [ "$CHASSIS" == "laptop" ]; then
    echo "Detected laptop, setting hostname to rst"
    hostnamectl set-hostname rst
    
    # Cleanup previous battery optimizations that caused wake issues on Framework 13 AMD
    echo "Cleaning up laptop power optimizations..."
    rpm-ostree kargs --delete="nvme.noacpi=1" --delete="rtc_cmos.use_acpi_alarm=1"
else
    echo "Detected $CHASSIS, setting hostname to rosieroo"
    hostnamectl set-hostname rosieroo
fi
