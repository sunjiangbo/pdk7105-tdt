#!/bin/bash

CURDIR=$1
TUFSBOXDIR=$2
OUTDIR=$3
TMPKERNELDIR=$4
TMPFWDIR=$5
TMPROOTDIR=$6
TMPEXTDIR=$7

echo "CURDIR       = $CURDIR"
echo "TUFSBOXDIR   = $TUFSBOXDIR"
echo "OUTDIR       = $OUTDIR"
echo "TMPKERNELDIR = $TMPKERNELDIR"
echo "TMPFWDIR     = $TMPFWDIR"
echo "TMPROOTDIR   = $TMPROOTDIR"
echo "TMPEXTDIR   = $TMPEXTDIR"

MKFSJFFS2=$TUFSBOXDIR/host/bin/mkfs.jffs2
SUMTOOL=$TUFSBOXDIR/host/bin/sumtool
PAD=$CURDIR/../common/pad
FUP=$CURDIR/fup

HOST=`cat $TMPEXTDIR/etc/hostname`
[ -d $CURDIR/../../cvs/apps/libstb-hal-exp ] && HAL_REV=_HAL-rev`cd $CURDIR/../../cvs/apps/libstb-hal-exp && git log | grep "^commit" | wc -l`-exp || HAL_REV=_HAL-rev`cd $CURDIR/../../cvs/apps/libstb-hal && git log | grep "^commit" | wc -l`
[ -d $CURDIR/../../cvs/apps/libstb-hal-exp ] && NMP_REV=_NMP-rev`cd $CURDIR/../../cvs/apps/neutrino-mp-exp && git log | grep "^commit" | wc -l`-exp || NMP_REV=_NMP-rev`cd $CURDIR/../../cvs/apps/neutrino-mp && git log | grep "^commit" | wc -l`
gitversion="_BASE-rev`(cd $CURDIR/../../ && git log | grep "^commit" | wc -l)`$HAL_REV$NMP_REV"
OUTFILE=$OUTDIR/update_w_fw.ird_$HOST$gitversion

if [ ! -e $OUTDIR ]; then
  mkdir $OUTDIR
fi

if [ -e $OUTFILE ]; then
  rm -f $OUTFILE
  rm -f $OUTFILE.md5
fi

cp $TMPKERNELDIR/uImage $CURDIR/uImage

# Create a jffs2 partition for fw's
# Size 6.875  MB = -p0x6E0000
# Folder which contains fw's is -r fw
# e.g.
# .
# ./fw
# ./fw/audio.elf
# ./fw/video.elf
echo "MKFSJFFS2 -qUfv -p0x6E0000 -e0x20000 -r $TMPFWDIR -o $CURDIR/mtd_fw.bin"
$MKFSJFFS2 -qUfv -p0x6E0000 -e0x20000 -r $TMPFWDIR -o $CURDIR/mtd_fw.bin > /dev/null
echo "SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_fw.bin -o $CURDIR/mtd_fw.sum.bin"
$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_fw.bin -o $CURDIR/mtd_fw.sum.bin > /dev/null
echo "PAD 0x6E0000 $CURDIR/mtd_fw.sum.bin $CURDIR/mtd_fw.sum.pad.bin"
$PAD 0x6E0000 $CURDIR/mtd_fw.sum.bin $CURDIR/mtd_fw.sum.pad.bin

# Create a jffs2 partition for ext
# 0x01220000 - 0x01DFFFFF (11.875 MB)
# Should be p0xBE0000 but due to a bug in stock uboot the size had to be decreased
$MKFSJFFS2 -qUfv -p0xBA0000 -e0x20000 -r $TMPEXTDIR -o $CURDIR/mtd_ext.bin
$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_ext.bin -o $CURDIR/mtd_ext.sum.bin
$PAD 0xBA0000 $CURDIR/mtd_ext.sum.bin $CURDIR/mtd_ext.sum.pad.bin

# Create a jffs2 partition for root
# Size 30     MB = -p0x1E00000
# Folder which contains fw's is -r fw
# e.g.
# .
# ./release
# ./release/etc
# ./release/usr
echo "MKFSJFFS2 -qUfv -p0x1E00000 -e0x20000 -r $TMPROOTDIR -o $CURDIR/mtd_root.bin"
$MKFSJFFS2 -qUfv -p0x1E00000 -e0x20000 -r $TMPROOTDIR -o $CURDIR/mtd_root.bin > /dev/null
echo "SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_root.bin -o $CURDIR/mtd_root.sum.bin"
$SUMTOOL -v -p -e 0x20000 -i $CURDIR/mtd_root.bin -o $CURDIR/mtd_root.sum.bin > /dev/null
echo "PAD 0x1E00000 $CURDIR/mtd_root.sum.bin $CURDIR/mtd_root.sum.pad.bin"
$PAD 0x1E00000 $CURDIR/mtd_root.sum.bin $CURDIR/mtd_root.sum.pad.bin

# Create a fortis signed update file for fw's
# Note: -g is a workaround which will be removed as soon as the missing conf partition is found
# Note: -e could be used as a extension partition but at the moment we dont use it
echo "FUP -ce $OUTFILE -k $CURDIR/uImage -f $CURDIR/mtd_fw.sum.pad.bin -g foo -e foo -r $CURDIR/mtd_root.sum.pad.bin"
$FUP -ce $OUTFILE -k $CURDIR/uImage -f $CURDIR/mtd_fw.sum.pad.bin -r $CURDIR/mtd_root.sum.pad.bin -g foo -e $CURDIR/mtd_ext.sum.pad.bin

rm -f $CURDIR/uImage
rm -f $CURDIR/mtd_fw.bin
rm -f $CURDIR/mtd_fw.sum.bin
rm -f $CURDIR/mtd_fw.sum.pad.bin
rm -f $CURDIR/mtd_root.bin
rm -f $CURDIR/mtd_root.sum.bin
rm -f $CURDIR/mtd_root.sum.pad.bin
rm -f $CURDIR/mtd_ext.bin
rm -f $CURDIR/mtd_ext.sum.bin
rm -f $CURDIR/mtd_ext.sum.pad.bin

zip -j $OUTFILE.zip $OUTFILE
