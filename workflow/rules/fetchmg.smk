rule fetchmg:
    input:
        OUTDIR/ "taxonomy/prokka/{sample}/{sample}.gtf",
        db="databases/fetchMGs/.setup_done"
    output:
        touch(OUTDIR/ "taxonomy/fetchmg/{sample}/.rule_completed")
    params:
        fetchmg=lambda wildcards, input: Path(input["db"]).parent,
        faa=lambda wildcards, input: Path(input[0]).parent,
        dir=lambda wildcards, output: Path(output[0]).parent
    shadow:
        "shallow"
    threads:
        40
    conda:
        "envs/fetchmg.yaml"
    benchmark:
        OUTDIR/ "benchmarks/{sample}_fetchmg.txt"
    shell:
        """
        rm -rf {params.dir}
        fetchMGs extraction {params.faa}/{wildcards.sample}.faa gene {params.dir} -t {threads}
        """
