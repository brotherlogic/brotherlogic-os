# Attempt Log

This file tracks attempts made to solve recurring issues in the codebase.

## Issue: Laptop Lockups (Suspend/Resume Hangs)

### 2026-04-27
- **Symptom**: Laptop locks up during or after `s2idle` suspend (lid closed or idle).
- **Diagnosis**: 
    - Kernel logs show `ucsi_acpi` errors: `ucsi_acpi USBC000:00: GET_CABLE_PROPERTY failed (-5)`.
    - Suspend entry `PM: suspend entry (s2idle)` is the last log before silence.
    - System was already running with `rtc_cmos.use_acpi_alarm=1` and `nvme.noacpi=1` (set manually via kargs), but lockups persisted.
- **Attempted Fix**:
    - Blacklisted `ucsi_acpi` via kernel arguments: `modprobe.blacklist=ucsi_acpi`.
    - Consolidated manual kargs into `recipes/recipe.yml` to ensure consistency:
        - `modprobe.blacklist=ucsi_acpi`
        - `rtc_cmos.use_acpi_alarm=1`
        - `nvme.noacpi=1`
        - `amdgpu.sg_display=0`
        - `amdgpu.dcdebugmask=0x10` (existing)
- **Status**: Changes committed to branch `fix/wake-lockup`.

### 2026-04-27 (Latest)
- **Symptom**: System still locking up, potentially related to display, NVMe, or I/O stability.
- **Diagnosis**: 
    - PSR (Panel Self Refresh) might need more aggressive disabling (PSR-SU).
    - Adaptive Backlight Management (ABM) can cause flickering and hangs on AMD Frameworks.
    - `nvme.noacpi=1` might be counter-productive on newer BIOS versions.
    - DMA remapping or PCIe power management might be causing hard freezes.
- **Attempted Fix**:
    - Updated `amdgpu.dcdebugmask=0x110` (disables PSR and PSR-SU).
    - Added `amdgpu.abmlevel=0` (disables ABM).
    - Added `iommu=pt` to improve DMA stability.
    - Added `amdgpu.gpu_recovery=1` to allow GPU resets instead of hard freezes.
    - Added `pcie_aspm=off` to rule out PCIe power management hangs.
- **Status**: Applying changes.

## Issue: Locking Behavior (Half Screen / Unresponsive)

### 2026-05-11 (Latest)
- **Symptom**: OS still locks in an "intermediary state" (likely half-rendered lock screen) when opening the lid, requiring a reboot.
- **Diagnosis**: 
    - Previous `sleep 1` might not be enough for `hyprlock` to fully initialize and render on some hardware/driver states.
    - `eDP-1` explicit targeting in `hyprlock` might fail if the monitor is not immediately available on resume.
    - Variable Frame Rate (VFR) might be causing rendering glitches during the suspend/resume transition.
- **Attempted Fix**:
    - Increased `sleep` to `2` seconds in `hypridle.conf`'s `before_sleep_cmd`.
    - Removed explicit `monitor = eDP-1` from `hyprlock.conf` to use generic targeting.
    - Added `ignore_empty_input = true` to `hyprlock.conf` for better input handling on resume.
    - Disabled `vfr` in `hyprland.conf` to improve compositor stability.
    - Added `LidSwitchIgnoreInhibited=no` to `logind.conf` to respect inhibits, potentially avoiding state conflicts.
- **Status**: Applying changes.

## Issue: Read-Only Filesystem After Wake

### 2026-05-11 (Latest)
- **Symptom**: Filesystem becomes read-only after waking from sleep, rendering the system unusable.
- **Diagnosis**: 
    - Common issue with Western Digital SN770/SN850 NVMe drives on AMD platforms.
    - NVMe controller or drive may be timing out or failing to re-initialize during resume.
    - Previous attempts used `pcie_aspm=off` and runtime `kargs` which may have been insufficient or applied too late.
- **Attempted Fix (New Strategy)**:
    - **New**: Added `nvme_core.admin_timeout=240` to specifically prevent the kernel from dropping the drive to RO during slow wake-ups.
    - **New**: Switched from `pcie_aspm=off` to `pcie_aspm.policy=performance` to allow cleaner PCIe state transitions while maintaining high power delivery.
    - **Consolidated**: Moved all arguments (`nvme.noacpi=1`, `mem_sleep_default=s2idle`, etc.) into `recipes/recipe.yml`. This ensures they are baked into the deployment and active before the OS even starts, rather than being applied by a script that might fail if the drive is already problematic.
    - Removed redundant `rpm-ostree kargs` calls from `files/system/usr/bin/set-hostname.sh`.
- **Status**: Applying changes.


## Issue: Hyprland Config Error (no_direct_scanout)

### 2026-04-27
- **Symptom**: Hyprland reports error: `misc:no_direct_scanout does not exist`.
- **Diagnosis**: The `no_direct_scanout` option was removed in Hyprland v0.41.0.
- **Attempted Fix**: Removed `no_direct_scanout = true` from `files/system/etc/skel/.config/hypr/hyprland.conf` and `files/system/usr/share/hyprland/hyprland.conf`.
- **Status**: Changes committed to branch `fix/wake-lockup`.
