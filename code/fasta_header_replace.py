'''
Replaces FASTA header with given ID. Does not support more than one sequence. 

Usage: python fasta_header_replace.py <fasta file> <new header string>
Version: 1.1 
Author: Kaiden Sewradj
Date: 06/08/2024
'''

import sys

fasta_file = sys.argv[1]
newheader = sys.argv[2]

# Open file
# Get file content
with open(fasta_file, "r") as f:
    lines = f.readlines()


# Redefine header
lines[0] = ">" + newheader + "\n"

# Print into file
with open(fasta_file, "w") as f:
    f.writelines(lines)