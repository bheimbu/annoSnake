rule MAG_gtdbtk:
      input:
        OUTDIR/ "MAGs/above_threshold_bins/.rule_completed"
      output:
        touch(OUTDIR/ "MAGs/gtdbtk/.rule_completed")
      params:
        out=lambda wildcards, output: Path(output[0]).parent,
        fa=lambda wildcards, input: Path(input[0]).parent
      threads:
        40
      conda:
        "envs/gtdbtk.yaml"
      shell:
        """
        mkdir -p {OUTDIR}/MAGs/gtdbtk/genome_dir
        cp -a {params.fa}/*/*.fa {params.out}/genome_dir
        gtdbtk classify_wf --genome_dir {params.out}/genome_dir --out_dir {params.out} --cpus {threads} --skip_ani_screen --extension fa
        """