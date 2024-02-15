rule fetchmg:
    input:
        OUTDIR/ "taxonomy/prokka/{sample}/{sample}.gtf",
        db="databases/.fetchmg_downloaded"
    output:
        touch(OUTDIR/ "taxonomy/fetchmg/{sample}/.rule_completed")
    params:
        fetchmg=lambda wildcards, input: Path(input["db"]).parent,
        faa=lambda wildcards, input: Path(input[0]).parent,
        dir=lambda wildcards, output: Path(output[0]).parent
    shadow:
        "shallow"
    threads:
        20
    conda:
        "envs/environment.yaml"
    shell:
        """
        mkdir -p {OUTDIR}/taxonomy/fetchmg/{wildcards.sample}
        {params.fetchmg}/fetchMGs/fetchMGs.pl -m extraction -x {params.fetchmg}/fetchMGs/bin {params.faa}/{wildcards.sample}.faa -o {params.out} -t {threads}
        """
