rule MAG_annotree:
      input:
          OUTDIR/ "MAGs/prokka/.rule_completed"
      output:
          directory(OUTDIR/ "MAGs/annotree/"),
          touch(OUTDIR/ "MAGs/annotree/.rule_completed")
      threads:
          20
      params:
          annotree="../../../databases/annotree/annotree.dmnd"		   
      conda:
          "envs/environment.yaml"
      shell:
          """
          mkdir -p {OUTDIR}/MAGs/annotree
          cd {OUTDIR}/MAGs/annotree
          for filename in ../prokka/*/*.faa; do
             base_name=$(basename "$filename" .faa)
             diamond blastp --db {params.annotree} --query ../prokka/"$base_name"/"$base_name".faa --outfmt 6 --out "$base_name".anno --threads {threads}
          done 			   
          """