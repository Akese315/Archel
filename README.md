# Archel

Configuration personnelle d’un environnement Arch Linux basé sur Hyprland, avec un thème SDDM assorti.

Le dépôt contient :

- une configuration Hyprland modulaire en Lua ;
- un thème SDDM nommé `archel` ;
- des scripts pour préparer un système installé depuis un environnement live Arch ;
- un script pour copier la configuration dans l’arborescence `airootfs` d’un projet Archiso.

## Structure

```text
config/
├── hypr/
│   ├── hyprland.lua
│   ├── hyprlock.conf
│   ├── hyprpaper.conf
│   ├── modules/       # Programmes, raccourcis, apparence, écrans, règles...
│   └── wallpapers/
└── sddm/
    ├── sddm.conf.d/   # Configuration du greeter SDDM
    └── themes/archel/ # Thème SDDM et ses fonds d’écran
```

## Prérequis

Pour utiliser la configuration :

- une installation Arch Linux démarrée en UEFI ;
- Hyprland, SDDM et NetworkManager installés ;
- les programmes utilisés par la configuration : Kitty, Dolphin, Firefox, Waybar,
  `nm-applet`, Hyprpaper, Hyprlock et un lanceur comme Rofi ou Wofi ;
- `rsync`, `genfstab`, `arch-chroot`, `grub-install` et `grub-mkconfig` pour le
  script d’installation du système.

Les commandes et paquets exacts peuvent dépendre de l’image Archiso utilisée.

## Installation dans un projet Archiso

`install-sddm-config.sh` est prévu pour être exécuté depuis un dépôt placé à côté
d’une arborescence Archiso contenant `airootfs` :

```text
projet-archiso/
├── airootfs/
└── Archel/
```

Depuis le dossier `Archel` :

```bash
chmod +x install-sddm-config.sh
./install-sddm-config.sh
```

Le script copie ensuite :

- `config/hypr` vers `airootfs/etc/skel/.config/hypr` ;
- le thème SDDM vers `airootfs/usr/share/sddm/themes/archel` ;
- la configuration SDDM vers `airootfs/etc/sddm.conf.d`.

Après cette étape, reconstruisez votre image Archiso avec votre outil habituel.

## Installation sur un système monté

`install-os-config.sh` transforme un système Arch préparé sur `/mnt` en
installation démarrable. Depuis un environnement live Arch, montez d’abord la
partition racine et la partition EFI :

```bash
mount /dev/sdX2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sdX1 /mnt/boot/efi
```

Puis exécutez le script depuis le live :

```bash
chmod +x install-os-config.sh
sudo ./install-os-config.sh
```

Le script doit être lancé en root et vérifie que `/mnt` et `/mnt/boot/efi`
sont montés. Il :

1. copie le système live vers `/mnt` avec `rsync` ;
2. génère `/mnt/etc/fstab` ;
3. remplace le preset `mkinitcpio` Archiso ;
4. active SDDM et NetworkManager ;
5. copie le noyau depuis `/mnt/usr/lib/modules/*/vmlinuz` vers
  `/mnt/boot/vmlinuz-linux`, puis génère les initramfs ;
6. installe GRUB en mode UEFI ;
7. active la détection des systèmes Windows avec `os-prober` ;
8. génère la configuration GRUB.

Si la copie doit être faite manuellement avant l’exécution de `mkinitcpio` :

```bash
cp /mnt/usr/lib/modules/*/vmlinuz /mnt/boot/vmlinuz-linux
```

Un journal complet est écrit dans `/var/log/install.log`. Une fois l’installation
terminée :

```bash
umount -R /mnt
poweroff
```

Retirez ensuite le support live avant de redémarrer.

## Personnalisation

Les programmes lancés par défaut sont définis dans
`config/hypr/modules/programs.lua`. Les services démarrés avec Hyprland sont
définis dans `config/hypr/modules/autostart.lua`.

Les écrans, raccourcis, règles, entrées et apparences sont séparés dans les
autres modules du dossier `config/hypr/modules`. Le fond et les couleurs du
thème SDDM sont configurés dans `config/sddm/themes/archel/theme.conf`.

## Attention

Les scripts modifient ou remplacent des fichiers du système cible, notamment
`/etc/fstab`, le preset `mkinitcpio`, la configuration GRUB et les fichiers de
configuration copiés dans `airootfs`. Vérifiez les périphériques `/dev/sdX1` et
`/dev/sdX2` avant toute exécution.

## Licence

Le thème SDDM indique une licence GPL-3.0-or-later.