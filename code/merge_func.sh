#!bin/bash 

# Standalone function to merge fastq.gz files into single fastq files per barcode
# fastq.gz files need to be in a subdirectory of the data directory
# Resulting fastq files will be named after the subdirectories

# Usage: merge_fastqgz <data directory> <output directory>

# Last file update: 26/07/24
# Author: Kaiden R. Sewradj 

merge_fastqgz() {
	data=$1
	mergedData=$2

	mkdir -p $mergedData
	for barcode in $data/*/; do
		file="$mergedData/$(basename "$barcode").fastq"
		gunzip -r -k -c $barcode >> $file
	done
}