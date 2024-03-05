# Gentoo install guide/script for my Desktop running an AMD Ryzen 5 5600X and a NVIDIA RTX 3060Ti


# Create efi and root partition (optionally home, not covered)
fdisk /dev/nvme0n1

# Format partitions
mkfs.fat -F 32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
mkfs.ext4 /dev/nvme0n1p3

# Mount Gentoo root partition
mount /dev/nvme0n1p2 /mnt/gentoo
cd /mnt/gentoo

# Download, extract and cleanup Stage 3 (amd64 desktop systemd merged-usr used in the following)
# Example UNI Bochum: https://linux.rz.ruhr-uni-bochum.de/download/gentoo-mirror/releases/amd64/autobuilds/current-stage3-amd64-openrc/
wget https://linux.rz.ruhr-uni-bochum.de/download/gentoo-mirror/releases/amd64/autobuilds/current-stage3-amd64-desktop-systemd-mergedusr/stage3-amd64-desktop-systemd-mergedusr-20240303T170409Z.tar.xz
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
rm stage3-*.tar.xz

# Edit make.conf, tweak as needed (see make.conf)
vim /mnt/gentoo/etc/portage/make.conf

# Configuring repos, networking
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

#Preparing chroot
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm

# chrooting
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"

# Mount efi partition
mkdir /boot/efi
mount /dev/nvme0n1p1 /boot/efi

# Configuring gentoo system
emerge-webrsync
eselect profile list
    # eselect profile set XY
emerge --ask --verbose --update --deep --newuse @world

# Setting timezone with OpenRC
ln -sf ../usr/share/zoneinfo/Europe/Berlin /etc/localtime

# Setting locale, uncoment and set as needed
nano -w /etc/locale.gen
locale-gen
eselect locale list
eselect locale set XY
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

# Configuring kernel
emerge gentoo-sources
eselect kernel list
esekect kernel set XY
cd /usr/src/linux
make nconfig # or menuconfig, ..., whatever preferred
make && make modules_install
make install
# for lz4 kernel compression
# emerge lz4

# generating initramfs (needed for surface devices)
emerge --ask sys-kernel/genkernel
genkernel --install --kernel-config /usr/src/linux/.config initramfs
# if not installed already, "R" in bracets means reinstall
    emerge linux-firmware

# Editing fstab
nano /etc/fstab
    > /dev/nvme0n1p3    /           ext4    noatime             0   1
    > /dev/nvme0n1p1    /boot/efi   vfat    defaults,noatime    0   2
    > /dev/nvme0n1p2    none        swap    sw                  0   0

# Setting hostname
nano /etc/conf.d/hostname
    > hostname="SP7-Gentoo"
nano /etc/hosts
    > 127.0.0.1 SP7-Gentoo
    > ::1       SP7-Gentoo

#Setting Password
passwd

# Setting up networking
emerge networkmanager
systemctl enable NetworkManager

# Installing different system utilities
# Skipping system logger, cron daemon
emerge --ask sys-apps/mlocate
emerge e2fsprogs

# Configuring bootloader, double check grub platforms in make.conf
emerge grub:2
grub-install --target=x86_64-efi --efi-directory=/boot/efi/ --bootloader-id=grub2
grub-mkconfig -o /boot/grub/grub.cfg

# Finishing up
exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo