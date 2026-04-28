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
- **Symptom**: System still locking up, potentially related to display or NVMe stability.
- **Diagnosis**: 
    - PSR (Panel Self Refresh) might need more aggressive disabling (PSR-SU).
    - Adaptive Backlight Management (ABM) can cause flickering and hangs on AMD Frameworks.
    - `nvme.noacpi=1` might be counter-productive on newer BIOS versions.
- **Attempted Fix**:
    - Updated `amdgpu.dcdebugmask=0x110` (disables PSR and PSR-SU).
    - Added `amdgpu.abmlevel=0` (disables ABM).
    - Removed `nvme.noacpi=1`.
- **Status**: Applying changes.

## Issue: Hyprland Config Error (no_direct_scanout)

### 2026-04-27
- **Symptom**: Hyprland reports error: `misc:no_direct_scanout does not exist`.
- **Diagnosis**: The `no_direct_scanout` option was removed in Hyprland v0.41.0.
- **Attempted Fix**: Removed `no_direct_scanout = true` from `files/system/etc/skel/.config/hypr/hyprland.conf` and `files/system/usr/share/hyprland/hyprland.conf`.
- **Status**: Changes committed to branch `fix/wake-lockup`.
