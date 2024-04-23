localrules: visualization_cogs, visualization_kegg, visualization_mags1, visualization_mags2, visualization_cazymes

rule visualization_cogs:
    input:
        quant=OUTDIR/ "combine/cogs.sf",
        gtf=OUTDIR/ "taxonomy/cogs/cogs.gtf",
        microbes=OUTDIR/ "taxonomy/cogs/cogs.blastp.matches.lca.microbes"
    output:
        html=OUTDIR/ "figures/rel_abundance_of_bacteria_and_archaea_in_metagenomes.html",
        pdf=OUTDIR/ "figures/rel_abundance_of_bacteria_and_archaea_in_metagenomes.pdf",
        csv=OUTDIR/ "tables/rel_abundance_of_bacteria_and_archaea_in_metagenomes.csv"
    conda:
        "envs/visualization.yaml"
    script:
        "scripts/cog_visualize.R"
		
rule visualization_kegg:
    input:
        kegg=OUTDIR/ "combine/kegg_combine.txt",
        gtf=OUTDIR/ "combine/contigs_combine.gtf",
        quant=OUTDIR/ "combine/contigs_combine.sf"
    params:
        keggID="rules/scripts/keggid_to_gene_name.csv"
    output:
        html=OUTDIR/ "figures/prokaryotic_metabolic_pathways.html",
        pdf=OUTDIR/ "figures/prokaryotic_metabolic_pathways.pdf",
        csv=OUTDIR/ "tables/prokaryotic_metabolic_pathways.csv"
    conda:
        "envs/visualization.yaml"
    script:
        "scripts/kegg_visualize.R"

rule visualization_mags1:
    input:
        OUTDIR/ "MAGs/microbeannotator/.rule_completed"
    params:
        KO_list="rules/scripts/KO_list.txt",
        kofam_results=lambda wildcards, output: Path(output[0]).parent
    output:
        hits=OUTDIR/ "MAGs/microbeannotator/kofam_results/all.hits",
        bins=OUTDIR/ "MAGs/microbeannotator/kofam_results/all.bins"
    conda:
        "envs/visualization.yaml"
    shell:
        """
        grep -E -f {params.KO_list} {params.kofam_results}/*filt > {output.bins}
        sed -i 's|{params.kofam_results}/||g' {output.bins}
        awk -F'\t' '{{sub(/\\.faa.*/, ".faa", $1); print $1, $3}}' {output.bins} > {output.hits}
        sed -i 's|.faa||g' {output.hits}
        """

rule visualization_mags2:
    input:
        hits=OUTDIR/ "MAGs/microbeannotator/kofam_results/all.hits",
        checkm=OUTDIR/ "MAGs/checkm/summaries"
    params:
        pathway="rules/scripts/keggid_to_genes_pathway.csv"
    output:
        pdf=OUTDIR/ "figures/MAG_metabolic_pathways.pdf",
        csv=OUTDIR/ "tables/MAG_metabolic_pathways.csv"
    conda:
        "envs/visualization.yaml"
    script:
        "scripts/mags_visualize.R"

rule visualization_cazymes:
    input:
        hits=OUTDIR/ "combine/cazy_combine.txt",
        gtf=OUTDIR/ "combine/contigs_combine.gtf",
        sf=OUTDIR/ "combine/contigs_combine.sf"
    output:
        pdf=OUTDIR/ "figures/relative_abundance_CAZymes_metagenomes.pdf",
        html=OUTDIR/ "figures/relative_abundance_CAZymes_metagenomes.html",
        csv=OUTDIR/ "tables/relative_abundance_CAZymes_metagenomes.csv"
    conda:
        "envs/visualization.yaml"
    script:
        "scripts/cazymes_visualize.R"

