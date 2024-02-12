rule metaquast:
    input:
        contigs=expand(OUTDIR/ "assemblies/preprocessed_contigs/{sample}/.rule_completed", sample=SAMPLES),
        downloaded="databases/.quast_downloaded"    		
    output:
        OUTDIR/ "assemblies/metaquast/report.html"
    params:
        contigs=OUTDIR/ "assemblies/preprocessed_contigs/*/*.fna",
        outdir=OUTDIR/ "assemblies/metaquast",
        metaquast=lambda wildcards, input: Path(input["downloaded"]).parent
    threads:
        20
    conda:
        "envs/MAGs.yaml"
    shell:
        """
        {params.metaquast}/quast/metaquast.py --threads {threads} -o {params.outdir} {params.contigs} --no-krona
		"""