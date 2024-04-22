#!/usr/bin/env Rscript

# Load required libraries
library(dplyr)
library(propr)
library(ggplot2)
library(tidyr)
library(compositions)
library(grid)
library(aplot)
library(ape)
library(vegan)

#data preparation####
meth_hits <- read.table(snakemake@input[['hits']])
colnames(meth_hits) <- c("bin", "KO")
meth_hits$binary <- rep(1, nrow(meth_hits))
df <- as_tibble(meth_hits)
df$bin <- as.character(df$bin)
df_transposed <- pivot_wider(df, id_cols = bin, names_from = KO, values_from = binary, values_fn = list(binary = mean), values_fill = 0)
df_gather <- gather(df_transposed, keggid, binary, -bin)
definition <- read.csv(snakemake@params[['pathway']], header = T)
definition <- definition %>%
  separate_rows(keggid, sep = " ")
mags <- merge(df_gather, definition, by.x = "keggid", by.y = "keggid", all.x = TRUE)
mags <-arrange(mags, keggid)
mags <- as_tibble(mags)
mags <- mags %>%
  mutate(binary = ifelse(binary == 1, "present", "absent"))

#checkm summaries
checkm_summaries <- list.files(snakemake@input[['checkm']], pattern = "\\.summary$", full.names = TRUE)
checkm_combine <- do.call(rbind, lapply(checkm_summaries, function(file) {
  df <- read.table(file, header=TRUE, fill=TRUE, comment.char = "-")
  subset_df <- df[, c("Bin", "X..1", "markers")]  
  colnames(subset_df) <- c("bin", "completeness", "contamination") 
  return(subset_df)
}))

#write csv
combined <- left_join(checkm_combine, mags, by = "bin")
write.csv(combined[order(combined$bin), ], snakemake@output[['csv']])

#plotting####
checkm_completeness_plot <- ggplot(checkm_combine, aes(x = "completeness", y = bin, fill = completeness)) +
  geom_tile(color = "black", size = 0.1) +
  scale_fill_viridis_c(option="D", direction = 1, name = "completeness in %") +
  theme_minimal() +
  theme(axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_text(angle = 90, hjust = .75, vjust = .25, face = "bold"),
        axis.text.y = element_text(face = "bold"),
        legend.text = element_text(face = "bold"),
        legend.title = element_text(face = "bold"))

checkm_contamination_plot <- ggplot(checkm_combine, aes(x = "contamination", y = bin, fill = contamination)) +
  geom_tile(color = "black", size = 0.1) +
  scale_fill_viridis_c(option="D", direction = -1, name = "contamination in %") +
  theme_minimal() +
  theme(axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_text(angle = 90, hjust = .75, vjust = .25, face = "bold"),
        axis.text.y = element_blank(),
        legend.text = element_text(face = "bold"),
        legend.title = element_text(face = "bold"))

heatmap <- ggplot(mags, aes(x = gene, y = bin, fill = binary)) +
  geom_tile(color = "black", size = 0.1) +
  scale_fill_viridis_d() + 
  facet_wrap(~pathway, scales = "free_x") +
  theme_minimal() +
  theme(axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_text(angle = 90, hjust = .75, vjust = .25),
        axis.text.y = element_blank(),
        legend.text = element_text(face = "bold"),
        legend.title = element_blank(),
        strip.text = element_text(face = "bold"))

#saving to pdf####
pdf(NULL)
pdf(snakemake@output[['pdf']], paper = "a4r", width = 30, height = 15)
heatmap %>% insert_left(checkm_contamination_plot, width = 0.05) %>% insert_left(checkm_completeness_plot, width = 0.05)
dev.off()
