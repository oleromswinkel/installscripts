# Gentoo install guide/script for my Desktop running an AMD Ryzen 5 5600X and a NVIDIA RTX 3060Ti
Similar Guide I found: https://pastebin.com/tXCWA4Mn 

## Create partition layout (efi, root and optionally home and/or swap)
EFI Partition with UUID: `c12a7328-f81f-11d2-ba4b-00a0c93ec93b` <br>
Swap Partition with UUID: `0657fd6d-a4ab-43c4-84e5-0933c84b4f4f` <br>
Root Partition with UUID: `4f68bce3-e8cd-4db1-96e7-fbcaf984b709` 

```
fdisk /dev/nvme0n1
```

## Format partitions
```
mkfs.fat -F 32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
mkfs.ext4 /dev/nvme0n1p3
```

## Mount root partition
```
mkdir /mnt/gentoo
mount /dev/nvme0n1p2 /mnt/gentoo
cd /mnt/gentoo
```

## Download, extract and cleanup Stage 3 (amd64 desktop systemd merged-usr used in the following)
UNI Bochum: https://linux.rz.ruhr-uni-bochum.de/download/gentoo-mirror/releases/amd64/autobuilds/
```
wget <tarball link>
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
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
```

## chrooting
```
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"
```

## Mount efi partition
```
mkdir --parents /boot/efi
mount /dev/nvme0n1p1 /boot/efi
```

## Syncing system clock
```
chronyd -q
```

## Updating minimal install
```
emerge-webrsync
emerge --oneshot app-portage/mirrorselect
mirrorselect -i -o >> /etc/portage/make.conf
eselect news read
emerge --sync
```

## Selecting profile
```
eselect profile list
eselect profile set <profile number>
```

## Updating world set
```
emerge --ask --verbose --update --deep --newuse @world
```

## Setting timezone with OpenRC
```
echo "Europe/Berlin" > /etc/timezone
emerge --config sys-libs/timezone-data
```

## Setting locale, uncoment and set as needed
```
nano /etc/locale.gen
locale-gen
eselect locale list
eselect locale set <preferred>
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
```

## Installing firmware + AMD microcode (integrated)
```
emerge sys-kernel/linux-firmware
```

## Configuring and compiling kernel
```
emerge sys-kernel/gentoo-sources
eselect kernel list
eselect kernel set <preferred>
cd /usr/src/linux
make menuconfig
make -j12 && make modules_install
make install
emerge sys-kernel/installkernel
nano /etc/portage/package.use/module-rebuild
    > */* dist-kernel
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
