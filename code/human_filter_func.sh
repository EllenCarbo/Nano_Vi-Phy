#!bin/bash 

# Standalone function to filter out human reads
# Protocol: map against human reference, filter out reads that do not map, remove alignments
# Logging and summary files are optional
# Usage: human_filter <directory with fastq files> <human reference> <temporary files directory> <output directory> \
#		<[OPTIONAL] log file> <[OPTIONAL] summary file>

# Last file update: 19/08/24
# Author: Kaiden R. Sewradj 

human_filter() {
	
	chopperOutput=$1
	humanRef=$2
	tmp=$3
	hivReads=$4
	threads=$5
	logFile=$6
	sumFile=$7

	
	mkdir -p $tmp $hivReads
	# Align to human reads
	if [ -z "${sumFile}" ]; then
		echo "Aligning reads to human genome and extracting unmapped reads" >> $sumFile
	fi
	for barcode in $chopperOutput/*.fastq; do
		BC=$(basename "$barcode" .fastq)
		alignmentFile="$tmp/${BC}_humanaln.sam"
		if [ ! -z "${sumFile}" ]; then
			echo "minimap2 -x map-ont -t $threads -B 6 -E 3,2 -a $humanRef $barcode > $alignmentFile" >> $sumFile
		fi
		
		if [ -z "${logFile}" ]; then
			minimap2 -x map-ont -t $threads -B 6 -E 3,2 -a $humanRef $barcode > $alignmentFile
		else
			minimap2 -x map-ont -t $threads -B 6 -E 3,2 -a $humanRef $barcode > $alignmentFile 2>> $logFile
		fi
		
		bamFile="$hivReads/${BC}.bam"
		readFile="$hivReads/${BC}.fastq"
		if [ -z "${logFile}" ]; then
			samtools view -@ $threads -b -f 4 $alignmentFile > $bamFile 
			samtools fastq -@ $threads $bamFile > $readFile 
		else
			samtools view -@ $threads -b -f 4 $alignmentFile > $bamFile 2>> $logFile
			samtools fastq -@ $threads $bamFile > $readFile 2>> $logFile
		fi
		
		if [ ! -z "${sumFile}" ]; then
			beforeCount=$(wc -l $barcode | sed 's@^[^0-9]*\([0-9]\+\).*@\1@')
			realBeforeCount=$(echo "$beforeCount / 4" | bc)
			afterCount=$(wc -l $readFile | sed 's@^[^0-9]*\([0-9]\+\).*@\1@')
			realAfterCount=$(echo "$afterCount / 4" | bc)
			echo "$(basename "$barcode" .fastq): Kept $realAfterCount reads out of $realBeforeCount" >> $sumFile
		fi
	done
	rm -r $tmp
}