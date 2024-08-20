# Last file update: 05/08/2024
# Author: Kaiden R. Sewradj 

nano_viphy_usage() {
	echo "Usage: $0 -c <config.sh>"
	echo "Options:"
	echo " -h, --help         Display this help message"
	echo " -c, --config       Config file"
	echo " -t, --test         Test dependencies, highly recommended before running."
	echo " -i, --install       Install all dependencies that are not yet installed using conda"
	echo ""
	echo "Inside the data directory should be subdirectories with unique names. These will be used as identifier. Avoid special characters." 
	echo "Inside each sub directory should reads be in .fastq.gz format"
	echo "Script can take as many .fastq.gz files as necessary"
	echo ""
	echo "If you have a already merged the fastq.gz files into fastq files put all fastq files in a single directory."
	echo "In config.sh set premerged to 'Y' to skip merging step"
}

test_dependencies() {
	
	chopper --version 
	if [ ! $? -eq 0 ]; then
		chopperTest="FAILED"
	else
		chopperTest="PASSED"
	fi
	
	bc --version 
	if [ ! $? -eq 0 ]; then
		bcTest="FAILED"
	else
		bcTest="PASSED"
	fi
	
	samtools --version 
	if [ ! $? -eq 0 ]; then
		samtoolsTest="FAILED"
	else
		samtoolsTest="PASSED"
	fi
	
	canu --version 
	if [ ! $? -eq 0 ]; then
		canuTest="FAILED"
	else
		canuTest="PASSED"
	fi
	
	minimap2 --version 
	if [ ! $? -eq 0 ]; then
		minimap2Test="FAILED"
	else
		minimap2Test="PASSED"
	fi

	python --version
	if [ ! $? -eq 0 ]; then
		pythonTest="FAILED"
	else
		pythonTest="PASSED"
	fi
	
	biopython=$(conda list | grep biopython)

	if [ -n "$biopython" ]; then
		biopythonTest="PASSED"
	else
		biopythonTest="FAILED"
	fi
	
	cons --version
	if [ ! $? -eq 0 ]; then
		embossTest="FAILED"
	else
		embossTest="PASSED"
	fi
	
	tgsgapcloser --version
	if [ ! $? -eq 0 ]; then
		tgsgapcloserTest="FAILED"
	else
		tgsgapcloserTest="PASSED"
	fi
	
	mafft --version
	if [ ! $? -eq 0 ]; then
		mafftTest="FAILED"
	else
		mafftTest="PASSED"
	fi
	
	
	for testResult in $chopperTest $bcTest $samtoolsTest $canuTest $minimap2Test $pythonTest $biopythonTest $embossTest $tgsgapcloserTest; do
		if [ "$testResult" == "FAILED" ]; then
			failed="True"
		fi
	done
	
	echo "chopper test has $chopperTest"
	echo "bc test has $bcTest"
	echo "samtools test has $samtoolsTest"
	echo "canu test has $canuTest"
	echo "minimap2 test has $minimap2Test"
	echo "python test has $pythonTest"
	echo "biopython test has $biopythonTest"
	
	if [ $biopythonTest == "FAILED" ]; then
		echo "biopython only necessary when building consensus from reference database"
	fi
	
	echo "emboss test has $embossTest"
	
	if [ $embossTest == "FAILED" ]; then
		echo "emboss only necessary when building consensus from reference database"
	fi
	
	echo "tgsgapcloser test has $tgsgapcloserTest"
	echo "mafft test has $mafftTest"
	
	if [ "$failed" == "True" ]; then
		echo "One or more dependencies have failed."
		echo "Make sure all dependencies are installed either manually or with bash nanoviphy.sh --install"
		echo "Make sure all installed dependencies have been added to PATH"
	fi
}

get_assembly_id() {
	assembly=$1
	
	if [[ "$assembly" == *contigs.fasta ]]; then
		BC=$(basename "$assembly" .contigs.fasta)
	fi
	if [[ "$assembly" == *_scaffold.fasta ]]; then
		BC=$(basename "$assembly" _scaffold.fasta)
	fi
	if [[ "$assembly" == *scaff_seqs ]]; then
		BC=$(basename "$assembly" .scaff_seqs)
	fi
	
	echo ${BC}
}

nano_viphy_install() {
# PREREQUISITES: Anaconda 3
if ! command -v conda &> /dev/null; then
    echo "Please install conda before running in installation mode"
    exit 1
fi

# Install conda packages if not installed
if ! command -v python &> /dev/null; then
	conda install -y python=3.12.2
fi

biopython=$(conda list | grep biopython)

if [ -z "$biopython" ]; then
	conda install -y -c conda-forge biopython=1.84
fi

if ! command -v chopper &> /dev/null; then
	conda install -y -c conda-forge libgcc-ng=14.1.0
	conda install -y -c conda-forge libstdcxx-ng=14.1.0
	conda install -y -c conda-forge zlib=1.2.13
    conda install -y -c bioconda chopper=0.8.0
fi

if ! command -v bc &> /dev/null; then
    conda install -y bc=1.07.1
fi

if ! command -v minimap2 &> /dev/null; then
    conda install -y minimap2=2.28
fi

if ! command -v samtools &> /dev/null; then
	conda install zlib
	conda install -y -c conda-forge libgcc-ng=14.1.0
	conda install -y -c conda-forge ncurses=6.5
	conda install -y -c conda-forge libcurl=8.7.1
	conda install -y -c conda-forge libdeflate=1.20
	conda install -y -c bioconda -c conda-forge htslib=1.20
	conda install -y samtools=1.20
fi

if ! command -v cons &> /dev/null; then
	conda install -y -c bioconda emboss=6.6.0
fi

if ! command -v tgsgapcloser &> /dev/null; then
	conda install -y -c bioconda tgsgapcloser=1.2.1
fi

if ! command -v mafft &> /dev/null; then
	conda install -y mafft=7.526
fi

if ! command -v iqtree &> /dev/null; then
	conda install -y iqtree=2.3.6
fi

# Install canu
if ! command -v canu &> /dev/null; then
	curl -L https://github.com/marbl/canu/releases/download/v2.2/canu-2.2.Linux-amd64.tar.xz -o "tools/canu-2.2.Linux.tar.xz"
	tar -xJf "tools/canu-2.2.Linux.tar.xz" -C tools
	canuPath=$(realpath "tools/canu-2.2/bin")
	echo "Path to canu executable: $canuPath"
	echo "Run: export PATH=${canuPath}:\$PATH"
fi
}