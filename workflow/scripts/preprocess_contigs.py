#!/usr/bin/env python
import sys
from Bio import SeqIO

output_file = sys.argv[1]
min_length = int(sys.argv[2])

with open(output_file, "w") as out_f:
    for record in SeqIO.parse(sys.stdin, "fasta"):
        header_parts = record.description.split()  # Split header by whitespace
        input_filename = header_parts[0][1:]  # Extract filename without '>' character
        if len(record.seq) >= min_length:
            SeqIO.write(record, out_f, "fasta")

