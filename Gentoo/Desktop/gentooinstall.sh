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

# Edit make.conf, tweak as needed
vim /mnt/gentoo/etc/portage/make.conf

# Configuring repos
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
eselect news read
eselect profile list
    # eselect profile set XY
emerge --ask app-portage/cpuid2cpuflags
cpuid2cpuflags
emerge --ask --verbose --update --deep --newuse @world

# Setting timezone with OpenRC
echo "Europe/Berlin" > /etc/timezone
    # with systemd
    # ln -sf ../usr/share/zoneinfo/Europe/Berlin /etc/localtime
emerge --config sys-libs/timezone-data

# Setting locale
nano -w /etc/locale.gen
    > en_US.UTF-8 UTF-8
    > C.UTF8 UTF-8
locale-gen
eselect locale list
eselect locale set XY
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

# Configuring gentoo-overlay
emerge eselect-repository
eselect repository enable linux-surface
echo sys-kernel/surface-sources ~amd64 >> /etc/portage/package.accept_keywords
emerge dev-vcs/git
emerge --sync
emaint sync -r linux-surface
emerge --ask sys-kernel/surface-sources

# Configuring kernel
eselect kernel list
esekect kernel set XY
    # shoulf be 1 already
cd /usr/src/linux
# for premade: wget git.io/JRW9y && mv JRW9y .config
make nconfig
    # ensure MS-Surface specific driver & wifi-card
    # emerge pciutils
    # lspci -k | grep Ethernet to check
make -j8 && make modules_install
make install
# if using lz4 kernel compression
# emerge lz4

# generating initramfs (needed for surface devices)
emerge --ask sys-kernel/genkernel
genkernel --install --kernel-config /usr/src/linux/.config initramfs
# if not installed already, "R" in bracets means reinstall
    emerge linux-firmware

# Editing fstab
nano /etc/fstab
    > /dev/nvme0n1p5    /           ext4    noatime             0   1
    > /dev/nvme0n1p1    /boot/efi   vfat    defaults,noatime    0   2
    > /dev/nvme0n1p6    none        swap    sw                  0   0

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
rc-update add NetworkManager default

# OpenRC specific init
nano /etc/rc.conf
    > rc_parallel="YES"

# Hardware Clock
nano /etc/conf.d/hwclock
    # for dualboot with Windows
    >clock="local"
    >clock_hctosys="YES"
    >clock_systohc="YES"

# Installing different system utilities
# Skipping system logger, cron daemon
emerge --ask sys-apps/mlocate
emerge e2fsprogs
    # possibly already installed

# Configuring bootloader, double check grub platform in make.conf
emerge grub:2
grub-install --target=x86_64-efi --efi-directory=/boot/efi/
# for dualboot detecttion
    emerge os-prober
    nano /etc/default/grub
    > GRUB_DISABLE_OS_PROBER=false
grub-mkconfig -o /boot/grub/grub.cfg

# Finishing up
exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo