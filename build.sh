#!/bin/bash
#
# Kernel build script for Samsung S24 devices
# Modified version by notfleshka, original by dx4m
# SPDX-License-Identifier: GPL-3.0

# Main variables
CURRENT_DIR="$(pwd)"    # Current directory
KERNELBUILD="${CURRENT_DIR}"  # Kernel build root directory
TOOLS="${KERNELBUILD}/tools"    # Tools directory
PREBUILTS="${KERNELBUILD}/prebuilts" # Prebuilts directory
EXTERNAL="${KERNELBUILD}/external"  # External directory
BUILD="${KERNELBUILD}/build"    # Build directory
KERNEL_DIR="${KERNELBUILD}" # Kernel source directory
OUTPUT_DIR="${CURRENT_DIR}/out" # Output directory
BUILDCHAIN="${KERNELBUILD}/buildchain"  # AOSP buildchain directory
BUILD_HOST=""   # Build host name
BUILD_USER=""   # Build user name

DISABLE_SAMSUNG_PROTECTION=true # Disables Samsung kernel protection, soon to be deprecated with another method
ENABLE_KERNELSU=false      # Enables KernelSU support, soon to be deprecated with another method
ENABLE_SUSFS=false    # Enables SuSFS support, soon to be deprecated with another method
ENABLE_KPM=false   # Enables KPM support from SukiSU Ultra, soon to be deprecated with another method
MENUCONFIG=false    # Enables menuconfig
# PRINTHELP=false   # Hardcodly disabled, code remnants still present. Prints help message
CLEAN=false # Cleans output directory
CONFIG=false    # Only configures the kernel (I am not so sure about what it does)
# CLEAN_BUILDCHAIN=false # Hardcordly disabled. Removes buildchain every build. If false, then downloading buildchain and copying prebuilts are skipped.

# This was used for fixing some versioning issues, but now I think it's not needed, code remnants are still present
# SETVERSION=""   # Hardcordly disabled. Kernel version to set, I am not sure what is difference between this and local ver)
# LOCALVERSION="" # Hardcordly disabled. Local version string, I am not sure what is difference between this and set ver)

LINUX_VER=$(make kernelversion 2>/dev/null) # Kernel linux version
KERNEL_NAME=""  # Kernel name (will be put in ak3 zip name) 
KERNEL_VER=""   # Kernel version (will be put in ak3 zip name)
EXTRA_NOTES=""  # Extra notes to put in ak3 zip name

BUILDCHAIN_URL="https://android.googlesource.com/kernel/manifest"   # URL of buildchain
BUILDCHAIN_BRANCH="common-android14-6.1"    # Branch of buildchain
AK3_REPO="https://github.com/notfleshka/AnyKernel3-S24" # AnyKernel3 repo URL
AK3_ZIP="${CURRENT_DIR}/$KERNEL_NAME-$KERNEL_VER-$EXTRA_NOTES-$DATE.zip"    # AnyKernel3 zip output path
AK3_DIR="${CURRENT_DIR}/AnyKernel3" # AnyKernel3 working directory
ODIN_TAR="${CURRENT_DIR}/boot.img.tar"  # Odin tar output path

TARGETSOC="s5e9945"
TARGET_DEFCONFIG="${1:-e1s_defconfig}"
# End of main variables

# Remove buildchain
function removeBuildchain() {
    rm -rf "$BUILDCHAIN"
}

# Download buildchain 
function getBuildtools() {
    echo "[💠] Getting the buildchain..."
    mkdir -p "$BUILDCHAIN" && cd "$BUILDCHAIN" || return 1

    repo init --depth=1 -u "$BUILDCHAIN_URL" -b "$BUILDCHAIN_BRANCH"
    repo sync -c -n -j 4
    repo sync -c -l -j 16

    cd "$CURRENT_DIR"
    echo "[✅] Buildchain downloaded."
}

function movePrebuilts() {
    echo "[💠] Copying prebuilts into kernel source tree..."
    cp -r "$BUILDCHAIN/tools" "$TOOLS"
    cp -r "$BUILDCHAIN/prebuilts" "$PREBUILTS"
    cp -r "$BUILDCHAIN/external" "$EXTERNAL"
    cp -r "$BUILDCHAIN/build" "$BUILD"
    echo "[✅] Done."
}

# if [ ! -d "$PREBUILTS" ]; then
#    if [ "$CLEAN_BUILDCHAIN" = true ]; then
#        removeBuildchain
        getBuildtools
        movePrebuilts
#    else
#        echo "[💠] Skipping buildchain download and prebuilt copy."
#    fi
#fi

# Broken and not needed
# if [ ! -d "$KERNEL_DIR" ]; then
#    echo "[❌] Missing kernel"
#    exit 1
# fi


while [[ $# -gt 0 ]]; do
    case "$1" in
        --disable-samsung-protection) DISABLE_SAMSUNG_PROTECTION=true; shift;;
        --enable-kernelsu) ENABLE_KERNELSU=true; shift;;
        menuconfig) MENUCONFIG=true; shift;;
        config) CONFIG=true; shift;;
        clean) CLEAN=true; shift;;
#        --help) PRINTHELP=true; shift;;
        --version) shift; LINUX_VER="$1"; shift;;
        *) OTHER_ARGS+=("$1"); shift;;
    esac
done


echo -e "\nINFO: Build info:
- Device: $TARGETSOC
- Kernel Name: $KERNEL_NAME
- Kernel Version: $LOCALVERSION
- Notes: $EXTRA_NOTES
- Linux version: $LINUX_VER
- Build date: $DATE
- Clean output: $CLEAN
- Menuconfig: $MENUCONFIG
- Config only: $CONFIG
- Disable Samsung Protection: $DISABLE_SAMSUNG_PROTECTION
- Enable KernelSU: $ENABLE_KERNELSU
"

install_deps_deb() {
    # Dependencies
    UB_DEPLIST="git-core gnupg flex bison build-essential zip curl zlib1g-dev libc6-dev-i386 x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig python3 repo"
        echo "INFO: Make sure you have these dependencies installed before proceeding: $UB_DEPLIST"
        echo "INFO: Names of these dependencies are for Ubuntu/Debian-based distros, please check how are they called on other distros."
        read -p "Are these dependencies installed? (y/n): " confirm
        case "${confirm,,}" in
            y|yes)
                echo "INFO: Continuing..."
                ;;
            *)
                echo "ERROR: Please install the dependencies manually before proceeding."
                exit 1
                ;;
        esac
}

install_deps_deb


# if [ "$PRINTHELP" = true ]; then
# cat << EOF
# build.sh [OPTIONS]
#  --disable-samsung-protection   (default)
#  --enable-kernelsu
#  menuconfig
#  config
#  clean
#  --version <ver>
# EOF
# exit 0
# fi

if [ "$CLEAN" = true ]; then
    rm -rf "$OUTPUT_DIR"
    echo "[✅] Cleaned."
    exit 0
fi

# Env setup 
export PATH="${PREBUILTS}/build-tools/linux-x86/bin:${PATH}"
export PATH="${PREBUILTS}/build-tools/path/linux-x86:${PATH}"
export PATH="${PREBUILTS}/clang/host/linux-x86/clang-r510928/bin:${PATH}"
export PATH="${PREBUILTS}/kernel-build-tools/linux-x86/bin:${PATH}"

LLD_COMPILER_RT="-fuse-ld=lld --rtlib=compiler-rt"
SYSROOT_FLAGS="--sysroot=${PREBUILTS}/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/sysroot"

CFLAGS="-I${PREBUILTS}/kernel-build-tools/linux-x86/include "
LDFLAGS="-L${PREBUILTS}/kernel-build-tools/linux-x86/lib64 ${LLD_COMPILER_RT}"

export LD_LIBRARY_PATH="${PREBUILTS}/kernel-build-tools/linux-x86/lib64"
export HOSTCFLAGS="${SYSROOT_FLAGS} ${CFLAGS}"
export HOSTLDFLAGS="${SYSROOT_FLAGS} ${LDFLAGS}"

ARGS="CC=clang LD=ld.lld ARCH=arm64 LLVM=1 LLVM_IAS=1"
CONFIG_FILE="${OUTPUT_DIR}/.config"

if [ -f "$CONFIG_FILE" ]; then
    TARGET_DEFCONFIG="oldconfig"
fi

# CONFIG only
if [ "$CONFIG" = true ]; then
    make -j"$(nproc)" -C "$KERNEL_DIR" O="$OUTPUT_DIR" $ARGS "$TARGET_DEFCONFIG"
    exit 0
fi

# MENUCONFIG
if [ "$MENUCONFIG" = true ]; then
    make -j"$(nproc)" -C "$KERNEL_DIR" O="$OUTPUT_DIR" $ARGS "${TARGET_DEFCONFIG}" HOSTCFLAGS="${CFLAGS}" HOSTLDFLAGS="${LDFLAGS}" menuconfig
    exit 0
fi

# Build defconfig
make -j"$(nproc)" \
    -C "${KERNEL_DIR}" O="${OUTPUT_DIR}" ${ARGS} \
    EXTRA_CFLAGS:=" -DCFG80211_SINGLE_NETDEV_MULTI_LINK_SUPPORT -DTARGET_SOC=${TARGETSOC}" \
    "${TARGET_DEFCONFIG}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "[❌] .config missing"
    exit 1
fi

# KernelSU enable
if [ "$ENABLE_KERNELSU" = true ]; then
    "${KERNEL_DIR}/scripts/config" --file "$CONFIG_FILE" \
        -e CONFIG_KSU 
fi

# SuSFS enable
if [ "$ENABLE_SUSFS" = true ]; then
    "${KERNEL_DIR}/scripts/config" --file "$CONFIG_FILE" \
        -e CONFIG_KSU_SUSFS -d CONFIG_KSU_KPROBES_HOOK
fi

# KPM enable
if [ "$ENABLE_KPM" = true ]; then
    "${KERNEL_DIR}/scripts/config" --file "$CONFIG_FILE" \
        -e CONFIG_KPM
fi

# Samsung protection remove
if [ "$DISABLE_SAMSUNG_PROTECTION" = true ]; then
    "${KERNEL_DIR}/scripts/config" --file "$CONFIG_FILE" \
        -d UH -d RKP -d KDP -d SECURITY_DEFEX -d INTEGRITY -d FIVE \
        -d TRIM_UNUSED_KSYMS -d PROCA -d PROCA_GKI_10 -d PROCA_S_OS \
        -d PROCA_CERTIFICATES_XATTR -d PROCA_CERT_ENG -d PROCA_CERT_USER \
        -d GAF -d GAF_V6 -d FIVE_CERT_USER -d FIVE_DEFAULT_HASH \
        -e CONFIG_TMPFS_XATTR -e CONFIG_TMPFS_POSIX_ACL
fi

# Version fix
# LOCALVERSION=$("${KERNEL_DIR}/scripts/config" --file "$CONFIG_FILE" --state CONFIG_LOCALVERSION)
# [ -z "$LOCALVERSION" ] && LOCALVERSION="${VERSION}"
# [ ! -z "$SETVERSION" ] && LOCALVERSION="${SETVERSION}"
#
# "${KERNEL_DIR}/scripts/config" --file "$CONFIG_FILE" \
#    --set-str CONFIG_LOCALVERSION "$LOCALVERSION" -d CONFIG_LOCALVERSION_AUTO
#
# sed -i 's/echo "+"$/echo ""/' $KERNEL_DIR/scripts/setlocalversion

# Compile kernel
KBUILD_BUILD_USER="$BUILD_USER" KBUILD_BUILD_HOST="$BUILD_HOST" \
make -j"$(nproc)" -C "$KERNEL_DIR" O="$OUTPUT_DIR" ${ARGS} \
     EXTRA_CFLAGS:=" -I$KERNEL_DIR/drivers/ufs/host/s5e9945/ -I$KERNEL_DIR/arch/arm64/kvm/hyp/include -DCFG80211_SINGLE_NETDEV_MULTI_LINK_SUPPORT -DTARGET_SOC=${TARGETSOC}"

# Fixing version, i have got no idea what it does, better hardcordly disable it
# sed -i 's/echo ""$/echo "+"/' $KERNEL_DIR/scripts/setlocalversion

# Automated selecting whether img or img.gz is used 
if [ -f "${OUTPUT_DIR}/arch/arm64/boot/Image" ]; then
  KERNEL_FOR_BOOT="${OUTPUT_DIR}/arch/arm64/boot/Image"
elif [ -f "${OUTPUT_DIR}/arch/arm64/boot/Image.gz" ]; then
  KERNEL_FOR_BOOT="${OUTPUT_DIR}/arch/arm64/boot/Image.gz"
else
  echo "[❌] Kernel image not found (expected Image or Image.gz in ${OUTPUT_DIR}/arch/arm64/boot)."
  exit 1
fi

# Odin file creation
if [ -e "$OUTPUT_DIR/arch/arm64/boot/Image" ]; then
    echo "[✅] Build success."
    python3 "$TOOLS/mkbootimg/mkbootimg.py" --header_version 4 \
        --kernel "${KERNEL_FOR_BOOT}" \
        --cmdline '' \
        --out "$CURRENT_DIR/boot.img"

    tar -cf "$ODIN_TAR" boot.img
    echo "[✅] Odin image ready"
else
    echo "[❌] Kernel build failed"
fi

# AnyKernel3 file creation
if [ ! -d "${AK3_DIR}" ]; then
  echo "[💠] Cloning AnyKernel3 template..."
  git clone --depth=1 "${AK3_REPO}" "${AK3_DIR}"
else
  echo "[💠] Found existing AnyKernel3 template, setting AK3_TEST flag and skipping..."
  AK3_TEST=1
fi
echo "[💠] Packing AnyKernel3 flashable zip..."
(
  cd "${AK3_DIR}" || { echo "[❌] Failed to cd to $AK3_DIR"; }
  zip -r9 "${AK3_ZIP}" . -x "*.git*" README.md
  echo "[✅] AnyKernel3 zip created"
)

# Summary
echo "[✅] Build succesful, outputs:"
echo "Odin tar: ${CURRENT_DIR}/boot.img.tar"
echo "AK3 zip : ${AK3_ZIP}"
echo "See ya! 👋"

