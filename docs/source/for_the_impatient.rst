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

**Install Snakemake** (note Snakemake <v8 is necessary as there are some breaking changes between Snakemake v7 and v8 that haven't been fixed yet; see this `thread <https://github.com/jdblischak/smk-simple-slurm/issues/21?notification_referrer_id=NT_kwDOAX35o7M4ODQ4OTE0MTA2OjI1MDMzMTIz>`_ for more infos about this)

.. code::

  mamba create -c conda-forge -c bioconda -n snakemake snakemake=7.32.4 #install Snakemake v7.32.4 into an environment called snakemake
  mamba activate snakemake # activate environment

Get annoSnake
^^^^^^^^^^^^^

.. code::

  git clone https://github.com/bheimbu/annoSnake.git

Run with example data, download from `Figshare <https://figshare.com/s/59c0bbaacf2f8e573bf2>`_
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. code::

  cd annoSnake/workflow
  # Step 1: unzip read folder and move figshare folder to workflow dir
  unzip 25772187.zip
  mv 25772187/figshare figshare # in params.yaml specified as inputdir 
  # Step 2: install all databases
  snakemake --profile profile/ databases/.setup_done  

  # Step 2: run the full workflow
  snakemake --profile profile/snakemake --profile profile/ -n # view the DAG of jobs first, then run...
  snakemake --profile profile/

.. important::
  For more information see :ref:`step_by_step`.

.. admonition:: You may start the workflow by using `tmux <https://github.com/tmux/tmux/wiki>`_.
  
   .. code::

    tmux new -s annosnake #starts a new tmux session with the name annosnake
    mamba activate snakemake #always activate the environment first
    snakemake --profile profile/ #starts annoSnake workflow

   You can exit the session by pressing :kbd:`Ctrl+B D`; and may close your terminal while the workflow is running.
  
   .. code::

    tmux attach -t annosnake #get back to your session

Run annoSnake locally
^^^^^^^^^^^^^^^^^^^^^
.. note::

   You may also run annoSnake locally using

   .. code::

     snakemake --cores 4 # adjust the number of cores to your PC specs
