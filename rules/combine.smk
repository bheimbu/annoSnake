localrules: combine_kegg1, combine_kegg2, combine_pfam, combine_cazy, combine_salmon_contigs1, combine_salmon_contigs2, combine_salmon_cogs, combine_metaquast, combine_gtf
		
rule combine_kegg1:
    input:
        OUTDIR/ "annotation/kegg/{sample}/{sample}.kegg.evalue"
    output:
        touch(OUTDIR/ "annotation/kegg/{sample}/{sample}.kegg.no_header")
    shell:
        """
        sed '1d' {input} > {output}
        """
		
rule combine_kegg2:
    input:
        expand(OUTDIR/ "annotation/kegg/{sample}/{sample}.kegg.no_header", sample=SAMPLES)
    output:
        OUTDIR/ "combine/kegg_combine.txt"
    shell:
        """
        cat {input} >> {output}
        """
		
rule combine_pfam:
    input:
        expand(OUTDIR/ "annotation/pfam/{sample}/{sample}.evalue", sample=SAMPLES)
    output:
        OUTDIR/ "combine/pfam_combine.txt"
    shell:
        """
        cat {input} >> {output}
        """
		
rule combine_cazy:
    input:
        expand(OUTDIR/ "annotation/cazy/{sample}/{sample}.top", sample=SAMPLES)
    output:
        OUTDIR/ "combine/cazy_combine.txt"
    shell:
        """
        cat {input} >> {output}
        """

rule combine_salmon_contigs1:
    input:
         expand(OUTDIR/ "quantification/contigs/{sample}/.rule_completed", sample=SAMPLES)
    output:
        touch(OUTDIR/ "quantification/contigs/{sample}/{sample}.quant/quant_no_header.sf")
    shell:
        """
        sed '1d' {OUTDIR}/quantification/contigs/{wildcards.sample}/{wildcards.sample}.quant/quant.sf > {output}
        """

rule combine_salmon_contigs2:
    input:
        expand(OUTDIR/ "quantification/contigs/{sample}/{sample}.quant/quant_no_header.sf", sample=SAMPLES)
    output:
        OUTDIR/ "combine/contigs_combine.sf"
    shell:
        """
        cat {input} >> {output}
        """
        
rule combine_salmon_cogs:
    input:
        OUTDIR/ "quantification/cogs/.quant_completed"
    output:
        OUTDIR/ "combine/cogs.sf"
    shell:
        """
        cp -a {OUTDIR}/quantification/cogs/cogs.quant/quant.sf {output}
        """

rule combine_metaquast:
    input:
        OUTDIR/ "assemblies/metaquast/report.html"
    output:
        OUTDIR/ "combine/metaquast.html"
    shell:
        """
        cp -a {input} {output}
        """
		
rule combine_checkm:
    input:
        expand(OUTDIR/ "MAGs/checkm/{sample}/.rule_completed", sample=SAMPLES)
    shell:
        """
        rm -rf {OUTDIR}/MAGs/above_threshold_bins/{wildcards.sample}_bin.*.fa
        """
		
rule combine_gtf:
    input:
        expand(OUTDIR/ "taxonomy/prokka/{sample}/{sample}.gtf", sample=SAMPLES)
    output:
        OUTDIR/ "combine/contigs_combine.gtf"
    shell:
        """
        cat {input} >> {output}
        """
		