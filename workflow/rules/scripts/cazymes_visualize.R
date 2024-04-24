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

#data wrangling####
data <- read.table(snakemake@input[['hits']], header = FALSE, sep = "\t")
result <- data[, c(2, 6)]
result <- as_tibble(result)

gtf <- read.table(snakemake@input[['gtf']], sep = "\t", header = FALSE, stringsAsFactors = FALSE)

result2 <- data.frame(gtf[, 1], gsub(".*gene_id\\s+", "", gtf[, 9]))
colnames(result2) <- c("V1", "V2")

merged_result <- merge(result, as_tibble(result2), by.x = "V2", by.y = "V2", all.x = TRUE, all.y = FALSE)
merged_result <- merged_result[, c("V1", "V2", "V6")]

table_data <- read.table(snakemake@input[['sf']], sep = "\t", header = FALSE)
table_data$V1 <- gsub(":.*$", "", table_data$V1)

merged_result2 <- merge(merged_result, table_data, by.x = "V1", by.y = "V1", all.x = TRUE, all.y = FALSE)
colnames(merged_result2) <- c("contig_names", "protein_names", "cazyme", "length", "effective_length", "tpm", "num_reads")
merged_result2 <- na.omit(merged_result2)


merged_result2$tpm <- as.numeric(merged_result2$tpm)
merged_result2$num_reads <- as.numeric(merged_result2$num_reads)


merged_result_filtered <- merged_result2 %>%
  filter(num_reads >= 50 & tpm >= 1)

merged_result_filtered <- as_tibble(merged_result_filtered)

merged_result_filtered  <- merged_result_filtered  %>%
  mutate(tpm = as.numeric(tpm))

merged_result_filtered$log_tpm <- log10(merged_result_filtered$tpm + 1)

merged_result_filtered <- merged_result_filtered %>%
  distinct(contig_names, cazyme, log_tpm)

spread <- spread(merged_result_filtered, cazyme, log_tpm)

aggregated_data <- spread %>%
  group_by(contig_names) %>%
  summarise_all(~ if (is.numeric(.)) sum(., na.rm = TRUE) else first(.))

contig <- spread %>%
  mutate(contig_names = sub("_contig.*", "", contig_names))

aggregated_data <- contig %>%
  group_by(contig_names) %>%
  summarise(across(everything(), sum, na.rm = TRUE))

aggregated_data <- aggregated_data %>%
  rename(sample = contig_names)

clr_data_subset <- aggregated_data[-which(names(aggregated_data) == "sample")]

clr <- decostand(clr_data_subset, method = "clr", pseudocount = 1)

clr_result <- cbind(sample = aggregated_data$sample, clr)

transposed_clr_result <- t(clr_result) 
transposed_clr_result<-as.data.frame(transposed_clr_result)
transposed_clr_result<-tibble::rownames_to_column(transposed_clr_result)
colnames(transposed_clr_result) <- transposed_clr_result[1, ]
transposed_clr_result <- transposed_clr_result[-1, ]
transposed_clr_result <- as_tibble(transposed_clr_result)
transposed_clr_result <- transposed_clr_result %>%
  mutate_at(vars(2:ncol(transposed_clr_result)), as.numeric)
transposed_clr_result <- transposed_clr_result %>%
  rename(cazyme = sample)


transposed_clr_result$TotalAbundance <- rowSums(transposed_clr_result[, -1])  # Calculate the row-wise abundances
top_50_cazymes <- transposed_clr_result[order(transposed_clr_result$TotalAbundance, decreasing = TRUE), ][1:50, ]

top_50_cazymes <- top_50_cazymes[, -ncol(top_50_cazymes)]

top_50_cazymes <- t(top_50_cazymes)
colnames(top_50_cazymes) <- top_50_cazymes[1, ]
top_50_cazymes <- top_50_cazymes[-1, ]
top_50_cazymes <- as.data.frame(top_50_cazymes)
top_50_cazymes$sample <- rownames(top_50_cazymes)
rownames(top_50_cazymes) <- NULL

clr_result_long <- gather(as.data.frame(top_50_cazymes), cazyme, clr_value, -sample)
clr_result_long$clr_value <- as.numeric(clr_result_long$clr_value)
clr_result_long$cazyme <- as.factor(clr_result_long$cazyme)

clr_result_long$cazyme <- sub("\\.hmm", "", clr_result_long$cazyme)

clr_result_long <- clr_result_long %>% arrange(cazyme)

write.csv(clr_result_long[order(clr_result_long$sample), ], snakemake@output[['csv']], row.names = FALSE)
              
#save as pdf#### 
heatmap <- clr_result_long %>% ggplot(aes(x = sample, y = cazyme, fill = clr_value, text = sample, label = cazyme, label2 = clr_value)) +
  geom_tile() +
  geom_tile(color = "black", linewidth = 0.1, fill = NA) +
  scale_fill_viridis_c(option="D", direction = 1, name = "log(TPM+1)") +
  theme_bw(base_line_size = 0, base_rect_size = 0, base_size = 10) +
  scale_fill_viridis_c(option="viridis", direction = 1, name = "log(TPM+1)") +
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
