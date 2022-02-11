# seqwish-paper


## building the manuscript

```shell
# Dependencies
sudo apt-get -y install texlive texlive-latex-recommended \
        texlive-pictures texlive-latex-extra texlive-fonts-extra \
        texlive-science

sudo apt install graphviz

git clone https://github.com/pangenome/seqwish-paper
cd seqwish-paper/manuscript && make -k
```


## tools to run the workflows

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
git checkout 948f1683d14927745aef781cdabeb66ac6c7880b
cmake -H. -Bbuild && cmake --build build -- -j 48
mv build/bin/wfmash build/bin/wfmash-948f1683d14927745aef781cdabeb66ac6c7880b
cd ..

git clone --recursive https://github.com/ekg/seqwish.git
cd seqwish
git checkout ccfefb016fcfc9937817ce61dc06bbcf382be75e
cmake -H. -Bbuild && cmake --build build -- -j 48
mv bin/seqwish bin/seqwish-ccfefb016fcfc9937817ce61dc06bbcf382be75e
cd ..

git clone --recursive https://github.com/pangenome/odgi.git
cd odgi
git checkout 9e9c4811169760f64690e86619dbd1b088ec5955
cmake -H. -Bbuild && cmake --build build -- -j 48
mv bin/odgi bin/odgi-9e9c4811169760f64690e86619dbd1b088ec5955
cd ..
```


# workflows

[Link to the `Arabidopsis_thaliana.md` workflow](workflows/Arabidopsis_thaliana.md).

[Link to the `Bacteria.md` workflow](workflows/Bacteria.md).

[Link to the `HPRC_plus.md` workflow](workflows/HPRC_plus.md).

[Link to the `Zea_mays.md` workflow](workflows/Zea_mays.md).


# instructions to get the statistics

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/statistics
cd /lizardfs/guarracino/seqwish-paper/statistics
```

FASTA statistics:

```shell
(echo input.fasta num.sequences num.haplotypes Gbps A.fraction C.fraction G.fraction T.fraction N.fraction; find /lizardfs/guarracino/seqwish-paper/ -name *.fasta.gz | while read FASTA; do
  FASTA_NAME=$(basename $FASTA .fasta.gz);
  NUM_SEQUENCES=$(cat $FASTA.fai | wc -l);
  if [ $FASTA_NAME == 'hprcplus38' ]; then
    NUM_HAPLOTYPES=38
  else
    NUM_HAPLOTYPES=$(cut -f 1 -d '#' $FASTA.fai | sort | uniq | wc -l);
  fi
  (echo -n "$FASTA_NAME $NUM_SEQUENCES $NUM_HAPLOTYPES "; seqtk comp $FASTA | awk '{num_bp+=$2;A+=$3;C+=$4;G+=$5;T+=$6;N+=$9}END{print num_bp/1000/1000/1000,A/num_bp,C/num_bp,G/num_bp,T/num_bp,N/num_bp}')
done)  | tr ' ' '\t' > /lizardfs/guarracino/seqwish-paper/statistics/input_fasta.tsv
```

PAF statistics:

```shell
echo input.paf num.alignments num.matches | tr ' ' '\t' > /lizardfs/guarracino/seqwish-paper/statistics/input_paf.tsv
ls /lizardfs/guarracino/seqwish-paper/{athaliana,fish,hprc_plus}/alignment/*.paf.gz | while read PAF; do
  echo $PAF
  PAF_NAME=$(basename $PAF .paf.gz);
  (echo -n "$PAF_NAME "; zcat $PAF | awk '{ alignments += 1; matches += $10 } END { print alignments"\t"matches }') | tr ' ' '\t' >> /lizardfs/guarracino/seqwish-paper/statistics/input_paf.tsv
done
for s in 50k 20k; do
  for p in 95 98; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
    
    if [ $p == 98 ]; then
        PAFS=/lizardfs/guarracino/seqwish-paper/zmays/alignment/zmays41.s$s.l$l.p$p.n41.paf.gz
    else
        PAFS=/lizardfs/guarracino/seqwish-paper/zmays/alignment/zmays41.s$s.l$l.p$p.n41.chunk_*.filtered.paf.gz
    fi
    
    echo $PAFS
    PAFS_NAME=zmays41.s$s.l$l.p$p.n41;
    (echo -n "$PAFS_NAME "; zcat $PAFS | awk '{ alignments += 1; matches += $10 } END { print alignments"\t"matches }') | tr ' ' '\t' >> /lizardfs/guarracino/seqwish-paper/statistics/input_paf.tsv
  done
done
for genus_species in "Helicobacter pylori"; do
  echo $genus_species
  
  genus_species_lower=$(echo $genus_species | tr '[:upper:]' '[:lower:]')
  g=$(echo $genus_species_lower | cut -f 1 -d ' ')
  g=${g:0:1} # fist letter
  species=$(echo $genus_species_lower | cut -f 2 -d ' ')
  gspecies=$(echo $g$species)
  
  ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/bacteria/assemblies/$gspecies/*fasta.gz
  NUM_HAPLOTYPES=$(cut -f 1 -d '#' $ASSEMBLIES.fai | sort | uniq | wc -l)
  FILENAME=$(basename $ASSEMBLIES .fasta.gz)

  for s in 10k 5k; do
      for p in 98 95 90; do
          s_no_k=${s::-1}
          l_no_k=$(echo $s_no_k '*' 3 | bc)
          l=${l_no_k}k

          PAFS=/lizardfs/guarracino/seqwish-paper/bacteria/alignment/$gspecies/$FILENAME.s$s.l$l.p$p.n${NUM_HAPLOTYPES}.chunk_*.filtered.paf.gz
            
          echo $PAFS
          PAFS_NAME=$FILENAME.s$s.l$l.p$p.n${NUM_HAPLOTYPES};
          (echo -n "$PAFS_NAME "; zcat $PAFS | awk '{ alignments += 1; matches += $10 } END { print alignments"\t"matches }') | tr ' ' '\t' >> /lizardfs/guarracino/seqwish-paper/statistics/input_paf.tsv
      done
  done
done
```

Graph induction statistics:

```shell
(echo output.gfa input.fasta input.paf s l p n k B time.seconds memory.Gbytes disk.Gbytes | tr ' ' '\t' ;
  join\
    <(cat /lizardfs/guarracino/seqwish-paper/logs/* | python3 /lizardfs/guarracino/seqwish-paper/scripts/log2info.py | sort -k 1)\
    <(cat /lizardfs/guarracino/seqwish-paper/logs/* | python3 /lizardfs/guarracino/seqwish-paper/scripts/sizeLog2diskUsage.py | sort -k 1) | sort -k2,4 -k5,5 -k7,7n) \
    > /lizardfs/guarracino/seqwish-paper/statistics/graph_induction.tsv
```

Graph statistics:

```shell
(echo input.gfa gzipped.gfa.disk.size.Gbytes | tr ' ' '\t'; find /lizardfs/guarracino/seqwish-paper/ -name *.gfa.gz | while read GFA; do
  GFA_NAME=$(basename $GFA .gfa.gz);
  FILESIZE_MB=$(du -m "$GFA" | cut -f1);
  FILESIZE_GB=$(echo "scale=4; $FILESIZE_MB" / 1024 | bc);
  echo $GFA_NAME $FILESIZE_GB  | tr ' ' '\t';
done) > /lizardfs/guarracino/seqwish-paper/statistics/output_gfa.tsv

(echo input.gfa graph.length.Gbps num.nodes num.edges num.paths num.components | tr ' ' '\t'; find /lizardfs/guarracino/seqwish-paper/ -name *.og.stats.txt | while read TXT; do
  GFA_NAME=$(basename $TXT .gfa.og.stats.txt);
  NUM_COMPONENTS=$(grep '##num_weakly_connected_components' $TXT | cut -f 2 -d ' ')
  (echo -n $GFA_NAME " "; (sed -n '2 p' $TXT | tr '\n' ' '); echo $NUM_COMPONENTS) | awk -v OFS='\t' '{print $1,$2/1000/1000/1000,$3,$4,$5,$6}' | tr ' ' '\t';
done) > /lizardfs/guarracino/seqwish-paper/statistics/graph_statistics.tsv
```


Put all together:

```shell
join\
  <(sed 1,1d /lizardfs/guarracino/seqwish-paper/statistics/input_fasta.tsv | sort -k 1)\
  <(sed 1,1d /lizardfs/guarracino/seqwish-paper/statistics/graph_induction.tsv | sed 's/.chunk_0.filtered//g' | sort -k 2)\
  -1 1 -2 2 > /lizardfs/guarracino/seqwish-paper/statistics/input_fasta+graph_induction.tmp.tsv

join\
  <(sed 1,1d /lizardfs/guarracino/seqwish-paper/statistics/input_paf.tsv | sort -k 1)\
  <(sed 1,1d /lizardfs/guarracino/seqwish-paper/statistics/input_fasta+graph_induction.tmp.tsv | sort -k 11)\
  -1 1 -2 11 | awk '{print $4,$5,$6,$7,$8,$9,$10,$11,$12,$1,$2,$3,$14,$15,$16,$17,$13,$18,$19,$20,$21,$22}' | tr ' ' '\t' > input_fasta+input+paf+graph_induction.tmp.tsv

join <(sed 1,1d output_gfa.tsv | sort -k 1) <(sed 1,1d graph_statistics.tsv | sort -k 1) > output_gfa+graph_statistics.tmp.tsv

(echo run input.fasta num.sequences num.haplotypes Gbps A.fraction C.fraction G.fraction T.fraction N.fraction input.paf num.alignments num.matches s l p n k B time.seconds memory.Gbytes disk.Gbytes gzipped.gfa.disk.size.Gbytes graph.length.Gbps num.nodes num.edges num.paths num.components| tr ' ' '\t';  join\
  <(sed 1,1d input_fasta+input+paf+graph_induction.tmp.tsv | sort -k 17)\
  <(sort output_gfa+graph_statistics.tmp.tsv -k 1) \
  -1 17 -2 1 | sort -k 2,2 -k 14,14 -k 16,16nr -k 18,18nr) | tr ' ' '\t' > all_statistics.tsv

rm input_fasta+graph_induction.tmp.tsv output_gfa+graph_statistics.tmp.tsv



(head all_statistics.tsv -n 1; grep k49 all_statistics.tsv | grep 'athaliana16.s20k.l60k.p90.n16.k49.B50M\|fish12.s50k.l150k.p80.n12.k49.B50M\|hprcplus38.s100k.l300k.p95.n38.k49.B50M\|zmays41.s20k.l60k.p95.n41.k49.B50M\|hpylori250.s5k.l15k.p90.n250.k49.B50M') | cut -f 2,3,4,5,18,20,21,22,24,28 | tr '\t' ',' 
```

processing all_statistics.tsv to break apart some of its fields

```shell
paste all_statistics.tsv <(echo group seg.len min.mapping.len map.ident map.n seqwish.k seqwish.B | tr ' ' '\t'; cat /lizardfs/guarracino/seqwish-paper/statistics/all_statistics.tsv | cut -f 1 | tr '.' '\t' | tail -n+2 ) >stats.tsv
Rscript scripts/experiment_plot.R
```

## Bioinformatics - Instructions to Authors

https://academic.oup.com/bioinformatics/pages/instructions_for_authors

Original Papers (up to 7 pages; this is approx. 5,000 words. excluding figures)
The abstracts should be succinct and contain only material relevant to the headings. A maximum of 150 words is
recommended.

Application Notes (up to 2 pages; this is approx. 1,300 words or 1,000 words plus one figure)
Abstracts for Applications Notes are much shorter than those for an Original Paper. They are structured with four
headings: Summary, Availability and Implementation, Contact and Supplementary Information.
