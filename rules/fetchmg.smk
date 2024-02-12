rule fetchmg:
    input:
        gtf=OUTDIR/ "taxonomy/prokka/{sample}/{sample}.gtf",
        db="databases/.fetchmg_downloaded"
    output:
        touch(OUTDIR/ "taxonomy/fetchmg/.{sample}_completed")
    params:
        fetchmg=lambda wildcards, input: Path(input[1]).parent,
        faa=lambda wildcards, input: Path(input[0]).parent
    shadow:
        "shallow"
    threads:
        20
    conda:
        "envs/environment.yaml"
    shell:
        """
        cd {OUTDIR}/taxonomy/fetchmg
		{params.fetchmg}/fetchMGs/fetchMGs.pl -m extraction -x {params.fetchmg}/fetchMGs/bin {params.faa}/{wildcards.sample}.faa -o {wildcards.sample} -t {threads}
        """