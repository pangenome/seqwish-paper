# Bacteria

## Download the assemblies

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/bacteria/assemblies
cd /lizardfs/guarracino/seqwish-paper/bacteria/assemblies
```

Download assembly information:

```shell
wget ftp://ftp.ncbi.nih.gov/genomes/genbank/bacteria/assembly_summary.txt && pigz 
# See ftp://ftp.ncbi.nlm.nih.gov/genomes/README_assembly_summary.txt for column descriptions
```

Get IDs, species, and links for `Reference/representative genome`, `latest` and `Complete Genome` assemblies coming from `Full` data:

```shell
zcat assembly_summary.txt | awk -F '\t' '{if($11=="latest" && $12=="Complete Genome" && $14=="Full" && $20 != "na") print $1"\t"$8"\t"$20 }' | pigz -c > assembly.bacteria.txt.gz
```

Top species with more assemblies:

```shell
zcat assembly.bacteria.txt.gz | cut -f 2 | cut -f 1,2 -d ' ' | sort | uniq -c | sort -k 1nr | head -n 15
   2621 Escherichia coli + 1 synthetic Escherichia coli C321.deltaA
   1596 Salmonella enterica
   1179 Klebsiella pneumoniae
   1067 Staphylococcus aureus
    754 Bordetella pertussis
    408 Enterococcus faecalis
    375 Pseudomonas aeruginosa
    312 Acinetobacter baumannii
    307 Mycobacterium tuberculosis
    282 Campylobacter jejuni
    273 Listeria monocytogenes
    253 Streptococcus pyogenes
    250 Helicobacter pylori
    240 Chlamydia trachomatis
    239 Enterococcus faecium
```

Prepare the URLs for a few species:

```shell
for species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $species
  
  sp=$(echo $species | tr ' ' '_')
  mkdir -p $sp
  zgrep "$species" assembly.bacteria.txt.gz | cut -f 3 | while read f; do
    # Slow: name=$(basename $f);
    # Slow: name=$(echo $f | rev | cut -f 1 -d '/' | rev)
    # Slow: name=$(echo $f | grep -o '[^/]*$')
    name=$(echo $f | awk -F '/' '{print $NF}')
    echo $f/${name}_genomic.fna.gz >> $sp/$sp.urls;
  done
done
```

Download the assemblies:

```shell
for species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $species
  
  sp=$(echo $species | tr ' ' '_')
  sbatch -p lowmem --wrap "cd /lizardfs/guarracino/seqwish-paper/bacteria/assemblies/'$sp'; cat *.urls | parallel -j 16 'wget -q {} && echo got {}'"
done
#sbatch -p headnode -w octopus01 --wrap 'zcat assembly.bacteria.txt.gz | cut -f 3 | while read f; do echo $f; name=$(basename $f); wget -c $f/${name}_genomic.fna.gz; done'


# Check integrity
for species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $species
  
  sp=$(echo $species | tr ' ' '_')
  ls $sp/*gz | while read f; do gzip -t $f; done
done
```

Trim headers and add prefixes:

```shell
for species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $species
  
  sp=$(echo $species | tr ' ' '_')
  cd $sp
  ls *.fna.gz | while read f; do
    prefix=$(echo $f | cut -f 1,2 -d '_');
    echo $prefix
    # `cut -f 1` to trim the headers
    ~/tools/fastix/target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834 -p "${prefix}#" <(zcat $f | cut -f 1) | bgzip -@ 48 -c > $prefix.fa.gz;
    samtools faidx $prefix.fa.gz
  done
  
  cd ..
done
```

Put all together:

```shell
zcat *.fa.gz | cut -f 1 | bgzip -@ 48 -c > athaliana16.fasta.gz; samtools faidx athaliana16.fasta.gz
```


## Explore the assemblies

Number of contigs (1st column) for each assemblies:

```shell
wc *fa.gz.fai
    7    35   349 GCA_000001735.2.fa.gz.fai
    6    30   299 GCA_000211275.1.fa.gz.fai
   30   150  1588 GCA_001651475.1.fa.gz.fai
  109   545  6019 GCA_900660825.1.fa.gz.fai
  111   555  6128 GCA_902460265.3.fa.gz.fai
  102   510  5621 GCA_902460275.1.fa.gz.fai
  105   525  5798 GCA_902460285.1.fa.gz.fai
   94   470  5198 GCA_902460295.1.fa.gz.fai
  184   920 10197 GCA_902460305.1.fa.gz.fai
  142   710  7851 GCA_902460315.1.fa.gz.fai
    5    25   249 GCA_902825305.1.fa.gz.fai
    5    25   249 GCA_903064275.1.fa.gz.fai
    5    25   249 GCA_903064285.1.fa.gz.fai
    5    25   249 GCA_903064295.1.fa.gz.fai
    5    25   249 GCA_903064325.1.fa.gz.fai
    7    35   350 GCA_904420315.1.fa.gz.fai
  922  4610 50643 total
```

Distances:

```shell
# guix install mash

ls *.fa.gz | while read f; do mash sketch $f; done
mash triangle *.fa.gz >athaliana.mash_triangle.txt
```


















## All-vs-all alignment and graph induction

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/arabidopsis/alignment/
mkdir -p /lizardfs/guarracino/seqwish-paper/arabidopsis/graphs/

ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/arabidopsis/assemblies/arabidopsis.fasta.gz

for s in 100000 50000 20000; do
  for p in 95 90; do
    l=$(echo $s '*' 3 | bc)
    PAF=/lizardfs/guarracino/seqwish-paper/arabidopsis/alignment/arabidopsis.s$s.l$l.p$p.n9.paf
    for k in 79 29 7 0; do
      GFA=/lizardfs/guarracino/seqwish-paper/arabidopsis/graphs/arabidopsis.s$s.l$l.p$p.n9.k$k.B50M.gfa
      sbatch -p workers -c 48 --wrap 'cd /scratch; \time -v ~/tools/wfmash/build/bin/wfmash-7fe6c05b57c030d71c64c586d8135d49d3a27528 '$ASSEMBLIES' '$ASSEMBLIES' -X -s '$s' -l '$l' -p '$p' -n 9 -t 48 > '$PAF'; \time -v ~/tools/seqwish/bin/seqwish-ccfefb016fcfc9937817ce61dc06bbcf382be75e -f '$ASSEMBLIES' -p '$PAF' -g '$GFA' -k '$k' -B50M -P'
    done
  done
done

```

