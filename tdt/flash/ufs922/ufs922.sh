#!/bin/bash
if [ `id -u` != 0 ]; then
	echo "You are not running this script as root. Try it again as root or with su/sudo command."
	echo "Bye Bye..."
	exit
fi

CURDIR=`pwd`
BASEDIR=$CURDIR/../..

TUFSBOXDIR=$BASEDIR/tufsbox
CDKDIR=$BASEDIR/cvs/cdk

SCRIPTDIR=$CURDIR/scripts
TMPDIR=$CURDIR/tmp
TMPROOTDIR=$TMPDIR/ROOT
TMPKERNELDIR=$TMPDIR/KERNEL
TMPSTORAGEDIR=$TMPDIR/VAR

OUTDIR=$CURDIR/out

rm -rf $TMPDIR
rm -rf $OUTDIR
rm -f $CURDIR/uImage
rm -f $CURDIR/mtd_root.bin
rm -f $CURDIR/mtd_var.bin
rm -f $CURDIR/mtd_var.sum.bin
rm -f $CURDIR/mtd_kernel.pad.bin
rm -f $CURDIR/mtd_root.pad.bin
rm -f $CURDIR/mtd_var.sum.pad.bin


if [  -e $TMPDIR ]; then
  rm -rf $TMPDIR/*
fi

mkdir $TMPDIR
mkdir $TMPROOTDIR
mkdir $TMPKERNELDIR
mkdir $TMPSTORAGEDIR

echo "This script creates flashable images for UFS22"
echo "Author: Schischu, Oxygen-1, TangoCash"
echo "Date: 12-01-2013"
echo "-----------------------------------------------------------------------"
echo "It's expected that an image was already build prior to this execution!"
echo "-----------------------------------------------------------------------"

$BASEDIR/flash/common/common.sh $BASEDIR/flash/common/

echo "-----------------------------------------------------------------------"
echo "Checking targets..."
echo "Found targets:"
if [  -e $TUFSBOXDIR/release ]; then
  echo "   1) Prepare Enigma2 (not maintained)"
fi
if [  -e $TUFSBOXDIR/release_neutrino ]; then
  echo "   2) Prepare Neutrino"
fi

read -p "Select target (1-2)? "
case "$REPLY" in
	0)  echo "Skipping...";;
	1)  echo "Preparing Enigma2 Root..."
		$SCRIPTDIR/prepare_root.sh $CURDIR $TUFSBOXDIR/release $TMPROOTDIR $TMPSTORAGEDIR $TMPKERNELDIR;;
	2)  echo "Preparing Neutrino Root..."
		$SCRIPTDIR/prepare_root_neutrino.sh $CURDIR $TUFSBOXDIR/release_neutrino $TMPROOTDIR $TMPSTORAGEDIR $TMPKERNELDIR;;
	*)  "Invalid Input! Exiting..."
		exit 2;;
esac
echo "Root prepared"
echo ""
echo "You can customize your image now (i.e. move files you like from ROOT to STORAGE)."
echo "Or insert your changes into scripts/customize.sh"
$SCRIPTDIR/customize.sh $CURDIR $TMPROOTDIR $TMPSTORAGEDIR $TMPKERNELDIR
echo "-----------------------------------------------------------------------"
echo "Checking targets..."
echo "Found flashtarget:"
echo "   1) KERNEL with ROOT and FW"
read -p "Select flashtarget (1)? "
case "$REPLY" in
	1)  echo "Creating KERNEL with ROOT and FW..."
		$SCRIPTDIR/flash_part_w_fw.sh $CURDIR $TUFSBOXDIR $OUTDIR $TMPKERNELDIR $TMPROOTDIR $TMPSTORAGEDIR;;
	*)  "Invalid Input! Exiting..."
		exit 3;;
esac
#clear
echo "-----------------------------------------------------------------------"
AUDIOELFSIZE=`stat -c %s $TMPROOTDIR/boot/audio.elf`
VIDEOELFSIZE=`stat -c %s $TMPROOTDIR/boot/video.elf`
if [ $AUDIOELFSIZE == "0" ]; then
  echo "!!! WARNING: AUDIOELF SIZE IS ZERO !!!"
  echo "IF YOUR ARE CREATING THE FW PART MAKE SURE THAT YOU USE CORRECT ELFS"
  echo "-----------------------------------------------------------------------"
fi
if [ $VIDEOELFSIZE == "0" ]; then
  echo "!!! WARNING: VIDEOELF SIZE IS ZERO !!!"
  echo "IF YOUR ARE CREATING THE FW PART MAKE SURE THAT YOU USE CORRECT ELFS"
  echo "-----------------------------------------------------------------------"
fi
if [ ! -e $TMPROOTDIR/dev/mtd0 ]; then
  echo "!!! WARNING: DEVS ARE MISSING !!!"
  echo "IF YOUR ARE CREATING THE ROOT PART MAKE SURE THAT YOU USE A CORRECT DEV.TAR"
  echo "-----------------------------------------------------------------------"
fi

echo ""
echo ""
echo ""
echo "-----------------------------------------------------------------------"
echo "Flashimage created:"
echo `ls $OUTDIR`

echo "-----------------------------------------------------------------------"
echo "To flash the created image rename the *.img file to flash.img and "
echo "copy it to /kathrein/ufs922 of your usb drive"
echo "To start the flashing process hold the record button on your"
echo "frontpanel while the box is switched on, followed from stop button."
echo "your updatescript.sh will do the rest"

