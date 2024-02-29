library(dplyr)
library(propr)
library(ggplot2)
library(tidyr)
library(compositions)
library(grid)
library(aplot)
library(ape)
library(vegan)
library(extrafont)

meth_hits <- read.table(snakemake@input[['hits']])
colnames(meth_hits) <- c("bin", "KO")
meth_hits$Binary <- rep(1, nrow(meth_hits))
df <- as_tibble(meth_hits)
df$bin <- as.character(df$bin)
df_transposed <- pivot_wider(df, id_cols = bin, names_from = KO, values_from = Binary, values_fn = list(Binary = mean), values_fill = 0)
df_gather <- gather(df_transposed, KeggID, Binary, -bin)
definition <- read.csv(snakemake@params[['pathway']], header = T)
definition <- definition %>%
  separate_rows(KeggID, sep = " ")
mags_methano <- merge(df_gather, definition, by.x = "KeggID", by.y = "KeggID", all.x = TRUE)
mags_methano <- mags_methano %>%
  arrange(pathway)
mags_methano <- as_tibble(mags_methano)
mags_methano <- mags_methano %>%
  mutate(Binary = ifelse(Binary == 1, "Gene present", "Gene absent"))
mags_methano$Binary <- as.character(mags_methano$Binary)

checkm_summaries <- list.files(snakemake@input[[''summaries]], pattern = "\\.summary$", full.names = TRUE)
checkm_combine <- do.call(rbind, lapply(checkm_summaries, function(file) {
  df <- read.table(file, header=TRUE, fill=TRUE, comment.char = "-")  # Read the file
  subset_df <- df[, c("Bin", "X..1", "markers")]  # Subset the desired columns
  colnames(subset_df) <- c("bin", "Completeness", "Contamination")  # Rename the columns
  return(subset_df)
}))

checkm_completeness_plot <- ggplot(checkm_combine, aes(x = "Completeness", y = bin, fill = Completeness)) +
  geom_tile(color = "black", size = 0.1) +
  scale_fill_viridis_c(option="D", direction = 1, name = "Completeness in %") +
  theme_minimal() +
  theme(axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_text(angle = 90, hjust = .75, vjust = .25, face = "bold"),
        axis.text.y = element_text(face = "bold"),
        legend.text = element_text(face = "bold"),
        legend.title = element_text(face = "bold"))

checkm_contamination_plot <- ggplot(checkm_combine, aes(x = "Contamination", y = bin, fill = Contamination)) +
  geom_tile(color = "black", size = 0.1) +
  scale_fill_viridis_c(option="D", direction = -1, name = "Contamination in %") +
  theme_minimal() +
  theme(axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_text(angle = 90, hjust = .75, vjust = .25, face = "bold"),
        axis.text.y = element_blank(),
        legend.text = element_text(face = "bold"),
        legend.title = element_text(face = "bold"))

heatmap_plot <- ggplot(mags_methano, aes(x = Gene, y = bin, fill = Binary)) +
  geom_tile(color = "black", size = 0.1) +
  scale_fill_viridis_d(option="D", direction = 1, name = "") +
  theme_minimal() +
  theme(axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_text(angle = 90, hjust = .75, vjust = .25, face = "bold"),
        axis.text.y = element_blank(),
        legend.text = element_text(face = "bold"),
        legend.title = element_text(face = "bold"))

heatmap_plot %>% insert_left(checkm_contamination_plot, width = 0.05) %>% insert_left(checkm_completeness_plot, width = 0.05)

ggsave(snakemake@output[['pdf']], width = 20, height = 20, units = "cm")
