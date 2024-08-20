###### INPUT ######
# Input Directory with subdirectories with .fastq.gz files
data=datadir

# Human reference genome file
humanRef=reference.fna

# Reference Database for scaffolding
# This can also be a fasta file with a single sequence
refDB=reference.fasta

# Background data for phylogenetic tree
# Only needed if phyloAnalysis="Y"
# This file may be aligned, but does not need to be
backgroundDB=background.fasta

###### PARAMETERS ######

# Background Phylogeny 
# 'Y' if you want to put samples in a phylogenetic tree with a background database
# 'N' if you don't want to do that 
phyloAnalysis="Y"

# Are the fastq.gz files already merged into fastq? 
# Y for yes and N for no
# If Y change 'mergedData' variable to directory with fastq files
premerged="N" 

# Estimation of genomeSize
# This is used for canu and building a consensus from a reference database 
genomeSize=9500

# Minimum read length to include 
minReadLength=200

# Maximum read length to include
maxReadLength=4000

# Phred score minimum
phred=20

# Trim to database
# Y if data is whole genome, but background database is not
# For extracting region from whole genome database
# Otherwise N
trimDB="N"

# Maximum threads to use
threads=8

###### LOGGING FILES #####
# Timing the pipeline file
timer=timer.txt

# Log file with stderr  
logFile=log.log

# Summary file
sumFile=log.summary

####### NEW DIRECTORIES ######
# Location of merged fastq.gz files
mergedData=output/merged-data

# Temporary files directory
# Needs to be deleted manually after pipeline is finished
# Files here may come in handy when you have unexpected results
tmp=tmp

# Trimmed and quality filtered reads directory
chopperOutput=output/trimmed-reads

# Filtered reads directory (non-human, assumed to be HIV)
# (or another target, just don't change the variable name)
hivReads=output/hiv-reads

# Canu output assembly directory 
contigs=output/contigs

# Scaffolds directory 
scaffoldDir=output/scaffolds

# Gap-filled directory
gapFillDir=output/gapfilled-scaffolds

# Reads aligned to assembly directory 
assemblyAln=output/assembly-aligned

# Alignment with BG data location & IQ-TREE output
treeOutput=output/tree