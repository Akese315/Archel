#!/bin/bash
set -e

# 1. Copier le système du live vers le disque monté sur /mnt
rsync -aAXH --exclude={"/dev/*","/proc/*","/sys/*","/run/*","/tmp/*","/mnt/*","/mnt","/etc/fstab"} / /mnt

# 2. fstab
genfstab -U /mnt > /mnt/etc/fstab

# 3. Retirer la config du live
rm -f /mnt/etc/mkinitcpio.conf.d/archiso.conf
cat > /mnt/etc/mkinitcpio.d/linux.preset << 'EOF'
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
PRESETS=('default' 'fallback')
default_image="/boot/initramfs-linux.img"
fallback_image="/boot/initramfs-linux-fallback.img"
fallback_options="-S autodetect"
EOF

# 4. Activer les services sur le système installé
arch-chroot /mnt systemctl enable sddm NetworkManager
arch-chroot /mnt systemctl set-default graphical.target

# 5. Initramfs et GRUB
arch-chroot /mnt mkinitcpio -P
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg