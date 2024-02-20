.. _step_by_step:
The annoSnake workflow: step by step
====================================

For the installation see :ref:`for_the_impatient`. Here, all steps of the annoSnake workflow are described in detail.

.. _params_yaml:
The ./profile/params.yaml file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ./profile/params.yaml is the main configuration file.

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
The ./profile/config.yaml file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ./profile/config.yaml needs to be modified to accommodate the user’s specific cluster environment settings, you can change the file as you like.

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
    - mem_mb=150000 # required memory per node, here in MB
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


