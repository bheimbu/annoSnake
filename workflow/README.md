To run annoSnake with the worked example data, use following commands. But first, download the raw paired-end sequencing reads used in the workflow demonstration. Go to https://figshare.com/s/59c0bbaacf2f8e573bf2 (or checkout the manuscript to find the figshare link) and download the whole dataset. Unzip the dataset and move the reads to a directory called **annoSnake/workflow/figshare**.

**See the *./profile/config.yaml* file to change any parameters related to Slurm job submission.**

**Additionally, you can enter your email address to be notified of any errors, etc. using the *./profile/params.yaml* file.**


    $ cd annoSnake/workflow 
    $ mamba activate snakemake         #make sure you have installed snakemake v7.32.4
    $ snakemake --profile profile -n   #check the DAG of jobs
    $ snakemake --profile profile      #run the worked example workflow
