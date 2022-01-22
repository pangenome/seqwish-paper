# Arabidopsis thaliana

## Download the assemblies

Go to `https://www.ncbi.nlm.nih.gov/assembly/?term=txid3702%5BOrganism%3Anoexp%5D`, set the filters
(`Latests`, `Chromosome`, `Exclude partial`, `Exclude anomalous`, click `Send to`, `File`, `Format ID Table (text`),
`Sort by Accession`, `Create File`. Rename the file from `assembly_results.txt` to `assembly_results.arabidopsis_thaliana.txt`.

Install `sudo apt install ncbi-entrez-direct` and then get all the links for the download:

```shell
bash genbank2url.sh assembly_results.arabidopsis_thaliana.txt arabidopsis_thaliana.ftp_links.txt
```

Download the assemblies on `Octopus`:

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/athaliana/assemblies
cd /lizardfs/guarracino/seqwish-paper/athaliana/assemblies

# scp the `assembly_results.arabidopsis_thaliana.txt` and `arabidopsis_thaliana.ftp_links.txt` files
grep -f <(cut -f 1 assembly_results.arabidopsis_thaliana.txt) arabidopsis_thaliana.ftp_links.txt | while read f; do
  echo $f
  wget -c $f
done

# Check integrity
ls *gz | while read f; do echo $f; gzip -t $f; done
```

Trim headers and add prefixes:

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
zcat *.fa.gz | bgzip -@ 48 -c > athaliana16.fasta.gz; samtools faidx athaliana16.fasta.gz
```


## Explore the assemblies

Number of contigs (1st column) for each assembly:

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

Top distances:

```shell
sed 1,1d athaliana.mash_triangle.txt | tr '\t' '\n' | grep GCA -v | grep e -v | sort -g -k 1nr | head -n 5
0.016782
0.0151342
0.0146108
0.0143027
0.0143027
```

## All-vs-all alignment

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/athaliana/alignment/

ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/athaliana/assemblies/athaliana16.fasta.gz

for s in 20k 50k 100k; do
  for p in 98 95 90; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
    
    PAF=/lizardfs/guarracino/seqwish-paper/athaliana/alignment/athaliana16.s$s.l$l.p$p.n16.paf.gz
    sbatch -p workers -c 48 --job-name athaliana --wrap 'hostname; cd /scratch; \time -v ~/tools/wfmash/build/bin/wfmash-948f1683d14927745aef781cdabeb66ac6c7880b '$ASSEMBLIES' '$ASSEMBLIES' -X -s '$s' -l '$l' -p '$p' -n 16 -t 48 | pigz -c > '$PAF
  done
done
```

## Graph induction

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/athaliana/graphs/

ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/athaliana/assemblies/athaliana16.fasta.gz

for s in 100k 50k 20k; do
  for p in 90 95 98; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
    
    PAF=/lizardfs/guarracino/seqwish-paper/athaliana/alignment/athaliana16.s$s.l$l.p$p.n16.paf.gz
    for k in 0 11 29 49 79 127 179 229 311; do
      GFA=/scratch/athaliana16.s$s.l$l.p$p.n16.k$k.B50M.gfa
      LOG=/scratch/athaliana16.s$s.l$l.p$p.n16.k$k.B50M.size.log
      #sbatch -p 386mem -c 48 --job-name athaliana --wrap 'hostname; cd /scratch; \time -v ~/tools/seqwish/bin/seqwish-ccfefb016fcfc9937817ce61dc06bbcf382be75e -t 48 -s '$ASSEMBLIES' -p '$PAF' -g '$GFA' -k '$k' -B50M -P; mv '$GFA' /lizardfs/guarracino/seqwish-paper/athaliana/graphs/'
    
      sbatch -p 386mem -c 48 --job-name athaliana --wrap 'bash /lizardfs/guarracino/seqwish-paper/scripts/seqwish_with_logging.sh '$ASSEMBLIES' '$PAF' '$GFA' '$k' 50M '$LOG' 10; mv '$GFA' /lizardfs/guarracino/seqwish-paper/athaliana/graphs/; mv '$LOG' /lizardfs/guarracino/seqwish-paper/logs/'
    done
  done
done
```

## Statistics

```shell
for s in 20k 50k 100k; do
  for p in 98 95 90; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
    
    for k in 311 229 179 127 79 49 29 11 0; do
      GFA=/lizardfs/guarracino/seqwish-paper/athaliana/graphs/athaliana16.s$s.l$l.p$p.n16.k$k.B50M.gfa
      sbatch -p workers -c 12 --job-name athaliana_stats --wrap 'hostname; cd /scratch && ~/tools/odgi/bin/odgi-9e9c4811169760f64690e86619dbd1b088ec5955 build -g '$GFA' -o '$GFA'.og -t 12 -P; ~/tools/odgi/bin/odgi-9e9c4811169760f64690e86619dbd1b088ec5955 stats -i '$GFA'.og -S -b -L -W -t 12 -P > '$GFA'.og.stats.txt'
    done
  done
done

# Compress GFA files
ls /lizardfs/guarracino/seqwish-paper/athaliana/graphs/*.gfa | while read f; do echo $f; pigz $f; done
```
