UNFINISHED

# install medium config
Loading appropriate keymap
```loadkeys de-latin1```
Setting up wifi if neccesary
`iwctl`
loadkeys de-latin1
timedatectl set-ntp true
reflector -c 'Germany' -a 12 - -sort rate - -save etc/pacman.d/mirrorlist
pacman -Syy

# partitioning disk
fdisk /dev/nvme0n1
mkfs.fat -F32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
mkfs.ext4 /dev/nvme0n1p3

# mounting disk
mount /dev/nvme0n1p3 /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

# installing base system
pacstrap /mnt base linux linux-firmware intel-ucode vim nano
genfstab -U /mnt >> /mnt/etc/fstab

# configuring in chroot environmnent
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
vim /etc/locale.gen   #uncomment locale, ISO and UTF-8
locale-gen
vim etc/locale.conf   #set language: LANG=en_US.UTF-8
vim /etc/hostname   #set hostname
vim /etc/hosts
# 127.0.0.1 localhost
# ::1   localhost
# 127.0.0.1 myhostname.localdomain myhostname
passwd

pacman -S linux-headers networkmanager network-manager-applet grub mtools dosfstools git \
    pulseaudio reflector xdg-utils xdg-user-dirs cups bluez-utils bluez

grub-install -target=x86_64-efi -efi-directory=/boot/efi -bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable NetworkManager
useradd -m -G wheel username
passwd username
visudo
bootctl install
exit

# extra packages after seccesful boot
sudo pacman -S xorg
sudo pacman -S gnome gnome-extra
sudo pacman -S libreoffice firefox thunderbird vlc \
    tar unrar p7zip p7zip-plugins rsync