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
