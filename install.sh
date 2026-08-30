#!/usr/bin/env bash
#
# install.sh — Installateur automatique Arch Linux (dual-boot friendly)
# À lancer depuis l'environnement live (clé USB Archel), en root.
#
set -euo pipefail

DOTFILES_REPO_DEFAULT="https://github.com/Akese315/Archel.git"
MIN_FREE_MIB=30000   # 30 Go minimum pour proposer une zone d'espace libre

PACKAGES=(
    base linux linux-firmware nano git openssh sudo networkmanager
    grub os-prober efibootmgr
    hyprland kitty waybar wofi dunst hyprpaper hyprlock
    polkit-gnome xdg-desktop-portal-hyprland
    pipewire pipewire-pulse pipewire-alsa wireplumber sof-firmware
    base-devel firefox thunar grim slurp pavucontrol brightnessctl
    network-manager-applet ttf-jetbrains-mono-nerd noto-fonts
    papirus-icon-theme vim
)

msg() { whiptail --title "Archel Installer" --msgbox "$1" 12 70; }
err() { whiptail --title "Erreur" --msgbox "$1" 12 70; exit 1; }

# --- 0. Vérifications préalables ---
[[ $EUID -eq 0 ]] || err "Ce script doit être lancé en root."
[[ -d /sys/firmware/efi/efivars ]] || err "Mode BIOS legacy détecté. Ce script nécessite l'UEFI."

whiptail --title "Archel Installer" --yesno \
"Cet installateur va :
- Détecter de l'espace disque libre non partitionné
- Créer une partition swap + une partition système dedans
- Installer Arch Linux + Hyprland + tes dotfiles
- Configurer GRUB en dual-boot avec Windows

Aucune partition existante ne sera modifiée ou supprimée.

Continuer ?" 16 70 || exit 0

# --- 1. Détection de l'espace libre non alloué, sur tous les disques ---
CANDIDATES=()   # chaque entrée : "disk|start|end|size_desc"
for disk in $(lsblk -dn -o NAME -e 7,11 | sed 's|^|/dev/|'); do
    while IFS= read -r line; do
        # ligne type: "  123456MiB  654321MiB  530865MiB  Free Space"
        if [[ "$line" == *"Free Space"* ]]; then
            start=$(awk '{print $1}' <<< "$line")
            end=$(awk '{print $2}' <<< "$line")
            size=$(awk '{print $3}' <<< "$line")
            size_num=${size%MiB}
            size_num=${size_num%.*}
            if [[ "$size_num" =~ ^[0-9]+$ ]] && (( size_num >= MIN_FREE_MIB )); then
                CANDIDATES+=("$disk|$start|$end|$disk : $size libres")
            fi
        fi
    done < <(parted -s "$disk" unit MiB print free 2>/dev/null | tail -n +8)
done

[[ ${#CANDIDATES[@]} -gt 0 ]] || err "Aucun espace libre non partitionné (>= ${MIN_FREE_MIB} MiB) trouvé sur les disques."

MENU_ITEMS=()
i=0
for c in "${CANDIDATES[@]}"; do
    desc="${c##*|}"
    MENU_ITEMS+=("$i" "$desc")
    ((i++))
done

CHOICE=$(whiptail --title "Choix de la zone d'installation" --menu \
    "Sélectionne l'espace libre à utiliser pour Arch Linux :" 20 78 10 \
    "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3) || exit 0

IFS='|' read -r TARGET_DISK FREE_START FREE_END _ <<< "${CANDIDATES[$CHOICE]}"

whiptail --title "Confirmation" --yesno \
"Zone sélectionnée :
Disque : $TARGET_DISK
De $FREE_START à $FREE_END

Cette zone va être partitionnée (swap + système).
Aucune autre partition ne sera touchée.

Confirmer ?" 14 70 || exit 0

# --- 2. Création des partitions dans l'espace libre ---
SWAP_END_MIB=$(( ${FREE_START%MiB} + 4096 ))   # 4 Go de swap

parted -s "$TARGET_DISK" \
    mkpart primary linux-swap "${FREE_START}" "${SWAP_END_MIB}MiB" \
    mkpart primary ext4 "${SWAP_END_MIB}MiB" "${FREE_END}"

sleep 2
partprobe "$TARGET_DISK"
sleep 2

# Identifier les nouvelles partitions (les 2 dernières créées sur ce disque)
mapfile -t NEW_PARTS < <(lsblk -ln -o NAME "$TARGET_DISK" | tail -n 2 | sed "s|^|/dev/|")
SWAP_PART="${NEW_PARTS[0]}"
ROOT_PART="${NEW_PARTS[1]}"

# --- 3. Trouver la partition EFI existante (celle de Windows) ---
EFI_PART=$(lsblk -ln -o NAME,PARTTYPE,FSTYPE "$TARGET_DISK" \
    | awk '$3=="vfat"{print $1}' | head -n1)
[[ -n "$EFI_PART" ]] || err "Aucune partition EFI existante trouvée sur $TARGET_DISK."
EFI_PART="/dev/$EFI_PART"

# --- 4. Formatage et montage ---
mkswap "$SWAP_PART"
swapon "$SWAP_PART"
mkfs.ext4 -F "$ROOT_PART"
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot/efi
mount "$EFI_PART" /mnt/boot/efi

# --- 5. Installation du système de base + paquets ---
pacstrap -K /mnt "${PACKAGES[@]}"
genfstab -U /mnt >> /mnt/etc/fstab

# --- 6. Infos utilisateur (nom, mot de passe, hostname) ---
HOSTNAME=$(whiptail --inputbox "Nom de la machine (hostname) :" 10 60 "archel" 3>&1 1>&2 2>&3)
USERNAME=$(whiptail --inputbox "Ton nom d'utilisateur :" 10 60 "axel" 3>&1 1>&2 2>&3)
USERPASS=$(whiptail --passwordbox "Mot de passe pour $USERNAME :" 10 60 3>&1 1>&2 2>&3)
ROOTPASS=$(whiptail --passwordbox "Mot de passe root :" 10 60 3>&1 1>&2 2>&3)
DOTFILES_REPO=$(whiptail --inputbox "URL du repo dotfiles (HTTPS) :" 10 70 "$DOTFILES_REPO_DEFAULT" 3>&1 1>&2 2>&3)
DOTFILES_TOKEN=$(whiptail --passwordbox "Token GitHub (laisser vide si repo public) :" 10 70 3>&1 1>&2 2>&3)

# --- 7. Configuration dans le chroot ---
arch-chroot /mnt /bin/bash <<CHROOT_EOF
set -e
echo "KEYMAP=fr" > /etc/vconsole.conf
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
sed -i 's/^#fr_FR.UTF-8/fr_FR.UTF-8/' /etc/locale.gen
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
echo "$HOSTNAME" > /etc/hostname

echo "root:$ROOTPASS" | chpasswd
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$USERPASS" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

systemctl enable NetworkManager

# GRUB en mode UEFI, avec détection Windows
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Archel
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Dotfiles
if [[ -n "$DOTFILES_TOKEN" ]]; then
    CLONE_URL=\$(echo "$DOTFILES_REPO" | sed "s|https://|https://$DOTFILES_TOKEN@|")
else
    CLONE_URL="$DOTFILES_REPO"
fi
su - "$USERNAME" -c "git clone \$CLONE_URL ~/dotfiles"
su - "$USERNAME" -c "bash -c '
for f in ~/dotfiles/home/.*; do
    name=\\\$(basename \\\$f)
    [[ \\\$name == \".\" || \\\$name == \"..\" ]] && continue
    ln -sfn \\\$f ~/\\\$name
done
mkdir -p ~/.config
for f in ~/dotfiles/config/*; do
    name=\\\$(basename \\\$f)
    ln -sfn \\\$f ~/.config/\\\$name
done
'"
CHROOT_EOF

# --- 8. Fin ---
umount -R /mnt
swapoff "$SWAP_PART" || true

whiptail --title "Terminé" --msgbox \
"Installation terminée !
Retire la clé USB et redémarre.
Ta machine devrait proposer Arch Linux et Windows au démarrage." 12 70
