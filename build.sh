#!/bin/bash
#
# Compile script for LOS kernel
# Copyright (C) 2020-2021 Adithya R & @johnmart19.
# Copyright (C) 2021 Craft Rom (melles1991).

SECONDS=0 # builtin bash timer

#Set Color
blue='\033[0;34m'
grn='\033[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
txtbld=$(tput bold)
txtrst=$(tput sgr0)  

echo -e " "
echo -e " "
echo -e "$blue░▐█▀█░▐█░▐█░▐██░▐█▀█▄▒▐█▀▀█▌▒▐█▀▀▄░▐██"
echo -e "░▐█──░▐████─░█▌░▐█▌▐█▒▐█▄▒█▌▒▐█▒▐█─░█▌"
echo -e "░▐█▄█░▐█░▐█░▐██░▐█▄█▀▒▐██▄█▌▒▐█▀▄▄░▐██$nocol"
echo -e " "

ZIPNAME="Chidori-Kernel-juice-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="$HOME/toolchains/proton-clang"
DEFCONFIG="vendor/juice-perf_defconfig"

export PATH="$TC_DIR/bin:$PATH"
export KBUILD_BUILD_USER=melles1991
export KBUILD_BUILD_HOST=CraftRom-build

echo -e "${txtbld}Config:${txtrst} $DEFCONFIG"
echo -e "${txtbld}ARCH:${txtrst} arm64"
echo -e "${txtbld}Username:${txtrst} $KBUILD_BUILD_USER"
echo -e " "

if ! [ -d "$TC_DIR" ]; then
echo "Proton clang not found! Cloning to $TC_DIR..."
if ! git clone -q --depth=1 --single-branch https://github.com/kdrag0n/proton-clang $TC_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

echo -e "$blue    \nMake DefConfig\n $nocol"
mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

if [[ $1 == "-c" || $1 == "--clean" ]]; then
if [  -d "./out/" ]; then
echo -e " "
        rm -rf ./out/
fi
echo -e "$grn \nFull cleaning was successful succesfully!\n $nocol"
sleep 2
fi

if [[ $1 == "-r" || $1 == "--regen" ]]; then
cp out/.config arch/arm64/configs/$DEFCONFIG
git commit -am "defconfig: juice: Regenerate" --signoff
echo -e "$grn \nRegened defconfig succesfully!\n $nocol"
make mrproper
echo -e "$grn \nCleaning was successful succesfully!\n $nocol"
sleep 4
exit 1
fi

# Build start
echo -e "$blue    \nStarting kernel compilation...\n $nocol"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz dtbo.img


kernel="out/arch/arm64/boot/Image.gz"
dtb="out/arch/arm64/boot/dts/vendor/qcom/bengal.dtb"
dtbo="out/arch/arm64/boot/dtbo.img"

if [ -f "$kernel" ] && [ -f "$dtb" ] && [ -f "$dtbo" ]; then
echo -e "$blue    \nKernel compiled succesfully! Zipping up...\n $nocol"
if ! [ -d "AnyKernel3" ]; then
echo "AnyKernel3 not found! Cloning..."
if ! git clone https://github.com/CraftRom/AnyKernel3 -b onclite AnyKernel3; then
echo "Cloning failed! Aborting..."
fi
fi
cp $kernel $dtbo AnyKernel3
cp $dtb AnyKernel3/dtb
rm -f *zip
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
echo -e "$grn \n(i)          Completed build$nocol $red$((SECONDS / 60))$nocol $grn minute(s) and$nocol $red$((SECONDS % 60))$nocol $grn second(s) !$nocol"
echo -e "$blue    \n             Flashable zip generated $yellow$ZIPNAME.\n $nocol"
rm -rf out/arch/arm64/boot
else
 echo -e "$red \nKernel Compilation failed! Fix the errors!\n $nocol"
fi

curl -F document=@$ZIPNAME https://api.telegram.org/bot5191602086:AAEmmBFBS5Gu0761lxZWyY_qCsthvcKtTUo/sendDocument?chat_id=1987074996
