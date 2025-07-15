#!/bin/bash

export CROSS_COMPILE=$(pwd)/toolchain/toolchains-gcc-10.3.0/bin/aarch64-buildroot-linux-gnu-
export CC=$(pwd)/toolchain/clang/host/linux-x86/clang-r383902/bin/clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export ARCH=arm64
#export ANDROID_MAJOR_VERSION=r

export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y
export CONFIG_DRV_BUILD_IN=y
export WERROR_FLAGS=-Wno-error
make -C $(pwd) O=$(pwd)/out KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y a13ve_defconfig
make -C $(pwd) O=$(pwd)/out KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y CFLAGS="-Wno-unused-variable" -j16
cp out/arch/arm64/boot/Image $(pwd)/arch/arm64/boot/Image


sudo apt-get install clang-format clang-tidy clang-tools clang clangd libc++-dev libc++1 libc++abi-dev libc++abi1 libclang-dev libclang1 liblldb-dev libllvm-ocaml-dev libomp-dev libomp5 lld lldb llvm-dev llvm-runtime llvm python3-clang -y
sudo apt-get install gcc-aarch64-linux-gnu bc -y

set -e

KERNEL_DIR="$(pwd)"
CHAT_ID="7898438749"
TOKEN="8188281304:AAGd1EB1FqT4NQjOgS7p4IfPyjYRXjHvIMw"
KERVER=$(make -s kernelversion | tr -d '[:space:]')
VERSION=v1
IMAGE=${KERNEL_DIR}/out/arch/arm64/boot/Image
ZIPNAME="coloroxkernel"
TANGGAL=$(date +"%F-%H%M")
FINAL_ZIP="${ZIPNAME}-${VERSION}-${KERVER}-${DEVICE}-${TANGGAL}.zip"
COMPILER="llvm"
VERBOSE=0

telegram_push() {
  curl --progress-bar -F document=@"$1" https://api.telegram.org/bot$TOKEN/sendDocument \
	-F chat_id="$CHAT_ID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=Markdown" \
	-F caption="$2"
}

git clone https://github.com/Mohamedfullhd/AnyKernel3.git --depth=1

KBUILD_BUILD_HOST="LR"
KBUILD_BUILD_USER="-4k"
KBUILD_COMPILER_STRING=$(clang --version | head -n 1 | perl -pe 's/http.*?//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
PROCS=$(nproc --all)
export KBUILD_COMPILER_STRING KBUILD_BUILD_USER KBUILD_BUILD_HOST PROCS

function compile() {
    START=$(date +"%s")
    MAKE_OPT=()

    if [ "$COMPILER" = "llvm" ]; then
        MAKE_OPT+=(CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-)
    elif [ "$COMPILER" = "aosp" ]; then
        MAKE_OPT+=(CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_ARM32=arm-linux-androideabi-)
    fi

    make -C $(pwd) O=$(pwd)/out KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y a13ve_defconfig
    make -C $(pwd) O=$(pwd)/out KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y CFLAGS="-Wno-unused-variable" -j16

    END=$(date +"%s")
    DIFF=$((END - START))
}

function zipping() {
    if [ ! -f "$IMAGE" ]; then
        telegram_push "error.log" "**Build Failed:** Kernel compilation threw errors"
        exit 1
    else
        cp "$IMAGE" AnyKernel3
        cd AnyKernel3 || exit 1
        echo "Generating ZIP: ${FINAL_ZIP}"
        zip -r9 "${FINAL_ZIP}" * -x .git README.md
        cd "$KERNEL_DIR" || exit 1
    fi
}

function upload() {
    telegram_push "AnyKernel3/${FINAL_ZIP}" "Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)"
    exit 0
}

compile
zipping
upload
