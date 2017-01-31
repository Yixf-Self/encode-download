#!/bin/bash
ROOTDIR=http://hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC/
#SUBDIR=wgEncodeBroadHistone
#FILETYPE=broadPeak

currdir=`pwd`

SUBDIR=$2
FILETYPE=$3
output=$4


if [ -z "$output" ]; then
    echo "encode-download.sh <pattern> <subdir> <filetype> <output.bed>"
    echo "encode-download.sh H3K4me3 wgEncodeBroadHistone broadPeak H3K4me3.bed"
    exit 1
fi

bigWigMerger() {
    if hash bigWigMerge 2>/dev/null; then
       bigWigMerge "$@"
    else
        echo "bigWigMerge not installed. Install from https://github.com/ENCODE-DCC/kentUtils"
	exit 1
    fi
}

bedtoolsr() {
    if hash bedtools 2>/dev/null; then
        bedtools "$@"
    else
        echo "bedtools not installed. Install from https://github.com/arq5x/bedtools2"
	exit 1
    fi
}

igvtoolsr() {
    if hash igvtools 2>/dev/null; then
        igvtools "$@"
    else
        echo "igvtools not installed (if you want index BED). Install from https://software.broadinstitute.org/software/igv/igvtools2"
	exit 0
    fi
}

## download to tmp dir
dir=`mktemp -d` && cd $dir

echo "Tmp dir: $dir"
sleep 2

## download file manifest
wget "${ROOTDIR}/${SUBDIR}/files.txt" -q

## capture them from the manifest file
files=($(grep $1 files.txt | grep $FILETYPE | cut -f1)) 

## download the files
if [[ $FILETYPE = "bed" ]]; then
    bedcmd=""
    for i in "${files[@]}"; do
	f="${ROOTDIR}/${SUBDIR}/${i}" 
	echo "...downloading bed $f"
	wget $f -q
	gunzip -c $i | perl -p -e 's/chr//g' | sort -V -k1,1 -k2,2n > ${i}.bed
	bedcmd="${bedcmd} ${i}.bed"
    done

    echo "cat $bedcmd | sort -V -k1,1 -k2,2 | bedtools merge -i stdin -c 7 -o mean > $output"
    cat $bedcmd | sort -V -k1,1 -k2,2 | bedtoolsr merge -i stdin -c 7 -o mean > $output
    
elif [[ $FILETYPE = "bigWig" ]]; then
    bedcmd=""
    for i in "${files[@]}"; do
	f="${ROOTDIR}/${SUBDIR}/${i}" 
	echo "...downloading bigWig $f"
	wget $f -q
	bedcmd="${bedcmd} ${i}"
    done

    echo "bigWigMerger $bedcmd $output"
    bigWigMerger $bedcmd $output
    perl -p -e 's/chr//g' $output | sort -V -k1,1 -k2,2n > ${output}.tmp
    mv ${output}.tmp $output
else 
    echo "Filetype $FILETYPE not recognized"
    echo "Supported files are: bed, bigwig"
fi

mv $output $currdir
cd $currdir
echo "tmp dir was : $dir"

igvtoolsr index $output
