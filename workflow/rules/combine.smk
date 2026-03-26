localrules: combine_kegg1, combine_kegg2, combine_pfam, combine_cazy, combine_salmon_contigs1, combine_salmon_contigs2, combine_salmon_cogs, combine_metaquast, combine_gtf
		
rule combine_kegg1:
    input:
        OUTDIR/ "annotation/kegg/{sample}/{sample}.kegg.evalue"
    output:
        touch(OUTDIR/ "annotation/kegg/{sample}/{sample}.kegg.no_header")
    benchmark:
        OUTDIR/ "benchmarks/{sample}_combine_kegg1.txt"
    shell:
        """
        sed '1d' {input} > {output}
        """
		
rule combine_kegg2:
    input:
        expand(OUTDIR/ "annotation/kegg/{sample}/{sample}.kegg.no_header", sample=SAMPLES)
    output:
        OUTDIR/ "combine/kegg_combine.txt"
    benchmark:
        OUTDIR/ "benchmarks/combine_kegg2.txt"
    shell:
        """
        cat {input} >> {output}
        """
		
rule combine_pfam:
    input:
        expand(OUTDIR/ "annotation/pfam/{sample}/{sample}.pfam", sample=SAMPLES)
    output:
        OUTDIR/ "combine/pfam_combine.tsv"
    benchmark:
        OUTDIR/ "benchmarks/combine_pfam.txt"
    shell:
        """
        header="seq_id\talignment_start\talignment_end\tenvelope_start\tenvelope_end\thmm_acc\thmm_name\ttype\thmm_start\thmm_end\thmm_length\tbit_score\tE-value\tsignificance\tclan"
        echo -e "$header" > {output}
        cat {input} | grep -v '^$' | sed 's/[[:space:]]\\+/\\t/g' | sed 's/^\\t//' >> {output}
        """
		
rule combine_cazy:
    input:
        expand(OUTDIR/ "annotation/cazy/{sample}/{sample}.dbcan", sample=SAMPLES)
    output:
        OUTDIR/ "combine/cazy_combine.tsv"
    benchmark:
        OUTDIR/ "benchmarks/combine_cazy.txt"
    shell:
        """
		header="domain_name\tdomain_length\tquery_id\tquery_length\te-value\thit_start\thit_end\tquery_start\tquery_end\thit_coverage"
		echo -e "$header" > {output}
        cat {input} >> {output}
        """

rule combine_salmon_contigs1:
    input:
         expand(OUTDIR/ "quantification/contigs/{sample}/.rule_completed", sample=SAMPLES)
    output:
        touch(OUTDIR/ "quantification/contigs/{sample}/{sample}.quant/quant_no_header.sf")
    benchmark:
        OUTDIR/ "benchmarks/{sample}_combine_salmon_contigs1.txt"
    shell:
        """
        sed '1d' {OUTDIR}/quantification/contigs/{wildcards.sample}/{wildcards.sample}.quant/quant.sf > {output}
        """

rule combine_salmon_contigs2:
    input:
        expand(OUTDIR/ "quantification/contigs/{sample}/{sample}.quant/quant_no_header.sf", sample=SAMPLES)
    output:
        OUTDIR/ "combine/contigs_combine.sf"
    benchmark:
        OUTDIR/ "benchmarks/combine_salmon_contigs2.txt"
    shell:
        """
        cat {input} >> {output}
        """
        
rule combine_salmon_cogs:
    input:
        OUTDIR/ "quantification/cogs/.quant_completed"
    output:
        OUTDIR/ "combine/cogs.sf"
    benchmark:
        OUTDIR/ "benchmarks/combine_salmon_cogs.txt"
    shell:
        """
        cp -a {OUTDIR}/quantification/cogs/cogs.quant/quant.sf {output}
        """

rule combine_metaquast:
    input:
        OUTDIR/ "assemblies/metaquast/report.html"
    output:
        OUTDIR/ "figures/metaquast.html"
    benchmark:
        OUTDIR/ "benchmarks/combine_metaquast.txt"
    shell:
        """
        cp -a {input} {output}
        """
		
rule combine_checkm:
    input:
        expand(OUTDIR/ "MAGs/checkm/{sample}/.rule_completed", sample=SAMPLES)
    benchmark:
        OUTDIR/ "benchmarks/combine_checkm.txt"
    shell:
        """
        rm -rf {OUTDIR}/MAGs/above_threshold_bins/{wildcards.sample}_bin.*.fa
        """
		
rule combine_gtf:
    input:
        expand(OUTDIR/ "taxonomy/prokka/{sample}/{sample}.gtf", sample=SAMPLES)
    output:
        OUTDIR/ "combine/contigs_combine.gtf"
    benchmark:
        OUTDIR/ "benchmarks/combine_gtf.txt"
    shell:
        """
        cat {input} >> {output}
        """
		
