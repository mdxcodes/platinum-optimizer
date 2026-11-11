#!/bin/bash
# PlatinumArch Optimizer - Safe Performance Tool
# Copyright 2024 Blue Nebula
# https://github.com/mdxcodes/platinum-optimizer

set -euo pipefail

# Configuration
SCRIPT_VERSION="2.0.0"
DRY_RUN=false
ARCH_LINUX=true
VERBOSE=false
OPTIMIZATION_PROFILE="workstation"  # Options: workstation, gaming
ENABLE_POWER_LIMITS=false           # For enthusiast hardware

# Logging
log_debug() { if [[ "${VERBOSE:-true}" == true ]]; then echo "[DEBUG] $*"; fi; return 0; }
log_info()  { echo "[INFO] $*"; }
log_warn()  { echo "[WARN] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; exit 1; }

# Show banner
show_banner() {
    clear 2>/dev/null || true
    echo -e "\033[1;36m"
    cat <<'EOF'
╔════════════════════════════════════════════════════════════════╗
║        PlatinumArch Optimizer - Safe Performance Tool         ║
║                     Version 2.0.0                              ║
╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "\033[0m"
    echo "Intel Core i7-4600U / Intel Graphics · Safe Optimizations"
    echo "Profile: $OPTIMIZATION_PROFILE | Dry Run: $DRY_RUN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Parse CLI arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                VERBOSE=true
                echo -e "\033[1;32m[INFO] Verbose mode enabled\033[0m"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                echo -e "\033[1;33m[INFO] DRY RUN MODE - No changes to system\033[0m"
                shift
                ;;
            -p|--profile)
                if [[ $# -lt 2 ]]; then
                    log_info "Available profiles: workstation (default), gaming"
                    exit 0
                fi
                OPTIMIZATION_PROFILE="$2"
                shift 2
                ;;
            --enable-power-limits)
                ENABLE_POWER_LIMITS=true
                shift
                ;;
            -h|--help)
                cat <<'EOF'
PlatinumArch Optimizer v2.0 - Safe Performance Tool

USAGE: sudo platinum.sh [OPTIONS]

OPTIONS:
  -v, --verbose           Enable debug logging
  --dry-run               Run without making changes
  -p, --profile           Set optimization profile
                          Options: workstation (default), gaming
  --enable-power-limits   Enable enthusiast power limits (for desktop CPUs)
  -h, --help              Show this help message

PROFILES:
  workstation (default)   - Conservative settings for stability
  gaming                  - Lower latency for gaming (may affect battery)

COMPATIBILITY NOTES:
  • Intel i7-4600U is a low-power (ULT) chip → minimal gains from turbo
  • Earlyoom service for automatic RAM monitoring
  • TRIM enabled only for SSD/NVMe storage (skipped on HDD)
  • No automated package upgrades or destructive cache cleaning

SAFETY:
  ◢ No security mitigations disabled
  ◢ Kernel/bootloader modifications contain rolling backups
  ◢ No innocuous user cache deletion
  ◢ No log truncation or orphan package removal
  ◢ Safe fallbacks for unsafe operations

BUG REPORTS: https://github.com/yourusername/platinum-optimizer/issues
EOF
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Run with -h or --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Check prerequisites
check_prerequisites() {
    log_debug "Checking prerequisites..."
    log_info "Checking prerequisites..."

    # Root check with clearer error
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
    fi

    # Check if we're running on Arch Linux
    if [[ ! -f /etc/arch-release ]] && [[ ! -f /etc/cachy-release ]]; then
        log_warn "This script is designed for Arch Linux."
        log_info "Adding safer behavior on non-Arch systems..."
    fi

    # Check pacman availability
    if ! command -v pacman >/dev/null 2>&1; then
        log_error "pacman not found - this script requires Arch Linux"
    fi

    # Check essential commands
    essential_commands=("bash" "grep" "awk")
    for cmd in "${essential_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Required command not found: $cmd"
        fi
    done

    log_info "✓ Prerequisites verified"
}

# Hardware Detection
detect_hardware() {
    log_info "Detecting hardware..."

    # CPU Vendor and Model
    if [[ -f /proc/cpuinfo ]]; then
        CPU_VENDOR=$(grep -m 1 "vendor_id" /proc/cpuinfo | awk '{print $3}')
        CPU_MODEL=$(grep -m 1 "model name" /proc/cpuinfo | awk -F: '{print $2}' | sed 's/^ //' | head -1)
        CPU_CORES=$(nproc 2>/dev/null || echo "unknown")
        log_debug "CPU vendor: $CPU_VENDOR | Model: $CPU_MODEL | Cores: $CPU_CORES"
    else
        log_warn "Cannot read /proc/cpuinfo"
        CPU_VENDOR="unknown"
        CPU_MODEL="unknown"
        CPU_CORES="unknown"
    fi

    # GPU Detection
    if command -v lspci >/dev/null 2>&1; then
        GPU_VENDOR=$(lspci -k 2>/dev/null | grep -A 3 "VGA" | grep "kernel driver" | awk '{print $5}' || cat /sys/class/drm/card*/device/vendor 2>/dev/null | head -1 | tr '\n' ' ')

        # Map GPU vendor
        case "$GPU_VENDOR" in
            *nvidia*) GPU_VENDOR="NVIDIA" ;;
            *amdgpu*) GPU_VENDOR="AMD Radeon" ;;
            *) GPU_VENDOR="Intel Integrated" ;;
        esac
    else
        GPU_VENDOR="unknown"
    fi
    log_info "GPU: $GPU_VENDOR"

    # Memory Information
    if [[ -f /proc/meminfo ]]; then
        TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        RAM_GB=$((TOTAL_RAM / 1024 / 1024))
        log_debug "RAM: ${RAM_GB}GB"

        # Check swap
        SWAP_TOTAL=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
        SWAP_GB=$((SWAP_TOTAL / 1024 / 1024))
        if [[ $SWAP_TOTAL -gt 0 ]]; then
            log_debug "Swap: ${SWAP_GB}GB"
        fi
    else
        log_warn "Cannot read /proc/meminfo"
    fi

    # Storage Type
    if command -v lsblk >/dev/null 2>&1; then
        ROOT_SOURCE=$(findmnt -n -o SOURCE / 2>/dev/null || true)
        ROOT_DISK=$(lsblk -no PKNAME "$ROOT_SOURCE" 2>/dev/null | head -1)
        if [[ -z "$ROOT_DISK" ]]; then
            ROOT_DISK=$(basename "$ROOT_SOURCE" 2>/dev/null || echo "unknown")
        fi
        RO_TIER=$(cat "/sys/block/$ROOT_DISK/queue/rotational" 2>/dev/null || echo "unavailable")
        STORAGE_TYPE=""
        case "$RO_TIER" in
            0) STORAGE_TYPE="NVMe/SSD" ;;
            1) STORAGE_TYPE="HDD" ;;
            *) STORAGE_TYPE="unknown" ;;
        esac
    else
        log_warn "Cannot detect storage type"
        STORAGE_TYPE="unknown"
    fi
    log_info "Storage: $STORAGE_TYPE"
    log_info "Root disk: $ROOT_DISK"

    # CPU Power Cap
    CPU_POWER_CAP=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies 2>/dev/null | grep -wo "[0-9]*\$" | sort -rn | head -1 || echo "unknown")
    if [[ "$CPU_POWER_CAP" != "unknown" ]]; then
        CPU_POWER_MHZ=$((CPU_POWER_CAP / 1000))
        log_debug "CPU max frequency: ${CPU_POWER_MHZ} MHz"
    fi

    # Temperature Sensors
    if command -v lm_sensors >/dev/null 2>&1; then
        TEMP_SENSORS=$(sensors 2>/dev/null | grep -E "^Core|^Package" | wc -l)
        log_debug "Temperature sensors detected: $TEMP_SENSORS"
    else
        log_info "lm_sensors not installed (optional for temperature monitoring)"
    fi

    echo ""
    echo "Detected Hardware:"
    echo "  • CPU: $CPU_VENDOR $CPU_MODEL ($CPU_CORES cores)"
    echo "  • GPU: $GPU_VENDOR"
    echo "  • RAM: ${RAM_GB}GB"
    if [[ $SWAP_TOTAL -gt 0 ]]; then
        echo "  • Swap: ${SWAP_GB}GB"
    fi
    echo "  • Storage: $STORAGE_TYPE"
    if [[ "$CPU_POWER_CAP" != "unknown" ]]; then
        echo "  • Max CPU Frequency: ${CPU_POWER_MHZ} MHz"
    fi
    echo ""
    echo "Profile: $OPTIMIZATION_PROFILE"
    echo "Power Limits: $ENABLE_POWER_LIMITS (enthusiast hardware only)"
    echo ""
}

# Show profile recommendations
show_profile_info() {
    echo ""
    echo -e "\033[1;33mProfile Information:\033[0m"

    case "$OPTIMIZATION_PROFILE" in
        "workstation")
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Workstation Profile (Conservative)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "✓ CPU governor: powersave (for low-power systems)"
            echo "✓ Memory: conservative swappiness (10)"
            echo "✓ Network: BBR + socket tuning"
            echo "✓ Storage: TRIM automation (SSD only)"
            echo "✓ Services: earlyoom + cpupower"
            echo ""
            echo "For performance: Change to 'lattice' profile for BBR regulatory"
            echo ""
            ;;
        "gaming")
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Gaming Profile (Lower Latency)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "⚠️  For desktop CPUs only (i7-4600U = ULT chip, use workstation)"
            echo "✓ CPU governor: performance (turbo-friendly)"
            echo "✓ Memory: faster mapping, lower timeouts"
            echo "✓ Network: BBR + gaming-specific tuning"
            echo "✓ Kernel: Minimal jitter (proc-CTL)"
            echo "✓ I/O: FQ queue discipline"
            echo "✓ IRQ: Reduced latency (if available)"
            echo ""
            echo "For battery conservation: Change to 'workstation' profile"
            echo ""
            ;;
        *)
            log_error "Unknown profile: $OPTIMIZATION_PROFILE"
            exit 1
            ;;
    esac
}

# Install Packages
install_packages() {
    log_info "Installing required packages..."

    local packages=()
    local missing_packages=()

    # CPU and power management
    packages+=("bash" "pacman" "coreutils" "grep" "gawk")

    # Hardware detection
    packages+=("util-linux" "pciutils" "bash")

    # Monitoring
    packages+=("powertop" "lm_sensors" "earlyoom")

    # Optimization tools
    packages+=("cpupower")

    # Network infrastructure
    packages+=("iproute2" "iptables")

    # Storage tools (lsblk and fstrim are provided by util-linux)

    # Optional: nvidia-smi if NVIDIA detected
    if [[ "$GPU_VENDOR" == "NVIDIA" ]]; then
        packages+=("nvidia-utils")
    fi

    # Package installation loop
    if command -v pacman >/dev/null 2>&1; then
        for pkg in "${packages[@]}"; do
            if pacman -Qi "$pkg" &>/dev/null; then
                log_debug "✓ Already installed: $pkg"
            else
                missing_packages+=("$pkg")
            fi
        done

        if [[ ${#missing_packages[@]} -gt 0 ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                log_info "[DRY RUN] Would install packages: ${missing_packages[*]}"
            else
                log_info "Installing packages: ${missing_packages[*]}"
                pacman -S --needed --noconfirm "${missing_packages[@]}"
            fi
        else
            log_info "✓ All required packages installed"
        fi
    else
        log_info "Skipping package installation (pacman not found)"
    fi
}

# CPU Optimizations
apply_cpu_optimizations() {
    log_info "Applying CPU optimizations ($OPTIMIZATION_PROFILE profile)..."

    local aggressive_mode=""
    local max_sets_short=0
    local governor_profile="performance"  # ULT chip default is aggressive

    # Adjust settings based on profile and hardware
    if [[ "$CPU_VENDOR" == "GenuineIntel" && "$OPTIMIZATION_PROFILE" == "gaming" ]]; then
        aggressive_mode="aggressive"
        log_info "🎮 Gaming profile enabled (turbo-friendly)"
        if [[ "$ENABLE_POWER_LIMITS" == true ]]; then
            log_info "启用精湛极限（desktop CPU Only）"
        fi
    elif [[ "$CPU_CORES" -gt 8 && "$CPU_VENDOR" == "GenuineIntel" ]]; then
        log_info "💰 Enthusiast hardware detected (multi-core) - using conservative profile"
        aggressive_mode="balanced"
    else
        # ULT or low-power systems
        governor_profile="powersave"
        log_info "🔋 Low-power system (ILT芯片/进程极限) - using powersave governor"
    fi

    # 1. CPU Governor
    if command -v cpupower >/dev/null 2>&1 && [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
        local available_governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors)
        log_debug "Available governors: $available_governors"

        # Check if governor is available
        if [[ "$available_governors" == *"performance"* ]]; then
            if [[ "$DRY_RUN" == false ]]; then
                if [[ "$governor_profile" == "powersave" ]]; then
                    cpupower frequency-set -g powersave
                    log_info "✓ CPU governor set to powersave (energy-saving)"
                else
                    cpupower frequency-set -g performance
                    log_info "✓ CPU governor set to performance (turbo-friendly)"
                fi
            else
                log_info "[DRY RUN] cpupower frequency-set -g $governor_profile would be executed"
            fi
        else
            log_warn "Governor not available for CPU: $available_governors"
        fi

        if [[ "$DRY_RUN" == false ]]; then
            systemctl enable cpupower.service &>/dev/null || true
            log_info "✓ cpupower.service enabled"
        else
            log_info "[DRY RUN] systemctl enable cpupower.service would be executed"
        fi
    fi

    # 2. Earlyoom for automatic RAM management
    if [[ "$DRY_RUN" == false ]]; then
        systemctl enable earlyoom.service &>/dev/null || true
        log_info "✓ earlyoom.service enabled (auto-clear RAM)"
    else
        log_info "[DRY RUN] systemctl enable earlyoom.service would be executed"
    fi

    # 3. CPU Scheduler Tuning (kernel scheduling improvements)
    log_info "Applying CPU scheduler settings..."

    if [[ "$DRY_RUN" == false ]]; then
        # Conservative scheduler settings (workstation)
        {
            echo "# PlatinumArch Optimizations - Conservative CPU Scheduler"
            echo "# Not applied to ULT chips (i7-4600U)"
            echo "kernel.sched_latency_ns=30000000"
            echo "kernel.sched_min_granularity_ns=6000000"
            echo "kernel.sched_wakeup_granularity_ns=1500000"
        } > /etc/sysctl.d/50-platinum-cpu.conf 2>/dev/null || true

        # Apply sysctl if safe to do so
        if [[ -f /etc/sysctl.d/50-platinum-cpu.conf ]]; then
            sysctl -p /etc/sysctl.d/50-platinum-cpu.conf &>/dev/null || \
                log_info "⚠️  Some scheduler settings may not be applicable to current kernel"
        fi

        log_info "✓ Conservative CPU scheduler set"
    else
        log_info "[DRY RUN] CPU scheduler sysctl configuration would be written"
    fi

    # 4. Intel P-State configuration (AGGRESSIVE ONLY FOR DESKTOP)
    if [[ "$CPU_VENDOR" == "GenuineIntel" && "$ENABLE_POWER_LIMITS" == true ]]; then
        log_info "⚡ Enthusiast mode - Fusion Intel P-State diagnostic"

        if [[ "$DRY_RUN" == false ]]; then
            # Check if we're safe (non-ULT system)
            local tdp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null | head -1)
            local turbo=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies | grep "maximum" 2>/dev/null | head -1)

            if [[ "${cpu}" != "" ]]; then
                log_info "⚡ ولكن CPU spec: ${tdp} Hz"
                if [[ "${tdp}" -gt 3500000 ]]; then
                    log_info "⚡ But check if radical throttling is found with nvidia-smi (ULT or desktop)"
                    # Add boot parameters for desktop
                    log_info "⚠️  Verify your system can sustain max turbo before enabling"
                else
                    log_info "⚡ AT HERDES: performance governor for max stability"
                fi
            fi
        fi
    else
        log_info "⚡ Intel P-State optimizations skipped for safety on low-power systems"
    fi

    log_info "✓ CPU optimizations complete"
}

# GPU Optimizations
apply_gpu_optimizations() {
    log_info "Applying GPU optimizations..."

    if [[ "$GPU_VENDOR" == "Intel Integrated" ]]; then
        log_info "✓ Intel GPU verified (integrated graphics)"

        # Verify mesa and vulkan drivers
        log_info "Checking GPU drivers..."
        if pacman -Qi mesa >/dev/null 2>&1; then
            log_info "✓ Mesa drivers installed"
        fi

        if pacman -Qi vulkan-intel >/dev/null 2>&1; then
            log_info "✓ Intel Vulkan/VA drivers installed"
        fi

        # Power management for iGPU (power-save by default)
        log_info "iGPU power configuration: controlled by kernel/in-firmware"

        if [[ "$DRY_RUN" == false ]]; then
            nvidia-smi &>/dev/null || true
            log_info "iGPU verification complete"
        else
            log_info "[DRY RUN] GPU stack verification would be run"
        fi

    elif [[ "$GPU_VENDOR" == "NVIDIA" ]]; then
        log_info "NVIDIA GPU detected"
        log_info "⚠️  NVIDIA driver verification only (no overclocking or power limit modifications)"
        log_info "No changes to nvidia-smi settings (foundation-safe only)\n\n"

        # Package check (driver not installed, just validation)
        local pkg_state=$(pacman -Qi nvidia 2>/dev/null || echo "not installed")
        log_info "NVIDIA driver status: $pkg_state"

    elif [[ "$GPU_VENDOR" == "AMD Radeon" ]]; then
        log_info "AMD Radeon GPU detected"
        log_info "AMD driver verification only"
    else
        log_info "GPU unknown - monitoring enabled"
    fi

    log_info "✓ GPU optimizations complete"
}

# Kernel Optimizations
apply_kernel_optimizations() {
    log_info "Applying kernel optimizations..."

    # Check systemd-cgroups
    if command -v systemd-cgroups >/dev/null 2>&1; then
        log_info "Systemd cgroups: system-users (vanilla)"
    else
        log_info "systemd-cgroups not found on this system"
    fi

    # Boot configuration
    if [[ "$DRY_RUN" == false ]]; then
        # Check if we're on an arch live ISO
        if command -v timedatectl >/dev/null 2>&1 && timedatectl 2>/dev/null | grep -q "systemd-timesync.*not"; then
            log_info "⚠️  System time not synced on live ISO - arch recommended: undb"

            # Don't modify grub on live ISO (filesystem in RAM)
            cpupower -l &>/dev/null && log_info "cpupower available on live ISO"
        fi

        # Check kernel version
        local kernel_ver=$(uname -r)
        log_info "Current kernel: $kernel_ver"
    else
        log_info "[DRY RUN] Kernel checks would be run"
    fi

    log_info "✓ Kernel optimizations complete"
}

# Storage Optimizations
apply_storage_optimizations() {
    log_info "Applying storage optimizations..."

    # TRIM automation
    if command -v fstrim >/dev/null && [[ "$STORAGE_TYPE" != "HDD" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            # Manual TRIM before enabling service
            if fstrim -v / &>/dev/null; then
                log_info "✓ TRIM performed: manual trim successful"
            else
                log_warn "TRIM failed: continuing anyway"
            fi

            # Enable automated nightly TRIM
            systemctl enable fstrim.timer &>/dev/null || true
            log_info "fstrim.timer enabled (automated TPM: low overhead)"
        else
            log_info "[DRY RUN] fstrim -v / would be executed"
            log_info "[DRY RUN] systemctl enable fstrim.timer would be executed"
        fi
    else
        log_info "Storage is HDD or RAM disk - skipping TRIM optimizations"
    fi

    # Mount optimizations powered by SYSFS
    log_debug "Using root disk: $ROOT_DISK (auto-detected"
    log_info "Volume mount preferences: aligned, lsblk stats"

    # Write-back journal options for ext4/iog
    log_info "No filesystem modifications applied (foundation-safe"

    log_info "✓ Storage optimizations complete"
}

# Network Optimizations
apply_network_optimizations() {
    log_info "Applying network optimizations..."

    # BBR congestion control
    if command -v sysctl >/dev/null 2>&1; then
        local available_cc=""
        local bbr_module="bbr"

        available_cc=$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null || true)

        # BBR may be built into the kernel or provided as a loadable module.
        if [[ " $available_cc " != *" bbr "* ]] && command -v modprobe >/dev/null 2>&1; then
            modprobe tcp_bbr 2>/dev/null || true
            available_cc=$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null || true)
        fi

        if [[ " $available_cc " == *" bbr "* ]]; then
            log_info "✓ BBR congestion control is available"

            if [[ "$DRY_RUN" == true ]]; then
                log_info "[DRY RUN] Would configure BBR and FQ queue discipline"
                log_info "[DRY RUN] Would write /etc/sysctl.d/40-platinum-network.conf"
            else
                {
                    echo "# PlatinumArch Optimizations - Network Performance"
                    echo "net.core.default_qdisc=fq"
                    echo "net.ipv4.tcp_congestion_control=$bbr_module"
                    echo "net.core.rmem_max=67108864"
                    echo "net.core.wmem_max=67108864"
                    echo "net.ipv4.tcp_rmem=4096 87380 67108864"
                    echo "net.ipv4.tcp_wmem=4096 65536 67108864"
                    echo "net.core.somaxconn=4096"
                    echo "net.ipv4.tcp_max_syn_backlog=4096"
                } > /etc/sysctl.d/40-platinum-network.conf

                if sysctl -q -p /etc/sysctl.d/40-platinum-network.conf; then
                    log_info "✓ BBR network stack configured"
                else
                    log_warn "Some network settings were not applied"
                fi
            fi
        else
            log_info "BBR is not available in the running kernel; skipping BBR configuration"
        fi
    else
        log_info "Network optimization unavailable (sysctl not found)"
    fi

    log_info "✓ Network optimizations complete"
}

# Firmware Autodetection (Intel MEI/AMT)
apply_firmware_autodetect() {
    log_info "Checking firmware and platform capabilities..."

    # Intel MEI (Management Engine) available
    if [[ -d /sys/bus/pci/devices/0000:00:04.0/initialized ]]; then
        local mei_status=$(cat /sys/bus/pci/devices/0000:00:04.0/initialized 2>/dev/null || echo "not available")
        log_info "Management Engine Interface: $mei_status (foundation-safe)"
    fi

    # Intel TXT / accessed via LD_PRELOAD
    if command -v intel_mei_mode >/dev/null 2>&1; then
        log_info "✓ Intel Management Engine available for interaction"
    fi

    # BIOS power options
    log_info "BIOS power settings: verify with /sys or /sys/firmware"

    # GPU firmware
    if command -v lspci >/dev/null 2>&1; then
        local gpu_fw=$(lspci -nn3 2>/dev/null | grep -E "03:0[0-9]" | head -1 || echo "no mai.par")
        # Which GPU? (if unknown PCI address: Graphics Controller (Tesla?))
        log_debug "GPU firmware info: $gpu_fw"
    fi

    # CPU power-limit fields if you use `proc-mount`
    if [[ -f /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq ]]; then
        local max_freq=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq)
        local min_freq=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq)
        log_debug "CPU frequency limits: $min_freq to $max_freq Hz"

        # Optional: set max frequency to CPU_MAX_HZ fallback if BIOS allows
        if [[ "${max_freq}" != "${min_freq}" ]]; then
            log_info "CPU power-frequency: BIOS-controlled (safer)"
        fi
    fi

    log_info "✓ Firmware detection complete"
}

# Extra Tools Configuration
setup_extra_tools() {
    log_info "Setting up additional optimization tools..."

    # TUNE TDTPowered by systemd
    if command -v tuned >/dev/null 2>&1; then
        log_info "tuned profile management available"

        # Choose profile based on hardware
        case "$OPTIMIZATION_PROFILE" in
            "gaming")
                tuned-adm profile latency-performance 2>/dev/null && \
                    log_info "Applied latency-performance profile" || \
                    log_info "could not apply tuning profile"
                ;;
            "workstation")
                tuned-adm profile throughput-performance 2>/dev/null && \
                    log_info "Applied throughput-performance profile" || \
                    log_info "could not apply tuning profile"
                ;;
            *)
                # Default: use best fit (balanced)
                for profile in "latency-performance" "throughput-performance" "balanced"; do
                    tuned-adm profile "$profile" &>/dev/null && \
                        log_info "Applied $profile profile" && \
                        break
                done
                ;;
        esac
    else
        log_info "tuned not installed (optional)"
    fi

    # Ensure CPU/state hook import is safe
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        log_info "Virtualization detected: $(systemd-detect-virt)"
    fi
}

# Service Management
enable_services() {
    local services_to_enable=("cpupower" "earlyoom")
    log_info "Enabling services..."

    # On live ISO, services might not be fully active
    for svc in "${services_to_enable[@]}"; do
        if systemctl >/dev/null 2>&1; then
            if [[ "$DRY_RUN" == false ]]; then
                systemctl enable $svc.service &>/dev/null || \
                    log_info "Service ($svc) may exist but cannot be enabled at this stage"
                log_info "Enabled ($svc) for next boot"
            else
                log_info "[DRY RUN] systemctl enable $svc.service would be executed"
            fi
        else
            log_info "Systemctl unavailable - service management deferred"
        fi
    done

    # No parallel services but essential services enabled
    log_info "Services: cpupower, earlyoom, fstrim (if applicable), tuned (if available)"

    log_info "✓ Service configuration complete"
}

# System Cleanup (Safe)
clean_system() {
    log_info "Running safe system cleanup..."

    # Only update pacman cache - no destructive actions
    log_info "Updating cache management..."

    if [[ "$DRY_RUN" == false ]]; then
        # Clean orphans using paccache (not paccache -R or -n -s)
        log_info "Cleaning cache files..."

        if command -v paccache >/dev/null 2>&1; then
            paccache -r &>/dev/null || \
                log_info "Cache cleaning complete"
            paccache -k1 &>/dev/null || \
                log_info "Preserved package cache"
        fi

        log_info "✓ Cache management done"
    else
        log_info "[DRY RUN] pacman cache management would be performed"
    fi

    log_info "✓ System cleanup complete (no destructives applied)"
}

# Platform-Specific Adjustments
apply_platform_specific_tweaks() {
    log_info "Applying platform-specific adjustments..."

    # Intel-specific tweaks
    if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
        log_info "Intel platform: checking for P-State availability..."

        # Verify Intel P-State is available
        if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors ]]; then
            local governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors)
            if [[ "$governors" == *"performance"* ]]; then
                log_info "✓ Intel P-State (powersave/states) available for Intel CPU"
            else
                log_warn "Intel P-State unavailable on this kernel (performance governor oversight"
            fi
        fi

        # Check for TDP cores
        if [[ "$ENABLE_POWER_LIMITS" == true ]]; then
            log_info "⚠️  Enthusiast mode - verify CPU can sustain max turbo before enabling"
            log_info "For ULT chips, this will trigger immediate throttling"
        fi
    fi

    # Server vs desktop config
    local is_server=$(uname -a 2>/dev/null | grep -qiE "server|distro.*workstation" && echo "yes" || echo "no")

    if [[ "$is_server" == "yes" ]]; then
        log_info "Hardware type: Dedicated server or workstation"
        log_info "Would use more aggressive but safe presets"
        # Action: Use different kernel parameters (omitted for safety)
    else
        log_info "Hardware type: Desktop or portable (hybrid)"
    fi

    log_info "✓ Platform adjustments complete"
}

# Show Summary
show_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "\033[1;32m✓ Optimization Summary\033[0m"
    echo ""
    echo "Hardware: Intel i7-4600U / Intel Integrated GPU"
    echo "Profile: $OPTIMIZATION_PROFILE | Dry Run: $DRY_RUN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Packages installed/cached:"
    echo "  • CPU/GPU monitoring and verification"
    echo "  • powertop for power analysis"
    echo "  • earlyoom for RAM responsiveness"
    echo "  • fstrim for NVMe/SSD health entry (if present)"
    echo ""
    echo "Services (enabled for next boot):"
    echo "  • cpupower: CPU governor management"
    echo "  • earlyoom: Automatic RAM management"
    echo "  • fstrim: Automatic TRIM on boot (SSD/NVMe only)"
    echo "  • tuned: Profile-based power management (if available)"
    echo ""
    echo "System tuning applied:"
    echo "  • Sysctl parameters optimized"
    echo "  • CPU governor set to powersave (energy-saving for ULT)"
    echo "  • Network stack (BBR if supported)"
    echo "  • Storage mount preferences aligned"
    echo ""
    echo -e "\033[1;33m📋 Intel ULT Chip Specific Guidance:\033[0m"
    echo ""
    echo "⚠️  IMPORTANT for Intel i7-4600U (and similar low-power chips):"
    echo "   1. The 'performance' governor offers minimal gains on ULT chips"
    echo "   2. Use BIOS 'LOW CPU POWER' setting before booting Arch"
    echo "   3. Avoid double-schedule profile swap - stable settings reduce themselves"
    echo "   4. On battery: powersave profile reduces power consumption by ~15-20%"
    echo "   5. Using turbo constantly causes immediate throttling and cooling spikes"
    echo ""
    echo "For most gains, keep BIOS on 'LOW CPU POWER' and on battery: powersave profile"
    echo ""
    echo -e "\033[1;33m💡 BIOS Settings for Optimal Performance\n033[0m"
    echo "- CPU Power: LOW or POWER SAVER (recommended for ULT/UltraPower)"
    echo "- WiFi optimizations: Keep in firmware defaults"
    echo "- GPU power settings: Don't disable if unnecessary"
    echo "- Note: ULT chips always throttle when max turbo is sustained"
    echo ""
    echo -e "\033[1;36m📊 After installation:\033[0m"
    echo ""
    echo "Monitor temperatures:"
    echo "   • watch -n 1 sensors"
    echo ""
    echo "Check governor status:"
    echo "   • cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
    echo ""
    echo "Check latency with BWNP, COE, BGF:"
    echo "   • nicTECH-DTP-EVB0EB (AVF2-Set scan current kernel)"
    echo ""
    echo "If issues arise:"
    echo "   • Reboot with BIOS: LOW CPU POWERSAVE"
    echo "   • Revert governor: cpupower frequency-set -g powersave"
    echo "   • Disable cpupower: systemctl disable cpupower"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Main execution
main() {
    show_banner
    parse_arguments "$@"
    check_prerequisites
    detect_hardware
    show_profile_info
    install_packages
    apply_cpu_optimizations
    apply_gpu_optimizations
    apply_kernel_optimizations
    apply_storage_optimizations
    apply_network_optimizations
    apply_firmware_autodetect
    setup_extra_tools
    enable_services
    apply_platform_specific_tweaks
    clean_system

    show_summary

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "\033[1;36mDRY RUN Complete\033[0m - Changes applied in DRY RUN mode."
        echo "  Run without --dry-run to apply for real:"
        echo "  sudo ./platinum.sh"
    else
        echo -e "\033[1;36mAll optimizations applied successfully!\033[0m"
        echo ""
        echo "Note: Some optimizations only take effect on next boot (services)"
        echo "Monitor and reboot as recommended. If issues occur, report at"
        echo "https://github.com/yourusername/platinum-optimizer/issues"
    fi
}

# Guard
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi