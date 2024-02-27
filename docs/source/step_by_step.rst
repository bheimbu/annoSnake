.. _step_by_step:
The annoSnake workflow: step by step
====================================

.. note::
  
  For installation see :ref:`getting_started`.

.. contents:: Here, all steps of the annoSnake workflow are described in detail.
   :local:
   :backlinks: none

Input data
^^^^^^^^^^

The user may provide paired-end or interleaved sequencing data (in gzipped format) in the specified :file:`{INPUTDIR}/`. There is no need to specify :samp:`{SAMPLE}` names as annoSnake reads them autmatically from the :file:`{INPUTDIR}/`. 

.. attention::
  
  There is no need to trim or filter the reads in advance.

.. code::

  For paired-end data:
  
  {INPUTDIR}
  ├── $SAMPLE1_R1.fastq.gz
  ├── $SAMPLE1_R2.fastq.gz
  ├── $SAMPLE2_R1.fastq.gz
  ├── $SAMPLE2_R2.fastq.gz
  ├── ..._R1.fastq.gz
  └── ..._R2.fastq.gz

  For interleaved data:
  
  {INPUTDIR}
  ├── $SAMPLE1.fastq.gz
  ├── $SAMPLE2.fastq.gz
  └── ...fastq.gz

.. _params_yaml:
./profile/params.yaml file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The :file:`./profile/params.yaml` is the main configuration file sitting in the :file:`./profile/` directory. See the `Snakemake webpage <https://snakemake.readthedocs.io/en/stable/executing/cli.html#profiles>`_ for more information on the :file:`./profile/` directory.

.. code::

  # Workflow configuration

  # specify input data
  inputdir: "input_paired_end"

  # input files are 'paired-end' or 'interleaved'?
  library_type: "paired-end"

  # specify output directory
  outdir: "results_paired_end" 

  # specify minimum length of contigs to output in MEGAHIT
  min_length: 1500

  # select whether metagenome-assembled genomes (MAGs) shall be assembled or not ('True' or 'False')
  mag_assembly: False

  # if 'mag_assembly: True' specify completeness and contamination of resulting bins [community standards for medium or high-quality MAGs are defined as follows: ≥50% completeness and ≤10% contamination (Bowers et al. (2017)]
  completeness: 30
  contamination: 10

  # select databases to use ('True' or 'False')
  PFAM: False
  COG: False
  KEGG: True
  CAZYMES: False

  # specify cut-off E-values
  blastp_evalue: "1e-24"
  blastx_evalue: "1e-24"
  cog_evalue: "1e-30"
  cazy_evalue: "1e-30"
  pfam_evalue: "1e-30"

  # visualize results ('True' or 'False')
  COG_VISUALIZATION: False
  KEGG_VISUALIZATION: True

.. _config_yaml:
./profile/config.yaml file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The :file:`./profile/config.yaml` needs to be modified to accommodate the user’s specific cluster environment settings, you can change the file as you like. 

.. code::

  ### Kudos to @jdblischak! https://github.com/jdblischak/smk-simple-slurm
  
  cluster:
    mkdir -p {OUTDIR}/logs/{rule} &&
    sbatch
      --partition={resources.partition}
      --time={resources.time}
      --cpus-per-task={threads}
      --mem={resources.mem_mb}
      --job-name={rule}.{jobid}
      --output={OUTDIR}/logs/{rule}/{rule}_{wildcards}_%J.out
      --error={OUTDIR}/logs/{rule}/{rule}_{wildcards}_%J.err
  
  default-resources:
    - partition=medium #eg. 'medium' or 'fat' (if in doubt, contact your local HPC support)
    - time="1-00:00:00" # maximum runtime of jobs, here 1 day / 24h
    - mem_mb=150000 # required memory per node in MB
  
  max-jobs-per-second: 1
  max-status-checks-per-second: 10
  local-cores: 1
  latency-wait: 60
  jobs: 100
  keep-going: True
  rerun-incomplete: True
  printshellcmds: True
  scheduler: greedy
  use-conda: True
  touch: False
  reason: True
  show-failed-logs: True

Metagenome assembly
^^^^^^^^^^^^^^^^^^^

Raw reads in the :file:`{INPUTDIR}/` are assembled with `MEGAHIT v1.2.9 <https://github.com/voutcn/megahit>`_, which is optimised for metagenome assemblies. The user must specify the minimum length of contigs (default: 1500 bp) in the :ref:`params_yaml`. If you want to change how the assembly is handled by MEGAHIT, you must change either :file:`annoSnake/workflow/rules/megahit_paired_end.smk` or :file:`annoSnake/workflow/rules/megahit_interleaved.smk`.

For example, if you don't want to run MEGAHIT with ``--presets meta-sensitive``, then change...   

.. code-block:: bash
   :emphasize-removed: 1
   :emphasize-added: 2

   megahit -1 {INPUTDIR}/{wildcards.sample}_R1.fastq.gz -2 {INPUTDIR}/{wildcards.sample}_R2.fastq.gz --out-prefix {wildcards.sample} --presets meta-sensitive --min-contig-len {params.min_length} -o {OUTDIR}/assemblies/megahit/{wildcards.sample} -t {threads}
   megahit -1 {INPUTDIR}/{wildcards.sample}_R1.fastq.gz -2 {INPUTDIR}/{wildcards.sample}_R2.fastq.gz --out-prefix {wildcards.sample} --min-contig-len {params.min_length} -o {OUTDIR}/assemblies/megahit/{wildcards.sample} -t {threads}

Under :file:`{OUTDIR}/assemblies/` (:samp:`{OUTDIR}` as specified in :ref:`params_yaml`), you can find the output of MEGAHIT, `metaQuast <https://quast.sourceforge.net/metaquast>`_ as well as the preprocessed contigs (with modified Fasta headers to include the sample name). 

.. code::

  {OUTDIR}/assemblies/
  ├── megahit/
  │       ├── $SAMPLE1/
  │       ├── $SAMPLE2/
  │       └── ...
  ├── metaquast/
  └── preprocessed_contigs/
          ├── $SAMPLE1/
          ├── $SAMPLE2/
          └── ...

.. _taxonomic_annotation:
Taxonomic annotation
^^^^^^^^^^^^^^^^^^^^

`Prokka 1.14.6 <https://github.com/tseemann/prokka>`_ (in ``--metagenome`` mode) is used to identify protein-coding sequences (CDS), rRNAs, and tRNAs. From the CDS, `fetchMG v.1.2 <https://github.com/motu-tool/fetchMGs>`_ extracts 40 single copy marker genes (called COGs; in protein format), which are taxonomically assigned with `DIAMOND <https://github.com/bbuchfink/diamond>`_ in ``blastp`` mode. Other CDS (in nucleotide format) are taxonomically assigned with `DIAMOND <https://github.com/bbuchfink/diamond>`_ but in ``blastx`` mode. Both annotations use `GTDB database ver 202 <https://gtdb.ecogenomic.org/>`_ as the default reference.

.. code::

  {OUTDIR}/taxonomy/
  ├── prokka/
  |       ├── $SAMPLE1/
  |       |  ├── $SAMPLE1.faa
  |       |  ├── $SAMPLE1.fna
  |       |  └── ...
  │       ├── $SAMPLE2/
  |       |  └── ...
  │       └── ...
  ├── blastx/
  |       ├── $SAMPLE1/
  │       ├── $SAMPLE2/
  │       └── ...
  └── blastp/
          ├── $SAMPLE1/
          ├── $SAMPLE2/
          └── ...

Functional annotation
^^^^^^^^^^^^^^^^^^^^^

The user can choose between different databases for functional annotation of metagenomic contigs (note, only metagenomic contigs assigned either as bacteria or archaea in the previous ``blastx`` search are annotated):

1. For identifying CDS with carbohydrate metabolising properties, Hidden Markov models (HMM) of CAZy domains deposited in the `dbCAN database release 11 <https://bcb.unl.edu/dbCAN2/download/>`_ are used as default.
2. To search for hydrogenases, HMM searches against the `Pfam database version 35 <https://www.ebi.ac.uk/interpro/download/Pfam/>`_ are performed. 
3. `KofamScan v1.3.0 <https://github.com/takaram/kofam_scan>`_ is used to reconstruct prokaryotic metabolic pathways against the `KEGG database <https://www.genome.jp/kegg/pathway.html>`_.

.. attention::

  Results are filtered by cut-off E-values (minimum significant hit) that must be specified by the user (see :ref:`params_yaml`). 

  .. code::

    # specify cut-off E-values
    blastp_evalue: "1e-24"
    blastx_evalue: "1e-24"
    cog_evalue: "1e-30"
    cazy_evalue: "1e-30"
    pfam_evalue: "1e-30"

.. code::

  {OUTDIR}/annotation/
  ├── kegg/
  |       ├── $SAMPLE1/
  │       ├── $SAMPLE2/
  │       └── ...
  ├── cazy/
  |       ├── $SAMPLE1/
  │       ├── $SAMPLE2/
  │       └── ...
  └── pfam/
          ├── $SAMPLE1/
          ├── $SAMPLE2/
          └── ...

.. attention::

  For prokaryotic metabolic pathways (ie., KEGG), KO profile thresholds and an E-value ≤1e-30 are used, if KEGG entries of interest (eg. *K12212*) are present. Otherwise, KEGG entries with the lowest E-value are taken.

.. hint::
  
  Databases are downloaded automatically. However, the user can choose to use their own protein databases, which must be saved in the correct format (see :ref:`databases`).

.. _abundance:
Abundance calculation of gene families
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Abundance is quantified with `Salmon v1.10.2 <https://salmon.readthedocs.io/en/latest/>`_, which aligns raw sequencing reads to the bacterial and archaeal contigs and to the COGs (see :ref:`taxonomic_annotation`). `Salmon <https://salmon.readthedocs.io/en/latest/>`_ adjusts for biases such as GC-content and differences in gene length, producing Transcripts per Million (TPM) values to represent CDS abundance. For visualisation purposes, TPM values >1 are kept and subsequently log-transformed. Normalisation of TPM counts is performed via centered log-ratio (clr) transformation. The transformation is executed in the R package `propr <https://github.com/tpq/propr>`_ with a pseudo count of 0.65 to handle zero values appropriately.

.. code::

  {OUTDIR}/quantification/
  ├── cogs/
  │       ├── cogs.index
  │       └── cogs.quant
  └── contigs/
          ├── $SAMPLE1/
          ├── $SAMPLE2/
          └── ...

Metagenome-assembled genomes (MAGs)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Metagenome contigs are binned into MAGs with three different binning algorithms (in default mode):

1. `MetaBAT version 2.10.2 <https://bitbucket.org/berkeleylab/metabat/src/master/>`_
2. `MetaCoAG v1.1.1 <https://github.com/metagentools/MetaCoAG>`_
3. `MaxBin 2.2.7 <https://sourceforge.net/projects/maxbin/files/>`_

To increase contiguity and completeness of the resulting bins, we implemented `metaWRAP‘s bin_refinement <https://github.com/bxlab/metaWRAP/blob/master/Module_descriptions.md>`_ module, which combines the obtained bins from the three different binning algorithms to produce a consolidated, improved bin set. 

.. note::

  Here, the user needs to specify the **minimum completeness** and **maximum contamination** of retained MAGs used for downstream analyses in the :ref:`params_yaml`.

  .. code::

       # if 'mag_assembly: True' specify completeness and contamination of resulting bins
      completeness: 30
      contamination: 10

Quality control of MAGs is performed by `CheckM 1.2.2 <https://github.com/Ecogenomics/CheckM>`_. They are taxonomically classified with `GTDB-Tk v2.3.2 <https://github.com/Ecogenomics/GTDBTk>`_  using the `GTDB database ver 202 <https://gtdb.ecogenomic.org/>`_ as a reference.

|

Gene prediction of MAGs is performed by `Prokka 1.14.6 <https://github.com/tseemann/prokka>`_, using the ``--metagenome`` option.

|

Predicted protein sequences are annotated with `MicrobeAnnotator <https://github.com/cruizperez/MicrobeAnnotator>`_ with ``-diamond`` search against the `KEGG database <https://www.genome.jp/kegg/pathway.html>`_.

.. note::

  For MAGs, pathway completeness is assessed based on presence/absence not on TPM values (see :ref:`abundance`).

.. code::

  {OUTDIR}/MAGs/
  ├── above_threshold_bins/ # bins with minimum completeness and maximum contamination as specified (see above)
  |       ├── $SAMPLE1/
  │       ├── $SAMPLE2/
  │       └── ...
  ├── bin_refinement/
  |       ├── $SAMPLE1/
  │       ├── $SAMPLE2/
  │       └── ...
  ├── checkm/
  |       ├── $SAMPLE1/
  |       ├── $SAMPLE2/
  |       └── ...
  ├── gtdbtk/
  |       ├── $SAMPLE1/
  │       ├── $SAMPLE2/
  │       └── ...
  ├── maxbin2/
  |       ├── $SAMPLE1/
  |       ├── $SAMPLE2/
  |       └── ...
  ├── metabat2/
  │       ├── $SAMPLE1/
  │       ├── $SAMPLE2/
  │       └── ...
  ├── metacoag/
  |       ├── $SAMPLE1/
  |       ├── $SAMPLE2/
  |       └── ...
  └── prokka/
          ├── $SAMPLE1/
          ├── $SAMPLE2/
          └── ...

Fresh Install
^^^^^^^^^^^^^

.. admonition:: A fresh install should look like this:

  .. code::

    annoSnake
    ├── docs/
    ├── workflow/
    │       ├── input_paired_end # includes example data
    │       ├── profile
    |       |     ├── config.yaml 
    |       |     └── params.yaml 
    │       ├── rules
    |       |     ├── envs/ # conda environment files
    |       |     ├── scripts/ # Rscripts etc. 
    |       |     ├── blastx.smk
    |       |     ├── cazy.smk
    |       |     └── ...
    |       └── Snakefile 
    ├── .git/
    ├── LICENSE
    ├── README.md
    └── .readthedocs.yaml
