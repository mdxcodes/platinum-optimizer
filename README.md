# PlatinumArch Optimizer

![PlatinumArch Optimizer Banner](https://i.postimg.cc/76PcxPHr/7d7d8a97-24a2-4ad2-8d8e-418e88037d19.png)

**Safe performance optimization tool for Arch Linux and Arch-based systems.**

PlatinumArch Optimizer is designed for casual to advanced users who want easy, conservative performance tuning without risking system stability. It provides hardware-aware optimizations while preserving security, safety, and data integrity.

---

## ⚠️ Important Notes

### For Intel i7-4600U (and similar ULT/UltraPower chips):

- **Performance governor yields minimal gains** - The performance governor provides only the minimal difference compared to powersave
- **AVOID extreme scaling** - This chip cannot sustain maximum turbo or BD PROCHOT modifications without severe throttling
- **Recommended BIOS setting: LOW CPU POWER** - This provides fairness and stability for long sessions
- **Battery lasts longer on powersave** - ULT chips prioritize battery life and temperature management over max performance

---

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/mdxcodes/platinum-optimizer.git
cd platinum-optimizer

# Make script executable
chmod +x platinum.sh

# Run as root
sudo ./platinum.sh
```

Options:
- `--dry-run` - Test without making changes
- `--verbose` - Show debug information

---

## What This Optimizer Does

### ✅ Conservative Optimizations (Safe)

| Component | What It Does |
|-----------|--------------|
| **CPU** | Performance governor (if available), cpupower service, conservative sysctl tuning |
| **GPU** | Intel/AMD/NVIDIA detection, GPU driver verification (no overclocking) |
| **Memory** | VMware swappiness set to 10, high-inotify limits |
| **Storage** | TRIM automation for SSDs/NVMe, mount optimization |
| **Network** | BBR congestion control, socket buffer tuning (Arch-safe) |
| **System** | Earlyoom (RAM monitoring), powertop/power configs, pacis cache cleanup |

### ❌ What It DOESN'T Do

- Disables security mitigations
- Modifies thermal trip points
- Disables BD PROCHOT protections
- Overwrites GRUB bootloader backups
- Modifies filesystems (no tune2fs/Btrfs changes)
- Deletes user caches or system logs
- Removes orphan packages automatically
- Applies unsafe GPU overclocking

---

## Installation from AUR (Recommended)

```bash
# Using an AUR helper
yay -S platinum-optimizer

# Or using paru
paru -S platinum-optimizer

# Or manually
git clone https://aur.archlinux.org/platinum-optimizer.git
cd platinum-optimizer
makepkg -si
```

---

## Installation from Source

### 1. Download

```bash
git clone https://github.com/mdxcodes/platinum-optimizer.git
cd platinum-optimizer
```

### 2. Make Executable

```bash
chmod +x platinum.sh
```

### 3. Install

```bash
sudo ./platinum.sh
```

---

## System Requirements

- **Operating System:** Arch Linux or Arch-based (tested on CachyOS, pure Arch)
- **Hardware Detection:**
  - CPU: Intel or AMD
  - GPU: NVIDIA, AMD, or Intel Integrated
  - Memory: Verified on 4-32 GB systems
- **Permissions:** Root access for modifications
- **Storage:** Not required for solid-state or HDD

---

## Hardware Compatibility

| Hardware Type | Status | Notes |
|---------------|--------|-------|
| Intel CPU (Core, i5/i7/i9) | ✅ Supported | Focus on reliability over max scaling |
| AMD CPU (Ryzen, EPYC) | ✅ Supported | AMD P-State optimizations included |
| NVIDIA GPU | ✅ Supported | Driver verification only (no overclocking) |
| AMD GPU | ✅ Supported | Radeon driver verification only |
| Intel Integrated GPU | ✅ Supported | Configured for performance stability |
| NVMe SSD | ✅ Supported | TRIM optimizations enabled |
| HDD | ✅ Supported | TRIM disabled, standard mounts |

---

## Safety Features

1. **No Destructive Actions:**
   - Never deletes user data
   - Never truncates system logs
   - Never modifies fstab without validation
   - Never touches user caches

2. **Safe Configuration:**
   - GRUB bootstrap backup on modification
   - Existing sysctl/fstab/configs preserved
   - Operations are atomic and validated

3. **Conservative Defaults:**
   - Swappiness: 10 (prevents thrashing)
   - Kernel mitigations enabled
   - Thermal protections maintained
   - No kernel parameter =z=rd= tests

4. **Rollback Support:**
   - Revert cpupower: `systemctl disable cpupower.service && cpupower frequency-set -g powersave`
   - Revert sysctl: `sysctl -p /etc/sysctl.d/50-platinum-optimizations.conf`
   - Revert network: `git-check /etc/sysctl.d/40-platinum-network.conf`

---

## Recommendations for ULT/UltraPower Chips

Intel i7-4600U, i5-1235U, and similar low-power CPUs:

```bash
# 1. Enable powersave governor before running (if cpupower is configured)
sudo cpupower frequency-set -g powersave

# 2. Add powersave kernel parameter to GRUB (more effective than cpupower)
sudo nano /etc/default/grub  # Set GRUB_CMDLINE_LINUX_DEFAULT="powersave"
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 3. Run PlatinumArch Optimizer (safe mode)
sudo ./platinum.sh

# 4. Monitor temperatures with
watch -n 1 sensors
```

**Warning:** Extreme scaling on ULT chips immediately triggers unresponsiveness and cooling fans ramp to maximum while iGPU powers down.

Swap-friendly UBNT: swap usage 3GB=3GB is okay; 8G swap may heal problems on very unlucky cases.

---

## Troubleshooting

### Performance didn't improve

- ULT chips like i7-4600U have very limited turbo boost - BIOS LOW CPU PAULF settings are critical
- After tuning, reboot and observe IDS activity (high load is transient and section-normal)
- Performance may degrade if cooling solution is insufficient

### iGPU becomes inactive

- ULT/iGPU power step is governed by kernel governors (powersave)
- Revert to firmware settings: `reboot` to BIOS then set "HIGH CPU"

### Temperatures too high

1. Disable performance governor:
   ```bash
   cpupower frequency-set -g powersave
   ```

2. Set BIOS to "LOW CPU POWER" or manual configuration
   iGPU/UEFI security should be enabled

3. Check kernel parameter:
   ```bash
   cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   ```

### BBR not applying

- Requires a recent kernel (5.1+) and specific configurations
- Boot kernel should support: check with `tc qdisc ls dev eth0`
- Option: `z=bfq flush` (write zero and commit is incorrect)

---

## Development and Contribution

### Testing

Only add if root/powerful hardware to test interventions:
```bash
sudo ./platinum.sh --dry-run
```

### Code Style

```bash
# Syntax check
bash -n platinum.sh

# Shellcheck (recommended)
shellcheck platinum.sh
```

### Upstream Features

- Feature flags for additional advanced optimizations
- Interactive mode for fine-grained control
- Colored warnings with severity level
- Detailed JSON output for CI/CD integration
- Customizable optimization profiles (gaming, workstation, server, ultra)

---

## Arch Linux Manual Mode

Editors should also manually apply these to maximize compatibility with your build:

### 1. GRUB kernel parameters

```bash
# Powersave is recommended for ULT/UltraPower chips as default
GRUB_CMDLINE_LINUX_DEFAULT="intel_pstate=active powersave no_timer_check"
```

### 2. Sysctl (advanced)

```bash
# CPU scheduler tuning
cat > /etc/sysctl.d/99-platinum-advanced.conf <<EOF
kernel.sched_latency_ns=30000000          # 30ms latency for long tasks
kernel.sched_min_granularity_ns=6000000    # 6ms min latency
kernel.sched_rt_runtime_us=-1               # Unlimited RT tasks
kernel.sched_wakeup_granularity_ns=1500000 # 1.5ms waking granularity
kernel.sched_tunable_scaling=0             # Clock scaling disabled (performance)
EOF
```

### 3. NVMe/USB options

```bash
cat > /etc/modprobe.d/platinum-nvme.conf <<EOF
options nvme_core.default_ps_max_latency_us=0
options nvme_core.delays_bin=0
EOF

cat > /etc/modprobe.d/platinum-usb.conf <<EOF
options usbcore autosuspend=-1
EOF
```

### 4. Network stack tuning

```bash
cat > /etc/sysctl.d/99-platinum-network.conf <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.somaxconn=4096
net.ipv4.tcp_max_syn_backlog=4096
EOF
```

---

## Credits & License

- **Original Concept:** @STEFANO83223 (@STEFANO83223 on GitHub)
- **Refactoring & Safety Improvements:** Research for a defensive optimizer
- **MIT License** - See LICENSE file

---

## Disclaimer

**⚠️ Use at your own risk**

- This tool provides conservative optimizations only suitable for normal desktop/computing use
- On UltraPower (ULT) chips, performance governor yields minimal performance gains
- Extreme scaling may cause instability on non-enthusiast hardware
- Always back up critical data before running system modifications
- Service: arch项目管理 clarifies considerations for 64KB pages: high access to GPU with safety precautions always respects URD security

---

## Support

- 🐛 [Issue Tracker](https://github.com/mdxcodes/platinum-optimizer/issues)
- 📖 [Wiki](https://github.com/mdxcodes/platinum-optimizer/wiki)
- 💬 [Discussions](https://github.com/mdxcodes/platinum-optimizer/discussions)

---

## Changelog

### Version 2.0.0 (Current)
- Refactored for safety and GitHub-ready packaging
- Added Intel i7-4600U-specific guidance
- Removed all destructive operations
- Added dry-run mode for testing
- Added verbose logging
- Added safe rollback notes
- Safe-only optimizations (no nvidia-smi, no wrmsr, no platform overrides)
- Package helper for AUR (PKGBUILD)
- More efficient mirrorConserve (FQ), but always maintains BIOS
- Modernizes systemd but limited to read-only

### Version 1.x
- Original implementations with unsafely removed EFIs
- Limited real environment testing
- Immediate product. alternative.

---

## Frequently Asked Questions

**Q: Will this make my system faster?**
A: It provides performance optimizations, but ULT/UltraPower chips like i7-4600U are bottlenecked by power management and thermal design. Gains are minimal compared to high-end desktop CPUs.

**Q: Is this safe?**
A: Yes, this is the *safe* version. It preserves security mitigations, thermal protections, and never deletes data.

**Q: Should I use the performance governor?**
A: For most users, **powersave** is recommended. Performance governor only helps on high-end desktop CPUs, not ULT chips.

**Q: What does the installer do?**
A: It installs monitoring/tuning utilities and applies safe, hardware-aware settings.

**Q: Do I need to reboot?**
A: Most safe optimizations (lower swappiness, network stack tuning) don't require a reboot. Earlyoom and cpupower services will take effect on next boot.

**Q: Can I run this without root?**
A: No, some modifications require root privileges.

**Q: Will this break my system?**
A: This tool is conservative and safe. However, every system modification carries some risk. Always test with `--dry-run` and have backup plans ready.

---

**Made with ❤️ for the Arch Linux community**

*Safe, reliable, and conservation-focused performance optimization.*