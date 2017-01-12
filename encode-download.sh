#!/bin/bash
ROOTDIR=http://hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC/
SUBDIR=wgEncodeBroadHistone
FILETYPE=broadPeak

currdir=`pwd`

output=$2

if [ -z "$output" ]; then
    echo "encode-download.sh <pattern> <output.bed>"
    exit 1
fi

## download to tmp dir
dir=`mktemp -d` && cd $dir

echo "Tmp dir: $dir"
sleep 2

## download file manifest
wget "${ROOTDIR}/${SUBDIR}/files.txt" -q

## capture them from the manifest file
files=($(grep $1 files.txt | grep $FILETYPE | cut -f1)) 

## download the files
bedcmd=""
for i in "${files[@]}"; do
    f="${ROOTDIR}/${SUBDIR}/${i}" 
    echo "...downloading $f"
    wget $f -q
    gunzip -c $i | perl -p -e 's/chr//g' | sort -V -k1,1 -k2,2n > ${i}.bed
    bedcmd="${bedcmd} ${i}.bed"
done

##
echo "cat $bedcmd | sort -V -k1,1 -k2,2 | bedtools merge -i stdin -c 7 -o mean > $output"
cat $bedcmd | sort -V -k1,1 -k2,2 | bedtools merge -i stdin -c 7 -o mean > $output
mv $output $currdir
cd $currdir
echo "tmp dir was : $dir"
igvtools index $output
z
