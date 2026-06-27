#!/bin/bash
# Detect chassis type and set hostname accordingly
# laptop (asset tag FRANMDCPA54394018R) -> seraphine
# laptop (other) -> rst
# desktop/others -> rosieroo

CHASSIS=$(hostnamectl chassis)

if [ "$CHASSIS" == "laptop" ]; then
    ASSET_TAG=""
    if [ -f /sys/class/dmi/id/chassis_asset_tag ]; then
        ASSET_TAG=$(cat /sys/class/dmi/id/chassis_asset_tag)
    fi

    if [ "$ASSET_TAG" == "FRANMDCPA54394018R" ]; then
        echo "Detected seraphine laptop, setting hostname to seraphine"
        hostnamectl set-hostname seraphine
    else
        echo "Detected rst laptop, setting hostname to rst"
        hostnamectl set-hostname rst
    fi
else
    echo "Detected $CHASSIS, setting hostname to rosieroo"
    hostnamectl set-hostname rosieroo
fi
