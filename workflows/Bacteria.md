# Bacteria

## Download the assemblies

Tips from here: https://medium.com/computational-biology/how-to-download-all-bacterial-assemblies-from-ncbi-35f4bc5435f9.

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
for genus_species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $genus_species
  
  genus_species_lower=$(echo $genus_species | tr '[:upper:]' '[:lower:]')
  g=$(echo $genus_species_lower | cut -f 1 -d ' ')
  g=${g:0:1} # fist letter
  species=$(echo $genus_species_lower | cut -f 2 -d ' ')
  gspecies=$(echo $g$species)
  
  mkdir -p $gspecies
  zgrep "$genus_species" assembly.bacteria.txt.gz | cut -f 3 | while read f; do
    # Slow: name=$(basename $f);
    # Slow: name=$(echo $f | rev | cut -f 1 -d '/' | rev)
    # Slow: name=$(echo $f | grep -o '[^/]*$')
    name=$(echo $f | awk -F '/' '{print $NF}')
    echo $f/${name}_genomic.fna.gz >> $gspecies/$gspecies.urls;
  done
done
```

Download the assemblies:

```shell
for genus_species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $genus_species
  
  genus_species_lower=$(echo $genus_species | tr '[:upper:]' '[:lower:]')
  g=$(echo $genus_species_lower | cut -f 1 -d ' ')
  g=${g:0:1} # fist letter
  species=$(echo $genus_species_lower | cut -f 2 -d ' ')
  gspecies=$(echo $g$species)
  
  sbatch -p lowmem --wrap "cd /lizardfs/guarracino/seqwish-paper/bacteria/assemblies/'$gspecies'; cat *.urls | parallel -j 16 'wget -q {} && echo got {}'"
done
#sbatch -p headnode -w octopus01 --wrap 'zcat assembly.bacteria.txt.gz | cut -f 3 | while read f; do echo $f; name=$(basename $f); wget -c $f/${name}_genomic.fna.gz; done'


# Check integrity
for genus_species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $genus_species
  
  genus_species_lower=$(echo $genus_species | tr '[:upper:]' '[:lower:]')
  g=$(echo $genus_species_lower | cut -f 1 -d ' ')
  g=${g:0:1} # fist letter
  species=$(echo $genus_species_lower | cut -f 2 -d ' ')
  gspecies=$(echo $g$species)
  
  ls $gspecies/*gz | while read f; do gzip -t $f; done
done
```

Trim headers and add prefixes:

```shell
for genus_species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $genus_species
  
  genus_species_lower=$(echo $genus_species | tr '[:upper:]' '[:lower:]')
  g=$(echo $genus_species_lower | cut -f 1 -d ' ')
  g=${g:0:1} # fist letter
  species=$(echo $genus_species_lower | cut -f 2 -d ' ')
  gspecies=$(echo $g$species)
  
  cd $gspecies
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
for genus_species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $genus_species
  
  genus_species_lower=$(echo $genus_species | tr '[:upper:]' '[:lower:]')
  g=$(echo $genus_species_lower | cut -f 1 -d ' ')
  g=${g:0:1} # fist letter
  species=$(echo $genus_species_lower | cut -f 2 -d ' ')
  gspecies=$(echo $g$species)
  
  cd $gspecies
  num_assemblies=$(ls *.fa.gz | wc -l)
  zcat *.fa.gz | cut -f 1 | bgzip -@ 48 -c > $gspecies${num_assemblies}.fasta.gz; samtools faidx $gspecies${num_assemblies}.fasta.gz
  cd ..
done
```


## Explore the assemblies

Number of total contigs (1st column) for each species:

```shell
wc */*fasta.gz.fai
  8660  43300 440033 ecoli/ecoli2622.fasta.gz.fai
   292   1460  14683 hpylori/hpylori250.fasta.gz.fai
  5094  25470 256697 kpneumoniae/kpneumoniae1179.fasta.gz.fai
  3361  16805 170949 senterica/senterica1596.fasta.gz.fai
 17407  87035 882362 total
```

Distances:

```shell
# guix install mash

for genus_species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $genus_species
  
  genus_species_lower=$(echo $genus_species | tr '[:upper:]' '[:lower:]')
  g=$(echo $genus_species_lower | cut -f 1 -d ' ')
  g=${g:0:1} # fist letter
  species=$(echo $genus_species_lower | cut -f 2 -d ' ')
  gspecies=$(echo $g$species)
  
  cd $gspecies
  ls *.fa.gz | while read f; do mash sketch $f; done
  mash triangle *.fa.gz >$gspecies.mash_triangle.txt
  cd ..
done
```
sbatch -p headnode -c 1 --wrap 'bash /lizardfs/guarracino/seqwish-paper/bacteria/assemblies/mash_triangle.sh'

Top distances:

```shell
for genus_species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $genus_species
  
  genus_species_lower=$(echo $genus_species | tr '[:upper:]' '[:lower:]')
  g=$(echo $genus_species_lower | cut -f 1 -d ' ')
  g=${g:0:1} # fist letter
  species=$(echo $genus_species_lower | cut -f 2 -d ' ')
  gspecies=$(echo $g$species)
  
  sed 1,1d $gspecies/$gspecies.mash_triangle.txt | tr '\t' '\n' | grep GCA -v | grep e -v | sort -g -k 1nr | uniq | head -n 5
done

Escherichia coli
1
0.295981
0.263022
0.243761
0.23011
Salmonella enterica
1
0.295981
0.263022
0.243761
0.23011
Klebsiella pneumoniae
0.0653942
0.0645437
0.0642645
0.0639874
0.0637124
Helicobacter pylori
0.0794837
0.0786628
0.0782587
0.0759181
0.0755413
```

## All-vs-all alignment

Mapping:

```shell
for genus_species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $genus_species
  
  genus_species_lower=$(echo $genus_species | tr '[:upper:]' '[:lower:]')
  g=$(echo $genus_species_lower | cut -f 1 -d ' ')
  g=${g:0:1} # fist letter
  species=$(echo $genus_species_lower | cut -f 2 -d ' ')
  gspecies=$(echo $g$species)
  
  mkdir -p /lizardfs/guarracino/seqwish-paper/bacteria/alignment/$gspecies
  
  ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/bacteria/assemblies/$gspecies/*fasta.gz
  NUM_HAPLOTYPES=$(cut -f 1 -d '#' $ASSEMBLIES.fai | sort | uniq | wc -l)
  FILENAME=$(basename $ASSEMBLIES .fasta.gz)

  for s in 5k 10k; do
      for p in 95; do
          s_no_k=${s::-1}
          l_no_k=$(echo $s_no_k '*' 3 | bc)
          l=${l_no_k}k
            
          APPROX_PAF=/lizardfs/guarracino/seqwish-paper/bacteria/alignment/$gspecies/$FILENAME.s$s.l$l.p$p.n${NUM_HAPLOTYPES}.approx.paf
          sbatch -p workers -c 48 --job-name $gspecies --wrap 'hostname; cd /scratch; \time -v ~/tools/wfmash/build/bin/wfmash-948f1683d14927745aef781cdabeb66ac6c7880b '$ASSEMBLIES' '$ASSEMBLIES' -X -s '$s' -l '$l' -p '$p' -n '$NUM_HAPLOTYPES' -t 48 -m > '${APPROX_PAF}
      done
  done
done
```

Split mappings:

```shell
for genus_species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $genus_species
  
  genus_species_lower=$(echo $genus_species | tr '[:upper:]' '[:lower:]')
  g=$(echo $genus_species_lower | cut -f 1 -d ' ')
  g=${g:0:1} # fist letter
  species=$(echo $genus_species_lower | cut -f 2 -d ' ')
  gspecies=$(echo $g$species)
  
  ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/bacteria/assemblies/$gspecies/*fasta.gz
  NUM_HAPLOTYPES=$(cut -f 1 -d '#' $ASSEMBLIES.fai | sort | uniq | wc -l)
  FILENAME=$(basename $ASSEMBLIES .fasta.gz)

  for s in 5k 10k; do
      for p in 95; do
          s_no_k=${s::-1}
          l_no_k=$(echo $s_no_k '*' 3 | bc)
          l=${l_no_k}k
            
          APPROX_PAF=/lizardfs/guarracino/seqwish-paper/bacteria/alignment/$gspecies/$FILENAME.s$s.l$l.p$p.n${NUM_HAPLOTYPES}.approx.paf
          python3 ~/tools/wfmash/scripts/split_approx_mappings_in_chunks.py $APPROX_PAF 10
      done
  done
done
```

Alignment:

```shell
for genus_species in "Helicobacter pylori" "Klebsiella pneumoniae" "Salmonella enterica" "Escherichia coli" ; do
  echo $genus_species
  
  genus_species_lower=$(echo $genus_species | tr '[:upper:]' '[:lower:]')
  g=$(echo $genus_species_lower | cut -f 1 -d ' ')
  g=${g:0:1} # fist letter
  species=$(echo $genus_species_lower | cut -f 2 -d ' ')
  gspecies=$(echo $g$species)
  
  ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/bacteria/assemblies/$gspecies/*fasta.gz
  NUM_HAPLOTYPES=$(cut -f 1 -d '#' $ASSEMBLIES.fai | sort | uniq | wc -l)
  FILENAME=$(basename $ASSEMBLIES .fasta.gz)

  for s in 5k 10k; do
      for p in 95; do
          s_no_k=${s::-1}
          l_no_k=$(echo $s_no_k '*' 3 | bc)
          l=${l_no_k}k
          
          seq 0 9 | while read i; do
            APPROX_PAF=/lizardfs/guarracino/seqwish-paper/bacteria/alignment/$gspecies/$FILENAME.s$s.l$l.p$p.n${NUM_HAPLOTYPES}.approx.paf.chunk_$i.paf
            UNFILTERED_PAF=/lizardfs/guarracino/seqwish-paper/bacteria/alignment/$gspecies/$FILENAME.s$s.l$l.p$p.n${NUM_HAPLOTYPES}.chunk_$i.paf.gz
            sbatch -p workers -c 48 --job-name $gspecies --wrap 'hostname; cd /scratch; \time -v ~/tools/wfmash/build/bin/wfmash-948f1683d14927745aef781cdabeb66ac6c7880b '$ASSEMBLIES' '$ASSEMBLIES' -X -s '$s' -l '$l' -p '$p' -n '$NUM_HAPLOTYPES' -t 48 -i '$APPROX_PAF' | pigz -c > '$UNFILTERED_PAF
          done
      done
  done
done
```

Filtering:

```shell
for genus_species in "Helicobacter pylori" "Klebsiella pneumoniae" "Salmonella enterica" "Escherichia coli" ; do
  echo $genus_species
  
  genus_species_lower=$(echo $genus_species | tr '[:upper:]' '[:lower:]')
  g=$(echo $genus_species_lower | cut -f 1 -d ' ')
  g=${g:0:1} # fist letter
  species=$(echo $genus_species_lower | cut -f 2 -d ' ')
  gspecies=$(echo $g$species)
  
  ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/bacteria/assemblies/$gspecies/*fasta.gz
  NUM_HAPLOTYPES=$(cut -f 1 -d '#' $ASSEMBLIES.fai | sort | uniq | wc -l)
  FILENAME=$(basename $ASSEMBLIES .fasta.gz)

  for s in 5k 10k; do
      for p in 95; do
          s_no_k=${s::-1}
          l_no_k=$(echo $s_no_k '*' 3 | bc)
          l=${l_no_k}k
          
          p_threshold=$(echo "scale=2; $p/100.0" | bc)
          
          seq 0 9 | while read i; do
              echo $s $p $i
              UNFILTERED_PAF=/lizardfs/guarracino/seqwish-paper/bacteria/alignment/$gspecies/$FILENAME.s$s.l$l.p$p.n${NUM_HAPLOTYPES}.chunk_$i.paf.gz
              PAF=/lizardfs/guarracino/seqwish-paper/bacteria/alignment/$gspecies/$FILENAME.s$s.l$l.p$p.n${NUM_HAPLOTYPES}.chunk_$i.filtered.paf.gz
              
              zcat $UNFILTERED_PAF | awk -v p=$p_threshold '{split($13, gi, /:/); if(gi[3] >= p) {print $0}}' | pigz -c > $PAF
          done
      done
  done
done
```

## Graph induction

```shell
for genus_species in "Escherichia coli" "Salmonella enterica" "Klebsiella pneumoniae" "Helicobacter pylori"; do
  echo $genus_species
  
  genus_species_lower=$(echo $genus_species | tr '[:upper:]' '[:lower:]')
  g=$(echo $genus_species_lower | cut -f 1 -d ' ')
  g=${g:0:1} # fist letter
  species=$(echo $genus_species_lower | cut -f 2 -d ' ')
  gspecies=$(echo $g$species)
  
  if [ $gspecies == "hpylori" ]; then
    LOGSECS=1 # Graph induction is fast because the dataset is small
  else
    LOGSECS=10
  fi
  
  mkdir -p /lizardfs/guarracino/seqwish-paper/bacteria/graphs/$gspecies
  
  ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/bacteria/assemblies/$gspecies/*fasta.gz
  NUM_HAPLOTYPES=$(cut -f 1 -d '#' $ASSEMBLIES.fai | sort | uniq | wc -l)
  FILENAME=$(basename $ASSEMBLIES .fasta.gz)

  for s in 10k 5k; do
      for p in 95; do
          s_no_k=${s::-1}
          l_no_k=$(echo $s_no_k '*' 3 | bc)
          l=${l_no_k}k

          PAFS=$(ls /lizardfs/guarracino/seqwish-paper/bacteria/alignment/$gspecies/$FILENAME.s$s.l$l.p$p.n${NUM_HAPLOTYPES}.chunk_*.paf.gz | tr '\n' ',')
          PAFS=${PAFS::-1}
          for k in 0 11 29 49 79 127 179 229 311; do
              GFA=/scratch/$FILENAME.s$s.l$l.p$p.n${NUM_HAPLOTYPES}.k$k.B10M.gfa
              LOG=/scratch/$FILENAME.s$s.l$l.p$p.n${NUM_HAPLOTYPES}.k$k.B10M.size.log
              
              sbatch -p 386mem -c 48 --job-name $gspecies --wrap 'bash /lizardfs/guarracino/seqwish-paper/scripts/seqwish_with_logging.sh '$ASSEMBLIES' '$PAFS' '$GFA' '$k' 10M '$LOG' '$LOGSECS'; mv '$GFA' /lizardfs/guarracino/seqwish-paper/graphs/'$gspecies'; mv '$LOG' /lizardfs/guarracino/seqwish-paper/logs/'
          done
      done
  done
done
```
