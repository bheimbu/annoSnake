rule salmon_quant_contigs_paired_end:
    input:
        OUTDIR/ "quantification/contigs/{sample}/{sample}.index"
    output:
        touch(OUTDIR/ "quantification/contigs/{sample}/.rule_completed")
    params:
        contigs=lambda wildcards, output: Path(output[0]).parent
    threads:
        20
    conda:
        "envs/salmon.yaml"
    shell:
        """
        salmon quant -i {input} -l IU -1 <(gunzip -c {INPUTDIR}/{wildcards.sample}_R1.fastq.gz) -2 <(gunzip -c {INPUTDIR}/{wildcards.sample}_R2.fastq.gz) -o {params.contigs}/{wildcards.sample}.quant --meta -p {threads}
        """