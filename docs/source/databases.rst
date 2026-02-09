.. _databases::
Databases
=========

.. contents::
   :local:
   :backlinks: none

Install Databases 
^^^^^^^^^^^^^^^^^
.. attention::
  Before executing the full workflow, install all required databases by running

  .. code::

    snakemake --profile profile/ databases/.setup_done

In general
^^^^^^^^^^

Databases are downloaded automatically. However, you can use your own protein databases, which must be saved in the correct format (see below). The file :file:`.setup_done` in each database subdirectory is necessary to run the workflow correctly. So if you want to use your own databases, make sure that there is one in the respective subdirectories (``touch .setup_done``) 

.. code::

  workflow/databases/
  ├── cazymes/
  |       ├── dbCAN-fam-HMMs.txt.v11
  │       ├── dbCAN-fam-HMMs.txt.v11.h3f
  │       ├── dbCAN-fam-HMMs.txt.v11.h3i
  │       ├── dbCAN-fam-HMMs.txt.v11.h3m
  │       ├── dbCAN-fam-HMMs.txt.v11.h3p
  │       └── .setup_done
  ├── checkm/
  |       ├── distributions/
  │       ├── ...
  │       └── .setup_done
  ├── fetchMGs/
  |       ├── bin/
  |       ├── ...
  |       └── .setup_done
  ├── gtdb/
  |       ├── gtdb_vers202_metadata.csv
  │       ├── gtdb_vers202/
  |       ├── ...
  │       └── .setup_done
  ├── gtdb_tk/
  |       └── .setup_done
  ├── kegg/
  │       ├── ko_list
  │       ├── profiles/
  │       └── .setup_done
  ├── microbeannotator/
  |       ├── conversion.db
  |       ├── ...
  |       └── .setup_done
  ├── pfam/
  |       ├── Pfam-A.hmm
  |       ├── ...
  |       └── .setup_done
  └── quast/
        ├── metaquast.py
        ├── ...
        └── .setup_done

MicrobeAnnotator
^^^^^^^^^^^^^^^^

An HTTP error can occur during MicrobeAnnotator setup. This is because the URL used to download the InterPro tables is incorrect.

1. Run ``snakemake --profile profile/`` first to create the *microbeannotator* conda environment, then stop the workflow with :kbd:`Ctrl+D`.

2. Then execute following command to change the URL.

.. code::

  cd annoSnake/workflow
  find . -type f -name "conversion_database_creator.py" -exec sed -i 's|ftp://ftp.ebi.ac.uk|https://ftp.ebi.ac.uk|g' {} +



  
