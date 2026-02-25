import csv
import re                      # <-- ADD
from collections import OrderedDict
from pathlib import Path

def norm_acc(acc: str) -> str: # <-- ADD
    acc = acc.strip()
    acc = re.sub(r"^(RS_|GB_)", "", acc)
    acc = acc.replace("GCA_", "GCA").replace("GCF_", "GCF")
    return acc

bac_tsv = snakemake.input["bac"]
ar_tsv  = snakemake.input["ar"]

out_names = Path(snakemake.output["names"])
out_nodes = Path(snakemake.output["nodes"])
out_genome = Path(snakemake.output["genome_taxid"])
outdir = out_names.parent
outdir.mkdir(parents=True, exist_ok=True)

RANK_PREFIX = OrderedDict([
    ("d__", "superkingdom"),
    ("p__", "phylum"),
    ("c__", "class"),
    ("o__", "order"),
    ("f__", "family"),
    ("g__", "genus"),
    ("s__", "species"),
])

def parse_lineage(tax_str):
    parts = [p.strip() for p in tax_str.split(";") if p.strip()]
    out = []
    for p in parts:
        for pref, rnk in RANK_PREFIX.items():
            if p.startswith(pref):
                out.append((p, rnk))
                break
    return out

def read_meta(path):
    with open(path) as f:
        r = csv.DictReader(f, delimiter="\t")
        for row in r:
            acc = row["accession"].strip()
            tax = row["gtdb_taxonomy"].strip()
            if acc and tax:
                yield norm_acc(acc), tax

taxa2id = {"root": 1}
id2taxa = {1: "root"}
parent = {1: 1}
rank = {1: "no rank"}
next_id = 2

genome2taxid = {}

for acc, tax in list(read_meta(bac_tsv)) + list(read_meta(ar_tsv)):
    lineage = parse_lineage(tax)
    if not lineage:
        continue
    prev = 1
    for name, rnk in lineage:
        if name not in taxa2id:
            taxa2id[name] = next_id
            id2taxa[next_id] = name
            parent[next_id] = prev
            rank[next_id] = rnk
            next_id += 1
        prev = taxa2id[name]
    genome2taxid[norm_acc(acc)] = prev

with open(out_names, "w") as out:
    for tid in sorted(id2taxa):
        out.write(f"{tid}\t|\t{id2taxa[tid]}\t|\t\t|\tscientific name\t|\n")

with open(out_nodes, "w") as out:
    for tid in sorted(id2taxa):
        out.write(f"{tid}\t|\t{parent[tid]}\t|\t{rank[tid]}\t|\n")

with open(out_genome, "w") as out:
    out.write("accession\ttaxid\n")
    for acc, tid in genome2taxid.items():
        out.write(f"{acc}\t{tid}\n")
