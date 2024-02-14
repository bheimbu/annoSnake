rule MAG_microbeannotator:
      input:
          OUTDIR/ "MAGs/prokka/.rule_completed",
          db_setup="databases/microbeannotator/.setup_done"
      output:
          touch(OUTDIR/ "MAGs/microbeannotator/.rule_completed")
      params:
          db=lambda wildcards, input: Path(input["db_setup"]).parent,
          dir=lambda wildcards, output: Path(output[0]).parent,
          faa=lambda wildcards, input: Path(input[0]).parent,
      threads:
          20
      conda:
          "envs/microbeannotator.yaml"
      shell:
          """
          microbeannotator -i $(ls {params.faa}/*/*.faa) -d {params.db} -o {params.dir} -m diamond -p 2 -t {threads} --light
#          grep -E -f search_strings.txt kofam_results > *_bins.txt	#search_strings.txt [one of *_list.txt], kofam_results [use *filt or *kofam to open all result files at once]
#          awk -F'\t' '{{sub(/\.faa.*/, ".faa", $1); print $1, $3}}' *_bins.txt > *_hits.txt
          """
