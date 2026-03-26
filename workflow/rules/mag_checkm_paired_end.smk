localrules: MAG_checkm_paired2

rule MAG_checkm_paired1:
      input:
        OUTDIR/ "MAGs/above_threshold_bins/.rule_completed",
        "databases/checkm2/.setup_done"
      output:
        touch(OUTDIR/ "MAGs/checkm/{sample}/.rule_completed")
      params:
        db="databases/checkm2/CheckM2_database/uniref100.KO.1.dmnd"
      threads:
        40
      conda:
        "envs/checkm2.yaml"
      benchmark:
        OUTDIR/ "benchmarks/{sample}_MAG_checkm_paired1.txt"
      shell:
        """
        if [ -e {OUTDIR}/"MAGs/above_threshold_bins/{wildcards.sample}/{wildcards.sample}_bin.1.fa" ]; then
			checkm2 predict --threads {threads} --extension .fa --input {OUTDIR}/MAGs/above_threshold_bins/{wildcards.sample} --output-directory {OUTDIR}/MAGs/checkm/{wildcards.sample} --database_path {params.db} --force
            coverm genome --coupled {INPUTDIR}/{wildcards.sample}_R1.fastq.gz {INPUTDIR}/{wildcards.sample}_R2.fastq.gz --genome-fasta-files {OUTDIR}/MAGs/above_threshold_bins/{wildcards.sample}/*.fa --threads {threads} >& {OUTDIR}/MAGs/checkm/{wildcards.sample}/{wildcards.sample}.abundance
        else
            touch "{OUTDIR}/MAGs/checkm/{wildcards.sample}/.rule_completed"
        fi
        """

rule MAG_checkm_paired2:
    input:
        expand(OUTDIR / "MAGs/checkm/{sample}/.rule_completed", sample=SAMPLES)
    output:
        directory(OUTDIR / "MAGs/checkm/summaries")
    params:
        indir=OUTDIR / "MAGs/checkm",
        samples=" ".join(SAMPLES)
    benchmark:
        OUTDIR/ "benchmarks/MAG_checkm_paired2.txt"
    shell:
        """
        mkdir -p {output}
        find {params.indir} -maxdepth 2 -name "quality_report.tsv" \
        -exec sh -c 'cp "$1" "{output}/$(basename $(dirname "$1")).tsv"' _ {{}} \\;
        """
