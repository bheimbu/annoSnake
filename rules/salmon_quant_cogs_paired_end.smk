rule salmon_quant_cogs_paired_end:
    input:
        OUTDIR/ "quantification/cogs/cogs.index"
    output:
        touch(OUTDIR/ "quantification/cogs/.quant_completed")
    threads:
        20
    params:
        cogs=lambda wildcards, output: Path(output[0]).parent  
    conda:
        "envs/salmon.yaml"
    shell:
        """
        salmon quant -i {input} -l IU -1 <(gunzip -c {INPUTDIR}/*_R1.fastq.gz) -2 <(gunzip -c {INPUTDIR}/*_R2.fastq.gz) -o {params.cogs}/cogs.quant --meta -p {threads}
        """