# Scalability test

## Tools

```shell
mkdir -p ~/tools $$ cd ~/tools

git clone --recursive https://github.com/ekg/fastix.git
cd fastix
git checkout 331c1159ea16625ee79d1a82522e800c99206834
cargo build --release
mv target/release/fastix target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834
cd ..

git clone --recursive https://github.com/ekg/wfmash.git
cd wfmash
git checkout 09e73eb3fcf24b8b7312b8890dd0741933f0d1cd
cmake -H. -Bbuild && cmake --build build -- -j 48
mv build/bin/wfmash build/bin/wfmash-09e73eb3fcf24b8b7312b8890dd0741933f0d1cd
cd ..

git clone --recursive https://github.com/ekg/seqwish.git
cd seqwish
git checkout ccfefb016fcfc9937817ce61dc06bbcf382be75e
cmake -H. -Bbuild && cmake --build build -- -j 48
mv bin/seqwish bin/seqwish-ccfefb016fcfc9937817ce61dc06bbcf382be75e
cd ..

git clone --recursive https://github.com/pangenome/odgi.git
cd odgi
git checkout 67a7e5bb2f328888e194845a362cef9c8ccc488f
mv bin/odgi bin/odgi-67a7e5bb2f328888e194845a362cef9c8ccc488f
cmake -H. -Bbuild && cmake --build build -- -j 48
cd ..
```

## Preparation and preprocessing

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/assemblies
cd /lizardfs/guarracino/seqwish-paper/assemblies
```

Get the URLs of the assemblies (**only HPRC+ samples**):

```shell
wget https://raw.githubusercontent.com/human-pangenomics/HPP_Year1_Assemblies/main/assembly_index/Year1_assemblies_v2_genbank.index
grep 'chm13\|h38' Year1_assemblies_v2_genbank.index | awk '{ print $2 }' | sed 's%s3://human-pangenomics/working/%https://s3-us-west-2.amazonaws.com/human-pangenomics/working/%g' >refs.urls
grep 'chm13\|h38' -v Year1_assemblies_v2_genbank.index  | grep HPRC_PLUS | awk '{ print $2; print $3 }' | sed 's%s3://human-pangenomics/working/%https://s3-us-west-2.amazonaws.com/human-pangenomics/working/%g' >samples.urls
```

Download them:

```shell
cat refs.urls samples.urls | parallel -j 4 'wget -q {} && echo got {}'
```

Add a prefix to the reference sequences:

```shell
( ~/tools/fastix/target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834 -p 'grch38#' <(zcat GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz) >grch38_full.fa && samtools faidx grch38_full.fa ) &
( ~/tools/fastix/target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834 -p 'chm13#' <(zcat chm13.draft_v1.1.fasta.gz) | pigz -c >chm13.fa.gz ) &
wait
```

Remove unplaced contigs from grch38 that are (hopefully) represented in chm13:

```shell
samtools faidx grch38_full.fa $(cat grch38_full.fa.fai | cut -f 1 | grep -v _ ) | pigz -c >grch38.fa.gz
```

Put all together:

```shell
zcat chm13.fa.gz grch38.fa.gz *genbank.fa.gz | bgzip -@ 48 -c > HPRC_plus.fa.gz && samtools faidx HPRC_plus.fa.gz
```

Cleaning:

```shell
rm chm13.draft_v1.1.fasta.gz chm13.fa.gz GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz grch38*.fa.gz
```


## Alignment

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/alignment
```

Generate all-vs-all mapping:

[comment]: <> (```shell)
[comment]: <> (sbatch -p lowmem -c 48 --wrap 'cd /scratch && wfmash -X -s 100k -l 300k -p 98 -n 90 -k 16 -t 48 /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz -m > HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.approx.paf && mv HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.approx.paf /lizardfs/guarracino/HPRC/')
[comment]: <> (```)

```shell
sbatch -p lowmem -c 48 --wrap 'cd /scratch && ~/tools/wfmash/build/bin/wfmash-09e73eb3fcf24b8b7312b8890dd0741933f0d1cd -X -s 100k -l 300k -p 98 -n 90 -k 16 -t 48 /lizardfs/guarracino/seqwish-paper/assemblies/HPRC_plus.fa.gz /lizardfs/guarracino/seqwish-paper/assemblies/HPRC_plus.fa.gz -m > HPRC_plus.s100k.l300k.p98.n90.k16.approx.paf && mv HPRC_plus.s100k.l300k.p98.n90.k16.approx.paf /lizardfs/guarracino/seqwish-paper/alignment/'
```

Split the mappings in chunks:

[comment]: <> ```shell
[comment]: <> python3 /home/guarracino/wfmash/scripts/split_approx_mappings_in_chunks.py /lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.approx.paf 5
[comment]: <> ```

```shell
python3 ~/tools/wfmash/split_approx_mappings_in_chunks.py /lizardfs/guarracino/seqwish-paper/alignment/HPRC_plus.s100k.l300k.p98.n90.k16.approx.paf 5
```

Run the alignments on multiple nodes:

[comment]: <> ```shell
[comment]: <> seq 0 4 | while read i; do sbatch -p lowmem -c 48 --wrap 'cd /scratch && /home/guarracino/wfmash/build/bin/wfmash -X -s 100k -l 300k -p 98 -n 90 -k 16 -t 48 /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz -i /lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.approx.paf.chunk_'$i'.paf | pigz -c > HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_'$i'.paf.gz && mv HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_'$i'.paf.gz /lizardfs/guarracino/HPRC/' ; done >>wfmash.alignment.jobids
[comment]: <> ```

```shell
seq 0 4 | while read i; do sbatch -p lowmem -c 48 --wrap 'cd /scratch && ~/tools/wfmash/build/bin/wfmash-09e73eb3fcf24b8b7312b8890dd0741933f0d1cd -X -s 100k -l 300k -p 98 -n 90 -k 16 -t 48 /lizardfs/guarracino/seqwish-paper/assemblies/HPRC_plus.fa.gz /lizardfs/guarracino/seqwish-paper/assemblies/HPRC_plus.fa.gz -i /lizardfs/guarracino/seqwish-paper/alignment/HPRC_plus.s100k.l300k.p98.n90.k16.approx.paf.chunk_'$i'.paf | pigz -c > HPRC_plus.s100k.l300k.p98.n90.k16.chunk_'$i'.paf.gz && mv HPRC_plus.s100k.l300k.p98.n90.k16.chunk_'$i'.paf.gz lizardfs/guarracino/seqwish-paper/alignment/' ; done >>alignment.jobids
```

## Graph induction

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/graphs
```

Run `seqwish`:

[comment]: <> ```shell
[comment]: <> sbatch -p workers -w octopus03 -c 48 --wrap '(echo 311; echo 229; echo 179; echo 127; echo 79; echo 29; echo 11) | while read k; do cd /scratch && \time -v seqwish -t 48 -s /lizardfs/erikg/HPRC/year1v2genbank/parts/HPRCy1.pan.fa.gz -p /lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_0.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_1.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_2.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_3.paf.gz,/lizardfs/guarracino/HPRC/HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.paf.chunk_4.paf.gz -k $k -g HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.seqwish.k$k.B50M.gfa -B 50M -P && mv HPRCy1.pan.fa.s100k.l300k.p98.n90.k16.seqwish.k$k.B50M.gfa /lizardfs/guarracino/HPRC/graphs/ ; done'
[comment]: <> ```

```shell
# list all base-level alignment PAFs
PAFS=$(ls /lizardfs/guarracino/seqwish-paper/alignment/HPRC_plus.s100k.l300k.p98.n90.k16.approx.paf.chunk_*.paf | tr '\n' ',')
PAFS=${PAFS::-1}

sbatch -p workers -w octopus03 -c 48 --wrap '(echo 311; echo 229; echo 179; echo 127; echo 79; echo 29; echo 11) | while read k; do cd /scratch && \time -v ~/tools/seqwish/bin/seqwish-ccfefb016fcfc9937817ce61dc06bbcf382be75e -t 48 -s /lizardfs/guarracino/seqwish-paper/assemblies/HPRC_plus.fa.gz -p '$PAFS' -k $k -B 50M -g HPRC_plus.s100k.l300k.p98.n90.k16.seqwish.k$k.B50M.gfa -P && mv HPRC_plus.s100k.l300k.p98.n90.k16.seqwish.k$k.B50M.gfa /lizardfs/guarracino/seqwish-paper/graphs/ ; done'
```

## Statistics

```shell
(echo 311; echo 229; echo 179; echo 127; echo 79; echo 29; echo 11) | while read k; do
  g=/lizardfs/guarracino/seqwish-paper/graphs/HPRC_plus.s100k.l300k.p98.n90.k16.seqwish.k$k.B50M.gfa
  sbatch -p workers -c 48 --wrap 'cd /scratch && ~/tools/odgi/bin/odgi-67a7e5bb2f328888e194845a362cef9c8ccc488f build -g '$g' -o '$g'.og -t 48 -P; ~/tools/odgi/bin/odgi-67a7e5bb2f328888e194845a362cef9c8ccc488f stats -S -W -L -N -b  -t 48 -P > '$g'.og.stats.txt';
done
```
