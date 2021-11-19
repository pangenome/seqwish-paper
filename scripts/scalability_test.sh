# All-vs-all using the whole HPRC year 1 dataset...

# ...from scratch
sbatch -p lowmem -c 48 --wrap 'cd /scratch && /home/guarracino/wfmash/build/bin/wfmash -X -s 100000 -l 300000 -p 98 -n 90 -k 16 -t 48 /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz | pigz -c > HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.gz && mv HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.gz /lizardfs/guarracino/HPRC/'

# ...from input approximate mappings
sbatch -p lowmem -c 48 --wrap 'cd /scratch && /home/guarracino/wfmash/build/bin/wfmash -X -s 100000 -l 300000 -p 98 -n 90 -k 16 -t 48 /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz -i /lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.approx.paf | pigz -c > HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.gz && mv HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.gz /lizardfs/guarracino/HPRC/'

# ...from input approximate mappings in chunks
python3 /home/guarracino/wfmash/scripts/split_approx_mappings_in_chunks.py /lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.approx.paf 5
seq 0 4 | while read i; do sbatch -p lowmem -c 48 --wrap 'cd /scratch && /home/guarracino/wfmash/build/bin/wfmash -X -s 100000 -l 300000 -p 98 -n 90 -k 16 -t 48 /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz -i /lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.approx.paf.chunk_'$i'.paf | pigz -c > HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_'$i'.paf.gz && mv HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_'$i'.paf.gz /lizardfs/guarracino/HPRC/' >> alignment_chunk_'$i'.jobids; done


# Graph induction (seqwish - beb7a3805c5af599b8425db94b9524eecbfc73e0)
mkdir -p /lizardfs/guarracino/HPRC/graphs

# ...single run from a single input PAF format file
sbatch -p lowmem -c 48 --wrap 'cd /scratch && \time -v seqwish -t 48 -s /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz -p /lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.gz -k 311 -g HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.seqwish.k311.B50M.gfa -B 50M -P && mv HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.seqwish.k311.B50M.gfa /lizardfs/guarracino/HPRC/graphs/'

# ...single run from multiple input PAF format chunks
sbatch -p lowmem -c 48 --wrap 'cd /scratch && \time -v seqwish -t 48 -s /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz -p /lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_0.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_1.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_2.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_3.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_4.paf.gz -k 311 -g HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.seqwish.k311.B50M.gfa -B 50M -P && mv HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.seqwish.k311.B50M.gfa /lizardfs/guarracino/HPRC/graphs/'

# ...loop from a single input PAF format file
(echo 449; echo 311; echo 239; echo 131; echo 71; echo 29) | while read k; do sbatch -p lowmem -c 48 --wrap 'cd /scratch && \time -v seqwish -t 48 -s /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz -p /lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_0.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_1.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_2.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_3.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_4.paf.gz -k '$k' -g HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.seqwish.k'$k'.B50M.gfa -B 50M -P && mv HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.seqwish.k'$k'.B50M.gfa.gz /lizardfs/guarracino/HPRC/graphs/' ; done
