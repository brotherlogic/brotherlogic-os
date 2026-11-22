# CZUR Shine Ultra Pro Scanning Setup

## Overview

The **CZUR Shine Ultra Pro** is not supported by CZUR's official Linux `.deb` package (which is restricted to select ET-series scanners) and does not use the standard Linux SANE framework. While its camera presents as a generic UVC webcam (`/dev/video*`), CZUR's proprietary **curve-flattening, finger removal, auto-cropping, and OCR** features are only available in the Windows software.

To support full scanner functionality on `brotherlogic-os`, the scanner is run inside a **Windows 11 KVM/QEMU virtual machine** with direct USB passthrough (`1e4f:0806`).

---

## Day-to-Day Usage & Shortcuts

Initial VM setup is **one-time**—your Windows 11 disk (`/var/lib/libvirt/images/czur-scanner-win11.qcow2`), VM hardware configuration, TPM 2.0 state, and SELinux contexts persist across reboots and OS image updates.

- **Start scanning:** Plug in and power on the CZUR Shine Ultra Pro, then open **`virt-manager`** and click **Play** on `czur-scanner-win11` (or run `virsh start czur-scanner-win11`).
- **Release captured mouse/keyboard:** Press **Left `Ctrl` + Left `Alt`** together.
- **Exit fullscreen mode in `virt-manager`:**
  1. Press **Left `Ctrl` + Left `Alt`** to release the input grab.
  2. Move the cursor to the **top-center edge of the screen** and wait a moment for the floating toolbar to drop down, then click **Leave Fullscreen**.
  3. On Hyprland, if the toolbar doesn't appear, switch workspaces or open a terminal (`Super + Q`), run `sleep 2 && hyprctl dispatch fullscreen 0`, and click back on the `virt-manager` window within 2 seconds.

---

## OS Prerequisites (Pre-installed in `brotherlogic-os`)

`brotherlogic-os` includes the required host configuration:

- **Virtualization, TPM 2.0, UEFI & USB packages** (`recipes/recipe.yml`):
  - `qemu-kvm`, `libvirt`, `virt-install`, `virt-manager`
  - `swtpm` and `swtpm-tools` (TPM 2.0 emulation required by Windows 11)
  - `edk2-ovmf` (UEFI + Secure Boot firmware)
  - `libvirt-daemon-config-network` (provides the `default` NAT network bridge)
  - `usbutils` (provides `lsusb`)
- **Modular Libvirt Sockets & `/var` SELinux Setup**:
  - `virtqemud.socket`, `virtnetworkd.socket`, `virtstoraged.socket`, and `virtnodedevd.socket` are enabled on boot (Fedora uses modular daemons rather than the legacy `libvirtd.service`).
  - `/usr/lib/tmpfiles.d/libvirt-swtpm.conf` ensures `/var/lib/libvirt`, `/var/lib/swtpm-localca`, `/var/log/libvirt`, and `/var/log/swtpm` exist with `tss:tss` ownership (for `swtpm`) and restored SELinux labels.
  - User `simon` is added to the `libvirt`, `kvm`, and `qemu` groups via `/usr/lib/sysusers.d/docker-simon.conf`.
  - `/etc/profile.d/libvirt.sh` exports `LIBVIRT_DEFAULT_URI="qemu:///system"` so `virsh` and `virt-install` target the system daemon automatically.
- **USB Permissions (`udev`)**:
  - `/etc/udev/rules.d/99-czur-scanner.rules` grants user-space access (`MODE="0666"`, `TAG+="uaccess"`) to CZUR `usb` and `hidraw` devices (`idVendor=="1e4f"`).

---

## Step 1: Verify the Scanner USB ID

Plug in and power on the CZUR Shine Ultra Pro (along with its foot pedal/hand button if separate), then run:

```bash
lsusb | grep -i -E "1e4f|czur"
```

Expected output:

```text
Bus 001 Device 010: ID 1e4f:0806 CZUR Technology Co., Ltd. CZUR USB HD MIC
```

Even though the USB product string says `CZUR USB HD MIC`, `1e4f:0806` is a composite USB device that bundles both the `ET08X` video camera (`bInterfaceClass 14 Video`) and the microphone (`bInterfaceClass 1 Audio`). Passing `1e4f:0806` gives the Windows VM access to the full scanner. *(If a separate foot pedal or device appears with a different ID, note its `<vendor>:<product>` pair for Step 4.)*

---

## Step 2: Ensure Modular Sockets, `/var` Contexts, and the `default` Network Are Ready

Check the status of the `default` NAT network:

```bash
virsh net-list --all
```

If `default` is `inactive` (or if you haven't yet rebooted into an OS build with `virt*.socket` and `/usr/lib/tmpfiles.d/libvirt-swtpm.conf`), initialize the `/var` directories, SELinux contexts, modular sockets, and `default` network:

```bash
sudo mkdir -p /var/lib/libvirt/dnsmasq /var/lib/libvirt/images /var/lib/libvirt/swtpm /var/lib/swtpm-localca /var/log/libvirt /var/log/swtpm/libvirt/qemu
sudo chown -R tss:tss /var/lib/swtpm-localca /var/lib/libvirt/swtpm /var/log/swtpm
sudo chmod 0750 /var/lib/swtpm-localca
sudo restorecon -R -v /var/lib/swtpm-localca /var/lib/libvirt /var/log/libvirt /var/log/swtpm
sudo systemctl stop libvirtd.service libvirtd.socket 2>/dev/null
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket virtnodedevd.socket
sudo virsh net-start default
sudo virsh net-autostart default
```

---

## Step 3: Download the Windows 11 ISO

1. Download the official **Windows 11 Disk Image (ISO) for x64 devices** from Microsoft:
   <https://www.microsoft.com/software-download/windows11>
2. Move the ISO to `/var/lib/libvirt/images/` and run `restorecon` so SELinux updates its label from `user_home_t` to `virt_image_t` (otherwise QEMU cannot read it):
   ```bash
   sudo mv ~/Downloads/Win11_*_x64*.iso /var/lib/libvirt/images/Win11_x64.iso
   sudo restorecon -v /var/lib/libvirt/images/Win11_x64.iso
   ```

---

## Step 4: Create the Windows 11 VM with `virt-install`

Save the script below as `setup_scanner_vm.sh` (using `bus=sata` and `model=e1000e` so Windows 11 detects the disk and network natively without requiring a separate `virtio-win` driver ISO):

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
  --disk size="$DISK_SIZE",bus=sata,format=qcow2 \
  --network "$NETWORK",model=e1000e \
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
> **Foot pedal / extra USB devices:** If `lsusb` showed a separate Vendor:Product ID for an external trigger, add another `--hostdev <vid>:<pid>,type=usb` flag above, or attach it dynamically inside `virt-manager` via **Virtual Machine → Redirect USB device**.

---

## Step 5: Complete Windows 11 & CZUR Shine Software Setup

1. Open **Virtual Machine Manager** (`virt-manager`) from your desktop/terminal and open the console for **`czur-scanner-win11`**.
2. If you land in the **UEFI Boot Manager** menu (because the initial DVD boot prompt timed out), highlight the **DVD** entry (`UEFI QEMU DVD-ROM`), press **Enter**, and **immediately press Space or Enter again** when `"Press any key to boot from CD or DVD....."` appears.
3. Walk through the Windows 11 installer (you can click **"I don't have a product key"** at the activation screen and choose your edition).
4. Once logged in to Windows 11, download and install the **CZUR Shine** Windows software from the official download center:
   <https://www.czur.com/support>
5. Launch the CZUR Shine software—your scanner (`1e4f:0806`) will be passed directly to the VM whenever it is plugged in and powered on.

---

## Step 6: Sharing Scanned Files with the Linux Host

To move scanned PDFs and images seamlessly between the Windows VM and `brotherlogic-os`, use either approach:

### Option A: Shared Folder (`virtiofs`)
1. Create a scans directory on the host, e.g.:
   ```bash
   mkdir -p /var/home/simon/Scans
   ```
2. In `virt-manager`, click **View → Details**:
   - Under **Memory**, enable **Enable shared memory**.
   - Click **Add Hardware → Filesystem**, choose **Driver: `virtiofs`**, set **Source path** to `/var/home/simon/Scans`, and set **Target path** to `scans`.
3. Inside Windows, install `virtio-win` guest drivers and the `WinFsp` service so the `VirtIO-FS Service` mounts `scans` as a Windows drive letter, then configure CZUR Shine's output folder to save directly there.

### Option B: SPICE Guest Tools (Clipboard & Drag-and-Drop)
Install **`spice-guest-tools`** inside the Windows 11 VM to enable bidirectional clipboard sharing, automatic display resizing, and drag-and-drop file transfers straight to your host desktop.
