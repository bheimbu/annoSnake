Getting started
=================
|
**Install Mamba**

Install `Mamba <https://mamba.readthedocs.io/en/latest/user_guide/mamba.html>`_ using miniforge as suggested `here <https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html>`_.

.. note::
  **Unix-like platforms (Mac OS & Linux)**
  
  .. code::
    
    curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
    bash Miniforge3-$(uname)-$(uname -m).sh
|

**Install Snakemake**


.. code::

  mamba install snakemake

|
**Get annoSnake**


.. code::

  git clone https://github.com/bheimbu/annoSnake.git

|
**Run with example data**

.. code::

  cd annoSnake/workflow
  snakemake --profile profile/ -n # view the DAG of jobs first, then run...
  snakemake --profile profile/

|

.. tip::
  You may start the workflow by using `tmux <https://github.com/tmux/tmux/wiki>`-

  .. code::
  
    tmux new -t annosnake #starts a new tmux session with the name annoSnake
    snakemake --profile profile/ #starts annoSnake workflow

  You can exit the session by pressing Ctrl + b d; and may close your terminal while the workflow is running

  .. code ::

    tmux attach -s annosnake #to get back to your session

