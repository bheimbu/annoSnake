rule prokka:
    input:
	    OUTDIR/ "assemblies/preprocessed_contigs/{sample}/.rule_completed"
    output:
        OUTDIR/ "taxonomy/prokka/{sample}/{sample}.gtf"
    params:
        contigs=lambda w, input: Path(input[0]).parent,
        gff=lambda w, output: Path(output[0]).parent
    threads:
        20
    conda:
        "envs/environment.yaml"
    shell:
        """
        prokka --force --cpus {threads} --metagenome --prefix {wildcards.sample} --outdir {OUTDIR}/taxonomy/prokka/{wildcards.sample} {params.contigs}/{wildcards.sample}.fna
        rules/scripts/prokkagff2gtf.sh {params.gff}/{wildcards.sample}.gff > {output}
        """
