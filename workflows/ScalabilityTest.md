# Scalability test

> wfmash - fedf0a0d69ec8cd8511fc22dda6598630d23437c
> 
> seqwish - beb7a3805c5af599b8425db94b9524eecbfc73e0

Create the main folder:

```
mkdir -p /lizardfs/guarracino/HPRC/
```

## Alignment

Generate all-vs-all mapping by using the whole HPRC year 1 dataset:

```
sbatch -p lowmem -c 48 --wrap 'cd /scratch && wfmash -X -s 100k -l 300k -p 98 -n 90 -k 16 -t 48 /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz -m > HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.approx.paf && mv HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.approx.paf /lizardfs/guarracino/HPRC/'
```

Split the mappings in chunks:

```
python3 /home/guarracino/wfmash/scripts/split_approx_mappings_in_chunks.py /lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.approx.paf 5
```

Run the alignments on multiple nodes:

```
seq 0 4 | while read i; do sbatch -p lowmem -c 48 --wrap 'cd /scratch && /home/guarracino/wfmash/build/bin/wfmash -X -s 100k -l 300k -p 98 -n 90 -k 16 -t 48 /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz -i /lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.approx.paf.chunk_'$i'.paf | pigz -c > HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_'$i'.paf.gz && mv HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_'$i'.paf.gz /lizardfs/guarracino/HPRC/' ; done >>wfmash.alignment.jobids
```

## Graph induction

Create the folder for the graphs:

```
mkdir -p /lizardfs/guarracino/HPRC/graphs
```

Run `seqwish` on the same nodes to compare the different runs:

```
sbatch -p lowmem -c 48 --wrap '(echo 311; echo 229; echo 179; echo 127; echo 79; echo 29; echo 11) | while read k; do cd /scratch && \time -v seqwish -t 48 -s /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz -p /lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_0.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_1.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_2.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_3.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_4.paf.gz -k $k -g HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.seqwish.k$k.B50M.gfa -B 50M -P && mv HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.seqwish.k$k.B50M.gfa /lizardfs/guarracino/HPRC/graphs/ ; done'
```