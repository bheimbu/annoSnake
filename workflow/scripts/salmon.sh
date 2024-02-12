#!/bin/bash

###conda envs

salmon index -p 30 -t ${FNA_DIR}/gtdbmicrobial-230-13-prokka.fasta -i ${OUT_DIR}/gtdbmicrobial-230-13-prokka_index

#parameters are taken from https://github.com/bxlab/metaWRAP/blob/master/bin/metawrap-modules/quant_bins.sh
salmon quant -i ${OUT_DIR}/gtdbmicrobial-230-13-prokka_index --libType IU -1 ${READS_DIR}/230-13_R1_paired.fq.gz -2 ${READS_DIR}/230-13_R2_paired.fq.gz -o ${OUT_DIR}/230-13.quant --meta -p 30
