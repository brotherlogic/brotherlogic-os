# CZUR Shine Ultra Pro Scanning Setup

## Overview

The **CZUR Shine Ultra Pro** is not supported by CZUR's official Linux `.deb` package (which is restricted to select ET-series scanners) and does not use the standard Linux SANE framework. While its camera presents as a generic UVC webcam (`/dev/video*`), CZUR's proprietary **curve-flattening, finger removal, auto-cropping, and OCR** features are only available in the Windows software.

To support full scanner functionality on `brotherlogic-os`, the scanner is run inside a **Windows 11 KVM/QEMU virtual machine** with direct USB passthrough (`1e4f:0806`).

---

## OS Prerequisites (Pre-installed in `brotherlogic-os`)

`brotherlogic-os` already includes the required host configuration:

- **Virtualization, TPM 2.0, UEFI & USB packages** (`recipes/recipe.yml`):
  - `qemu-kvm`, `libvirt`, `virt-install`, `virt-manager`
  - `swtpm` and `swtpm-tools` (TPM 2.0 emulation required by Windows 11)
  - `edk2-ovmf` (UEFI + Secure Boot firmware)
  - `libvirt-daemon-config-network` (provides the `default` NAT network bridge)
  - `usbutils` (provides `lsusb`)
- **System Daemon & User Groups**:
  - `libvirtd.service` is enabled on boot.
  - User `simon` is added to the `libvirt`, `kvm`, and `qemu` groups via `/usr/lib/sysusers.d/docker-simon.conf`.
  - `/etc/profile.d/libvirt.sh` exports `LIBVIRT_DEFAULT_URI="qemu:///system"` so `virsh` and `virt-install` target the system daemon automatically.
- **USB Permissions (`udev`)**:
  - `/etc/udev/rules.d/99-czur-scanner.rules` grants user-space access (`MODE="0666"`, `TAG+="uaccess"`) to CZUR `usb` and `hidraw` devices (`idVendor=="1e4f"`).

> [!NOTE]
> Make sure your system has updated to an image build containing PR `#118` (`rpm-ostree upgrade` and reboot) before continuing.

---

## Step 1: Verify the Scanner USB ID

Plug in and power on the CZUR Shine Ultra Pro (along with its foot pedal/hand button if separate), then run:

```bash
lsusb | grep -i -E "1e4f|czur"
```

Confirm the Vendor ID and Product ID (expected: `1e4f:0806`). If your device or foot pedal appears with a different ID or as a second USB device, note both `<vendor>:<product>` pairs for Step 4.

---

## Step 2: Ensure the Libvirt `default` Network is Active

Check the status of the `default` NAT network and enable it if it is inactive:

```bash
virsh net-list --all
```

If `default` is not listed as `active` and `autostart: yes`, run:

```bash
virsh net-start default
virsh net-autostart default
```

---

## Step 3: Download the Windows 11 ISO

1. Download the official **Windows 11 Disk Image (ISO) for x64 devices** from Microsoft:
   <https://www.microsoft.com/software-download/windows11>
2. Save or move the ISO to `/var/lib/libvirt/images/` (or another directory readable by the `qemu` user, ensuring permissions allow `qemu` to read the file):
   ```bash
   sudo mv ~/Downloads/Win11_*_x64*.iso /var/lib/libvirt/images/Win11_x64.iso
   ```

---

## Step 4: Create the Windows 11 VM with `virt-install`

Save the script below as `setup_scanner_vm.sh` (updating `ISO_PATH` if your ISO is stored elsewhere):

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="czur-scanner-win11"
RAM_MB="8192"
VCPUS="4"
DISK_SIZE="60"
OS_VARIANT="win11"
NETWORK="network=default"
ISO_PATH="/var/lib/libvirt/images/Win11_x64.iso"

if [ ! -f "$ISO_PATH" ]; then
    echo "Error: Windows 11 ISO not found at $ISO_PATH"
    exit 1
fi

virt-install \
  --name="$VM_NAME" \
  --memory="$RAM_MB" \
  --vcpus="$VCPUS" \
  --os-variant="$OS_VARIANT" \
  --disk size="$DISK_SIZE",bus=virtio,format=qcow2 \
  --network "$NETWORK",model=virtio \
  --graphics spice,listen=127.0.0.1 \
  --video qxl \
  --cdrom="$ISO_PATH" \
  --boot uefi \
  --features smm=on \
  --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
  --hostdev 1e4f:0806,type=usb \
  --noautoconsole
```

Make it executable and run it:

```bash
chmod +x setup_scanner_vm.sh
./setup_scanner_vm.sh
```

> [!TIP]
> **Foot pedal / extra USB devices:** If `lsusb` showed a separate Vendor:Product ID for the foot pedal or if your Shine Ultra Pro uses a different product ID, add or adjust `--hostdev <vid>:<pid>,type=usb` in the command above, or attach it dynamically inside `virt-manager` via **Virtual Machine → Redirect USB device**.

---

## Step 5: Complete Windows 11 & CZUR Shine Software Setup

1. Open **Virtual Machine Manager** (`virt-manager`) from your desktop/terminal.
2. Open the console for **`czur-scanner-win11`** and walk through the Windows 11 installation.
   *(If Windows asks for storage drivers during disk selection because the disk uses `virtio`, either attach the Fedora `virtio-win` ISO as a second CD-ROM or change `bus=virtio` to `bus=sata` in `virt-install`.)*
3. Once logged in to Windows 11, download and install the **CZUR Shine** Windows software from the official download center:
   <https://www.czur.com/support>
4. Launch the CZUR Shine software—your scanner (`1e4f:0806`) will be passed directly to the VM whenever it is plugged in and powered on before/during VM launch.

---

## Step 6: Sharing Scanned Files with the Linux Host

To move scanned PDFs and images seamlessly between the Windows VM and `brotherlogic-os`, use either approach:

### Option A: Shared Folder (`virtiofs`)
1. Create a scans directory on the host, e.g.:
   ```bash
   mkdir -p /var/home/simon/Scans
   ```
2. In `virt-manager`, open the VM details (**Show virtual hardware details**):
   - Under **Memory**, enable **Enable shared memory**.
   - Click **Add Hardware → Filesystem**, choose **Driver: `virtiofs`**, set **Source path** to `/var/home/simon/Scans`, and set **Target path** to `scans`.
3. Inside Windows, install `virtio-win` guest drivers and the `WinFsp` service so the `VirtIO-FS Service` mounts `scans` as a Windows drive letter, then configure CZUR Shine's output folder to save directly there.

### Option B: SPICE Guest Tools (Clipboard & Drag-and-Drop)
Install **`spice-guest-tools`** inside the Windows 11 VM to enable bidirectional clipboard sharing, automatic display resizing, and drag-and-drop file transfers straight to your host desktop.
