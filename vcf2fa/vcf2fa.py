#!/usr/bin/env python
from os import path
from os import makedirs
from collections import defaultdict as dd
import re
import argparse


ambi = {'AC':'M', 'AG':'R', 'AT':'W', 'CG':'S', 'CT':'Y', 'GT':'K',
        'CA':'M', 'GA':'R', 'TA':'W', 'GC':'S', 'TC':'Y', 'TG':'K',
        'AA':'A', 'CC':'C', 'GG':'G', 'TT':'T'}

def m_dir(d):
    try:
        makedirs(d)
    except OSError:
        pass
def try_int(c):
    try:
        return int(c)
    except ValueError:
        return c

class rec(object):
    def __init__ (self):
        '''
        container for previous, current, next objects
        '''
        self.up=0
        self.curr=0
        self.down=0

class Vcf(object):
    '''
    fVcf: POSITION SORTED vcf file name
    vcf: a generator that walks over a vcf file

    sample VCF line:
    CHROM  POS  ID  REF  ALT  QUAL  FILTER  INFO  FORMAT sam1...samn
    '''
    def __init__(self, vcf_fh):
        self.header_lines=[]
        self.vcf_handle=vcf_fh
        self.rec = rec()

        l=''
        #initialize samples, strip off vcf header
        #stop at first line with real data
        while True:
            l = self.vcf_handle.readline()

            if l.startswith("#CHROM"):
                a=l.lstrip('#').rstrip().split('\t')
                self.cols = a[:9]
                self.samples = []
                for sam in a[9:]:
                    sam_name = re.sub('\.bam$|\.sorted\.bam$', '', path.basename(sam))
                    self.samples.append(sam_name)

            elif l.startswith("##"):
                self.header_lines.append(l.rstrip())

            else:
                self.rec.up = 0
                self.rec.curr = 0
                self.rec.down = self.parse_vcf_line(l)
                self.format = self.rec.down['FORMAT'].split(':')
                break
    
    def __iter__(self):
        return self

    def next(self):
        '''
        '''
        if self.rec.curr != None:
            self.rec.up = self.rec.curr
            self.rec.curr = self.rec.down
            self.rec.down = self.parse_vcf_line(self.vcf_handle.readline())
            return self.rec.curr
        else:
            raise StopIteration()

    def parse_vcf_line(self, line):
        tmp = {}
        vals = line.split()
        while len(vals) == len(self.cols)+len(self.samples) and vals[7].startswith('INDEL'):
            vals = self.vcf_handle.readline().split()
        if len(vals) != len(self.cols)+len(self.samples):
            return None
        for i,v in zip(self.cols,vals[:9]):
            tmp[i]=try_int(v)
        for i,v in zip(self.samples, vals[9:]):
            try:
                tmp[i] = dict(zip(self.format, [try_int(x) for x in v.split(':')]))
            except AttributeError:
                tmp[i] = dict(zip(tmp['FORMAT'].split(':'), [try_int(x) for x in v.split(':')]))
        return tmp

def vcf_gt_to_dna(snp, ind):
    ref = snp['REF']
    alt = snp['ALT']
    gt = snp[ind]['GT']
    poss_gts = [ref.upper()]+[x.upper() for x in alt.split(',')] 
    trans = dict(zip([str(x) for x in range(len(poss_gts))], poss_gts))
    sam_dna = ambi[''.join([trans[x] for x in gt.split('/')])]
    return sam_dna

def fill_ref(samples, mincov, cov, seqs, ref_bp):
    for s,c in zip(samples,cov):
        if c >= mincov:
            seqs[s].append(ref_bp)
        else:
            seqs[s].append('N')

def fill_snp(samples, mincov, cov, seqs, snp):
    for s,c in zip(samples,cov):
        if c >= mincov:
            seqs[s].append(vcf_gt_to_dna(snp, s))
        else:
            seqs[s].append('N')

def get_snp(vcf):
    try:
        snp = vcf.next()
    except StopIteration:
        snp = None
    return snp

def make_fasta(mincov, mcb, vcf_fh):
    vcf = Vcf(vcf_fh)
    m_dir('consensus')
    seqs = dd(lambda: [])

    curr_chrom = ''
    #get a snp
    snp = get_snp(vcf)

    for l in mcb:
        #get info about current position
        tmp = l.split()
        if tmp[0] != curr_chrom:
            if len(seqs) != 0:
                out = open(path.join('consensus', '{}_consensus.fa'.format(curr_chrom)), 'w')
                for s in seqs.keys():
                    #write multi fasta
                    out.write('>{}\n{}\n'.format(s, ''.join(seqs[s])))
                out.close()
            seqs = dd(lambda: [])
            curr_chrom = tmp[0]
            snp = get_snp(vcf)

        #one and zero-based positions, vcf is 1-indexed
        (pos0, pos1) = [int(x) for x in tmp[1:3]]
        ref_bp = tmp[3]
        cov = [int(x) for x in tmp[4:]]

        #no more snps in vcf file!
        if snp == None:
            fill_ref(vcf.samples, mincov, cov, seqs, ref_bp)
        
        #need to catch up to current SNP
        elif pos1 < snp['POS'] and curr_chrom == snp['CHROM']:
            fill_ref(vcf.samples, mincov, cov, seqs, ref_bp)
        #caught up, add SNP, get the next one
        elif pos1 == snp['POS'] and curr_chrom == snp['CHROM']:
            fill_snp(vcf.samples, mincov, cov, seqs, snp)
            snp = get_snp(vcf)
        #shouldn't happen
        elif pos1 > snp['POS'] and curr_chrom == snp['CHROM']:
            print("this shouldn't happen!")
        #bed file needs to catch up to snp
        elif curr_chrom != snp['CHROM']:
            fill_ref(vcf.samples, mincov, cov, seqs, ref_bp)
        else:
            print("wasn't expecting this!")
            

    #write last curr_chrom's worth of data
    out = open(path.join('consensus', '{}_consensus.fa'.format(curr_chrom)), 'w')
    for s in seqs.keys():
        #write multi fasta
        out.write('>{}\n{}\n'.format(s, ''.join(seqs[s])))
    out.close()
    

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="generate a subfolder in the current directory of fasta files, each one a locus/chromosome, containing one sequence for each individual found in the vcf/bed files specified")
    parser.add_argument("-m","--multicov_file", help="Your multicov file. Must be based off the ref_single_base.bed created by gen_bed_files.py and running bedtools. See readme for suggested bedtools command", type=argparse.FileType('r'), required=True)
    parser.add_argument("-v","--vcf_file", help="The vcf file generated using the same bam files used to generate the multicov bed file", type=argparse.FileType('r'), required=True)
    parser.add_argument("-c","--min_cov", help="The minimum required coverage for a base to not be masked in a sample's consensus with an 'N' ", type=int, default=7)
    args = parser.parse_args()

    make_fasta(args.min_cov, args.multicov_file, args.vcf_file)
