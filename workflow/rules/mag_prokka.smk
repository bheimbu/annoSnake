rule MAG_prokka:
    input:
       OUTDIR / "MAGs/checkm2/summaries"
    output:
       touch(OUTDIR/ "MAGs/prokka/.rule_completed")
    threads:
       20
    conda:
       "envs/prokka.yaml"
    benchmark:
       OUTDIR/ "benchmarks/MAG_prokka.txt"
    shell:
       """
       mkdir -p {OUTDIR}/MAGs/prokka
       cd {OUTDIR}/MAGs/prokka
       ln -sf ../above_threshold_bins/*/*fa .
       for filename in ./*.fa; do
          base_name=$(basename "$filename" .fa)
          prokka --force --cpus {threads} --metagenome --prefix "$base_name" --outdir "$base_name" "$base_name".fa
       done
       rm -rf *fa
       """
