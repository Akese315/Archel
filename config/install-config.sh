#!/bin/bash

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installation de la configuration Archel..."

# ─────────────────────────────────────────────
# Hyprland
# ─────────────────────────────────────────────

echo "→ Installation de la configuration Hyprland..."

mkdir -p "$SCRIPT_DIR/airootfs/etc/skel/.config"

rm -rf "$SCRIPT_DIR/airootfs/etc/skel/.config/hypr"

cp -r "$SCRIPT_DIR/config/hypr" \
      "$SCRIPT_DIR/airootfs/etc/skel/.config/hypr"


# ─────────────────────────────────────────────
# SDDM
# ─────────────────────────────────────────────

echo "→ Installation du thème SDDM..."

mkdir -p "$SCRIPT_DIR/airootfs/usr/share/sddm/themes"

rm -rf "$SCRIPT_DIR/airootfs/usr/share/sddm/themes/archel"

cp -r "$SCRIPT_DIR/config/sddm/archel" \
      "$SCRIPT_DIR/airootfs/usr/share/sddm/themes/archel"


# Configuration SDDM
if [ -f "$SCRIPT_DIR/config/sddm/archel.conf" ]; then

    echo "→ Installation de la configuration SDDM..."

    mkdir -p "$SCRIPT_DIR/airootfs/etc/sddm.conf.d"

    cp "$SCRIPT_DIR/config/sddm/archel.conf" \
       "$SCRIPT_DIR/airootfs/etc/sddm.conf.d/archel.conf"

fi


echo
echo "✓ Configuration Archel installée."