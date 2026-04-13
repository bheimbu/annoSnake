#!/usr/bin/env Rscript

# Load libraries
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
library(readr)

#data wrangling####
data <- read_tsv(snakemake@input[['pfam']])
gtf <- read.table(snakemake@input[['gtf']], sep = "\t", header = FALSE, stringsAsFactors = FALSE)

result2 <- data.frame(gtf[, 1], gsub(".*gene_id\\s+", "", gtf[, 9]))
colnames(result2) <- c("V1", "V2")

merged_result <- merge(data, as_tibble(result2), by.x = "seq_id", by.y = "V2", all.x = TRUE, all.y = FALSE)

table_data <- read.table(snakemake@input[['sf']], sep = "\t", header = FALSE)
table_data$V1 <- gsub(":.*$", "", table_data$V1)

merged_result2 <- merge(merged_result, table_data, by.x = "V1", by.y = "V1", all.x = TRUE, all.y = FALSE)
colnames(merged_result2) <- c("contig_name", "seq_id", "alignment_start", "alignment_end", "envelope_start", "envelope_end", "hmm_acc", "hmm_name",  "type", "hmm_start", "hmm_end", "hmm_length", "bit_score", "E-value", "significance", "clan",                    "length", "effective_length", "tpm", "num_reads")
merged_result2 <- na.omit(merged_result2)

merged_result2$tpm <- as.numeric(merged_result2$tpm)
merged_result2$num_reads <- as.numeric(merged_result2$num_reads)

# write csv####
csv <- merged_result2 %>%
  mutate(sample = sub("_contig.*", "", contig_name)) %>%
  relocate(sample, .before = everything())
write.csv(csv,snakemake@output[['csv']], row.names = FALSE)

#data wrangling continued####
merged_result_filtered <- csv %>%
  filter(num_reads >= 50 & tpm >= 1)

merged_result_filtered <- as_tibble(merged_result_filtered)

merged_result_filtered  <- merged_result_filtered  %>%
  mutate(tpm = as.numeric(tpm))

merged_result_filtered$log_tpm <- log10(merged_result_filtered$tpm + 1)

merged_result_filtered <- merged_result_filtered %>%
  distinct(contig_name, hmm_name, log_tpm)

spread <- spread(merged_result_filtered, hmm_name, log_tpm)

aggregated_data <- spread %>%
  group_by(contig_name) %>%
  summarise_all(~ if (is.numeric(.)) sum(., na.rm = TRUE) else first(.))

contig <- spread %>%
  mutate(contig_name = sub("_contig.*", "", contig_name))

aggregated_data <- contig %>%
  group_by(contig_name) %>%
  summarise(across(everything(), sum, na.rm = TRUE))

aggregated_data <- aggregated_data %>%
  rename(sample = contig_name)

clr_data_subset <- aggregated_data[-which(names(aggregated_data) == "sample")]
clr <- decostand(clr_data_subset, method = "clr", pseudocount = .65)
clr_result <- cbind(sample = aggregated_data$sample, clr)

transposed_clr_result <- t(clr_result) 
transposed_clr_result<-as.data.frame(transposed_clr_result)
transposed_clr_result<-tibble::rownames_to_column(transposed_clr_result)
colnames(transposed_clr_result) <- transposed_clr_result[1, ]
transposed_clr_result <- transposed_clr_result[-1, ]
transposed_clr_result <- as_tibble(transposed_clr_result)
transposed_clr_result <- transposed_clr_result %>%
  mutate_at(vars(2:ncol(transposed_clr_result)), as.numeric)

transposed_clr_result$TotalAbundance <- rowSums(transposed_clr_result[, -1])  # Calculate the row-wise abundances
n_pfam <- nrow(transposed_clr_result)
top_n <- min(50, n_pfam)
top_50_pfam <- transposed_clr_result[order(transposed_clr_result$TotalAbundance, decreasing = TRUE), ][1:top_n, ]
top_50_pfam <- top_50_pfam[, -ncol(top_50_pfam)]
top_50_pfam <- t(top_50_pfam)
colnames(top_50_pfam) <- top_50_pfam[1, ]
top_50_pfam <- top_50_pfam[-1, ]
top_50_pfam <- as.data.frame(top_50_pfam)
top_50_pfam$sample <- rownames(top_50_pfam)
rownames(top_50_pfam) <- NULL

clr_result_long <- gather(as.data.frame(top_50_pfam), pfam, clr_value, -sample)
clr_result_long$clr_value <- as.numeric(clr_result_long$clr_value)
clr_result_long$pfam <- as.factor(clr_result_long$pfam)
clr_result_long <- clr_result_long %>% arrange(pfam)

#save as pdf#### 
heatmap <- clr_result_long %>% ggplot(aes(x = sample, y = pfam, fill = clr_value, text = sample, label = pfam, label2 = clr_value)) +
  geom_tile() +
  geom_tile(color = "black", linewidth = 0.1, fill = NA) +
  scale_fill_viridis_c(option="D", direction = 1, name = "log(TPM+1)") +
  theme_bw(base_line_size = 0, base_rect_size = 0, base_size = 11) +
  scale_fill_viridis_c(option="viridis", direction = 1, name = "log(TPM+1)",
                       breaks = seq(floor(min(clr_result_long$clr_value, na.rm=TRUE)),
                                    ceiling(max(clr_result_long$clr_value, na.rm=TRUE)),
                                    by = 0.5)) +
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
p <- ggplotly(heatmap, tooltip = c("text","label","label2"))
htmlwidgets::saveWidget(p, snakemake@output[['html']])
