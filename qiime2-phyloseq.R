#### import and analysis of qiime2 results using phyloseq ####

# install bioconductor package
#source("http://bioconductor.org/biocLite.R")
#biocLite('phyloseq')
# load package
library(phyloseq)
# install ggplot2
#install.packages("ggplot2")
# load package
library(ggplot2)

#### data import ####
# import biom (otu table and tax table)
biom <- import_biom("qiime2-exported/table.biom", parseFunction = parse_taxonomy_greengenes)
# you will receive warning messages from the command above
# the code below corrects this issue with taxonomic ranks
# view names
rank_names(biom)
# correct taxonomy
tax_table(biom) <- tax_table(biom)[, 1:7]
rank_names(biom)
biom
# import map (metadata) file
map <- import_qiime_sample_data("qiime2-exported/sample-metadata.tsv")
str(map)
# import tree file
rep_tre <- read_tree("qiime2-exported/tree.nwk")
rep_tre
# combine otu/tax and map
comb <- merge_phyloseq(biom, map, rep_tre)
str(comb)
comb


