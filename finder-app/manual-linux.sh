#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=${1:-/tmp/aeld}
OUTDIR=$(realpath "$OUTDIR")
KERNEL_REPO=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

echo "Using output directory: $OUTDIR"

mkdir -p ${OUTDIR} || { echo "Failed to create output directory $OUTDIR"; exit 1; }

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
    git clone --depth 1 --branch ${KERNEL_VERSION} ${KERNEL_REPO} linux-stable
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}
    
    echo "Building the Linux kernel..."
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    cp arch/${ARCH}/boot/Image ${OUTDIR}/
fi

echo "Kernel build completed. Files are in $OUTDIR"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]; then
    echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm -rf ${OUTDIR}/rootfs
fi
mkdir -p ${OUTDIR}/rootfs/{bin,sbin,etc,proc,sys,usr,lib,dev,home,var,tmp}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]; then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    make distclean
    make defconfig
else
    cd busybox
fi

make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc)
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=${OUTDIR}/rootfs install || { echo "BusyBox installation failed"; exit 1; }

if [ ! -e "${OUTDIR}/rootfs/bin/busybox" ]; then
    echo "Error: BusyBox binary not found in ${OUTDIR}/rootfs/bin/"
    exit 1
fi

echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

SYSROOT=$(${CROSS_COMPILE}gcc --print-sysroot)

if [ -d "$SYSROOT/lib" ]; then
    cp -a $SYSROOT/lib/ld-* ${OUTDIR}/rootfs/lib/ || echo "Warning: ld-* not found in lib/"
fi

if [ -d "$SYSROOT/lib64" ]; then
    if [ ! -d "$OUTDIR/rootfs/lib64/" ]; then
        mkdir -p ${OUTDIR}/rootfs/lib64/
    fi
    cp -a $SYSROOT/lib64/ld-* ${OUTDIR}/rootfs/lib64/ || echo "Warning: ld-* not found in lib64/"
    cp -a $SYSROOT/lib64/libm.so.* ${OUTDIR}/rootfs/lib64/ || echo "Warning: libm.so.* not found"
    cp -a $SYSROOT/lib64/libresolv.so.* ${OUTDIR}/rootfs/lib64/ || echo "Warning: libresolv.so.* not found"
    cp -a $SYSROOT/lib64/libc.so.* ${OUTDIR}/rootfs/lib64/ || echo "Warning: libc.so.* not found"
else
    echo "Warning: lib64 directory not found in sysroot"
fi

sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1

cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
cp writer ${OUTDIR}/rootfs/home/

cp finder.sh finder-test.sh autorun-qemu.sh ${OUTDIR}/rootfs/home/
mkdir -p ${OUTDIR}/rootfs/home/conf
cp conf/username.txt conf/assignment.txt ${OUTDIR}/rootfs/home/conf/
sed -i 's|../conf/assignment.txt|conf/assignment.txt|' ${OUTDIR}/rootfs/home/finder-test.sh

sudo chown -R root:root ${OUTDIR}/rootfs

cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio

echo "Initramfs creation completed."
