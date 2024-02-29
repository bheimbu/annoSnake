localrules: MAG_checkm_paired2

rule MAG_checkm_paired1:
      input:
        OUTDIR/ "MAGs/above_threshold_bins/.rule_completed"
      output:
        touch(OUTDIR/ "MAGs/checkm/{sample}/.rule_completed")
      threads:
        40
      conda:
        "envs/gtdbtk.yaml"
      shell:
        """
        if [ -e {OUTDIR}/"MAGs/above_threshold_bins/{wildcards.sample}/{wildcards.sample}_bin.1.fa" ]; then
            checkm lineage_wf -t {threads} -x fa {OUTDIR}/MAGs/above_threshold_bins/{wildcards.sample} {OUTDIR}/MAGs/checkm/{wildcards.sample}
            checkm qa -t {threads} -o 2 -f {OUTDIR}/MAGs/checkm/{wildcards.sample}/{wildcards.sample}.summary {OUTDIR}/MAGs/checkm/{wildcards.sample}/lineage.ms {OUTDIR}/MAGs/checkm/{wildcards.sample}/
            coverm genome --coupled {INPUTDIR}/{wildcards.sample}_R1.fastq.gz {INPUTDIR}/{wildcards.sample}_R2.fastq.gz --genome-fasta-files {OUTDIR}/MAGs/above_threshold_bins/{wildcards.sample}/*.fa --threads {threads} >& {OUTDIR}/MAGs/checkm/{wildcards.sample}/{wildcards.sample}.abundance
        else
            touch "{OUTDIR}/MAGs/checkm/{wildcards.sample}/.rule_completed"
        fi
        """

rule MAG_checkm_paired2:
      input:
        expand(OUTDIR/ "MAGs/checkm/{sample}/.rule_completed", sample=SAMPLES)
      output:
        directory(OUTDIR/ "MAGs/checkm/checkm_summaries")
      params:
        summary=lambda wildcards, input: Path(input[0]).parent
	  shell:
        """
        cp -a {params.summary} {output}
        """
