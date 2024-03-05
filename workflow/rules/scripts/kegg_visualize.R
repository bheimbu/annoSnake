#!/usr/bin/env Rscript

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

kofam <- read.table(snakemake@input[['kegg']], header = FALSE, sep = ",")
# Select the third and last columns
kofam <- kofam[, c( 4, 5)]
kofam <- subset(kofam, V5 != "fullproteinnames" & V5 != "annotation")

keggids <- c("K01938","K01491","K13990","K00297","K00122","K00198","K14138","K00194","K00197","K15023","K00625","K00925","K00394","K00395","K00958","K11180","K11181","K02586","K02591","K02588","K02587","K02592","K02585","K00370","K00371","K00374","K02567","K02568","K00362","K00363","K03385","K15876","K01428","K01429","K01430","K00265","K00266","K01915","K03320","K11959","K11960","K11961","K11962","K11963","K00926","K00611","K01940","K01755","K00399","K00401","K00402")

filtered_kofam <- kofam %>%
  filter(V4 %in% keggids)

colnames(filtered_kofam) <- c("keggID", "protein")

keggID_to_gene_name <- read.csv(snakemake@params[['keggID']], header = T)

keggID_to_gene_name <- keggID_to_gene_name %>%
  separate_rows(keggID, sep = " ")

kofam_gene <- merge(filtered_kofam, keggID_to_gene_name, by.x = "keggID", by.y = "keggID", all.x = TRUE)

# Read the tab-separated table
gtf <- read.table(snakemake@input[['gtf']], sep = "\t", header = FALSE, stringsAsFactors = FALSE)

# Extract the first column and everything after "gene_id"
gtf_extracted <- data.frame(gtf[, 1], gsub(".*gene_id\\s+", "", gtf[, 9]))
colnames(gtf_extracted) <- c("contig_names", "protein")

merged_result <- merge(kofam_gene, gtf_extracted, by.x = "protein", by.y = "protein", all.x = TRUE, all.y = FALSE)

# Read tab-separated table data
quant <- read.table(snakemake@input[['quant']], sep = "\t", header = F)
quant$V1 <- gsub(":.*$", "", quant$V1)

merged_result2 <- merge(merged_result, quant, by.x = "contig_names", by.y = "V1", all.x = TRUE, all.y = FALSE)
colnames(merged_result2) <- c("contig_names", "protein", "keggID", "gene_name", "pathway", "length", "effective_length", "tpm", "num_reads")
merged_result2 <- na.omit(merged_result2)

# Filter merged result
merged_result2 <- as_tibble(merged_result2)

merged_result_filtered  <- merged_result2  %>%
  mutate(tpm = as.numeric(tpm), num_reads = as.numeric(num_reads))

merged_result_filtered <- merged_result_filtered %>%
  filter(num_reads >= 10 & tpm >= 1)

merged_result_filtered$log_tpm <- log10(merged_result_filtered$tpm + 1)

# Select specific columns and remove duplicates
merged_result_filtered <- merged_result_filtered %>%
  distinct(contig_names, gene_name, log_tpm)

# Spread the filtered result
spread <- spread(merged_result_filtered, gene_name, log_tpm)

# Group by contig names and summarize data
aggregated_data <- spread %>%
  group_by(contig_names) %>%
  summarise_all(~ if (is.numeric(.)) sum(., na.rm = TRUE) else first(.))

# Extract the contig names
contig <- spread %>%
  mutate(contig_names = sub("_.*", "", contig_names))

# Group and summarize the data
aggregated_data <- contig %>%
  group_by(contig_names) %>%
  summarise(across(everything(), sum, na.rm = TRUE))

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

# Join the clr_result_long data frame with keggID_to_gene_name to get pathway information
heatmap_data <- clr_result_long %>%
  left_join(keggID_to_gene_name, by = c("gene_name" = "gene_name"), suffix = c("_clr_result", "_keggID"))

heatmap_data$gene_name <- factor(heatmap_data$gene_name, levels = unique(heatmap_data$gene_name[order(heatmap_data$pathway)]))
                
heatmap_data <- heatmap_data %>%
  arrange(pathway)

heatmap <- ggplot(heatmap_data, aes(x = sample, y = gene_name, fill = clr_value)) +
  geom_tile(color = "white", size = 0.1) +
  scale_fill_viridis_c(option="D", direction = 1, name = "log(TPM+1)") +
  theme_minimal() +
  theme(axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_text(angle = 90, hjust = .75, vjust = .25, face = "bold"),
        axis.text.y = element_text(face = "bold"),
        legend.text = element_text(face = "bold"),
        legend.title = element_text(face = "bold"))

                
#save as pdf####
pdf(NULL)
pdf(snakemake@output[['pdf']], paper = "a4r", width = 30, height = 15)
heatmap
dev.off()
                
#save as html####
p <- ggplotly(heatmap) %>%
layout(xaxis = list(ticktext = paste0("<b>", levels(factor(heatmap_data$sample)), "</b>")))
htmlwidgets::saveWidget(p, snakemake@output[['html']])
