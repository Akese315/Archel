#!/bin/bash
# Installe le système live sur le disque monté sur /mnt (ESP montée sur /mnt/boot/efi).
# Usage : mount /dev/sdX2 /mnt ; mkdir -p /mnt/boot/efi ; mount /dev/sdX1 /mnt/boot/efi ; install.sh

set -eE

LOG="/var/log/install.log"
TOTAL=8
CURRENT_STEP="initialisation"

# --- Affichage -------------------------------------------------------------
BLUE=$'\e[1;34m'; GREEN=$'\e[1;32m'; YELLOW=$'\e[1;33m'; RED=$'\e[1;31m'; RESET=$'\e[0m'

step() {  # step <numéro> <description>
    CURRENT_STEP="$2"
    echo
    echo "${BLUE}[$1/$TOTAL]${RESET} $2..."
}
ok()   { echo "${GREEN}  ✔ $*${RESET}"; }
info() { echo "  → $*"; }
warn() { echo "${YELLOW}  ⚠ $*${RESET}"; }

# --- Gestion des erreurs ---------------------------------------------------
on_error() {
    local code=$? line=$1 cmd=$2
    echo
    echo "${RED}✘ ERREUR pendant l'étape : ${CURRENT_STEP}${RESET}"
    echo "${RED}  Ligne    : ${line}${RESET}"
    echo "${RED}  Commande : ${cmd}${RESET}"
    echo "${RED}  Code     : ${code}${RESET}"
    echo "${RED}  Journal complet : ${LOG}${RESET}"
    echo "${RED}Installation interrompue.${RESET}"
    exit "$code"
}
trap 'on_error $LINENO "$BASH_COMMAND"' ERR

# --- Journal : tout ce qui s'affiche est aussi écrit dans $LOG -------------
exec > >(tee -a "$LOG") 2>&1

echo "=== Installation démarrée le $(date '+%Y-%m-%d %H:%M:%S') ==="

# --- 0. Vérifications préalables ------------------------------------------
CURRENT_STEP="vérifications préalables"
echo
echo "${BLUE}[0/$TOTAL]${RESET} Vérifications préalables..."

[ "$(id -u)" -eq 0 ] || { echo "${RED}✘ Ce script doit être lancé en root.${RESET}"; exit 1; }

mountpoint -q /mnt || { echo "${RED}✘ /mnt n'est pas monté (partition racine).${RESET}"; exit 1; }
ok "/mnt est monté ($(findmnt -no SOURCE /mnt))"

mountpoint -q /mnt/boot/efi || { echo "${RED}✘ /mnt/boot/efi n'est pas monté (partition EFI).${RESET}"; exit 1; }
ok "/mnt/boot/efi est monté ($(findmnt -no SOURCE /mnt/boot/efi))"

[ -d /sys/firmware/efi ] || warn "Le live n'est pas démarré en UEFI : grub-install (EFI) risque d'échouer."

# --- 1. Copie du système ---------------------------------------------------
step 1 "Copie du système vers /mnt (peut prendre plusieurs minutes)"
rc=0
rsync -aAXH --info=progress2 \
    --exclude="/dev/*" --exclude="/proc/*" --exclude="/sys/*" --exclude="/run/*" \
    --exclude="/tmp/*" --exclude="/mnt/*" --exclude="/mnt" --exclude="/etc/fstab" \
    --exclude="/boot/efi/*" \
    --exclude="/root/.zsh_history" --exclude="/home/*/.zsh_history" \
    / /mnt || rc=$?
if [ "$rc" -eq 24 ]; then
    warn "Certains fichiers ont disparu pendant la copie (code 24), sans gravité."
elif [ "$rc" -ne 0 ]; then
    echo "${RED}✘ rsync a échoué (code $rc).${RESET}"
    exit "$rc"
fi
ok "Système copié"

# --- 2. fstab --------------------------------------------------------------
step 2 "Génération du fstab"
genfstab -U /mnt > /mnt/etc/fstab
info "Contenu :"
sed 's/^/     /' /mnt/etc/fstab
ok "fstab généré"

# --- 3. Retirer la config du live -----------------------------------------
step 3 "Suppression de la configuration archiso (preset mkinitcpio)"
rm -f /mnt/etc/mkinitcpio.conf.d/archiso.conf
cat > /mnt/etc/mkinitcpio.d/linux.preset << 'EOF'
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
PRESETS=('default' 'fallback')
default_image="/boot/initramfs-linux.img"
fallback_image="/boot/initramfs-linux-fallback.img"
fallback_options="-S autodetect"
EOF
if grep -q 'archiso' /mnt/etc/mkinitcpio.conf; then
    warn "/etc/mkinitcpio.conf mentionne encore 'archiso' : vérifie la ligne HOOKS."
fi
ok "Preset 'linux' remplacé par le preset standard"

# --- 4. Services -----------------------------------------------------------
step 4 "Activation des services (sddm, NetworkManager) et de graphical.target"
arch-chroot /mnt systemctl enable sddm NetworkManager
arch-chroot /mnt systemctl set-default graphical.target
ok "Services activés"

# --- 5. Initramfs ----------------------------------------------------------
step 5 "Installation du noyau et génération des initramfs (mkinitcpio -P)"
# Sur le live, le noyau n'est pas dans /boot du système : archiso le place sur le média (bootmnt).
if [ ! -f /mnt/boot/vmlinuz-linux ]; then
    KERNEL_SRC=""
    # 1) Le paquet linux fournit toujours /usr/lib/modules/<version>/vmlinuz (déjà copié par rsync)
    for d in /mnt/usr/lib/modules/*/; do
        if [ -f "${d}vmlinuz" ] && [ "$(cat "${d}pkgbase" 2>/dev/null)" = "linux" ]; then
            KERNEL_SRC="${d}vmlinuz"
            break
        fi
    done
    # 2) Sinon, le média live (absent si copytoram, Ventoy, etc.)
    if [ -z "$KERNEL_SRC" ]; then
        KERNEL_SRC="$(find /run/archiso/bootmnt -name vmlinuz-linux 2>/dev/null | head -n1)"
    fi
    if [ -z "$KERNEL_SRC" ]; then
        echo "${RED}✘ Noyau introuvable (ni dans /usr/lib/modules, ni sur /run/archiso/bootmnt).${RESET}"
        echo "${RED}  Solution : arch-chroot /mnt pacman -Sy linux (nécessite le réseau).${RESET}"
        exit 1
    fi
    info "Copie du noyau depuis $KERNEL_SRC"
    install -Dm644 "$KERNEL_SRC" /mnt/boot/vmlinuz-linux
fi
ok "Noyau présent : /boot/vmlinuz-linux"
arch-chroot /mnt mkinitcpio -P
[ -f /mnt/boot/initramfs-linux.img ] || { echo "${RED}✘ /boot/initramfs-linux.img est absent.${RESET}"; exit 1; }
ok "initramfs générés"

# --- 6. Installation de GRUB ----------------------------------------------
step 6 "Installation de GRUB (UEFI)"
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
ok "GRUB installé sur la partition EFI"

# --- 7. os-prober ----------------------------------------------------------
step 7 "Activation de os-prober (détection de Windows)"
if grep -q '^#\?GRUB_DISABLE_OS_PROBER' /mnt/etc/default/grub; then
    sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /mnt/etc/default/grub
else
    echo 'GRUB_DISABLE_OS_PROBER=false' >> /mnt/etc/default/grub
fi
ok "GRUB_DISABLE_OS_PROBER=false"

# --- 8. grub.cfg -----------------------------------------------------------
step 8 "Génération de grub.cfg"
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
[ -s /mnt/boot/grub/grub.cfg ] || { echo "${RED}✘ /boot/grub/grub.cfg est vide ou absent.${RESET}"; exit 1; }
ok "grub.cfg généré"

# --- Fin -------------------------------------------------------------------
echo
echo "${GREEN}=== Installation terminée avec succès ===${RESET}"
echo "Journal : ${LOG}"
echo "Tu peux maintenant : umount -R /mnt ; poweroff, puis retirer l'ISO."