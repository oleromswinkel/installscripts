# Gentoo install guide/script for my Desktop running an AMD Ryzen 5 5600X and a NVIDIA RTX 3060Ti
Similar Guide I found: https://pastebin.com/tXCWA4Mn 

## Create efi and root partition (optionally home and/or swap)
EFI Partition with UUID: `c12a7328-f81f-11d2-ba4b-00a0c93ec93b` <br>
Swap Partition with UUID: `0657fd6d-a4ab-43c4-84e5-0933c84b4f4f` <br>
Root Partition with UUID: `4f68bce3-e8cd-4db1-96e7-fbcaf984b709` 

```
fdisk /dev/nvme0n1
```

## Format partitions
```
mkfs.fat -F 32 /dev/nvme0n1p1
mkfs.ext4 /dev/nvme0n1p3
```

## Mount Gentoo root partition
```
mkdir /mnt/gentoo
mount /dev/nvme0n1p2 /mnt/gentoo
cd /mnt/gentoo
```

## Download, extract and cleanup Stage 3 (amd64 desktop systemd merged-usr used in the following)
UNI Bochum: https://linux.rz.ruhr-uni-bochum.de/download/gentoo-mirror/releases/amd64/autobuilds/current-stage3-amd64-openrc/
```
wget https://linux.rz.ruhr-uni-bochum.de/download/gentoo-mirror/releases/amd64/autobuilds/current-stage3-amd64-desktop-systemd-mergedusr/stage3-amd64-desktop-systemd-mergedusr-20240303T170409Z.tar.xz
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
rm stage3-*.tar.xz
```

## Edit make.conf, tweak as needed (see make.conf)
```
vim /mnt/gentoo/etc/portage/make.conf
```

## Configuring repos, networking
```
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
```

## Preparing chroot
```
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm
```

## chrooting
```
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"
```

## Mount efi partition
```
mkdir /boot/efi
mount /dev/nvme0n1p1 /boot/efi
```

## Configuring gentoo system
```
emerge-webrsync
eselect profile list
eselect profile set XY
emerge --ask --verbose --update --deep --newuse @world
```

## All-in-One emerge for all further needed packages
Skipping system logger, cron daemon
```
emerge gentoo-sources lz4 sys-kernel/genkernel linux-firmware networkmanager e2fsprogs \
 sys-apps/mlocate grub:2
```

## Setting timezone with OpenRC
```
ln -sf ../usr/share/zoneinfo/Europe/Berlin /etc/localtime
```

## Setting locale, uncoment and set as needed
```
nano /etc/locale.gen
locale-gen
eselect locale list
eselect locale set <preferred>
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
```

## Configuring and compiling kernel
```
eselect kernel list
esekect kernel set XY
cd /usr/src/linux
make menuconfig
make -j12 -l12 && make -j12 -l12 modules
make install && make modules_install
```

## Generating initramfs (needed for surface devices)
```
genkernel --install --kernel-config /usr/src/linux/.config initramfs
```

## Editing fstab
```
nano /etc/fstab
    > /dev/nvme0n1p3    /           ext4    noatime             0   1
    > /dev/nvme0n1p1    /boot/efi   vfat    defaults,noatime    0   2
    > /dev/nvme0n1p2    none        swap    sw                  0   0
```

## Configuring hostname
```
nano /etc/conf.d/hostname
    > hostname="Desktop-Gentoo"
nano /etc/hosts
    > 127.0.0.1 Desktop-Gentoo
    > ::1       Desktop-Gentoo
```

## Setting Password
```
passwd
```

## Setting up networking 
```
systemctl enable NetworkManager
```

## Configuring bootloader, double check grub platforms in make.conf
```
grub-install --target=x86_64-efi --efi-directory=/boot/efi/ --bootloader-id=grub2
grub-mkconfig -o /boot/grub/grub.cfg
```

## Finishing up
```
exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
```