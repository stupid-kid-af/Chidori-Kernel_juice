#Set time zone to Moscow
sudo ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
echo "Cloning dependencies"
git clone --depth=1 https://github.com/sohamxda7/llvm-stable clang
git clone https://github.com/sohamxda7/llvm-stable -b gcc64 --depth=1 gcc
git clone https://github.com/sohamxda7/llvm-stable -b gcc32  --depth=1 gcc32
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image
START=$(date +"%s")
KERNEL_DIR=$(pwd)
PATH="${KERNEL_DIR}/clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
VERSION="$(cat arch/arm64/configs/vendor/citrus-perf_defconfig | grep "CONFIG_LOCALVERSION\=" | sed -r 's/.*"(.+)".*/\1/' | sed 's/^.//')"
export KBUILD_BUILD_HOST=Revers
export KBUILD_BUILD_USER="Sezam4ik"

# Compile plox
function compile() {
    make O=out ARCH=arm64 vendor/citrus-perf_defconfig
    make -j$(nproc --all) O=out \
                    ARCH=arm64 \
                    CC=clang \
                    CLANG_TRIPLE=aarch64-linux-gnu- \
                    CROSS_COMPILE=aarch64-linux-android- \
                    CROSS_COMPILE_ARM32=arm-linux-androideabi-

    if ! [ -a "$IMAGE" ]; then
        exit 1
    fi
    cp out/arch/arm64/boot/Image AnyKernel3
}
# Zipping
function zipping() {
    cd AnyKernel3 || exit 1
    zip -r9 $VERSION-juice-$(date +%Y%m%d-%H%M).zip *
    cd ..
}

compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
echo "Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)."
