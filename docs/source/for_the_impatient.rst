.. _getting_started:
Getting started
=================

.. contents::
   :local:
   :backlinks: none

Install Mamba
^^^^^^^^^^^^
Install `Mamba <https://mamba.readthedocs.io/en/latest/user_guide/mamba.html>`_ using `miniforge <https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html>`_.

.. admonition:: For Unix-like platforms (Mac OS & Linux)
  
  .. code::
    
    curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
    bash Miniforge3-$(uname)-$(uname -m).sh

Install `Snakemake <https://snakemake.github.io/>`_ and `snakemake-executor-plugin-slurm <https://snakemake.github.io/snakemake-plugin-catalog/plugins/executor/slurm.html>`_

.. code::

  mamba create -c conda-forge -c bioconda -n snakemake snakemake
  mamba activate snakemake # activate environment
  pip install snakemake-executor-plugin-slurm # To run annoSnake on HPC environments using the SLURM scheduler

Get annoSnake
^^^^^^^^^^^^^

.. code::

  git clone https://github.com/bheimbu/annoSnake.git

Running with example data, download from `Figshare <https://figshare.com/s/59c0bbaacf2f8e573bf2>`_
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. code::

  cd annoSnake/workflow
  # Step 1: unzip read folder and move figshare folder to workflow dir
  unzip 25772187.zip
  mv 25772187/figshare figshare # in params.yaml specified as inputdir 
  # Step 2: install all environments and databases
  snakemake --use-conda --conda-frontend conda --conda-create-envs-only
  snakemake --profile profile/ databases/.setup_done  

  # Step 2: run the full workflow
  snakemake --profile profile/ -n # view the DAG of jobs first, then run...
  snakemake --profile profile/

.. important::
  For more information see :ref:`step_by_step`.

.. admonition:: You may start the workflow by using `tmux <https://github.com/tmux/tmux/wiki>`_.
  
   .. code::

    tmux new -s annosnake #starts a new tmux session with the name annosnake
    mamba activate snakemake #always activate the environment first
    snakemake --profile profile/ #starts annoSnake workflow

   You can exit the session by pressing :kbd:`Ctrl+B` followed by :kbd:`D`; and may close your terminal while the workflow is running.
  
   .. code::

    tmux attach -t annosnake #get back to your session

Running annoSnake locally
^^^^^^^^^^^^^^^^^^^^^^^^
.. note::

   You may also run annoSnake locally using

   .. code::

     snakemake --use-conda --conda-frontend conda --cores 4 # adjust the number of cores to your PC specs

Running annoSnake with other scheduling systems
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
You may have no access to SLURM, but that's no problem at all. There are Snakemake profiles for different scheduling systems, including LSF, HTCondor, etc. Check out `here <https://github.com/Snakemake-Profiles>`_. Additionally, there are plugins, which help Snakemake workflows function better in, for example, HTCondor environments (see `here <https://snakemake.github.io/snakemake-plugin-catalog/plugins/executor/htcondor.html>`_ for more details).
