#!bin/bash/

# Changed in comparison with version 6: 
# Iteration removed 
# Added minimum and maximum read length to config file
# Extra logging
# Remove terminal Ns from consensus sequences 
# Preventing errors when no reads pass the quality check
# Allowed to set phred in config.sh
# Added some error catching (failed assembly) 
# Moved functionality of dependencies.sh to here
# Improved logging
# Added thread usage to config.sh 

# Last file update: 20/08/24
# Author: Kaiden R. Sewradj 

source code/utils_func.sh
source code/merge_func.sh
source code/chopper_func.sh
source code/human_filter_func.sh
source code/canu_func.sh
source code/scaffold_func.sh
source code/reads_cons.sh
source code/check_msa_func.sh
source code/align_cons_func.sh
ref_cons=code/ref_cons.sh
MSA_Trimmer=tools/MSA_trimmer_KR/alignment_trimmer.py
noambig=code/noambig.py
conLen=code/consensuslength.py
fastaHeaderReplace=code/fasta_header_replace.py

while [ $# -gt 0 ]; do
	case $1 in
		-h | --help)
			nano_viphy_usage
			exit 0
        ;;
		-t | --test)
			test_dependencies
			exit 0
		;;
		-i | --install)
			nano_viphy_install
			exit 0
		;;
		-c | --config)
			if [ ! -f "$2" ]; then
				echo "Configuration file not found" >&2
				exit 1
			fi
			
			configFile=$2
			shift
		;;
		*)
			echo "Invalid option: $1" >&2
			nano_viphy_usage
			exit 1
		;;
    esac
	shift
done

if [ ! -f "$configFile" ]; then
	echo "ERROR: Configuration file $configFile not found" >&2
	exit 1
fi

source $configFile

##### CHECK FILE/DIR EXISTENCE #####
if [ $premerged == "N" ]; then
	if [ ! -d "$data" ]; then
		echo "ERROR: Data $data not found or is not a directory" >&2
		exit 1
	fi
elif [ ! -d "$mergedData" ]; then
		echo "ERROR: Data $mergedData not found or is not a directory" >&2
		exit 1
fi

if [ ! -f "$humanRef" ]; then
	echo "ERROR: Human reference genome $humanRef not found or is not a file" >&2
	exit 1
fi

if [ ! -f "$refDB" ]; then
	echo "ERROR: Reference database $refDB not found or is not a file" >&2
	exit 1
fi

if [ ! -f $fastaHeaderReplace ]; then
	echo "ERROR: $fastaHeaderReplace not found" >&2
	exit 1
fi

if [ $phyloAnalysis == "Y" ]; then
	if [ ! -f "$backgroundDB" ]; then
		echo "ERROR: Background database not found or is not a file" >&2
		exit 1
	fi
fi

sequenceCount=$(grep ">" $refDB | wc -l)
if [ "$sequenceCount" -gt 1 ]; then 
	buildCon="True"
else
	buildCon="False"
fi

##### CHECK PYTHON FILES EXISTENCE #####
if [ "$buildCon" == "True" ]; then
	for file in $MSA_Trimmer $noambig $conLen; do
		if [ ! -f $file ]; then
			echo "ERROR: $file not found." >&2
			exit 1
		fi
	done
fi

###### MERGE DATA ######
# Logging
echo "Pipeline started on: $(date)" > $sumFile
echo "Process, time in seconds" > $timer

if [ $premerged == "N" ]; then
	echo "Merging data..."
	start=$(date '+%s.%N')

	merge_fastqgz $data $mergedData

	# Logging
	end=$(date '+%s.%N')
	runtime=$( echo "$end - $start" | bc -l )
	echo "Merging data, $runtime" >> $timer
fi

echo "Processing $(ls -1q ${mergedData}/*.fastq | wc -l) samples." >> $sumFile

###### CHOPPER ######
# Logging
echo "Quality controlling reads..."
start=$(date '+%s.%N')

chopper_reads $mergedData $chopperOutput $sumFile $minReadLength $maxReadLength $phred $threads

# Logging
end=$(date '+%s.%N')
runtime=$( echo "$end - $start" | bc -l )
echo "Trimming with chopper, $runtime" >> $timer

###### REMOVE EMPTY FILES ######
for file in $chopperOutput/*.fastq; do
	FILESIZE=$(stat -c%s "$file")
	
	if (( FILESIZE < 1 )); then
		echo "WARNING: $file has no reads that passed quality check, removing..." >&2
		echo "WARNING: $file has no reads that passed quality check, removing..." >> $sumFile
		rm $file
	fi 
done

###### CHECK IF ANY FILES ARE LEFT ######
if [ -z "$( ls -A "$chopperOutput" )" ]; then
	echo "ERROR: No sample passed quality check. Exiting..." >&2
	echo "ERROR: No sample passed quality check. Exiting..." >> $sumFile
	exit 1
fi

###### FILTER HUMAN READS ######
# Logging
echo "Filtering out human reads..."
start=$(date '+%s.%N')

human_filter $chopperOutput $humanRef $tmp $hivReads $threads $logFile $sumFile 

# Logging
end=$(date '+%s.%N')
runtime=$( echo "$end - $start" | bc -l )
echo "Extracting non-human reads, $runtime" >> $timer

###### ASSEMBLY WITH CANU ######
# Logging
echo "Assembling reads..."
start=$(date '+%s.%N')

canu_assembly $hivReads $contigs $genomeSize $logFile $sumFile $minReadLength $threads

# Logging
end=$(date '+%s.%N')
runtime=$( echo "$end - $start" | bc -l )
echo "Assembling contigs, $runtime" >> $timer

###### EXTRACT INCOMPLETE ASSEMBLIES ######
# Assumption: more than 1 contig == not full genome
singleContig=()
multiContig=()

# Sort contigs in which ones need to be completed and which ones are already a single sequence 
for barcode in $contigs/*/; do
	BC="$(basename "$barcode")"
	contigFile="${barcode}${BC}.contigs.fasta"
	
	# Check if assembly failed
	if [ ! -f "$contigFile" ]; then
		echo "WARNING: Failed assembly for $BC"
		echo "WARNING: Failed assembly for $BC" >> $sumFile
		continue
	fi
	
	contigCount=$(grep -o '>' $contigFile | wc -l)
	if [ "$contigCount" -gt 1 ]; then
		multiContig+=( $contigFile )
	else
		singleContig+=( $contigFile )
	fi
done

# Override consensus building if scaffolding is not necessary
# Determine if scaffolding/filling the gap is necessary 
if [ ${#multiContig[@]} -eq 0 ]; then
	buildCon="False"
	scafFill="False"
else
	scafFill="True"
fi


###### BUILD CONSENSUS OF REFERENCE DATABASE ###### 
if [ "$buildCon" == "True" ]; then
	# Logging
	echo "Building reference consensus for scaffolding..."
	echo "Building consensus from reference database with $sequenceCount sequences" >> $sumFile
	start=$(date '+%s.%N')
	mkdir -p $tmp $scaffoldDir
	bash $ref_cons $refDB $genomeSize $logFile $sumFile $scaffoldDir $threads  >> $logFile 2>&1
	
	# Logging
	ref="$scaffoldDir/$(basename "$refDB" .fasta)_consensus_noambig.fasta"
	end=$(date '+%s.%N')
	runtime=$( echo "$end - $start" | bc -l )
	echo "Building consensus from reference database with $sequenceCount sequences, $runtime" >> $timer
else
	ref=$refDB
fi

###### SCAFFOLDING AND GAP-FILLING ######
if [ "$scafFill" == "True" ]; then
	# Logging
	echo "Scaffolding..."
	echo "Scaffolding and gap-filling ${#multiContig[@]} samples." >> $sumFile
	for contigFile in ${multiContig[@]}; do
		contigCount=$(grep -o '>' $contigFile | wc -l)
		echo "$contigFile has $contigCount contigs" >> $sumFile
	done
	
	mkdir -p $tmp $scaffoldDir
	
	# Scaffold contigs
	scaffolds=()
	start=$(date '+%s.%N')
	for contigFile in ${multiContig[@]}; do
		scaffold $contigFile $ref $scaffoldDir $logFile $sumFile $threads
		BC=$(basename "$contigFile" .contigs.fasta)
		scaffoldFile="$scaffoldDir/${BC}_scaffold.fasta"
		scaffolds+=( $scaffoldFile )
	done
	
	# Logging
	end=$(date '+%s.%N')
	runtime=$( echo "$end - $start" | bc -l )
	echo "Scaffolding, $runtime" >> $timer
	
	# Fill gaps
	echo "Filling gaps..."
	start=$(date '+%s.%N')
	for scaffoldFile in ${scaffolds[@]}; do
		BC=$(basename "$scaffoldFile" _scaffold.fasta)
		output="$gapFillDir/$BC"
		mkdir -p $output
		
		readsBAM="${hivReads}/${BC}.bam"
		reads="${hivReads}/${BC}.fasta"
		
		echo "Closing gap for $scaffoldFile" >> $logFile
		samtools fasta -@ $threads $readsBAM > $reads 2>> $logFile
		echo "tgsgapcloser --scaff $scaffoldFile --reads $reads --output $output/$BC --ne --threads $threads" >> $sumFile
		tgsgapcloser --scaff $scaffoldFile --reads $reads --output "$output/$BC" --ne --threads $threads >> $logFile 2>&1
		
		# If no gaps filled, add scaffold file
		# Otherwise add gap-filled file
		if [ -z "$( ls -A "$output" )" ]; then
			rm -r $output
			singleContig+=( $scaffoldFile )
			echo "$scaffoldFile had no gap to fill" >> $sumFile
		else
			echo "$scaffoldFile was filled" >> $sumFile
			filledFile="$output/${BC}.scaff_seqs"
			singleContig+=( $filledFile )
		fi
	done
	
	# Logging
	end=$(date '+%s.%N')
	runtime=$( echo "$end - $start" | bc -l )
	echo "Filling gaps, $runtime" >> $timer
fi

###### CHECK IF ANY ASSEMBLIES SUCCEEDED ######
if [ ${#singleContig[@]} -eq 0 ]; then
	echo "ERROR: All assemblies failed"
	echo "ERROR: All assemblies failed" >> $sumFile
fi

###### ALIGN READS TO GET CONSENSUS ######
echo "Building consensus sequences..."
start=$(date '+%s.%N')

consensusSeqs=()
for assembly in ${singleContig[@]}; do
	BC=$(get_assembly_id "$assembly")
	reads="$hivReads/${BC}.fastq"
	reads_cons $assembly $reads "$assemblyAln/$BC" $logFile $sumFile $threads
	consensusSeqs+=( "$assemblyAln/$BC/${BC}_consensus.fasta" )
done

end=$(date '+%s.%N')
runtime=$( echo "$end - $start" | bc -l )
echo "Mapping reads and calling consensus, $runtime" >> $timer


###### REPLACE FASTA HEADERS ######
echo "Renaming consensus sequences"
start=$(date '+%s.%N')
for consensus in ${consensusSeqs[@]}; do
	BC=$(basename "$consensus" _consensus.fasta)
	python $fastaHeaderReplace $consensus $BC
done

# Logging
end=$(date '+%s.%N')
runtime=$( echo "$end - $start" | bc -l )
echo "Fixing consensus headers, $runtime" >> $timer

####### BUILD PHYOLOGENETIC TREE WITH BACKGROUND DATA ######
if [ $phyloAnalysis == "Y" ]; then
	# Align consensus sequences and background data with MAFFT
	echo "Aligning consensus sequences to background dataset..."
	isAligned=$(check_MSA $backgroundDB)
	alnFile="$treeOutput/consensus_$(basename "$backgroundDB" .fasta)_Aln.fasta"
	start=$(date '+%s.%N')
	align_conseqs $assemblyAln $backgroundDB $isAligned $alnFile $logFile $sumFile $tmp $treeOutput $trimDB $threads
	end=$(date '+%s.%N')
	runtime=$( echo "$end - $start" | bc -l )
	echo "Aligning consensus to background, $runtime" >> $timer
	
	# Build tree with IQ-TREE
	echo "Building tree..."
	
	start=$(date '+%s.%N')
	echo "iqtree -s $alnFile -m MFP -T $threads -B 1000">> $sumFile
	iqtree -s $alnFile -m MFP -T $threads -B 1000 >> $logFile 2>&1
	
	# Logging
	end=$(date '+%s.%N')
	runtime=$( echo "$end - $start" | bc -l )
	echo "Building tree with IQ-TREE, $runtime" >> $timer
	totalSeqsCount=$(grep ">" $alnFile | wc -l)
	echo "Tree built with $totalSeqsCount sequences" >> $sumFile
fi

# Clean up 
rm done_step1_tag done_step_4.1_tag done_step_4.2_tag
rm -r $tmp

echo "Pipeline finished on: $(date)" >> $sumFile

echo "DONE :D"