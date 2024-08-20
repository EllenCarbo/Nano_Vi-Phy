#!bin/bash 

# Standalone function to assemble with Canu
# Usage: canu_assembly <directory with fastq files> <output directory> <genomeSize> <log file> <minimum read length> <threads>

# Last file update: 19/08/24
# Author: Kaiden R. Sewradj 

canu_assembly() {
	hivReads=$1
	contigs=$2
	genomeSize=$3
	logFile=$4
	sumFile=$5
	minReadLength=$6
	threads=$7
	
	for barcode in $hivReads/*.fastq; do
		BC=$(basename "$barcode" .fastq)
		bcOutput="$contigs/$BC"
		mkdir -p $bcOutput
		echo "Assembling $barcode : canu corErrorRate=0.134 genomeSize=$genomeSize maxThreads=$threads minReadLength=500 minOverlapLength=200 rawErrorRate=0.5 -trimmed -corrected -nanopore" >> $sumFile
		canu -p $BC -d $bcOutput corErrorRate=0.134 genomeSize=$genomeSize maxThreads=$threads minReadLength=$minReadLength minOverlapLength=200 rawErrorRate=0.5 -trimmed -corrected -nanopore $barcode 2>> $logFile
	done 
}