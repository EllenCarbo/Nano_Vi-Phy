#!bin/bash 

# Standalone function to scaffold contigs using a reference
# You might want to change line 21 if you're not using canu output or match canu's output filenames
# Will still work if you don't
# Usage: scaffold <contigs_file.fasta> <reference.fasta> <scaffold output> <temporary file directory> <log filename> <threads>

# Last file update: 19/08/24
# Author: Kaiden R. Sewradj 


scaffold() {
	contigFile=$1
	ref=$2
	scaffoldDir=$3
	logFile=$4
	sumFile=$5
	threads=$6

	# Create single consensus for contigs
	mkdir -p $tmp
	BC=$(basename "$contigFile" .contigs.fasta)
	base="$scaffoldDir/$BC"
		
	# Align contigs 
	alnFile="${base}_contigaln.sam"
	echo "minimap2 -a -t $threads $ref $contigFile > $alnFile" >> $sumFile
	minimap2 -a -t $threads $ref $contigFile > $alnFile 2>> $logFile
	
	#Convert to bam 
	bamFile="${base}_contigaln.bam"
	samtools sort -O bam -o $bamFile -@ $threads $alnFile 2>> $logFile
	rm $alnFile
	
	# Create scaffold sequence
	scaffoldFile="$scaffoldDir/${BC}_scaffold.fasta"
	echo "samtools consensus -o $scaffoldFile -c 0.1 -H 0.05 -a -m simple -@ $threads $bamFile" >> $sumFile
	samtools consensus -o $scaffoldFile -c 0.1 -H 0.05 -a -m "simple" -@ $threads $bamFile 2>> $logFile
}