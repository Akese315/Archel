#!/bin/bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installation de la configuration Archel..."

# ============================================================
# HYPRLAND
# ============================================================

echo "→ Installation de la configuration Hyprland..."

mkdir -p "$ROOT/airootfs/etc/skel/.config"

rm -rf "$ROOT/airootfs/etc/skel/.config/hypr"

cp -a "$ROOT/config/hypr" "$ROOT/airootfs/etc/skel/.config/"


# ============================================================
# SDDM - THEME
# ============================================================

echo "→ Installation du thème SDDM..."

mkdir -p "$ROOT/airootfs/usr/share/sddm/themes"

rm -rf "$ROOT/airootfs/usr/share/sddm/themes/archel"

cp -a "$ROOT/config/sddm/themes/archel" "$ROOT/airootfs/usr/share/sddm/themes/"


# ============================================================
# SDDM - CONFIGURATION
# ============================================================

if [ -d "$ROOT/config/sddm/sddm.conf.d" ]; then

    echo "→ Installation de la configuration SDDM..."

    mkdir -p "$ROOT/airootfs/etc/sddm.conf.d"

    cp -a "$ROOT/config/sddm/sddm.conf.d/." "$ROOT/airootfs/etc/sddm.conf.d/"

fi


echo
echo "✓ Configuration Archel installée avec succès."