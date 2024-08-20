#!bin/bash 

# Script to build a consensus from a sequence database in fasta format 
# Usage: bash ref_cons.sh <database in fasta format> <genome size> <tmp dir> <threads>
# Requires MSA_Trimmer and noambig.py

# Last file update: 20/08/24
# Author: Kaiden R. Sewradj 

db=$1
genomeSize=$2
logFile=$3
sumFile=$4
scaffoldDir=$5
threads=$6
alignmentFile="$scaffoldDir/$(basename "$db" .fasta)_aligned.fasta"
trimmedAlnFile="$scaffoldDir/$(basename "$alignmentFile" .fasta)_trimmed.fasta"
consensusFile="$scaffoldDir/$(basename "$db" .fasta)_consensus.fasta"
mkdir -p $tmp

consensus() {
	# Trim
	python $1 -c $2 --trim_gappy $3 
	
	# Call consensus
	cons -sequence $4 -outseq $5 -plurality 1 -snucleotide1 Y 
}

# Align database
echo "mafft --auto --thread $threads $db > $alignmentFile" >> $sumFile
mafft --auto --thread $threads $db > $alignmentFile 2>> $logFile

# Trim columns until the length of the alignment is under <genome size> 
# Trim increments of 5% 
gapPCT=0.95
consensus tools/MSA_trimmer_KR/alignment_trimmer.py $alignmentFile $gapPCT $trimmedAlnFile $consensusFile $logFile 
conLength=$(python code/consensuslength.py $consensusFile)
echo "Trimming gaps until consensus is =< $genomeSize" >> $sumFile
echo "Trimming positions with this percentage gaps, leaves a consensus this size" >> $sumFile
echo "${gapPCT},${conLength}" >> $sumFile 

while [ "$conLength" -gt "$genomeSize" ]; do
	gapPCT=$(bc -l <<< $gapPCT-0.05)
	consensus tools/MSA_trimmer_KR/alignment_trimmer.py $alignmentFile $gapPCT $trimmedAlnFile $consensusFile 
	conLength=$(python code/consensuslength.py $consensusFile)
	echo "${gapPCT},${conLength}" >> $sumFile
done

# Remove ambiguous bases 
python code/noambig.py $consensusFile

# Rename fasta header
python code/fasta_header_replace.py "$scaffoldDir/$(basename "$consensusFile" .fasta)_noambig.fasta" "$(basename "$db" .fasta) consensus"