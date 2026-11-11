# Maintainer: MAMBO-LIT <mambo.lit@example.com>
# Contributor: Stefan Stoica <stefan.stoica@email.com>

pkgname=platinum-optimizer
pkgver=2.0.0
pkgrel=1
pkgdesc="Safe performance optimization tool for Arch Linux and Arch-based systems"
arch=('any')
url="https://github.com/mdxcodes/platinum-optimizer"
license=('MIT')
depends=('bash' 'pacman' 'coreutils')
optdepends=('cpupower: CPU power management'
            'powertop: Power consumption analysis'
            'tuned: Service profiles for power management'
            'earlyoom: Automatic RAM management'
            'terminus-font: Optional dependencies for better hooks')
makedepends=('git')
provides=('platinum-optimizer')
conflicts=('platinum-optimizer-git' 'platinum-optimizer-stable')
source=("$pkgname-$pkgver.tar.gz::https://github.com/mdxcodes/platinum-optimizer/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=('SKIP')  # Replace with actual SHA256 hash after building

pkgver() {
    cd "$srcdir/$pkgname-$pkgver"
    printf "%s" "$(cat VERSION.txt 2>/dev/null || echo "$pkgver")"
}

build() {
    cd "$srcdir/$pkgname-$pkgver"

    # Precompile if needed (bash scripts don't need compilation, but we can run checks)
    if command -v shellcheck &>/dev/null; then
        shellcheck -s bash -e SC1083,SC1091,SC2164,SC2039,SC2086 platinum.sh
    fi

    if command -v bash &>/dev/null; then
        bash -n platinum.sh
    fi
}

package() {
    cd "$srcdir/$pkgname-$pkgver"

    # Install the main script
    install -Dm755 platinum.sh "$pkgdir/usr/bin/platinum-optimizer"

    # Install usage document
    install -Dm644 README.md "$pkgdir/usr/share/doc/platinum-optimizer/README.md"

    # Install GitHub-modded version
    install -Dm755 docs/safety-guidé.md "$pkgdir/usr/share/doc/platinum-optimizer/SAFETY_GUIDE.md"

    # Install help man page
    mkdir -p "$pkgdir/usr/share/man/man1"
    cat << EOF > "$pkgdir/usr/share/man/man1/platinum-optimizer.1"
.TH PLATINUM-OPTIMIZER 1 "November 2024" "PlatinumArch Optimizer"
.SH NAME
PlatinumArch Optimizer \- Safe performance optimization tool
.SH SYNOPSIS
.B platinum-optimizer
.RB [ \-v ]
.RB [ \-\-dry-run ]
.RB [ \-h ]
.SH DESCRIPTION
PlatinumArch Optimizer provides conservative performance tuning for Arch Linux.
.RS
.br
.TP
.B -v, \-\-verbose
Enable debug logging
.TP
.B \-\-dry-run
Run without making changes
.TP
.B -h, \-\-help
Show this help message
.RE
.SH SALES
Always backup your system before running optimizations.
.SH LICENSE
MIT
EOF
    gzip "$pkgdir/usr/share/man/man1/platinum-optimizer.1"

    # Install cache directory
    install -dm755 "$pkgdir/usr/lib/platinum-optimizer"
}

# vim:set ts=4 sw=4 noet: