# Zea mays

## Download the assemblies

Go to `https://www.ncbi.nlm.nih.gov/assembly/?term=txid4577%5BOrganism%3Anoexp%5D`, set the filters 
(`Latests`, `Chromosome`, `Exclude partial`, `Exclude anomalous`, click `Send to`, `File`, `Format ID Table (text`), 
`Sort by Accession`, `Create File`. Rename the file from `assembly_results.txt` to `assembly_results.zea_mays.txt`.

Install `sudo apt install ncbi-entrez-direct` and then get all the links for the download:

```shell
bash genbank2url.sh assembly_results.zea_mays.txt zea_mays.ftp_links.txt
```

Download the assemblies:

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/zmays/assemblies
cd /lizardfs/guarracino/seqwish-paper/zmays/assemblies

# scp the `assembly_results.zea_mays.txt` and `zea_mays.ftp_links.txt` files
grep -f <(cut -f 1 assembly_results.zea_mays.txt) zea_mays.ftp_links.txt | while read f; do
  echo $f
  wget -c $f
done

# Check integrity
ls *gz | while read f; do echo $f; gzip -t $f; done
```

Add prefixes:

```shell
ls *.fna.gz | while read f; do
  prefix=$(echo $f | cut -f 1,2 -d '_');
  echo $prefix
  # `cut -f 1` to trim the headers
  ~/tools/fastix/target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834 -p "${prefix}#" <(zcat $f | cut -f 1) | bgzip -@ 48 -c > $prefix.fa.gz;
  samtools faidx $prefix.fa.gz
done
```

Put all together:

```shell
zcat *.fa.gz | bgzip -@ 48 -c > zmays41.fasta.gz; samtools faidx zmays41.fasta.gz
```

## Explore the assemblies

Number of contigs (1st column) for each assembly:

```shell
wc *fa.gz.fai
    265    1325   14333 GCA_000005005.6.fa.gz.fai
   2203   11015  118730 GCA_003185045.1.fa.gz.fai
    797    3985   43097 GCA_003704525.1.fa.gz.fai
    972    4860   52567 GCA_003709335.1.fa.gz.fai
    673    3365   36362 GCA_009176585.1.fa.gz.fai
    998    4990   57069 GCA_014529475.1.fa.gz.fai
   8450   42250  480441 GCA_016432965.1.fa.gz.fai
    291    1455   16643 GCA_019095955.1.fa.gz.fai
   1584    7920   90484 GCA_019095975.1.fa.gz.fai
   1547    7735   88978 GCA_019095995.1.fa.gz.fai
    930    4650   53309 GCA_019096015.1.fa.gz.fai
    380    1900   21767 GCA_019096025.1.fa.gz.fai
    615    3075   30851 GCA_902166955.1.fa.gz.fai
    413    2065   20756 GCA_902166965.1.fa.gz.fai
   1069    5345   53648 GCA_902166975.1.fa.gz.fai
    906    4530   45429 GCA_902166985.1.fa.gz.fai
    796    3980   39943 GCA_902166995.1.fa.gz.fai
   1379    6895   69252 GCA_902167005.1.fa.gz.fai
    757    3785   38005 GCA_902167015.1.fa.gz.fai
   1092    5460   54812 GCA_902167025.1.fa.gz.fai
   1313    6565   65898 GCA_902167035.1.fa.gz.fai
    647    3235   32502 GCA_902167045.1.fa.gz.fai
    632    3160   31726 GCA_902167055.1.fa.gz.fai
    282    1410   14173 GCA_902167065.1.fa.gz.fai
    800    4000   40137 GCA_902167075.1.fa.gz.fai
    395    1975   19829 GCA_902167085.1.fa.gz.fai
   1268    6340   63642 GCA_902167095.1.fa.gz.fai
   1165    5825   58424 GCA_902167105.1.fa.gz.fai
   1398    6990   70189 GCA_902167115.1.fa.gz.fai
   1331    6655   66772 GCA_902167135.1.fa.gz.fai
    685    3425   34388 GCA_902167145.1.fa.gz.fai
   1533    7665   76920 GCA_902167155.1.fa.gz.fai
   1076    5380   54009 GCA_902167165.1.fa.gz.fai
    739    3695   37063 GCA_902167175.1.fa.gz.fai
   1548    7740   77673 GCA_902167185.1.fa.gz.fai
   1045    5225   52448 GCA_902167205.1.fa.gz.fai
   1012    5060   50767 GCA_902167375.1.fa.gz.fai
   1682    8410   84486 GCA_902373975.1.fa.gz.fai
    936    4680   46973 GCA_902714155.1.fa.gz.fai
     10      50     529 GCA_905067065.1.fa.gz.fai
    675    3375   38516 GCA_910593975.1.fa.gz.fai
  46289  231445 2443540 total
```

Distances:

```shell
# guix install mash

ls *.fa.gz | while read f; do mash sketch $f; done
mash triangle *.fa.gz >zmays.mash_triangle.txt
```

Top distances:

```shell
sed 1,1d zmays.mash_triangle.txt | tr '\t' '\n' | grep GCA -v | grep e -v | sort -g -k 1nr | head -n 5
0.022205
0.0220623
0.0219913
0.0218499
0.0216393
```

## All-vs-all alignment

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/zmays/alignment/

ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/zmays/assemblies/zmays41.fasta.gz

# -p 98
for s in 20k 50k; do
  for p in 98; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
    
    PAF=/lizardfs/guarracino/seqwish-paper/zmays/alignment/zmays41.s$s.l$l.p$p.n41.paf.gz
    sbatch -p workers -c 48 --job-name zmays --wrap 'hostname; cd /scratch; \time -v ~/tools/wfmash/build/bin/wfmash-948f1683d14927745aef781cdabeb66ac6c7880b '$ASSEMBLIES' '$ASSEMBLIES' -X -s '$s' -l '$l' -p '$p' -n 41 -t 48 | pigz -c > '$PAF
  done
done

# -p 95
### Approximate mapping and splitting
for s in 20k 50k; do
  for p in 95; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
    
    APPROX_PAF=/lizardfs/guarracino/seqwish-paper/zmays/alignment/zmays41.s$s.l$l.p$p.n41.approx.paf
    sbatch -p workers -c 48 --job-name zmays --wrap 'hostname; cd /scratch; \time -v ~/tools/wfmash/build/bin/wfmash-948f1683d14927745aef781cdabeb66ac6c7880b '$ASSEMBLIES' '$ASSEMBLIES' -X -s '$s' -l '$l' -p '$p' -n 41 -t 48 -m > '$APPROX_PAF'; python3 ~/tools/wfmash/scripts/split_approx_mappings_in_chunks.py '$APPROX_PAF' 5'
  done
done
### Alignment
for s in 20k 50k; do
  for p in 95; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
        
    seq 0 4 | while read i; do
      APPROX_PAF=/lizardfs/guarracino/seqwish-paper/zmays/alignment/zmays41.s$s.l$l.p$p.n41.approx.paf.chunk_$i.paf
      UNFILTERED_PAF=/lizardfs/guarracino/seqwish-paper/zmays/alignment/zmays41.s$s.l$l.p$p.n41.chunk_$i.paf.gz
      sbatch -p workers -c 48 --job-name zmays --wrap 'hostname; cd /scratch; \time -v ~/tools/wfmash/build/bin/wfmash-948f1683d14927745aef781cdabeb66ac6c7880b '$ASSEMBLIES' '$ASSEMBLIES' -X -s '$s' -l '$l' -p '$p' -n 41 -t 48 -i '$APPROX_PAF' | pigz -c > '$UNFILTERED_PAF
    done
  done
done
### Filtering
for s in 20k 50k; do
  for p in 95; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
    
    p_threshold=$(echo "scale=2; $p/100.0" | bc)
        
    seq 0 4 | while read i; do
      echo $s $p $i
      UNFILTERED_PAF=/lizardfs/guarracino/seqwish-paper/zmays/alignment/zmays41.s$s.l$l.p$p.n41.chunk_$i.paf.gz
      PAF=/lizardfs/guarracino/seqwish-paper/zmays/alignment/zmays41.s$s.l$l.p$p.n41.chunk_$i.filtered.paf.gz
      
      zcat $UNFILTERED_PAF | awk -v p=$p_threshold '{split($13, gi, /:/); if(gi[3] >= p) {print $0}}' | pigz -c > $PAF
    done
  done
done
```

## Graph induction

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/zmays/graphs/

ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/zmays/assemblies/zmays41.fasta.gz

for s in 50k 20k; do
  for p in 95 98; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
    
    if [ $p == 98 ]; then
        PAFS=/lizardfs/guarracino/seqwish-paper/zmays/alignment/zmays41.s$s.l$l.p$p.n41.paf.gz
    else
        PAFS=$(ls /lizardfs/guarracino/seqwish-paper/zmays/alignment/zmays41.s$s.l$l.p$p.n41.chunk_*.filtered.paf.gz | tr '\n' ',')
        PAFS=${PAFS::-1}
    fi
        
    for k in 0 11 29 49 79 127 179 229 311; do
      if [ $p == 98 ]; then
          B=50M
      else
        if (( $k > 29)); then
          B=50M
        else
          B=10k
        fi
      fi
      if [[ ! -s /lizardfs/guarracino/seqwish-paper/zmays/graphs/zmays41.s$s.l$l.p$p.n41.k$k.B$B.gfa ]]; then
          GFA=/scratch/zmays41.s$s.l$l.p$p.n41.k$k.B$B.gfa
          LOG=/scratch/zmays41.s$s.l$l.p$p.n41.k$k.B$B.size.log
          #sbatch -p 386mem -c 48 --job-name seqwish_zmays --wrap 'hostname; cd /scratch; \time -v ~/tools/seqwish/bin/seqwish-ccfefb016fcfc9937817ce61dc06bbcf382be75e -t 48 -s '$ASSEMBLIES' -p '$PAFS' -g '$GFA' -k '$k' -B '$B' -P; mv '$GFA' /lizardfs/guarracino/seqwish-paper/zmays/graphs/'
     
          sbatch -p 386mem -c 48 --job-name zmays --wrap 'bash /lizardfs/guarracino/seqwish-paper/scripts/seqwish_with_logging.sh '$ASSEMBLIES' '$PAFS' '$GFA' '$k' '$B' '$LOG' 10; mv '$GFA' /lizardfs/guarracino/seqwish-paper/zmays/graphs/; mv '$LOG' /lizardfs/guarracino/seqwish-paper/logs/'        
      fi
    done
  done
done
```

## Statistics

```shell
for s in 50k 20k; do
  for p in 95 98; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
    
    for k in 0 11 29 49 79 127 179 229 311; do
      if [ $p == 98 ]; then
          B=50M
      else
        if (( $k > 29)); then
          B=50M
        else
          B=10k
        fi
      fi

      GFA=/lizardfs/guarracino/seqwish-paper/zmays/graphs/zmays41.s$s.l$l.p$p.n41.k$k.B$B.gfa
      sbatch -p workers -c 24 --job-name zmays_stats --wrap 'hostname; cd /scratch && ~/tools/odgi/bin/odgi-9e9c4811169760f64690e86619dbd1b088ec5955 stats -i '$GFA' -S -b -L -W -t 24 -P > '$GFA'.og.stats.txt'    
    done
  done
done

# Compress GFA files
ls /lizardfs/guarracino/seqwish-paper/zmays/graphs/*.gfa | while read f; do echo $f; pigz $f; done
```
