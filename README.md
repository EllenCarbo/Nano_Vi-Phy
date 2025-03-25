# Nano Vi-Phy
Pipeline of student Kaiden for analyzing Oxford Nanopore Technologies (ONT) reads into whole genome sequences by creating sample specific references, this will lead to more mapped reads and therefor, more accurate variant analysis.

Main/Bioinformatic supervisor: Ellen

Extra supervisor: Marion

Lab technician: Fokla




# Nano Vi-Phy
Nano Vi-Phy (Nanopore Viral Phylogeny) is a pipeline designed for processing Oxford Nanopore Technologies (ONT) data into whole genome sequences and using these sequences for building a phylogenetic tree with a background data set. Nano Vi-Phy was inspired by [shiver](https://github.com/ChrisHIV/shiver). The goal I set for this pipeline was: set up the config file, press play, get a coffee break and when you’re back, you got your tree file. Nano Vi-Phy was made for HIV whole genome sequencing, but should work on other small (viral) genomes and selected regions as well, just adjust parameters accordingly. Instructions for customisable options will be in the manual. There is no guarantee that everything won’t crash when using this on large genomes. Try it at your own risk if you want.  

## Quick start
```
git clone --recurse-submodules https://github.com/Kaiden-exe/Nano_Vi-Phy.git
cd Nano_Vi-Phy
conda create -n nanoviphy
conda activate nanoviphy
bash nanoviphy.sh --install
export PATH=/path/to/tools/canu-2.2/bin:$PATH
bash nanoviphy.sh --test
```

If all dependencies passed, adjust config.sh

`bash nanoviphy.sh -c config.sh`

See the [manual](https://github.com/Kaiden-exe/Nano_Vi-Phy/blob/main/Nano_Vi-Phy_Manual.pdf) for details. 

