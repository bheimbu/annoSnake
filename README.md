```

  █████╗  ███╗   ██╗ ███╗   ██╗  ██████╗  ███████╗ ███╗   ██╗  █████╗  ██╗  ██╗ ███████╗
 ██╔══██╗ ████╗  ██║ ████╗  ██║ ██╔═══██╗ ██╔════╝ ████╗  ██║ ██╔══██╗ ██║ ██╔╝ ██╔════╝
 ███████║ ██╔██╗ ██║ ██╔██╗ ██║ ██║   ██║ ███████╗ ██╔██╗ ██║ ███████║ █████╔╝  █████╗  
 ██╔══██║ ██║╚██╗██║ ██║╚██╗██║ ██║   ██║ ╚════██║ ██║╚██╗██║ ██╔══██║ ██╔═██╗  ██╔══╝  
 ██║  ██║ ██║ ╚████║ ██║ ╚████║ ╚██████╔╝ ███████║ ██║ ╚████║ ██║  ██║ ██║  ██╗ ███████╗
 ╚═╝  ╚═╝ ╚═╝  ╚═══╝ ╚═╝  ╚═══╝  ╚═════╝  ╚══════╝ ╚═╝  ╚═══╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚══════╝
```


annoSnake is a Snakemake workflow that streamlines taxonomic and functional annotation of metagenomes and metagenome-assembled genomes (MAGs). See the documentation under https://annosnake.readthedocs.io/en/latest/ for more details.

annoSnake has been published in **Computational and Structural Biotechnology Reports**  under https://doi.org/10.34133/csbr.0002.

## Known limitation: Snakedeploy / module deployment

annoSnake's rule files share several global variables (`OUTDIR`, `SAMPLES`,
`INPUTDIR`) that are defined once in `workflow/rules/workflow.smk` and
referenced across the other rule files. This works correctly when the
workflow is run directly from a clone of this repository, or via
`.test/` (see `.test/README.md`), since Snakemake's `include:` mechanism
shares a single global namespace across all included files in that
context.

**This pattern is currently incompatible with Snakemake's module
deployment mechanism** (`snakedeploy deploy-workflow` /
`module ... use rule * from annoSnake`). When deployed this way, rules
defined in files other than the one that sets these global variables
raise `NameError` (e.g. `OUTDIR` is unknown in this context), because
the module system does not guarantee the same shared-namespace behaviour
across a source repository's included files.

**Recommended usage for now:** clone this repository directly and run
the workflow from the repository root (or from `.test/` for a quick
smoke test), rather than deploying it as a Snakemake module:

```bash
git clone https://github.com/bheimbu/annoSnake.git
cd annoSnake
snakemake --profile config/
```

Fixing this properly would require refactoring every rule to access
`config["outdir"]`, `config["inputdir"]`, and the sample list via each
rule's own `params:`/`input:`/`output:` blocks rather than through
shared global variables -- tracked as a future improvement.
