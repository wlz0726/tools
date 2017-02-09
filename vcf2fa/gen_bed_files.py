#!/usr/bin/env python
import sys
import re
from os import path
from Bio import SeqIO

ref_fn = sys.argv[1]
ref = SeqIO.index(ref_fn, "fasta")
sbed_fn = re.sub('\.fa$|\.fasta$', '_single_base.bed', path.basename(ref_fn))
genome_fn = re.sub('\.fa$|\.fasta$', '.genome', path.basename(ref_fn))
bed_fn = re.sub('\.fa$|\.fasta$', '.bed', path.basename(ref_fn))

with open(sbed_fn, 'w') as sbed_fh:
    with open(genome_fn, 'w') as genome_fh:
        with open(bed_fn, 'w') as bed_fh:
            for rec in SeqIO.parse(open(ref_fn), "fasta"):
                length = len(rec)
                genome_fh.write('{}\t{}\n'.format(rec.id, length))
                bed_fh.write('{}\t0\t{}\n'.format(rec.id, length))
                for pos in range(length):
                    sbed_fh.write('{}\t{}\t{}\t{}\n'.format(
                                  rec.id, pos, pos+1, rec[pos]))
