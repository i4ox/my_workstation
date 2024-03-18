# Arch + i3 = ❤️

### Quick Links

* [Connect to the Wi-Fi](#wifi)
* [Create,format,mount the partitions](#partitions)
* [Base install](#base_install)
* [Base configuration after install](#after_install)
* [Network utils](#net_utils)
* [Configure pacman](#pacman)
* [Nvidia](#nvidia)
* [Audio and bluetooth](#audio_bluetooth)
* [Keyboard layouts](#keyboard)
* [X11 Server](#x11)

## Connect to the Wi-Fi <a id='wifi'></a>

```sh
iwctl
> station wlan0 scan wifi
> station wlan0 get-networks
> station wlan0 connect SSID
> quit
```

## Create,format,mount the partitions <a id='partitions'></a>

```sh
# Create EFI, BOOT and ROOT partitions
cfdisk /dev/nvme0n1 # or /dev/sda

# Format the partitions
mkfs.vfat -nBOOT -F32 /dev/nvme0n1p1 # or /dev/sda1
mkfs.ext2 -L grub /dev/nvme0n1p2 # or /dev/sda2
mkfs.btrfs -L arch -f /dev/nvme0n1p3 # or /dev/sda3

# Mount the partitions
BTRFS_OPTS="rw,ssd,discard=async,noatime,compress=zstd,commit=120,space_cache=v2"
mount -o $BTRFS_OPTS /dev/nvme0n1p3 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt

mount -o $BTRFS_OPTS,subvol=@ /dev/nvme0n1p3 /mnt
mkdir /mnt/home && mount -o $BTRFS_OPTS,subvol=@home /dev/nvme0n1p3 /mnt/home
mkdir /mnt/.snapshots && mount -o $BTRFS_OPTS,subvol=@snapshots /dev/nvme0n1p3 /mnt/.snapshots

# Extra subvolumes
mkdir -p /mnt/var/cache
btrfs subvolume create /mnt/var/cache/pacman
btrfs subvolume create /mnt/var/tmp
btrfs subvolume create /mnt/srv
btrfs subvolume create /mnt/var/swap # Only if you need a swapfile

mkdir /mnt/efi && mount -o rw,noatime /dev/nvme0n1p1 /mnt/efi # or /dev/sda1
mkdir /mnt/boot && mount -o rw,noatime /dev/nvme0n1p2 /mnt/boot # or /dev/sda2
```

## Base install <a id='base_install'></a>

```sh
# Optimize the pacman(for the better performance and speed)
pacman -Syy
pacman -S reflector
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector -c "RU" -p https -l 10 -n 10 --save /etc/pacman.d/mirrorlist

pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware neovim btrfs-progs {intel,amd}-ucode iucode-tool

genfstab -U /mnt >> /mnt/etc/fstab
BTRFS_OPTS=$BTRFS_OPTS PS1='chroot# ' arch-chroot /mnt /bin/bash
```

## Base configuration after install <a id="after_install"></a>

```sh
# Setting TimeZone
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Setting up locale
sed -i "s/#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
sed -i "s/#ru_RU.UTF-8/ru_RU.UTF-8/g" /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
export LANG=en_US.UTF-8

# Network configuration
echo 'arch' > /etc/hostname
cat << EOF >> /etc/hosts
127.0.0.1       localhost
::1             localhost
127.0.1.1       arch.localdomain  arch
EOF

# Setup the root password
passwd

# Install Grub bootloader
pacman -S grub efibootmgr mtools dosfstools os-prober
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/efi
grub-mkconfig -o /boot/grub/grub.cfg

# Create additional user
pacman -S sudo
useradd -m -g users -G wheel,storage,audio,video,power -s /bin/bash user
passwd user
sed -i "s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g" /etc/sudoers
```

## Network utils <a id="net_utils"></a>

```sh
pacman -S net-tools iproute2 networkmanager wpa_supplicant dhcpcd
systemctl enable NetworkManager.service
systemctl enable dhcpcd
```

## Configure pacman <a id="pacman"></a>

```sh
# Install AUR helper
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd .. && rm -rf yay

# Enable multilib
sudo nvim /etc/pacman.conf # Uncomment the two lines below
# [multilib]
# Include = /etc/pacman.d/mirrorlist
# Also add Color, ParallelDownloads and ILoveCandy
yay -Syu
```

## Nvidia <a id="nvidia"></a>

```sh
yay -S nvidia-dkms nvidia-utils nvidia-settings opencl-nvidia lib32-opencl-nvidia lib32-nvidia-utils

sed -i "s/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/g" /etc/mkinitcpio.conf

sudo mkdir -p /etc/modprobe.d
cat >> /etc/modprobe.d/nvidia-drm-nomodeset.conf<<EOF
options nvidia_drm modeset=1
EOF
sudo mkinitcpio -P

sudo mkdir -p /etc/pacman.d/hooks
cat >> /etc/pacman.d/hooks/nvidia.hook<<EOF
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-dkms

[Action]
Depends=mkinitcpio
When=PostTransaction
Exec=/usr/bin/mkinitcpio -P
EOF
sudo nvidia-xconfig
sudo mv /etc/X11/xorg.conf /etc/X11/xorg.conf.d/20-nvidia.conf
```

## Audio and bluetooth <a id="audio_bluetooth"></a>

```sh
yay -S pipewire pipewire-alsa pipewire-pulse pipewire-jack alsa-utils wireplumber pavucontrol lib32-pipewire lib32-pipewire-jack bluez bluez-utils
yay -S pulsemixer bluetuith
sudo systemctl enable bluetooth.service
mkdir -p ~/.config/pipewire/media-session.d/
cp /usr/share/pipewire/*.conf ~/.config/pipewire/
sudo nvim ~/.config/pipewire/pipewire.conf # Add into default.clock.allowed-rates "44100"
systemctl --user enable pipewire.service
systemctl --user enable pipewire-pulse.service
```

## Keyboard layouts <a id="keyboard"></a>

```sh
cat > /etc/X11/xorg.conf.d/00-keyboard.conf <<EOF
Section "InputClass"
            Identifier "system-keyboard"
            MatchIsKeyboard "on"
            Option "XkbLayout" "us,ru"
            Option "XkbModel" "pc105"
            Option "XkbOptions" "grp:alt_shift_toggle"
EndSection
EOF
```

## X11 server <a id="x11"></a>

```sh
yay -S xorg-server xorg-xinit xclip
cp /etc/X11/xinit/xinitrc ~/.xinitrc
nvim ~/.xinitrc # Add something
startx # Run after add something you need

sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin i4ox --noclear %I 38400 linux
EOF
sudo sed -i "s/i4ox/${USER}/g" /etc/systemd/system/getty@tty1.service.d/override.conf

sudo cat > ~/.bash_profile <<EOF
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec startx
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
EOF
```
