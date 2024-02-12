rule salmon_quant_cogs_interleaved:
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
        scripts/runner.sh salmon quant -i {input} -l IU --interleaved <(gunzip -c {INPUTDIR}/*gz) -o {params.cogs}/cogs.quant --meta -p {threads}
        """