#!bin/bash 

# Standalone function to align reads to a reference with minimap2 and get a consensus

# Usage: reads_cons <reference.fasta> <reads.fastq> <output directory> <log file> <summary file> <threads>

# Last file update: 19/08/24
# Author: Kaiden R. Sewradj 

reads_cons() {
	ref=$1
	reads=$2
	output=$3
	logFile=$4
	sumFile=$5
	threads=$6
	mkdir -p $output
	BC=$(basename "$reads" .fastq)
	alnFile="$output/${BC}_reads_to_assembly.sam"
	bamFile="$output/${BC}_reads_to_assembly.bam"
	consensusFile="$output/${BC}_consensus.fasta"
	
	# Align 
	echo "minimap2 -x map-ont -t $threads -a $ref $reads > $alnFile" >> $sumFile
	minimap2 -x map-ont -t $threads -a $ref $reads > $alnFile 2>> $logFile
	
	# Convert to bam 
	samtools sort -O bam -@ $threads $alnFile > $bamFile 2>> $logFile
	
	# Generate consensus
	echo "samtools consensus -A --low-MQ 5 --scale-MQ 1.5 --het-scale 0.37 -@ $threads $bamFile > $consensusFile" >> $sumFile
	samtools consensus -A --low-MQ 5 --scale-MQ 1.5 --het-scale 0.37 -@ $threads $bamFile > $consensusFile 2>> $logFile
}