rule MAG_gtdbtk:
      input:
        OUTDIR / "MAGs/checkm2/summaries",
        "databases/gtdb_tk/.setup_done"
      output:
        touch(OUTDIR/ "MAGs/gtdbtk/.rule_completed")
      params:
        out=lambda wildcards, output: Path(output[0]).parent
      threads:
        40
      conda:
        "envs/gtdbtk.yaml"
      benchmark:
        OUTDIR/ "benchmarks/MAG_gtdbtk.txt"
      shell:
        """
        mkdir -p {OUTDIR}/MAGs/gtdbtk/genome_dir
        cp -a {OUTDIR}/MAGs/above_threshold_bins/*/*.fa {params.out}/genome_dir
        gtdbtk classify_wf --genome_dir {params.out}/genome_dir --out_dir {params.out} --cpus {threads} --skip_ani_screen --extension fa
		cp -a {OUTDIR}/MAGs/gtdbtk/*summary.tsv {OUTDIR}/tables/
        """
