'''
Removal of ambiguous bases (IUPAC) and replacement of said bases.
This script should (no guarantee) work on fasta files with multiple sequences.
However, the base frequency will be calculated over ALL sequences. 
Replacement of bases is based on the frequency at which they are present in the sequence.
This means that the sequence needs at least 1 occurrence of each base. 

Usage: python noambig.py <fasta file>
Version: 1.1 
Author: Kaiden Sewradj
Date: 20/08/2024
'''
import sys
from numpy.random import choice
from pathlib import Path

sequence = sys.argv[1]

sequence_file = open(sequence, "r")
lines = sequence_file.readlines()

# Count occurences of the bases in consensus sequence
dic = {}
for line in lines:
    if line[0] == ">":
        continue
    
    line_stripped = line.strip()
    
    for i in range(len(line_stripped)):
        c = line_stripped[i]
        c = c.upper()
        
        try:
            dic[c] += 1
        except KeyError:
            dic[c] = 1


# Create percentage dict for each base
# W = A or T | S = C or G | M = A or C
# K = G or T | R = A or G | Y = C or T
# B = C or G or T | D = A or G or T
# H = A or C or T | V = A or C or G
# N = any 
# This could probably be shorter with a function, but this was easier
replacement = {}

# W
total = dic['A'] + dic['T']
pct_A = dic['A'] / total
pct_T = dic['T'] / total
replacement['W'] = {'A': pct_A, 'T' : pct_T}

# S
total = dic['C'] + dic['G']
pct_C = dic['C'] / total
pct_G = dic['G'] / total
replacement['S'] = {'C': pct_C, 'G' : pct_G}

# M
total = dic['A'] + dic['C']
pct_A = dic['A'] / total
pct_C = dic['C'] / total
replacement['M'] = {'A': pct_A, 'C' : pct_C}

# K
total = dic['G'] + dic['T']
pct_G = dic['G'] / total
pct_T = dic['T'] / total
replacement['K'] = {'G': pct_G, 'T' : pct_T}

# R
total = dic['A'] + dic['G']
pct_A = dic['A'] / total
pct_G = dic['G'] / total
replacement['R'] = {'A': pct_A, 'G' : pct_G}

# Y
total = dic['C'] + dic['T']
pct_C = dic['C'] / total
pct_T = dic['T'] / total
replacement['Y'] = {'C': pct_C, 'T' : pct_T}

# B
total = dic['C'] + dic['G'] + dic['T']
pct_C = dic['C'] / total
pct_G = dic['G'] / total
pct_T = dic['T'] / total
replacement['B'] = {'C': pct_C, 'G' : pct_G, 'T' : pct_T}

# D
total = dic['A'] + dic['G'] + dic['T']
pct_A = dic['A'] / total
pct_G = dic['G'] / total
pct_T = dic['T'] / total
replacement['D'] = {'A': pct_A, 'G' : pct_G, 'T' : pct_T}

# H
total = dic['A'] + dic['C'] + dic['T']
pct_A = dic['A'] / total
pct_C = dic['C'] / total
pct_T = dic['T'] / total
replacement['H'] = {'A': pct_A, 'C' : pct_C, 'T' : pct_T}

# V
total = dic['A'] + dic['C'] + dic['G']
pct_A = dic['A'] / total
pct_C = dic['C'] / total
pct_G = dic['G'] / total
replacement['V'] = {'A': pct_A, 'C' : pct_C, 'G' : pct_G}

# N
total = dic['A'] + dic['C'] + dic['T'] + dic['G']
pct_A = dic['A'] / total
pct_C = dic['C'] / total
pct_T = dic['T'] / total
pct_G = dic['G'] / total
replacement['N'] = {'A': pct_A, 'C' : pct_C, 'T' : pct_T, 'G' : pct_G}

# Create new file and put consensus in
new_file = Path(sequence)
new_file = new_file.with_suffix('')
new_file = open(str(new_file) + "_noambig.fasta", "w")
for line in lines:
    if line[0] == ">":
        new_file.write(line)
        continue
    
    line_stripped = line.strip()
    replaced_line = ""
    
    for i in range(len(line_stripped)):
        
        c = line_stripped[i]
        c = c.upper()
        
        if c in replacement.keys():
            new_base = choice(list(replacement[c].keys()), 1, p=list(replacement[c].values()))
            replaced_line += str(new_base[0])
        else:
            replaced_line += c
    new_file.write(replaced_line)