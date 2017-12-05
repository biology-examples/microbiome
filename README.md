# Microbiome analysis

Scripts for software install and analysis for microbiome datasets

## QIIME2
* `qiime2install.txt`: code for qiime2 software installation
  * customized for JetStream BioLinux instances
  * installs Miniconda, QIIME2, and dependencies
* The following scripts set up project directories, and perform the basic analysis:
  * `moving-pictures-qiime2.sh`: script for general workflow using qiime2
  * `moving-pictures-qiime2export.sh`: script for exporting data from qiime2 for import to R
  
  ## R
  * `phyloseq-qiime2.R`: imports data, performs statistical tests, and visualizes results
  
