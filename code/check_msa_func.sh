#!bin/bash 

# Standalone function to check if a fasta file is an MSA. 
# Assumed all MSA have a - not in a header and all non-MSA never contain a - outside the header.
# Usage: check_MSA <multi.fasta> 

# Last file update: 02/08/24
# Author: Kaiden R. Sewradj 

check_MSA() {
	while read -r line; do
		if [[ "$line" == ">"* ]]; then
			continue
		fi
		
		if [[ "$line" == *"-"* ]]; then
			echo "True"
			exit 0
		fi
	done < $1
	
	echo "False"
}