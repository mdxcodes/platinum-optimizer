#!/bin/bash
# Platinum Optimizer for Linux By @STEFANO83223
# Script completo di ottimizzazioni per CPU, GPU, Kernel e sistema
# Versione ottimizzata per Arch Linux con modalità ESTREMA

# Controllo root
if [ "$EUID" -ne 0 ]; then
    echo "Esegui come root o con sudo"
    exit 1
fi

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variabile per modalità ESTREMA
EXTREME_MODE=false

# Funzioni di logging
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_platinum() {
    echo -e "${PURPLE}[PLATINUM]${NC} $1"
}

log_extreme() {
    echo -e "${RED}[ESTREMA]${NC} $1"
}

# Banner PLATINUM+ OPTIMIZER
show_banner() {
    clear
    echo -e "${RED}"
    echo '██████╗ ██╗      █████╗ ████████╗██╗███╗   ██╗██╗   ██╗███╗   ███╗       █████╗ ██████╗  ██████╗██╗  ██╗'
    echo '██╔══██╗██║     ██╔══██╗╚══██╔══╝██║████╗  ██║██║   ██║████╗ ████║      ██╔══██╗██╔══██╗██╔════╝██║  ██║'
    echo '██████╔╝██║     ███████║   ██║   ██║██╔██╗ ██║██║   ██║██╔████╔██║█████╗███████║██████╔╝██║     ███████║'
    echo '██╔═══╝ ██║     ██╔══██║   ██║   ██║██║╚██╗██║██║   ██║██║╚██╔╝██║╚════╝██╔══██║██╔══██╗██║     ██╔══██║'
    echo '██║     ███████╗██║  ██║   ██║   ██║██║ ╚████║╚██████╔╝██║ ╚═╝ ██║      ██║  ██║██║  ██║╚██████╗██║  ██║'
    echo '╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝      ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝'
    echo
    echo '                    ██████╗ ██████╗ ████████╗██╗███╗   ███╗██╗███████╗███████╗██████╗'
    echo '                   ██╔═══██╗██╔══██╗╚══██╔══╝██║████╗ ████║██║╚══███╔╝██╔════╝██╔══██╗'
    echo '                   ██║   ██║██████╔╝   ██║   ██║██╔████╔██║██║  ███╔╝ █████╗  ██████╔╝'
    echo '                   ██║   ██║██╔═══╝    ██║   ██║██║╚██╔╝██║██║ ███╔╝  ██╔══╝  ██╔══██╗'
    echo '                   ╚██████╔╝██║        ██║   ██║██║ ╚═╝ ██║██║███████╗███████╗██║  ██║'
    echo '                    ╚═════╝ ╚═╝        ╚═╝   ╚═╝╚═╝     ╚═╝╚═╝╚══════╝╚══════╝╚═╝  ╚═╝'
    echo
    echo -e "${CYAN}                           The ultimate Arch Linux and Arch-based gaming optimizer          ${NC}"
    echo -e "${CYAN}              =============================  By @STEFANO83223  =============================${NC}"
    echo
}

# Aggiornamento sistema e installazione pacchetti
update_system() {
    log_platinum "Aggiornamento del sistema e installazione pacchetti necessari..."

    # Aggiornamento del sistema
    pacman -Syu --noconfirm

    # Installazione pacchetti base per ottimizzazioni
    local base_packages=(
        cpupower mesa vulkan-icd-loader libva-utils
        nvidia nvidia-utils nvidia-settings
        vulkan-radeon libva-mesa-driver mesa-vdpau
        vulkan-intel libva-intel-driver intel-media-driver
        tuned dmidecode lm_sensors powertop
        util-linux usbutils pciutils preload
        earlyoom linux-zen linux-zen-headers
        reflector irqbalance msr-tools
        thermald alsa-utils
    )

    pacman -S --needed --noconfirm "${base_packages[@]}"
}

# Rilevamento hardware
detect_hardware() {
    log_platinum "Rilevamento hardware..."

    # CPU
    CPU_VENDOR=$(grep -m 1 "vendor_id" /proc/cpuinfo | awk '{print $3}')
    CPU_MODEL=$(grep -m 1 "model name" /proc/cpuinfo | awk -F: '{print $2}' | sed 's/^ //')
    CPU_CORES=$(nproc)

    log_info "CPU: $CPU_VENDOR $CPU_MODEL ($CPU_CORES cores)"

    # GPU
    if lspci | grep -i "nvidia" > /dev/null; then
        GPU_VENDOR="NVIDIA"
        GPU_MODEL=$(lspci | grep -i "nvidia" | head -1 | cut -d ':' -f3 | sed 's/^ //')
    elif lspci | grep -i "amd" > /dev/null; then
        GPU_VENDOR="AMD"
        GPU_MODEL=$(lspci | grep -i "amd" | head -1 | cut -d ':' -f3 | sed 's/^ //')
    elif lspci | grep -i "intel" > /dev/null; then
        GPU_VENDOR="INTEL"
        GPU_MODEL=$(lspci | grep -i "intel" | grep -i "vga" | head -1 | cut -d ':' -f3 | sed 's/^ //')
    else
        GPU_VENDOR="UNKNOWN"
        GPU_MODEL="Sconosciuta"
    fi

    log_info "GPU: $GPU_VENDOR $GPU_MODEL"

    # RAM
    TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_GB=$((TOTAL_RAM / 1024 / 1024))
    log_info "RAM: ${TOTAL_RAM_GB}GB"

    # Storage (SSD/HDD)
    if lsblk -d -o rota | grep -q "0"; then
        STORAGE_TYPE="SSD"
    else
        STORAGE_TYPE="HDD"
    fi
    log_info "Storage: $STORAGE_TYPE"

    # Rilevamento disco root
    ROOT_DISK=$(findmnt -n -o SOURCE / | sed 's/[0-9]*$//' | xargs basename 2>/dev/null || echo "sda")
    log_info "Disco root: $ROOT_DISK"
}

# Installazione driver GPU specifici
install_gpu_drivers() {
    log_platinum "Installazione driver GPU per $GPU_VENDOR..."

    case "$GPU_VENDOR" in
        "NVIDIA")
            local nvidia_packages=(
                nvidia nvidia-utils nvidia-settings
                libva-vdpau-driver opencl-nvidia
            )
            pacman -S --needed --noconfirm "${nvidia_packages[@]}"

            # Configurazione NVIDIA
            mkdir -p /etc/modprobe.d
            echo "options nvidia_drm modeset=1" > /etc/modprobe.d/nvidia.conf
            ;;

        "AMD")
            local amd_packages=(
                mesa vulkan-radeon libva-mesa-driver
                mesa-vdpau radeon-vulkan vulkan-icd-loader
            )
            pacman -S --needed --noconfirm "${amd_packages[@]}"
            ;;

        "INTEL")
            local intel_packages=(
                mesa vulkan-intel libva-intel-driver
                intel-media-driver intel-gpu-tools
            )
            pacman -S --needed --noconfirm "${intel_packages[@]}"
            ;;
    esac
}

# Ottimizzazioni CPU
apply_cpu_optimizations() {
    log_platinum "Applicazione ottimizzazioni CPU..."

    # Governor prestazioni
    if command -v cpupower > /dev/null; then
        cpupower frequency-set -g performance
        systemctl enable cpupower.service
    fi

    # IRQ Balance
    systemctl enable irqbalance.service

    # Kernel parameters per CPU
    local cpu_optimizations=""
    case "$CPU_VENDOR" in
        "GenuineIntel")
            cpu_optimizations="intel_pstate=active intel_idle.max_cstate=0 processor.max_cstate=1"
            ;;
        "AuthenticAMD")
            cpu_optimizations="amd_pstate=active"
            ;;
    esac

    # Parametri generici CPU
    cat > /etc/sysctl.d/10-cpu-optimizations.conf << EOF
kernel.nmi_watchdog=0
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=10
vm.dirty_background_ratio=5
vm.dirty_writeback_centisecs=1500
kernel.sched_migration_cost_ns=5000000
kernel.sched_autogroup_enabled=0
EOF

    # Ottimizzazioni specifiche per numero di core
    if [ "$CPU_CORES" -ge 8 ]; then
        echo "kernel.sched_latency_ns=6000000" >> /etc/sysctl.d/10-cpu-optimizations.conf
        echo "kernel.sched_min_granularity_ns=400000" >> /etc/sysctl.d/10-cpu-optimizations.conf
    fi

    # Aggiungi parametri al kernel
    if [ -f "/etc/default/grub" ]; then
        local current_cmdline=$(grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub | cut -d'"' -f2)
        local new_cmdline="$current_cmdline nowatchdog mitigations=off preempt=full $cpu_optimizations"
        sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$new_cmdline\"|" /etc/default/grub

        # Aggiorna GRUB
        if command -v grub-mkconfig > /dev/null; then
            grub-mkconfig -o /boot/grub/grub.cfg
        fi
    fi
}

# Ottimizzazioni GPU
apply_gpu_optimizations() {
    log_platinum "Applicazione ottimizzazioni GPU..."

    case "$GPU_VENDOR" in
        "NVIDIA")
            # Abilita persistence mode
            nvidia-smi -pm 1

            # Imposta massime prestazioni
            nvidia-settings -a '[gpu:0]/GpuPowerMizerMode=1' 2>/dev/null


            # Abilita servizi NVIDIA
            systemctl enable nvidia-persistenced.service
            ;;

        "AMD"|"INTEL")
            # Trova il percorso corretto per la GPU
            for card in /sys/class/drm/card*/; do
                if [ -f "${card}device/power_dpm_force_performance_level" ]; then
                    echo "performance" > "${card}device/power_dpm_force_performance_level" 2>/dev/null || \
                    echo "high" > "${card}device/power_dpm_force_performance_level" 2>/dev/null || \
                    echo "max" > "${card}device/power_dpm_force_performance_level" 2>/dev/null
                    break
                fi
            done
            ;;
    esac
}

# Ottimizzazioni Kernel
apply_kernel_optimizations() {
    log_platinum "Applicazione ottimizzazioni Kernel..."

    # Installa kernel Zen se non presente
    if ! pacman -Q linux-zen 2>/dev/null; then
        pacman -S --needed --noconfirm linux-zen linux-zen-headers
    fi

    # Ottimizzazioni I/O scheduler
    if [ -d "/sys/block/${ROOT_DISK}/queue" ]; then
        if [ "$STORAGE_TYPE" = "SSD" ]; then
            echo "bfq" > "/sys/block/${ROOT_DISK}/queue/scheduler" 2>/dev/null || true
            echo "0" > "/sys/block/${ROOT_DISK}/queue/rotational" 2>/dev/null || true
            if [ -f "/sys/block/${ROOT_DISK}/queue/iosched/low_latency" ]; then
                echo "1" > "/sys/block/${ROOT_DISK}/queue/iosched/low_latency" 2>/dev/null || true
            fi
        else
            echo "mq-deadline" > "/sys/block/${ROOT_DISK}/queue/scheduler" 2>/dev/null || true
        fi
    fi

    # Aumenta limite dei file aperti
    echo "fs.file-max = 1000000" > /etc/sysctl.d/10-file-max.conf
}

# Ottimizzazioni memoria
apply_memory_optimizations() {
    log_platinum "Applicazione ottimizzazioni memoria..."

    # Calcola valori ottimali in base alla RAM
    local min_filelist=$((TOTAL_RAM / 2))
    local max_filelist=$((TOTAL_RAM * 2))

    cat > /etc/sysctl.d/10-memory-optimizations.conf << EOF
vm.min_free_kbytes = $((TOTAL_RAM / 200))  # 0.5% della RAM
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.dirty_writeback_centisecs = 1500
vm.vfs_cache_pressure = 50
vm.swappiness = 10
inotify.max_user_watches = 524288
EOF

    # Ottimizzazioni specifiche per grandi quantità de RAM
    if [ "$TOTAL_RAM_GB" -ge 16 ]; then
        echo "vm.dirty_bytes = 268435456" >> /etc/sysctl.d/10-memory-optimizations.conf
        echo "vm.dirty_background_bytes = 134217728" >> /etc/sysctl.d/10-memory-optimizations.conf
    fi

    # Early OOM (Out Of Memory) per prevenire freeze del sistema
    if systemctl list-unit-files | grep -q earlyoom.service; then
        systemctl enable earlyoom.service
    else
        log_warning "earlyoom.service non trovato, installazione in corso..."
        pacman -S --noconfirm earlyoom
        systemctl enable earlyoom.service
    fi
}

# Ottimizzazioni disco e filesystem
apply_disk_optimizations() {
    log_platinum "Applicazione ottimizzazioni disco e filesystem..."

    # Ottimizzazioni per SSD
    if [ "$STORAGE_TYPE" = "SSD" ]; then
        # Abilita TRIM
        systemctl enable fstrim.timer

        # Aumenta readahead per SSD
        if [ -d "/sys/block/${ROOT_DISK}/queue" ]; then
            echo 256 > "/sys/block/${ROOT_DISK}/queue/read_ahead_kb" 2>/dev/null || true
        fi

        # Disabilita access time
        sed -i '/\/dev\/sd/ s/defaults/defaults,noatime,nodiratime/' /etc/fstab 2>/dev/null || true
    fi

    # Ottimizzazioni I/O
    cat > /etc/sysctl.d/10-disk-optimizations.conf << EOF
vm.dirty_writeback_centisecs = 1500
vm.dirty_expire_centisecs = 3000
EOF
}

# Ottimizzazioni sicurezza (minime per performance)
apply_security_tweaks() {
    log_platinum "Applicazione tweaks sicurezza..."

    # Disabilita alcuni mitigazioni per le performance
    cat > /etc/sysctl.d/10-security-tweaks.conf << EOF
kernel.kptr_restrict = 0
kernel.dmesg_restrict = 0
kernel.printk = 3 3 3 3
EOF
}

# Ottimizzazioni ESTREME per CPU
apply_extreme_cpu_optimizations() {
    log_extreme "Applicazione ottimizzazioni CPU ESTREME..."

    case "$CPU_VENDOR" in
        "GenuineIntel")
            log_info "Applicazione ottimizzazioni ESTREME per Intel CPU..."

            # Set Intel pstate to maximum performance
            if [ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]; then
                echo 0 | tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null 2>&1
            fi

            if [ -f "/sys/devices/system/cpu/intel_pstate/max_perf_pct" ]; then
                echo 100 | tee /sys/devices/system/cpu/intel_pstate/max_perf_pct > /dev/null 2>&1
            fi

            if [ -f "/sys/devices/system/cpu/intel_pstate/min_perf_pct" ]; then
                echo 100 | tee /sys/devices/system/cpu/intel_pstate/min_perf_pct > /dev/null 2>&1
            fi

            # Set governor to performance for each CPU
            for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                if [ -f "$cpu" ]; then
                    echo performance | tee $cpu > /dev/null 2>&1
                fi
            done

            # Disable BD PROCHOT if possible (requires msr-tools)
            if command -v wrmsr > /dev/null; then
                wrmsr -a 0x1FC 0 > /dev/null 2>&1
            fi

            # Increase thermal limits (if available)
            for zone in /sys/class/thermal/thermal_zone*/trip_point_*_temp; do
                if [ -f "$zone" ]; then
                    echo 95000 | tee $zone > /dev/null 2>&1
                fi
            done
            ;;

        "AuthenticAMD")
            log_info "Applicazione ottimizzazioni ESTREME per AMD CPU..."

            # Set governor to performance for each CPU
            for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                if [ -f "$cpu" ]; then
                    echo performance | tee $cpu > /dev/null 2>&1
                fi
            done

            # Set min and max frequency to the maximum (if available)
            for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
                if [ -f "$cpu/scaling_min_freq" ]; then
                    cat "$cpu/cpuinfo_max_freq" | tee "$cpu/scaling_min_freq" > /dev/null 2>&1
                fi
                if [ -f "$cpu/scaling_max_freq" ]; then
                    cat "$cpu/cpuinfo_max_freq" | tee "$cpu/scaling_max_freq" > /dev/null 2>&1
                fi
            done
            ;;
    esac
}

# Ottimizzazioni ESTREME per GPU
apply_extreme_gpu_optimizations() {
    log_extreme "Applicazione ottimizzazioni GPU ESTREME..."

    case "$GPU_VENDOR" in
        "NVIDIA")
            log_info "Applicazione ottimizzazioni ESTREME per NVIDIA GPU..."

            # Set power limit to maximum (requires nvidia-smi)
            MAX_POWER=$(nvidia-smi --query-gpu=power.max_limit --format=csv,noheader,nounits | head -1)
            if [ ! -z "$MAX_POWER" ]; then
                nvidia-smi --power-limit=$MAX_POWER > /dev/null 2>&1
            fi

            # Enable persistent mode
            nvidia-smi --persistence-mode=1 > /dev/null 2>&1

            # Set performance mode to maximum
            nvidia-settings -a '[gpu:0]/GpuPowerMizerMode=1' > /dev/null 2>&1

            # Set clock offsets to maximum (if supported)
            nvidia-settings -a '[gpu:0]/GPUGraphicsClockOffset[3]=100' > /dev/null 2>&1
            nvidia-settings -a '[gpu:0]/GPUMemoryTransferRateOffset[3]=100' > /dev/null 2>&1
            ;;

        "AMD"|"INTEL")
            log_info "Applicazione ottimizzazioni ESTREME per $GPU_VENDOR GPU..."

            # Trova il percorso corretto per la GPU
            for card in /sys/class/drm/card*/; do
                if [ -f "${card}device/power_dpm_force_performance_level" ]; then
                    echo "high" > "${card}device/power_dpm_force_performance_level" 2>/dev/null || \
                    echo "performance" > "${card}device/power_dpm_force_performance_level" 2>/dev/null || \
                    echo "max" > "${card}device/power_dpm_force_performance_level" 2>/dev/null
                    break
                fi
            done

            # Set power limit to maximum (if available)
            for hwmon in /sys/class/drm/card*/device/hwmon/hwmon*/; do
                if [ -f "${hwmon}power1_cap_max" ]; then
                    MAX_POWER=$(cat "${hwmon}power1_cap_max" 2>/dev/null)
                    if [ ! -z "$MAX_POWER" ]; then
                        echo $MAX_POWER > "${hwmon}power1_cap" 2>/dev/null
                    fi
                    break
                fi
            done
            ;;
    esac
}

# Ottimizzazioni avanzate per filesystem e I/O
apply_advanced_io_optimizations() {
    log_platinum "Applicazione ottimizzazioni I/O avanzate..."

    # Ottimizzazioni per filesystem EXT4/BTRFS
    if mount | grep -q "ext4"; then
        if [ -d "/sys/block/${ROOT_DISK}/queue" ]; then
            echo "deadline" > "/sys/block/${ROOT_DISK}/queue/scheduler" 2>/dev/null || true
            echo 0 > "/sys/block/${ROOT_DISK}/queue/rotational" 2>/dev/null || true
            echo 256 > "/sys/block/${ROOT_DISK}/queue/nr_requests" 2>/dev/null || true
        fi
    fi

    # Aumenta i limiti de I/O
    echo 1048576 > /proc/sys/fs/aio-max-nr 2>/dev/null || true

    # Ottimizzazioni per database e carichi pesanti
    cat > /etc/sysctl.d/10-advanced-io.conf << EOF
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
vm.dirty_expire_centisecs = 1000
vm.dirty_writeback_centisecs = 100
vm.swappiness = 1
EOF
}

# Ottimizzazioni avanzate di memoria
apply_advanced_memory_optimizations() {
    log_platinum "Applicazione ottimizzazioni memoria avanzate..."

    # Ottimizzazioni per systemd
    mkdir -p /etc/systemd/system.conf.d/
    cat > /etc/systemd/system.conf.d/10-memory-optimize.conf << EOF
[Manager]
DefaultCPUAccounting=no
DefaultIOAccounting=no
DefaultIPAccounting=no
DefaultBlockIOAccounting=no
DefaultMemoryAccounting=no
DefaultTasksAccounting=no
EOF

    # Ottimizzazioni per transparent hugepages
    if [ -f "/sys/kernel/mm/transparent_hugepage/enabled" ]; then
        echo "always" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
    fi
    if [ -f "/sys/kernel/mm/transparent_hugepage/defrag" ]; then
        echo "madvise" > /sys/kernel/mm/transparent_hugepage/defrag 2>/dev/null || true
    fi

    # Ottimizzazioni per cgroups v2
    if [ -d /sys/fs/cgroup ]; then
        if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
            echo "memory" > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || true
            echo "cpu" > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || true
            echo "io" > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || true
        fi
    fi
}

# Ottimizzazioni avanzate per sicurezza performante
apply_advanced_security_optimizations() {
    log_platinum "Applicazione ottimizzazioni sicurezza avanzate..."

    # Rimuove mitigazioni per massime prestazioni
    cat > /etc/sysctl.d/10-advanced-security.conf << EOF
kernel.kptr_restrict = 0
kernel.dmesg_restrict = 0
kernel.printk = 3 3 3 3
kernel.unprivileged_bpf_disabled = 0
net.core.bpf_jit_enable = 1
kernel.timer_migration = 0
kernel.sched_energy_aware = 0
kernel.numa_balancing = 0
kernel.ipc = 0
EOF
}

# Ottimizzazioni ESTREME avanzate
apply_extreme_advanced_optimizations() {
    log_extreme "Applicazione ottimizzazioni ESTREME avanzate..."

    # Disabilita completamente le mitigazioni
    echo 0 > /proc/sys/kernel/numa_balancing 2>/dev/null || true
    echo 0 > /proc/sys/kernel/sched_schedstats 2>/dev/null || true
    echo 0 > /proc/sys/kernel/sched_energy_aware 2>/dev/null || true

    # Ottimizzazioni CPU estreme
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/; do
        [ -f "${cpu}scaling_min_freq" ] && cat "${cpu}cpuinfo_max_freq" | tee "${cpu}scaling_min_freq" >/dev/null 2>&1 || true
        [ -f "${cpu}scaling_max_freq" ] && cat "${cpu}cpuinfo_max_freq" | tee "${cpu}scaling_max_freq" >/dev/null 2>&1 || true
        [ -f "${cpu}scaling_governor" ] && echo "performance" | tee "${cpu}scaling_governor" >/dev/null 2>&1 || true
    done

    # Ottimizzazioni I/O estreme
    if [ -d "/sys/block/${ROOT_DISK}/queue" ]; then
        echo 1024 > "/sys/block/${ROOT_DISK}/queue/nr_requests" 2>/dev/null || true
        echo 0 > "/sys/block/${ROOT_DISK}/queue/rotational" 2>/dev/null || true
        echo 0 > "/sys/block/${ROOT_DISK}/queue/add_random" 2>/dev/null || true
        echo 0 > "/sys/block/${ROOT_DISK}/queue/iostats" 2>/dev/null || true
        echo 256 > "/sys/block/${ROOT_DISK}/queue/read_ahead_kb" 2>/dev/null || true
    fi
}

# Ottimizzazioni avanzate per la rete (esclusi WiFi e bootloader)
apply_advanced_network_optimizations() {
    log_platinum "Applicazione ottimizzazioni avanzate di rete..."

    cat > /etc/sysctl.d/10-network-optimizations.conf << EOF
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.core.optmem_max = 134217728
net.core.netdev_max_backlog = 300000
net.core.somaxconn = 100000
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_max_syn_backlog = 300000
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
EOF
}

# Ottimizzazioni avanzate per filesystem
apply_advanced_filesystem_optimizations() {
    log_platinum "Applicazione ottimizzazioni avanzate filesystem..."

    # Ottimizzazioni per ext4
    if mount | grep -q "ext4"; then
        sed -i '/ext4/ s/defaults/defaults,noatime,nodiratime,commit=120,barrier=0,data=writeback/' /etc/fstab 2>/dev/null || true
    fi

    # Ottimizzazioni per btrfs
    if mount | grep -q "btrfs"; then
        sed -i '/btrfs/ s/defaults/defaults,noatime,nodiratime,commit=120,compress=zstd:1,ssd/' /etc/fstab 2>/dev/null || true
    fi

    # Aumento inotify watches
    echo "fs.inotify.max_user_watches = 524288" >> /etc/sysctl.d/10-fs-optimizations.conf
    echo "fs.inotify.max_user_instances = 8192" >> /etc/sysctl.d/10-fs-optimizations.conf
}

# Ottimizzazioni per la memoria virtuale
apply_virtual_memory_optimizations() {
    log_platinum "Applicazione ottimizzazioni memoria virtuale..."

    cat > /etc/sysctl.d/10-vm-optimizations.conf << EOF
vm.overcommit_memory = 1
vm.overcommit_ratio = 100
vm.page-cluster = 0
vm.stat_interval = 10
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
vm.dirty_expire_centisecs = 1000
vm.dirty_writeback_centisecs = 100
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF
}

# Ottimizzazioni per l'I/O del disco
apply_advanced_disk_io_optimizations() {
    log_platinum "Applicazione ottimizzazioni I/O disco avanzate..."

    # Imposta scheduler I/O per ogni disco
    for disk in /sys/block/sd*; do
        if [ -d "$disk/queue" ]; then
            diskname=$(basename $disk)
            if [ "$STORAGE_TYPE" = "SSD" ]; then
                echo "none" > "$disk/queue/scheduler" 2>/dev/null || true
                echo "0" > "$disk/queue/rotational" 2>/dev/null || true
                echo "256" > "$disk/queue/read_ahead_kb" 2>/dev/null || true
            else
                echo "mq-deadline" > "$disk/queue/scheduler" 2>/dev/null || true
                echo "128" > "$disk/queue/read_ahead_kb" 2>/dev/null || true
            fi
            echo "256" > "$disk/queue/nr_requests" 2>/dev/null || true
            echo "0" > "$disk/queue/add_random" 2>/dev/null || true
            echo "0" > "$disk/queue/iostats" 2>/dev/null || true
        fi
    done
}

# Ottimizzazioni per il kernel estreme
apply_extreme_kernel_optimizations() {
    log_extreme "Applicazione ottimizzazioni kernel ESTREME..."

    cat > /etc/sysctl.d/10-extreme-kernel.conf << EOF
kernel.sched_min_granularity_ns = 1000000
kernel.sched_wakeup_granularity_ns = 1500000
kernel.sched_migration_cost_ns = 500000
kernel.sched_autogroup_enabled = 0
kernel.perf_cpu_time_max_percent = 50
kernel.perf_event_max_sample_rate = 100000
kernel.perf_event_paranoid = 0
kernel.panic = 10
kernel.panic_on_oops = 1
kernel.printk = 3 3 3 3
EOF
}

# Ottimizzazioni specifiche per chipset e controller
apply_chipset_optimizations() {
    log_platinum "Applicazione ottimizzazioni specifiche chipset..."

    # Ottimizzazioni per chipset Intel
    if lspci | grep -i "Intel.*Chipset" > /dev/null; then
        log_info "Rilevato chipset Intel, applicando ottimizzazioni..."

        # Ottimizzazioni per Intel Management Engine Interface
        if [ -d "/sys/bus/pci/drivers/mei_me" ]; then
            echo "options mei_me disable_msi=1" > /etc/modprobe.d/mei.conf
        fi

        # Ottimizzazioni per Intel HD Audio
        if [ -d "/sys/module/snd_hda_intel" ]; then
            echo "options snd_hda_intel power_save=0" > /etc/modprobe.d/snd_hda_intel.conf
            echo "options snd_hda_intel enable_msi=1" >> /etc/modprobe.d/snd_hda_intel.conf
        fi
    fi

    # Ottimizzazioni per chipset AMD
    if lspci | grep -i "AMD.*Chipset" > /dev/null; then
        log_info "Rilevato chipset AMD, applicando ottimizzazioni..."

        # Ottimizzazioni per AMD SoC e chipset
        if [ -f "/sys/bus/pci/drivers/amd_sb" ]; then
            echo "options amd_sb disable_msi=0" > /etc/modprobe.d/amd_sb.conf
        fi
    fi

    # Ottimizzazioni per controller USB
    apply_usb_optimizations
}

# Ottimizzazioni per controller USB
apply_usb_optimizations() {
    log_platinum "Applicazione ottimizzazioni controller USB..."

    # Disabilita autosuspend per dispositivi USB essenziali
    for usb in /sys/bus/usb/devices/*/power/control; do
        if [ -f "$usb" ]; then
            echo "on" > "$usb" 2>/dev/null || true
        fi
    done

    # Aumenta il potere di risparmio energetico per porte USB
    for usb in /sys/bus/usb/devices/*/power/autosuspend_delay_ms; do
        if [ -f "$usb" ]; then
            echo "-1" > "$usb" 2>/dev/null || true
        fi
    done

    # Ottimizzazioni specifiche per controller USB xHCI
    if [ -d "/sys/module/xhci_hcd" ]; then
        echo "options xhci_hcd quirks=0x100" > /etc/modprobe.d/xhci.conf
    fi

    # Ottimizzazioni per controller USB EHCI
    if [ -d "/sys/module/ehci_hcd" ]; then
        echo "options ehci_hcd log2_irq_thresh=0" > /etc/modprobe.d/ehci.conf
    fi
}

# Ottimizzazioni per controller SATA/AHCI
apply_sata_optimizations() {
    log_platinum "Applicazione ottimizzazioni controller SATA/AHCI..."

    # Ottimizzazioni per controller AHCI
    if [ -d "/sys/module/ahci" ]; then
        echo "options ahci msix=1" > /etc/modprobe.d/ahci.conf

        # Imposta link power management a max performance
        for link in /sys/class/scsi_host/host*/link_power_management_policy; do
            if [ -f "$link" ]; then
                echo "max_performance" > "$link" 2>/dev/null || true
            fi
        done
    fi

    # Ottimizzazioni specifiche per controller Intel SATA
    if lspci | grep -i "SATA.*Intel" > /dev/null; then
        echo "options ahci enable_sss=1" >> /etc/modprobe.d/ahci.conf
    fi

    # Ottimizzazioni per controller AMD SATA
    if lspci | grep -i "SATA.*AMD" > /dev/null; then
        echo "options ahci sids=1" >> /etc/modprobe.d/ahci.conf
    fi
}

# Ottimizzazioni per controller NVMe
apply_nvme_optimizations() {
    log_platinum "Applicazione ottimizzazioni controller NVMe..."

    if lspci | grep -i "NVMe" > /dev/null; then
        log_info "Rilevato controller NVMe, applicando ottimizzazioni..."

        # Ottimizzazioni per NVMe
        if [ -d "/sys/module/nvme" ]; then
            echo "options nvme poll_queues=0" > /etc/modprobe.d/nvme.conf
            echo "options nvme io_timeout=30" >> /etc/modprobe.d/nvme.conf
        fi

        # Imposta massime prestazioni per dispositivi NVMe
        for nvme in /sys/class/nvme/*/power/control; do
            if [ -f "$nvme" ]; then
                echo "on" > "$nvme" 2>/dev/null || true
            fi
        done

        # Disabilita APST per massime prestazioni NVMe
        for nvme in /sys/class/nvme/*/power/autosuspend_delay_ms; do
            if [ -f "$nvme" ]; then
                echo "-1" > "$nvme" 2>/dev/null || true
            fi
        done
    fi
}

# Ottimizzazioni per schede audio
apply_audio_optimizations() {
    log_platinum "Applicazione ottimizzazioni schede audio..."

    # Ottimizzazioni ALSA
    if [ -d "/proc/asound" ]; then
        cat > /etc/asound.conf << EOF
defaults.pcm.rate_converter "speexrate_medium"
defaults.pcm.dmix.rate 96000
defaults.pcm.dmix.format s32_le
defaults.pcm.dmix.period_time 0
defaults.pcm.dmix.period_size 1024
defaults.pcm.dmix.buffer_size 8192
EOF

        # Disabilita risparmio energetico per schede audio
        for card in /sys/module/snd_*; do
            if [ -f "${card}/parameters/power_save" ]; then
                echo "0" > "${card}/parameters/power_save" 2>/dev/null || true
            fi
        done
    fi

    # Ottimizzazioni specifiche per scheda audio
    if lspci | grep -i "Audio.*Intel" > /dev/null; then
        echo "options snd_hda_intel power_save=0" >> /etc/modprobe.d/snd_optimizations.conf
        echo "options snd_hda_intel enable_msi=1" >> /etc/modprobe.d/snd_optimizations.conf
    fi
}

# Ottimizzazioni per controller di rete (escluso WiFi)
apply_network_controller_optimizations() {
    log_platinum "Applicazione ottimizzazioni controller di rete..."

    # Ottimizzazioni per schede di rete Intel
    if lspci | grep -i "Network.*Intel" > /dev/null; then
        log_info "Rilevata scheda di rete Intel, applicando ottimizzazioni..."

        # Ottimizzazioni per driver e1000e
        if [ -d "/sys/module/e1000e" ]; then
            echo "options e1000e InterruptThrottleRate=0" > /etc/modprobe.d/e1000e.conf
        fi

        # Ottimizzazioni per driver igb
        if [ -d "/sys/module/igb" ]; then
            echo "options igb InterruptThrottleRate=0" > /etc/modprobe.d/igb.conf
        fi

        # Ottimizzazioni per driver ixgbe
        if [ -d "/sys/module/ixgbe" ]; then
            echo "options ixgbe InterruptThrottleRate=0" > /etc/modprobe.d/ixgbe.conf
        fi
    fi

    # Ottimizzazioni per schede di rete Realtek
    if lspci | grep -i "Network.*Realtek" > /dev/null; then
        log_info "Rilevata scheda di rete Realtek, applicando ottimizzazioni..."

        if [ -d "/sys/module/r8169" ]; then
            echo "options r8169 s5wol=0" > /etc/modprobe.d/r8169.conf
            echo "options r8169 use_dac=1" >> /etc/modprobe.d/r8169.conf
        fi
    fi

    # Ottimizzazioni per schede di rete Broadcom
    if lspci | grep -i "Network.*Broadcom" > /dev/null; then
        log_info "Rilevata scheda di rete Broadcom, applicando ottimizzazioni..."

        if [ -d "/sys/module/tg3" ]; then
            echo "options tg3 MSI_CAP=1" > /etc/modprobe.d/tg3.conf
        fi
    fi

    # Aumenta buffer di rete per tutte le interfacce
    for iface in /sys/class/net/eth* /sys/class/net/en*; do
        if [ -d "$iface" ]; then
            iface_name=$(basename "$iface")
            cat > /etc/sysctl.d/10-network-$iface_name.conf << EOF
net.core.netdev_max_backlog = 300000
net.core.dev_weight = 512
EOF
        fi
    done
}

# Ottimizzazioni per periferiche di input
apply_input_optimizations() {
    log_platinum "Applicazione ottimizzazioni periferiche di input..."

    # Ottimizzazioni per mouse e tastiere
    if [ -d "/sys/module/usbhid" ]; then
        echo "options usbhid mouse_poll=1" > /etc/modprobe.d/usbhid.conf
        echo "options usbhid kb_poll=1" >> /etc/modprobe.d/usbhid.conf
        echo "options usbhid jspoll=1" >> /etc/modprobe.d/usbhid.conf
    fi

    # Riduci latenza input
    echo "kernel/sched/latency_ns = 1000000" >> /etc/sysctl.d/10-input.conf
    echo "kernel/sched/min_granularity_ns = 500000" >> /etc/sysctl.d/10-input.conf
}

# Ottimizzazioni per gestione energetica avanzata
apply_advanced_power_optimizations() {
    log_platinum "Applicazione ottimizzazioni gestione energetica avanzata..."

    # Configurazione avanzata per cpupower
    if command -v cpupower > /dev/null; then
        # Imposta governor performance per tutte le CPU
        cpupower frequency-set -g performance

        # Disabilita turbo boost per stabilità (se richiesto in modalità estrema)
        if [ "$EXTREME_MODE" = true ]; then
            if [ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]; then
                echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo
            fi
        fi

        # Ottimizzazioni specifiche per architettura CPU
        case "$CPU_VENDOR" in
            "GenuineIntel")
                # Ottimizzazioni per Intel P-State
                if [ -d "/sys/devices/system/cpu/intel_pstate" ]; then
                    echo 100 > /sys/devices/system/cpu/intel_pstate/max_perf_pct
                    echo 100 > /sys/devices/system/cpu/intel_pstate/min_perf_pct
                fi
                ;;
            "AuthenticAMD")
                # Ottimizzazioni per AMD CPPC
                if [ -d "/sys/devices/system/cpu/cpufreq/policy0" ]; then
                    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
                        if [ -f "${policy}/energy_performance_preference" ]; then
                            echo "performance" > "${policy}/energy_performance_preference" 2>/dev/null || true
                        fi
                    done
                fi
                ;;
        esac
    fi

    # Ottimizzazioni per gestione termica
    apply_thermal_optimizations
}

# Ottimizzazioni per gestione termica
apply_thermal_optimizations() {
    log_platinum "Applicazione ottimizzazioni gestione termica..."

    # Configurazione thermal daemon
    if command -v thermald > /dev/null; then
        systemctl enable thermald.service

        # Configurazione personalizzata per thermald
        cat > /etc/thermald/thermal-conf.xml << EOF
<?xml version="1.0"?>
<ThermalConfiguration>
  <Platform>
    <Name>Optimized Thermal Configuration</Name>
    <ProductName>*</ProductName>
    <Preference>PERFORMANCE</Preference>
    <ThermalZones>
      <ThermalZone>
        <Type>cpu</Type>
        <TripPoints>
          <TripPoint>
            <Temperature>85000</Temperature>
            <type>passive</type>
          </TripPoint>
          <TripPoint>
            <Temperature>90000</Temperature>
            <type>active</type>
          </TripPoint>
          <TripPoint>
            <Temperature>95000</Temperature>
            <type>critical</type>
          </TripPoint>
        </TripPoints>
      </ThermalZone>
    </ThermalZones>
  </Platform>
</ThermalConfiguration>
EOF
    fi

    # Ottimizzazioni per curve termiche
    if [ -d "/sys/class/thermal" ]; then
        for thermal in /sys/class/thermal/thermal_zone*/; do
            if [ -f "${thermal}/policy" ]; then
                echo "step_wise" > "${thermal}/policy" 2>/dev/null || true
            fi
        done
    fi
}

# Ottimizzazioni per virtualizzazione
apply_virtualization_optimizations() {
    log_platinum "Applicazione ottimizzazioni virtualizzazione..."

    # Ottimizzazioni per KVM
    if [ -d "/sys/module/kvm" ]; then
        echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf
        echo "options kvm report_ignored_msrs=0" >> /etc/modprobe.d/kvm.conf

        # Ottimizzazioni specifiche per Intel VT-d
        if [ -d "/sys/module/vfio_iommu_type1" ]; then
            echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/vfio.conf
        fi
    fi

    # Ottimizzazioni per containers
    if [ -d "/sys/fs/cgroup" ]; then
        echo "kernel.sched_cfs_bandwidth_slice_us = 1000" >> /etc/sysctl.d/10-cgroup.conf
        echo "kernel.sched_latency_ns = 6000000" >> /etc/sysctl.d/10-cgroup.conf
    fi
}

# Ottimizzazioni per filesystem BTRFS avanzate
apply_btrfs_advanced_optimizations() {
    log_platinum "Applicazione ottimizzazioni avanzate BTRFS..."

    if mount | grep -q "btrfs" && command -v btrfs > /dev/null; then
        log_info "Rilevato filesystem BTRFS, applicando ottimizzazioni avanzate..."

        # Ottimizzazioni mount BTRFS
        for mountpoint in $(mount | grep btrfs | awk '{print $3}'); do
            # Defragmentation manuale (solo se necessario)
            btrfs filesystem defragment -r -v "$mountpoint" > /dev/null 2>&1 || true

            # Balance dei dati
            btrfs balance start --bg -dusage=75 "$mountpoint" > /dev/null 2>&1 || true
        done

        # Ottimizzazioni kernel per BTRFS
        cat > /etc/sysctl.d/10-btrfs.conf << EOF
vm.dirty_bytes = 536870912
vm.dirty_background_bytes = 268435456
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
EOF
    fi
}

# Ottimizzazioni per filesystem EXT4 avanzate
apply_ext4_advanced_optimizations() {
    log_platinum "Applicazione ottimizzazioni avanzate EXT4..."

    if mount | grep -q "ext4"; then
        log_info "Rilevato filesystem EXT4, applicando ottimizzazioni avanzate..."

        # Tune2fs ottimizzazioni
        for device in $(mount | grep ext4 | awk '{print $1}'); do
            tune2fs -O dir_index,has_journal,large_file,extent "$device" > /dev/null 2>&1 || true
            tune2fs -o journal_data_writeback "$device" > /dev/null 2>&1 || true
        done

        # Ottimizzazioni specifiche per EXT4
        cat > /etc/sysctl.d/10-ext4.conf << EOF
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
EOF
    fi
}

# Aggiungi queste funzioni prima della funzione main()

# Ottimizzazioni per systemd e servizi di sistema
apply_systemd_optimizations() {
    log_platinum "Ottimizzazioni avanzate per systemd..."

    # Configurazione servizi systemd
    mkdir -p /etc/systemd/system.conf.d/
    cat > /etc/systemd/system.conf.d/10-optimize.conf << EOF
[Manager]
DefaultCPUAccounting=no
DefaultIOAccounting=no
DefaultIPAccounting=no
DefaultBlockIOAccounting=no
DefaultMemoryAccounting=no
DefaultTasksAccounting=no
LogLevel=warning
LogTarget=journal-or-kmsg
EOF

    # Ottimizzazioni journald
    mkdir -p /etc/systemd/journald.conf.d/
    cat > /etc/systemd/journald.conf.d/10-optimize.conf << EOF
[Journal]
SystemMaxUse=64M
SystemMaxFiles=10
SystemMaxFileSize=8M
RuntimeMaxUse=32M
RuntimeMaxFiles=5
EOF

    # Riduzione tempi avvio servizi
    cat > /etc/systemd/system.conf.d/10-reduce-timeouts.conf << EOF
[Manager]
DefaultTimeoutStartSec=10s
DefaultTimeoutStopSec=5s
DefaultRestartSec=100ms
EOF
}

# Ottimizzazioni per il filesystem e mount points
apply_filesystem_advanced_optimizations() {
    log_platinum "Ottimizzazioni filesystem avanzate..."

    # Ottimizzazioni per tmpfs
    echo "tmpfs /tmp tmpfs defaults,noatime,nodiratime,size=2G,mode=1777 0 0" >> /etc/fstab

    # Ottimizzazioni specifiche per filesystem
    case $(findmnt -n -o FSTYPE /) in
        "ext4")
            tune2fs -O dir_index,has_journal,large_file,extent /dev/${ROOT_DISK} > /dev/null 2>&1 || true
            ;;
        "btrfs")
            btrfs filesystem defragment -r / > /dev/null 2>&1 || true
            ;;
    esac
}

# Ottimizzazioni per la gestione energetica CPU avanzata
apply_advanced_cpu_power_management() {
    log_platinum "Ottimizzazioni avanzate gestione energetica CPU..."

    # Configurazione intel_pstate per CPU Intel
    if [ -d "/sys/devices/system/cpu/intel_pstate" ]; then
        echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
        echo 100 > /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || true
        echo 100 > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
    fi

    # Configurazione AMD CPPC
    if [ -d "/sys/devices/system/cpu/cpufreq/policy0" ]; then
        for policy in /sys/devices/system/cpu/cpufreq/policy*; do
            [ -f "${policy}/energy_performance_preference" ] &&
                echo "performance" > "${policy}/energy_performance_preference" 2>/dev/null || true
        done
    fi
}

# Ottimizzazioni per la gestione degli interrupt
apply_irq_advanced_optimizations() {
    log_platinum "Ottimizzazioni avanzate gestione interrupt..."

    # Assegnazione IRQ specifica per CPU
    local i=0
    for irq in /proc/irq/*; do
        if [ -d "$irq" ] && [ "$irq" != "/proc/irq/0" ]; then
            echo $((1 << i)) > "$irq/smp_affinity" 2>/dev/null || true
            i=$(( (i + 1) % CPU_CORES ))
        fi
    done

    # Ottimizzazioni per IRQ balance
    cat > /etc/default/irqbalance << EOF
ENABLED="1"
ONESHOT="0"
IRQBALANCE_ARGS="--deepestcache=2 --hintpolicy=ignore"
EOF
}

# Ottimizzazioni per la memoria e swap avanzate
apply_advanced_swap_optimizations() {
    log_platinum "Ottimizzazioni avanzate memoria e swap..."

    # Configurazione zswap
    echo 1 > /sys/module/zswap/parameters/enabled 2>/dev/null || true
    echo zstd > /sys/module/zswap/parameters/compressor 2>/dev/null || true
    echo 20 > /sys/module/zswap/parameters/max_pool_percent 2>/dev/null || true

    # Ottimizzazioni swapiness dinamico
    cat > /etc/sysctl.d/10-swap-optimizations.conf << EOF
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.page-cluster=0
vm.dirty_ratio=10
vm.dirty_background_ratio=5
vm.dirty_expire_centisecs=3000
vm.dirty_writeback_centisecs=500
EOF
}

# Ottimizzazioni per i processi e lo scheduler
apply_process_scheduler_optimizations() {
    log_platinum "Ottimizzazioni avanzate scheduler processi..."

    cat > /etc/sysctl.d/10-process-optimizations.conf << EOF
kernel.sched_min_granularity_ns=1000000
kernel.sched_wakeup_granularity_ns=1500000
kernel.sched_migration_cost_ns=500000
kernel.sched_autogroup_enabled=0
kernel.sched_cfs_bandwidth_slice_us=1000
kernel.perf_cpu_time_max_percent=5
kernel.perf_event_max_sample_rate=10000
EOF
}

# Ottimizzazioni per i limiti di sistema
apply_ulimit_optimizations() {
    log_platinum "Ottimizzazioni limiti di sistema..."

    cat > /etc/security/limits.d/99-platinum.conf << EOF
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 65536
* hard nproc 65536
* soft memlock unlimited
* hard memlock unlimited
* soft stack unlimited
* hard stack unlimited
EOF
}

# Ottimizzazioni per i driver di input
apply_input_driver_optimizations() {
    log_platinum "Ottimizzazioni driver di input..."

    # Ottimizzazioni per mouse e tastiera
    cat > /etc/udev/rules.d/99-input-optimize.rules << EOF
SUBSYSTEM=="input", KERNEL=="mouse*", ATTR{device/poll_delay}="1000"
SUBSYSTEM=="input", KERNEL=="event*", ATTR{device/poll_delay}="1000"
EOF
}

# Ottimizzazioni per i controller de storage
apply_storage_controller_optimizations() {
    log_platinum "Ottimizzazioni controller storage..."

    # Ottimizzazioni AHCI
    if lspci | grep -qi "ahci"; then
        echo "options ahci msix=1" > /etc/modprobe.d/ahci-optimize.conf
    fi

    # Ottimizzazioni NVMe
    if lspci | grep -qi "nvme"; then
        echo "options nvme_core io_timeout=30" > /etc/modprobe.d/nvme-optimize.conf
    fi
}

# Ottimizzazioni per la gestione termica avanzata
apply_advanced_thermal_optimizations() {
    log_platinum "Ottimizzazioni termiche avanzate..."

    # Configurazione thermal daemon avanzata
    cat > /etc/thermald/thermal-conf.xml << EOF
<?xml version="1.0"?>
<ThermalConfiguration>
  <Platform>
    <Name>Advanced Thermal Control</Name>
    <ProductName>*</ProductName>
    <Preference>PERFORMANCE</Preference>
    <ThermalZones>
      <ThermalZone>
        <Type>cpu</Type>
        <TripPoints>
          <TripPoint>
            <Temperature>85000</Temperature>
            <type>passive</type>
          </TripPoint>
          <TripPoint>
            <Temperature>90000</Temperature>
            <type>active</type>
          </TripPoint>
          <TripPoint>
            <Temperature>95000</Temperature>
            <type>critical</type>
          </TripPoint>
        </TripPoints>
      </ThermalZone>
    </ThermalZones>
  </Platform>
</ThermalConfiguration>
EOF
}

# Configurazione servizi
enable_services() {
    log_platinum "Abilitazione servizi..."

    # Servizi base
    systemctl enable cpupower.service

    # Per SSD
    if [ "$STORAGE_TYPE" = "SSD" ]; then
        systemctl enable fstrim.timer
    fi

    # earlyoom
    if systemctl list-unit-files | grep -q earlyoom.service; then
        systemctl enable earlyoom.service
    else
        log_warning "earlyoom.service non trovato, installazione in corso..."
        pacman -S --noconfirm earlyoom
        systemctl enable earlyoom.service
    fi

    # irqbalance
    if systemctl list-unit-files | grep -q irqbalance.service; then
        systemctl enable irqbalance.service
    else
        log_warning "irqbalance.service non trovato, installazione in corso..."
        pacman -S --noconfirm irqbalance
        systemctl enable irqbalance.service
    fi

    # Servizi specifici GPU
    if [ "$GPU_VENDOR" = "NVIDIA" ]; then
        systemctl enable nvidia-persistenced.service
    fi
}

# Configurazione preload
setup_preload() {
    log_platinum "Configurazione preload..."

    if command -v preload > /dev/null; then
        systemctl enable preload.service

        # Configurazione preload
        sed -i 's/^#PRELOAD_SIZE.*/PRELOAD_SIZE=1024m/' /etc/preload.conf
        sed -i 's/^#PRELOAD_FREQ.*/PRELOAD_FREQ=10/' /etc/preload.conf
    fi
}

# Ottimizzazioni mirrorlist
optimize_mirrorlist() {
    log_platinum "Ottimizzazione mirrorlist per Arch Linux..."

    # Backup mirrorlist originale
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

    # Utilizza reflector per ottenere mirror più veloci
    if command -v reflector > /dev/null; then
        reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist --connection-timeout 10
    fi
}

# Pulizia sistema
clean_system() {
    log_platinum "Pulizia sistema..."

    # Pulizia cache pacman
    paccache -rk1

    # Pulizia cache utente
    find /home -type d -name '.cache' -exec rm -rf {} + 2>/dev/null || true
    find /root -type d -name '.cache' -exec rm -rf {} + 2>/dev/null || true

    # Pulizia log
    find /var/log -type f -name '*.log' -exec truncate -s 0 {} \;
    journalctl --vacuum-time=7d

    # Rimuove pacchetti orfani
    pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true
}

# Funzione principale
main() {
    show_banner

    # Rilevamento hardware
    detect_hardware

    # Richiesta modalità ESTREMA
    read -p "Applicare ottimizzazioni ESTREME? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        EXTREME_MODE=true
        log_warning "ATTENZIONE: Le ottimizzazioni ESTREME possono aumentare il consumo energetico e la temperatura, e potrebbero ridurre la vita utile dell'hardware."
        read -p "Sei sicuro di voler continuare? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            EXTREME_MODE=false
            log_info "Modalità ESTREMA annullata."
        else
            log_info "Modalità ESTREMA abilitata."
        fi
    fi

    # Conferma
    read -p "Continuare con l'ottimizzazione? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Operazione annullata."
        exit 0
    fi

    # Esecuzione ottimizzazioni
    update_system
    install_gpu_drivers
    apply_cpu_optimizations
    apply_gpu_optimizations
    apply_kernel_optimizations
    apply_memory_optimizations
    apply_disk_optimizations
    apply_security_tweaks

    # Applica ottimizzazioni avanzate
    apply_advanced_io_optimizations
    apply_advanced_memory_optimizations
    apply_advanced_security_optimizations
    apply_advanced_network_optimizations
    apply_advanced_filesystem_optimizations
    apply_virtual_memory_optimizations
    apply_advanced_disk_io_optimizations

    # Applica ottimizzazioni hardware specifiche
    apply_chipset_optimizations
    apply_sata_optimizations
    apply_nvme_optimizations
    apply_audio_optimizations
    apply_network_controller_optimizations
    apply_input_optimizations
    apply_advanced_power_optimizations
    apply_virtualization_optimizations
    apply_btrfs_advanced_optimizations
    apply_ext4_advanced_optimizations

    # Applica ottimizzazioni ESTREME se richiesto
    if [ "$EXTREME_MODE" = true ]; then
        apply_extreme_cpu_optimizations
        apply_extreme_gpu_optimizations
        apply_extreme_advanced_optimizations
        apply_extreme_kernel_optimizations
    fi

    # Applica le nuove ottimizzazioni aggiunte
    apply_systemd_optimizations
    apply_filesystem_advanced_optimizations
    apply_advanced_cpu_power_management
    apply_irq_advanced_optimizations
    apply_advanced_swap_optimizations
    apply_process_scheduler_optimizations
    apply_ulimit_optimizations
    apply_input_driver_optimizations
    apply_storage_controller_optimizations
    apply_advanced_thermal_optimizations

    enable_services
    setup_preload
    optimize_mirrorlist
    clean_system

    log_success "Ottimizzazioni completate!"
    echo
    log_info "Riepilogo ottimizzazioni applicate:"
    log_info "- CPU: Governor performance, ottimizzazioni specifiche $CPU_VENDOR"
    log_info "- GPU: Driver e ottimizzazioni per $GPU_VENDOR"
    log_info "- Kernel: Parametri ottimizzati, I/O scheduler"
    log_info "- Memoria: Swappiness ridotto, cache pressure ottimizzato"
    log_info "- Disco: Ottimizzazioni per $STORAGE_TYPE"
    log_info "- Rete: Ottimizzazioni TCP avanzate, BBR congestion control"
    log_info "- Filesystem: Ottimizzazioni mount, inotify watches aumentati"
    log_info "- Chipset: Ottimizzazioni specifiche per controller"
    log_info "- Audio: Configurazione ALSA avanzata"
    log_info "- Input: Riduzione latenza per mouse e tastiera"
    log_info "- Servizi: Abilitati cpupower, fstrim, earlyoom, irqbalance"
    log_info "- Ottimizzazioni Avanzate: I/O, Memoria, Rete e Sicurezza"
    log_info "- Systemd: Ottimizzazioni servizi e journald"
    log_info "- Filesystem Avanzate: Ottimizzazioni tmpfs e filesystem specifici"
    log_info "- Gestione Energetica CPU: Ottimizzazioni avanzate power management"
    log_info "- Gestione Interrupt: Ottimizzazioni IRQ avanzate"
    log_info "- Memoria e Swap: Configurazione zswap e swapiness dinamico"
    log_info "- Scheduler Processi: Ottimizzazioni scheduling avanzate"
    log_info "- Limiti Sistema: Aumento limiti file e processi"
    log_info "- Driver Input: Ottimizzazioni latenza input"
    log_info "- Controller Storage: Ottimizzazioni AHCI e NVMe"
    log_info "- Termica Avanzata: Configurazione thermal daemon avanzata"

    if [ "$EXTREME_MODE" = true ]; then
        log_extreme "- Modalità ESTREMA: Ottimizzazioni aggressive applicate"
        log_warning "Monitorare attentamente le temperature del sistema!"
    fi

    echo
    log_warning "Alcune ottimizzazioni richiedono a riavvio per essere effettive."
    log_warning "Si consiglia di riavviare il sistema."
    echo
    read -p "Riavviare ora? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        reboot
    fi
}

main
