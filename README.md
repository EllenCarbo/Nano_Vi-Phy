# Nano Vi-Phy
Nano Vi-Phy is a pipeline designed for processing Oxford Nanopore Technologies (ONT) data into whole genome sequences and using these sequences for building a phylogenetic tree with a background data set. Nano Vi-Phy was inspired by [shiver](https://github.com/ChrisHIV/shiver). The goal I set for this pipeline was: set up the config file, press play, get a coffee break and when you’re back, you got your tree file. Nano Vi-Phy was made for HIV whole genome sequencing, but should work on other small (viral) genomes and selected regions as well, just adjust parameters accordingly. Instructions for customisable options will be in the manual. There is no guarantee that everything won’t crash when using this on large genomes. Try it at your own risk if you want.  

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

See the manual for details. 

