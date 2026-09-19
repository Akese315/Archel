#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$REPO_ROOT/.." && pwd)"

echo "==> Installation de la configuration Archel dans : $ROOT"

# ============================================================
# HYPRLAND
# ============================================================

echo "→ Installation de la configuration Hyprland..."

mkdir -p "$ROOT/airootfs/etc/skel/.config"

rm -rf "$ROOT/airootfs/etc/skel/.config/hypr"

cp -a "$REPO_ROOT/config/hypr" "$ROOT/airootfs/etc/skel/.config/"


# ============================================================
# SDDM - THEME
# ============================================================

echo "→ Installation du thème SDDM..."

mkdir -p "$ROOT/airootfs/usr/share/sddm/themes"

rm -rf "$ROOT/airootfs/usr/share/sddm/themes/archel"

cp -a "$REPO_ROOT/config/sddm/themes/archel" "$ROOT/airootfs/usr/share/sddm/themes/"


# ============================================================
# SDDM - CONFIGURATION
# ============================================================

if [ -d "$REPO_ROOT/config/sddm/sddm.conf.d" ]; then

    echo "→ Installation de la configuration SDDM..."

    mkdir -p "$ROOT/airootfs/etc/sddm.conf.d"

    cp -a "$REPO_ROOT/config/sddm/sddm.conf.d/." "$ROOT/airootfs/etc/sddm.conf.d/"

fi


echo
echo "✓ Configuration Archel installée avec succès."