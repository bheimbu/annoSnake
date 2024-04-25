#!/usr/bin/env Rscript

# Load required libraries
library(forcats)
library(dplyr)
library(propr)
library(ggplot2)
library(tidyr)
library(compositions)
library(aplot)
library(ape)
library(vegan)
library(tidyverse)
library(gridExtra)
library(plotly)

#data preparation####
kofam <- read.table(snakemake@input[['kegg']], header = FALSE, sep = ",")
# Select the third and last columns
kofam <- kofam[, c( 4, 5)]
kofam <- subset(kofam, V5 != "fullproteinnames" & V5 != "annotation")

# Read KEGG ID to gene name mapping
keggid_to_gene_name <- read.csv(snakemake@params[['keggID']], header = TRUE)
keggid_to_gene_name <- keggid_to_gene_name %>%
  separate_rows(keggid, sep = " ")

# Filter KEGG data
filtered_kofam <- kofam %>%
  filter(V4 %in% keggid_to_gene_name$keggid)
colnames(filtered_kofam) <- c("keggid", "protein")

# Merge filtered KEGG data with gene names
kofam_gene <- merge(filtered_kofam, keggid_to_gene_name, by.x = "keggid", by.y = "keggid", all.x = TRUE)

# Read GTF data
gtf <- read.table(snakemake@input[['gtf']], sep = "\t", header = FALSE, stringsAsFactors = FALSE)

# Extract contig names and protein IDs from GTF data
gtf_extracted <- data.frame(gtf[, 1], gsub(".*gene_id\\s+", "", gtf[, 9]))
colnames(gtf_extracted) <- c("contig_names", "protein")

# Merge KOFAM gene data with GTF extracted data
merged_result <- merge(kofam_gene, gtf_extracted, by.x = "protein", by.y = "protein", all.x = TRUE, all.y = FALSE)

# Read tab-separated table data
quant <- read.table(snakemake@input[['quant']], sep = "\t", header = FALSE)
quant$V1 <- gsub(":.*$", "", quant$V1)

# Merge merged result with quant data
merged_result2 <- merge(merged_result, quant, by.x = "contig_names", by.y = "V1", all.x = TRUE, all.y = FALSE)
colnames(merged_result2) <- c("contig_names", "protein", "keggid", "gene_name", "pathway", "length", "effective_length", "tpm", "num_reads")
merged_result2 <- na.omit(merged_result2)

# write csv####
csv <- merged_result2  %>%
  mutate(contig_names = sub("_contig.*", "", contig_names))
csv <- csv %>% rename(sample = contig_names)
csv_write <- csv[, c("sample", "keggid","gene_name", "pathway", "tpm", "num_reads")]
write.csv(csv_write[order(csv_write$sample), ], snakemake@output[['csv']], row.names = FALSE)
#####

# Filter merged result
merged_result2 <- as_tibble(merged_result2)
merged_result_filtered <- merged_result2 %>%
  mutate(tpm = as.numeric(tpm), num_reads = as.numeric(num_reads)) %>%
  filter(num_reads >= 50 & tpm >= 1)

# Calculate log TPM
merged_result_filtered$log_tpm <- log10(merged_result_filtered$tpm + 1)

# Remove duplicates
merged_result_filtered <- merged_result_filtered %>%
  distinct(contig_names, gene_name, log_tpm)

# Spread the data
spread <- spread(merged_result_filtered, gene_name, log_tpm)

# Group by contig names and summarize data
aggregated_data <- spread %>%
  group_by(contig_names) %>%
  summarise_all(~ if (is.numeric(.)) sum(., na.rm = TRUE) else first(.))

# Extract the contig names
contig <- spread %>%
  mutate(contig_names = sub("_contig.*", "", contig_names))

# Group and summarize the data
aggregated_data <- contig %>%
  group_by(contig_names) %>%
  summarise(across(everything(), sum, na.rm = TRUE))

# Rename columns
aggregated_data <- aggregated_data %>%
  rename(sample = contig_names)

# Subset the data frame to exclude the "sample" column
clr_data_subset <- aggregated_data[-which(names(aggregated_data) == "sample")]

# Perform CLR transformation
clr <- as_tibble(decostand(clr_data_subset, method = "clr", pseudocount = 0.65))

# Add the "sample" column back to the transformed data
clr_result <- cbind(sample = aggregated_data$sample, clr)
clr_result <- as_tibble(clr_result)

# Reshape data to long format
clr_result_long <- gather(clr_result, gene_name, clr_value, -sample)
clr_result_long$clr_value <- as.numeric(clr_result_long$clr_value)
clr_result_long$gene_name <- as.factor(clr_result_long$gene_name)

# Join the clr_result_long data frame with keggid_to_gene_name to get pathway information
heatmap_data <- clr_result_long %>%
  inner_join(distinct(keggid_to_gene_name, gene_name, .keep_all = TRUE), by = "gene_name")

# Order the rows by the pathway column
heatmap_data <- heatmap_data %>%
  group_by(pathway) %>%
  mutate(gene_name = fct_reorder(gene_name, clr_value, .fun = function(x) mean(x))) %>%
  ungroup()
heatmap_data <- heatmap_data %>%
  select(sample, gene_name, keggid, pathway, clr_value)

#write csv
write.csv(heatmap_data[order(heatmap_data$sample), ], snakemake@output[['csv']], row.names = FALSE)
                          
#plotting####

#save as pdf####
heatmap <- heatmap_data %>% ggplot(aes(x = sample, y = gene_name, fill = clr_value, text = sample, label = clr_value, label2 = gene_name, label3 = pathway)) +
  geom_tile() +
  geom_tile(color = "black", linewidth = 0.1, fill = NA) +
  scale_fill_viridis_c(option="D", direction = 1, name = "log(TPM+1)") +
  theme_minimal() +
  scale_y_discrete(position = "right") +
  theme(axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_text(angle = 90, hjust = .75, vjust = .25, face = "bold"),
        axis.text.y = element_text(face = "bold"),
        legend.text = element_text(face = "bold"),
        legend.title = element_text(face = "bold"),
        legend.position = "left") +
  labs(x = "", y = "")

pdf(NULL)
pdf(snakemake@output[['pdf']], paper = "a4r", width = 30, height = 15)
heatmap
dev.off()

#save as html####
p <- ggplotly(heatmap, tooltip = c("text","label","label2","label3"))
htmlwidgets::saveWidget(p, snakemake@output[['html']])
