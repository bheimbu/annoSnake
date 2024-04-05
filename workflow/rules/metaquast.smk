rule metaquast:
    input:
        contigs=expand(OUTDIR/ "assemblies/preprocessed_contigs/{sample}/.rule_completed", sample=SAMPLES),
        done="databases/quast/.setup_done"   		
    output:
        OUTDIR/ "assemblies/metaquast/report.html"
    params:
        contigs=OUTDIR/ "assemblies/preprocessed_contigs/*/*.fna",
        outdir=OUTDIR/ "assemblies/metaquast",
        metaquast=lambda wildcards, input: Path(input["done"]).parent
    threads:
        20
    conda:
        "envs/mags.yaml"
    shell:
        """
        {params.metaquast}/metaquast.py --threads {threads} -o {params.outdir} {params.contigs} --no-krona
	"""
