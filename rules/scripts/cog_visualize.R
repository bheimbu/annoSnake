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
  filter(grepl("^d__[^_]+_p__[^_]+_c__[^_]+_o__[^_]+", marker_taxonomy))

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

clr_long_df_separated <- as_tibble(clr_result_long) %>%
  extract(bacteria,
          into = c("domain", "phylum", "class", "order", "family", "genus", "species"),
          regex = "^d__([^_]+)(?:_p__([^_]+))?(?:_c__([^_]+))?(?:_o__([^_]+))?(?:_f__([^_]+))?(?:_g__([^_]+))?(?:_s__(.*))?",
          remove = FALSE) %>%
  mutate(across(domain:species, ~if_else(is.na(.), "Unknown", .)))  # Replace NA with "Unknown"

# Create the plotly heatmap
p <- plot_ly(data = clr_long_df_separated, 
             x = ~sample, 
             y = ~bacteria, 
             z = ~clr_value, 
             type = "heatmap",
             colorscale = "viridis",
             colorbar = list(title = "log(TPM+1)"),
             text = ~paste("Domain:", domain,
                           "<br>Phylum:", phylum,
                           "<br>Class:", class,
                           "<br>Order:", order,
                           "<br>Family:", family,
                           "<br>Genus:", genus,
                           "<br>Species:", species),
             hoverinfo = "text") %>% layout(yaxis = list(showticklabels = FALSE, autorange="reversed", title = ''), 
                  xaxis = list(title = ''))

# Save as HTML
htmlwidgets::saveWidget(p, snakemake@output[['html']])


