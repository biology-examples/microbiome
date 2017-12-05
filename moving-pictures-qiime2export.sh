#!/bin/bash

## export qiime2 results from "moving pictures" analysis for use in R

## usage: bash moving-pictures-qiime2export.sh 
# first run moving-pictures-qiime2.sh

## activate the environment
source activate qiime2-2017.10
# test installation
#qiime --help

## export data and prepare for working in R
mkdir qiime-exported
# copy mapping file to exported file
cp qiime2-moving-pictures-tutorial/sample-metadata.tsv qiime-exported/

cd qiime2-moving-pictures-tutorial/

# export data from qza
qiime tools export taxonomy.qza --output-dir ../qiime-exported
qiime tools export rooted-tree.qza --output-dir ../qiime-exported
qiime tools export table.qza --output-dir ../qiime-exported

cd ../qiime-exported/

# add taxonomy to biom table
biom add-metadata -i feature-table.biom -o table.biom --observation-metadata-fp taxonomy.tsv --observation-header OTUID,taxonomy,confidence
