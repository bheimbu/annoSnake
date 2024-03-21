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

# Read the CSV file
data <- read.csv(snakemake@input[['microbes']], header = FALSE)

# Remove double quotes from all columns
data <- lapply(data, function(x) gsub('"', '', x))
data <- as.data.frame(data)

# Select the third and last columns
result <- data[, c(3, 7)]

# Read the tab-separated table
gtf <- read.table(snakemake@input[['gtf']], sep = "\t", header = FALSE, stringsAsFactors = FALSE)

# Extract the first column and everything after "gene_id"
result2 <- data.frame(gtf[, 1], gsub(".*gene_id\\s+", "", gtf[, 9]))
colnames(result2) <- c("V1", "V2")

merged_result <- merge(result, result2, by.x = "V3", by.y = "V2", all.x = TRUE, all.y = FALSE)
merged_result <- merged_result[, c("V1", "V3", "V7")]

# Read tab-separated table data
table_data <- read.table(snakemake@input[['quant']], sep = "\t", header = TRUE)
table_data$Name <- gsub(":.*$", "", table_data$Name)

merged_result2 <- merge(merged_result, table_data, by.x = "V1", by.y = "Name", all.x = TRUE, all.y = FALSE)
colnames(merged_result2) <- c("contig_names", "protein_names", "marker_taxonomy", "length", "effective_length", "tpm", "num_reads")

# Filter merged result
merged_result_filtered <- merged_result2 %>%
  filter(num_reads >= 10 & tpm >= 1)

merged_result_filtered$log_tpm <- log(merged_result_filtered$tpm + 1)

merged_result_filtered <- merged_result_filtered %>%
  distinct(contig_names, marker_taxonomy, log_tpm)

# Group by contig names and filter based on marker_taxonomy
result <- merged_result_filtered %>%
  group_by(contig_names) %>%
  filter(grepl("^d__[^_]", marker_taxonomy))

result <- result %>%
  distinct(contig_names, marker_taxonomy, log_tpm)

result <- result %>% dplyr::mutate(row_id = row_number())

# Spread the filtered result
spread <- spread(result, marker_taxonomy, log_tpm)

spread <- spread %>% select(-row_id)
# Group by contig names and summarize data
aggregated_data <- spread %>%
  group_by(contig_names) %>%
  summarise_all(~ if (is.numeric(.)) sum(., na.rm = TRUE) else first(.))

# Extract the contig names
contig <- spread %>%
  mutate(contig_names = sub("_.*", "", contig_names))

# Group and summarize the data
aggregated_data <- contig %>%
  dplyr::group_by(contig_names) %>%
  summarise(across(everything(), sum, na.rm = TRUE))

aggregated_data <- aggregated_data %>%
  rename(sample = contig_names)

# Subset the data frame to exclude the "sample" column
clr_data_subset <- aggregated_data[-which(names(aggregated_data) == "sample")]

clr <- as_tibble(decostand(clr_data_subset, method = "clr", pseudocount = 1))

# Add the "sample" column back to the transformed data
clr_result <- cbind(sample = aggregated_data$sample, clr)

clr_result_df <- as.data.frame(clr_result)

# Reshape data to long format
clr_result_long <- gather(clr_result_df, bacteria, clr_value, -sample)

clr_result_long$clr_value <- as.numeric(clr_result_long$clr_value)
clr_result_long$bacteria <- as.factor(clr_result_long$bacteria)

heatmap <- clr_result_long %>% ggplot(aes(x = sample, y = bacteria, fill = clr_value, text = `sample`, label = `clr_value`, label2 = `bacteria`)) +
  geom_tile() +
  geom_tile(color = "black", linewidth = 0.1, fill = NA) +
  scale_fill_viridis_c(option="viridis", direction = 1, name = "log(TPM+1)") +
  theme_bw(base_line_size = 0, base_rect_size = 0, base_size = 10) +
  scale_y_discrete(limits=rev) +
  theme(axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_text(angle = 90, hjust = .75, vjust = .25, face = "bold"),
        axis.text.y = element_text(face = "bold"),
        legend.text = element_text(face = "bold"),
        legend.title = element_text(face = "bold")) +
  labs(x = "", y = "")
                
#save as pdf####
pdf(NULL)
pdf(snakemake@output[['pdf']], paper = "a4r", width = 30, height = 15)
heatmap
dev.off()

#save as html####
clr_long_df_separated <- as_tibble(clr_result_long) %>%
  extract(bacteria,
          into = c("domain", "phylum", "class", "order", "family", "genus", "species"),
          regex = "^d__([^_]+)(?:_p__([^_]+))?(?:_c__([^_]+))?(?:_o__([^_]+))?(?:_f__([^_]+))?(?:_g__([^_]+))?(?:_s__(.*))?",
          remove = FALSE) %>%
  mutate(across(domain:species, ~if_else(is.na(.), "Unknown", .)))

heatmap_plotly <- clr_long_df_separated %>% ggplot(aes(x = sample, y = bacteria, fill = clr_value, text = `sample`, label = `clr_value`, label2 = `domain`, label3 = `phylum`, label4 = `class`, label5 = `order`, label6 = `family`, label7 = `genus`, label8 = `species`)) +
  geom_tile() +
  geom_tile(color = "black", linewidth = 0.1, fill = NA) +
  scale_fill_viridis_c(option="viridis", direction = 1, name = "log(TPM+1)") +
  theme_minimal() +
  scale_y_discrete(limits=rev) +
  theme(axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_text(angle = 90, hjust = .75, vjust = .25, face = "bold"),
        axis.text.y = element_blank(),
        legend.text = element_text(face = "bold"),
        legend.title = element_text(face = "bold")) +
  labs(x = "", y = "")

p <- ggplotly(heatmap_plotly, tooltip = c("text","label","label2","label3","label4","label5","label6","label7","label8"))
htmlwidgets::saveWidget(p, snakemake@output[['html']])


