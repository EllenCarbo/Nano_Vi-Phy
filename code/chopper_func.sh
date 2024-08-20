#!bin/bash 

# Standalone function to quality control fastq files with chopper
# Usage: chopper_reads <directory containing fastq files> <output directory> <summary file> <minimum read length> \
#		<maximum read length> <phred score minimum> <threads>

# Last file update: 19/08/24
# Author: Kaiden R. Sewradj 

chopper_reads() {
	mergedData=$1
	chopperOutput=$2
	sumFile=$3
	minReadLength=$4
	maxReadLength=$5
	phred=$6
	threads=$7
	
	mkdir -p $chopperOutput
	for barcode in $mergedData/*.fastq; do
		outputFile="$chopperOutput/$(basename "$barcode")"
		echo "chopper -q $phred --minlength $minReadLength --maxlength $maxReadLength --headcrop 8 --threads $threads -i $barcode 1> $outputFile" >> $sumFile
		chopper -q $phred --minlength $minReadLength --maxlength $maxReadLength --headcrop 8 --threads $threads -i $barcode 1> $outputFile 2>> $sumFile
	done
}