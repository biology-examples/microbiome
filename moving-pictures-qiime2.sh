#!/bin/bash

## example qiime2 analysis using "moving pictures" data

## usage: bash moving-pictures-qiime2.sh 
# first run commands in qiime2install.txt
# adapted from this tutorial: https://docs.qiime2.org/2017.11/tutorials/moving-pictures/

## activate the environment
source activate qiime2-2017.10
# test installation
#qiime --help

## set up directory
mkdir qiime2-moving-pictures-tutorial
cd qiime2-moving-pictures-tutorial
mkdir emp-single-end-sequences

## download data
# metadata
wget -O "sample-metadata.tsv" "https://data.qiime2.org/2017.10/tutorials/moving-pictures/sample_metadata.tsv"
# sequences
wget -O "emp-single-end-sequences/barcodes.fastq.gz" "https://data.qiime2.org/2017.10/tutorials/moving-pictures/emp-single-end-sequences/barcodes.fastq.gz"
wget -O "emp-single-end-sequences/sequences.fastq.gz" "https://data.qiime2.org/2017.10/tutorials/moving-pictures/emp-single-end-sequences/sequences.fastq.gz"

## import sequence data
qiime tools import \
  --type EMPSingleEndSequences \
  --input-path emp-single-end-sequences \
  --output-path emp-single-end-sequences.qza

## demultiplex sequences
qiime demux emp-single \
  --i-seqs emp-single-end-sequences.qza \
  --m-barcodes-file sample-metadata.tsv \
  --m-barcodes-category BarcodeSequence \
  --o-per-sample-sequences demux.qza
# summarize demultiplexing
qiime demux summarize \
  --i-data demux.qza \
  --o-visualization demux.qzv
  
## quality control data with DADA2 (takes awhile)
qiime dada2 denoise-single \
  --i-demultiplexed-seqs demux.qza \
  --p-trim-left 0 \
  --p-trunc-len 120 \
  --o-representative-sequences rep-seqs-dada2.qza \
  --o-table table-dada2.qza
# organize files
mv rep-seqs-dada2.qza rep-seqs.qza
mv table-dada2.qza table.qza

# visually summarize data
qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file sample-metadata.tsv
qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv

## generate phylogenetic tree
# align sequences
qiime alignment mafft \
  --i-sequences rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza
# remove highly variable positions
qiime alignment mask \
  --i-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza
# create phylogeny
qiime phylogeny fasttree \
  --i-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza
# root tree at midpoint
qiime phylogeny midpoint-root \
  --i-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

# alpha and beta diversity analyses
# core metrics
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table table.qza \
  --p-sampling-depth 1109 \
  --m-metadata-file sample-metadata.tsv \
  --output-dir core-metrics-results
# test for associations: alpha 
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization core-metrics-results/faith-pd-group-significance.qzv
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization core-metrics-results/evenness-group-significance.qzv
# test for associations: beta
qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-category BodySite \
  --o-visualization core-metrics-results/unweighted-unifrac-body-site-significance.qzv \
  --p-pairwise
qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-category Subject \
  --o-visualization core-metrics-results/unweighted-unifrac-subject-group-significance.qzv \
  --p-pairwise

# create PCoA plots
qiime emperor plot \
  --i-pcoa core-metrics-results/unweighted_unifrac_pcoa_results.qza \
  --m-metadata-file sample-metadata.tsv \
  --p-custom-axis DaysSinceExperimentStart \
  --o-visualization core-metrics-results/unweighted-unifrac-emperor-DaysSinceExperimentStart.qzv
qiime emperor plot \
  --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza \
  --m-metadata-file sample-metadata.tsv \
  --p-custom-axis DaysSinceExperimentStart \
  --o-visualization core-metrics-results/bray-curtis-emperor-DaysSinceExperimentStart.qzv

# create rarefaction plots
qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-max-depth 4000 \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization alpha-rarefaction.qzv
  
#### taxonomic analysis
# download classifier
wget -O "gg-13-8-99-515-806-nb-classifier.qza" "https://data.qiime2.org/2017.10/common/gg-13-8-99-515-806-nb-classifier.qza"
# apply classifier
qiime feature-classifier classify-sklearn \
  --i-classifier gg-13-8-99-515-806-nb-classifier.qza \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy.qza
qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv
# view taxonomic composition
qiime taxa barplot \
  --i-table table.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization taxa-bar-plots.qzv

# testing taxonomic composition
# create feature table
qiime feature-table filter-samples \
  --i-table table.qza \
  --m-metadata-file sample-metadata.tsv \
  --p-where "BodySite='gut'" \
  --o-filtered-table gut-table.qza
# add to feature table
qiime composition add-pseudocount \
  --i-table gut-table.qza \
  --o-composition-table comp-gut-table.qza
# identify differences in feature table
qiime composition ancom \
  --i-table comp-gut-table.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-category Subject \
  --o-visualization ancom-Subject.qzv
# collapse taxonomic levels and rerun
qiime taxa collapse \
  --i-table gut-table.qza \
  --i-taxonomy taxonomy.qza \
  --p-level 6 \
  --o-collapsed-table gut-table-l6.qza
qiime composition add-pseudocount \
  --i-table gut-table-l6.qza \
  --o-composition-table comp-gut-table-l6.qza
qiime composition ancom \
  --i-table comp-gut-table-l6.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-category Subject \
  --o-visualization l6-ancom-Subject.qzv
