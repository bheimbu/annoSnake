#!/usr/bin/env Rscript

# Load required libraries
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

# Read COG blastp microbes (protein-level, higher priority)
cog_data <- read.csv(snakemake@input[['microbes_blastp']], header = FALSE)
cog_data <- as.data.frame(lapply(cog_data, function(x) gsub('"', '', x)))
cog_result <- cog_data[, c(2, 6)]
colnames(cog_result) <- c("protein", "lineage_cog")
cog_result$protein <- gsub("\\..*", "", cog_result$protein)

# Read blastx microbes (contig-level, lower priority fallback)
blastx_data <- read.csv(snakemake@input[['microbes_blastx']], header = FALSE)
blastx_data <- as.data.frame(lapply(blastx_data, function(x) gsub('"', '', x)))
blastx_result <- blastx_data[, c(2, 6)]
colnames(blastx_result) <- c("contig_names", "lineage_blastx")

# Deduplicate blastx: some contigs appear twice with different rank labels
# Keep most resolved (longest lineage)
blastx_result <- blastx_result %>%
  group_by(contig_names) %>%
  slice_max(nchar(lineage_blastx), n = 1, with_ties = FALSE) %>%
  ungroup()

# Read GTF to map proteins -> contigs
gtf <- read.table(snakemake@input[['gtf']], sep = "\t", header = FALSE, stringsAsFactors = FALSE)
gtf_extracted <- data.frame(gtf[, 1], gsub(".*gene_id\\s+", "", gtf[, 9]))
colnames(gtf_extracted) <- c("contig_names", "protein")

# Step 1: map COG taxonomy onto proteins via GTF
cog_contigs <- merge(cog_result, gtf_extracted, by = "protein", all.y = TRUE)

# Step 2: aggregate to contig level — pick most resolved COG taxonomy per contig
cog_per_contig <- cog_contigs %>%
  filter(!is.na(lineage_cog)) %>%
  group_by(contig_names) %>%
  slice_max(nchar(lineage_cog), n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(contig_names, lineage_cog)

# Step 3: merge COG and blastx — COG priority, blastx fallback, Unassigned if neither
combined <- merge(cog_per_contig, blastx_result, by = "contig_names", all = TRUE) %>%
  mutate(marker_taxonomy = case_when(
    !is.na(lineage_cog)    ~ lineage_cog,
    !is.na(lineage_blastx) ~ lineage_blastx,
    TRUE                   ~ "Unassigned"
  )) %>%
  select(contig_names, marker_taxonomy)

# Read quant data — no header in sf file
table_data <- read.table(snakemake@input[['quant']], sep = "\t", header = FALSE)
colnames(table_data) <- c("Name", "length", "effective_length", "tpm", "num_reads")
table_data$Name <- gsub(":.*$", "", table_data$Name)

# Get full sample list before any filtering
all_samples <- unique(sub("_contig.*", "", table_data$Name))

# Merge combined taxonomy with quant
merged_result2 <- merge(combined, table_data, by.x = "contig_names", by.y = "Name", all.x = FALSE, all.y = TRUE)
colnames(merged_result2) <- c("contig_names", "marker_taxonomy", "length", "effective_length", "tpm", "num_reads")
merged_result2$marker_taxonomy[is.na(merged_result2$marker_taxonomy)] <- "Unassigned"

# write csv####
csv <- merged_result2 %>%
  mutate(contig_names = sub("_contig.*", "", contig_names))
csv <- csv %>% rename(sample = contig_names)
csv_write <- csv[, c("sample", "marker_taxonomy", "tpm", "num_reads")]
write.csv(csv_write[order(csv_write$sample), ], snakemake@output[['csv']], row.names = FALSE)
#####

# Filter by expression thresholds
merged_result_filtered <- merged_result2 %>%
  mutate(tpm = as.numeric(tpm), num_reads = as.numeric(num_reads)) %>%
  filter(num_reads >= 50 & tpm >= 1)

# Log transform TPM
merged_result_filtered$log_tpm <- log(merged_result_filtered$tpm + 1)

# Remove duplicates
merged_result_filtered <- merged_result_filtered %>%
  distinct(contig_names, marker_taxonomy, log_tpm)

# Keep only lineages starting with d__ OR "Unassigned"
result <- merged_result_filtered %>%
  group_by(contig_names) %>%
  filter(grepl("^d__[^_]", marker_taxonomy) | marker_taxonomy == "Unassigned")

result <- result %>%
  distinct(contig_names, marker_taxonomy, log_tpm) %>%
  dplyr::mutate(row_id = row_number())

# Spread
spread <- spread(result, marker_taxonomy, log_tpm)
spread <- spread %>% select(-row_id)

# Extract sample names
contig <- spread %>%
  mutate(contig_names = sub("_contig.*", "", contig_names))

# Group and summarize
aggregated_data <- contig %>%
  dplyr::group_by(contig_names) %>%
  summarise(across(everything(), sum, na.rm = TRUE)) %>%
  rename(sample = contig_names) %>%
  complete(sample = all_samples, fill = list(0))

# CLR transformation
clr_data_subset <- aggregated_data[-which(names(aggregated_data) == "sample")]
clr <- as_tibble(decostand(clr_data_subset, method = "clr", pseudocount = .65))
clr_result <- cbind(sample = aggregated_data$sample, clr)
clr_result_df <- as.data.frame(clr_result)

# Reshape to long format
clr_result_long <- gather(clr_result_df, taxonomy, clr_value, -sample)
clr_result_long$clr_value <- as.numeric(clr_result_long$clr_value)
clr_result_long$taxonomy   <- as.factor(clr_result_long$taxonomy)

#plotting####

heatmap <- clr_result_long %>%
  ggplot(aes(x = sample, y = taxonomy, fill = clr_value,
             text = sample, label = clr_value, label2 = taxonomy)) +
  geom_tile() +
  geom_tile(color = "black", linewidth = 0.1, fill = NA) +
  scale_fill_viridis_c(option = "viridis", direction = 1, name = "log(TPM+1)") +
  theme_minimal(base_size = 11) +
  scale_y_discrete(limits = rev, position = "right") +
  theme(
    axis.title.y     = element_blank(),
    axis.title.x     = element_blank(),
    axis.text.x      = element_text(angle = 90, hjust = .75, vjust = .25, face = "bold"),
    axis.text.y      = element_text(face = "bold", hjust = 0),
    legend.text      = element_text(face = "bold"),
    legend.title     = element_text(face = "bold"),
    legend.position  = "left"
  ) +
  labs(x = "", y = "")

#save as pdf####
ggsave(snakemake@output[['pdf']], width = 30, height = 20, units = "cm")

#save as html####
clr_result_long$taxonomy_orig <- clr_result_long$taxonomy

clr_result_long$taxonomy <- gsub("d__", "domain_", clr_result_long$taxonomy)
clr_result_long$taxonomy <- gsub("p__", "phylum_", clr_result_long$taxonomy)
clr_result_long$taxonomy <- gsub("c__", "class_",  clr_result_long$taxonomy)
clr_result_long$taxonomy <- gsub("o__", "order_",  clr_result_long$taxonomy)
clr_result_long$taxonomy <- gsub("f__", "family_", clr_result_long$taxonomy)
clr_result_long$taxonomy <- gsub("g__", "genus_",  clr_result_long$taxonomy)
clr_result_long$taxonomy <- gsub("s__", "species_",clr_result_long$taxonomy)

clr_long_df_separated <- as_tibble(clr_result_long) %>%
  separate(taxonomy,
           into = c("domain", "phylum", "class", "order", "family", "genus", "species"),
           sep  = ";",
           extra = "drop",
           fill  = "right")

clr_long_df_separated$domain  <- gsub("domain_",  "", clr_long_df_separated$domain)
clr_long_df_separated$phylum  <- gsub("phylum_",  "", clr_long_df_separated$phylum)
clr_long_df_separated$class   <- gsub("class_",   "", clr_long_df_separated$class)
clr_long_df_separated$order   <- gsub("order_",   "", clr_long_df_separated$order)
clr_long_df_separated$family  <- gsub("family_",  "", clr_long_df_separated$family)
clr_long_df_separated$genus   <- gsub("genus_",   "", clr_long_df_separated$genus)
clr_long_df_separated$species <- gsub("species_", "", clr_long_df_separated$species)

heatmap_plotly <- clr_long_df_separated %>%
  ggplot(aes(x = sample, y = taxonomy_orig, fill = clr_value,
             text = sample, label = clr_value,
             label2 = domain, label3 = phylum, label4 = class,
             label5 = order, label6 = family, label7 = genus, label8 = species)) +
  geom_tile() +
  geom_tile(color = "black", linewidth = 0.1, fill = NA) +
  scale_fill_viridis_c(option = "viridis", direction = 1, name = "log(TPM+1)") +
  theme_minimal() +
  scale_y_discrete(limits = rev, position = "right") +
  theme(
    axis.title.y     = element_blank(),
    axis.title.x     = element_blank(),
    axis.text.x      = element_text(angle = 90, hjust = .75, vjust = .25, face = "bold"),
    axis.text.y      = element_text(face = "bold", hjust = 0),
    legend.text      = element_text(face = "bold"),
    legend.title     = element_text(face = "bold")
  ) +
  labs(x = "", y = "")

p <- ggplotly(heatmap_plotly,
              tooltip = c("text", "label", "label2", "label3", "label4",
                          "label5", "label6", "label7", "label8"))
htmlwidgets::saveWidget(p, snakemake@output[['html']])
