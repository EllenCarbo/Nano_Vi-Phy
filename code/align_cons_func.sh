#!bin/bash 

# Function that aligns consensus sequences with a background database and then builds a tree with IQ-TREE
# Usage: build_tree <directory> <background.fasta> <background is aligned: True or False> \
#        <name for alignment file> <log file> <summary file> <temporary file directory> \
#		<output directory> <trim: Y or N> <threads>
# Structure of <directory> is directory/ID/ID_reference.fasta
# Trim Y is for adding whole genome sequences to a short sequence database and trimming to database length 
# Trim N disables trimming, recommended for whole genome sequences with whole genome database [default]

# Last file update: 20/08/24
# Author: Kaiden R. Sewradj 

align_conseqs() {
	assemblyAln=$1
	backgroundDB=$2
	isAligned=$3
	alnFile=$4
	logFile=$5
	sumFile=$6
	tmp=$7
	treeOutput=$8
	trim=$9
	threads=${10}
	allCons="$tmp/consensus_sequences.fasta"
	allSeq="$tmp/consensus_and_BG_seqs.fasta"
	mkdir -p $tmp $treeOutput
	
	# Count consensus sequences 
	consensusCount=$(find "$assemblyAln"/* -maxdepth 0 -type d | wc -l)
	
	# Add all consensus sequences to a single file
	for barcode in $assemblyAln/*/; do
		BC=$(basename "$barcode")
		conFile="$assemblyAln/$BC/${BC}_consensus.fasta"
		cat $conFile >> $allCons
	done
	
	# If database is aligned, add consensus sequences to the alignment
	if [ $isAligned == "True" ]; then
		sequenceCount=$(grep ">" $backgroundDB | wc -l)
		echo "Adding $consensusCount consensus sequences to aligned database of $sequenceCount sequences" >> $sumFile
		if [ $trim == "Y" ]; then
			echo "Trimming alignment to length of database" >> $sumFile
			echo "mafft --auto --thread $threads --adjustdirection --keeplength --addlong $allCons --reorder $backgroundDB > $alnFile" >> $sumFile
			mafft --auto --thread $threads --adjustdirection --keeplength --addlong $allCons --reorder $backgroundDB > $alnFile 2>> $logFile
		else
			echo "mafft --auto --thread $threads --adjustdirection --add $allCons --reorder $backgroundDB > $alnFile" >> $sumFile
			mafft --auto --thread $threads --adjustdirection --add $allCons --reorder $backgroundDB > $alnFile 2>> $logFile
		fi
		rm $allCons
		
	# If database is not aligned, align all sequences
	elif [ $trim == "Y" ]; then
			sequenceCount=$(grep ">" $backgroundDB | wc -l)
			echo "Adding $consensusCount long consensus sequences to shorter database of $sequenceCount sequences" >> $sumFile
			tempAln="$tmp/$(basename "$backgroundDB" .fasta)_aln.fasta"
			echo "mafft --auto --thread $threads $backgroundDB > $tempAln" >> $sumFile
			mafft --auto --thread $threads $backgroundDB > $tempAln 2>> $logFile
			echo "mafft --auto --thread $threads --adjustdirection --keeplength --addlong $allCons --reorder $tempAln > $alnFile" >> $sumFile
			mafft --auto --thread $threads --adjustdirection --keeplength --addlong $allCons --reorder $tempAln > $alnFile 2>> $logFile
			rm $tempAln
	else
		cat $backgroundDB > $allSeq
		cat $allCons >> $allSeq
		sequenceCount=$(grep ">" $allSeq | wc -l)
		echo "Aligning $sequenceCount sequences, of which $consensusCount are consensus sequences" >> $sumFile
		echo "mafft --auto --thread $threads --adjustdirection $allSeq > $alnFile" >>$sumFile
		mafft --auto --thread $threads --adjustdirection $allSeq > $alnFile 2>> $logFile
		rm $allCons $allSeq
	fi
}