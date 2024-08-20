import sys

file = sys.argv[1]
length=0

with open(file, 'r') as f:
	lines = f.readlines()
	
	for line in lines:
		if line.startswith('>'):
			continue
		
		length += len(line.strip())
		
sys.stdout.write(str(length))