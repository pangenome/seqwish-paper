# Fish

## Download the assemblies

Install `sudo apt install ncbi-entrez-direct` and then get all the links for the download:

```shell
bash genbank2url.sh assembly.fish.txt fish.ftp_links.txt
```

Download the assemblies:

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/fish/assemblies
cd /lizardfs/guarracino/seqwish-paper/fish/assemblies

# scp the `assembly.fish.txt` and `fish.ftp_links.txt` files
grep -f assembly.fish.txt fish.ftp_links.txt | while read f; do
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
zcat *.fa.gz | bgzip -@ 48 -c > fish12.fasta.gz; samtools faidx fish12.fasta.gz
```


## Explore the assemblies

Number of contigs (1st column) for each assembly:

```shell
wc *fa.gz.fai
   189    945  10083 GCA_007364275.2.fa.gz.fai
   468   2340  24747 GCA_009762535.1.fa.gz.fai
   139    695   7698 GCA_015220745.1.fa.gz.fai
    93    465   5089 GCA_017639745.1.fa.gz.fai
   249   1245  13223 GCA_900246225.5.fa.gz.fai
   442   2210  24770 GCA_900634775.2.fa.gz.fai
   202   1010  11303 GCA_902148845.1.fa.gz.fai
    87    435   4774 GCA_902150065.1.fa.gz.fai
    30    150   1610 GCA_902362185.1.fa.gz.fai
   755   3775  42733 GCA_903684855.2.fa.gz.fai
    65    325   3547 GCA_904848185.1.fa.gz.fai
   219   1095  12229 GCA_905171665.1.fa.gz.fai
  2938  14690 161806 total
```

Distances:

```shell
# guix install mash

ls *.fa.gz | while read f; do mash sketch $f; done
mash triangle *.fa.gz >fish.mash_triangle.txt
```

Top distances:

```shell
sed 1,1d fish.mash_triangle.txt | tr '\t' '\n' | grep GCA -v | grep e -v | sort -g -k 1nr | head -n 5
0.295981
0.263022
0.263022
0.263022
0.263022
```

## All-vs-all alignment

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/fish/alignment

ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/fish/assemblies/fish12.fasta.gz

### Approximate mapping
for s in 50k 20k; do
  for p in 85 80 75; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
    
    APPROX_PAF=/lizardfs/guarracino/seqwish-paper/fish/alignment/fish12.s$s.l$l.p$p.n12.approx.paf.gz
    sbatch -p workers -c 48 --job-name fish --wrap 'hostname; cd /scratch; \time -v ~/tools/wfmash/build/bin/wfmash-948f1683d14927745aef781cdabeb66ac6c7880b '$ASSEMBLIES' '$ASSEMBLIES' -X -s '$s' -l '$l' -p '$p' -n 12 -t 48 -m | pigz -c > '$APPROX_PAF
  done
done

### Alignment
#for s in 50k 20k; do
#  for p in 85 80 75; do
for s in 20k; do
  for p in 85; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
    
    APPROX_PAF=/lizardfs/guarracino/seqwish-paper/fish/alignment/fish12.s$s.l$l.p$p.n12.approx.paf.gz
    UNFILTERED_PAF=/lizardfs/guarracino/seqwish-paper/fish/alignment/fish12.s$s.l$l.p$p.n12.paf.gz
    #sbatch -p workers -c 48 --job-name fish --wrap 'hostname; cd /scratch; \time -v ~/tools/wfmash/build/bin/wfmash-948f1683d14927745aef781cdabeb66ac6c7880b '$ASSEMBLIES' '$ASSEMBLIES' -X -s '$s' -l '$l' -p '$p' -n 12 -t 48 -i '$APPROX_PAF' -b 1 | pigz -c > '$UNFILTERED_PAF
    
    DIR_WFPLOTS=/lizardfs/guarracino/seqwish-paper/fish/alignment/fish12.s$s.l$l.p$p.n12/
    mkdir -p ${DIR_WFPLOTS}
    sbatch -p workers -c 48 --job-name fish --wrap 'hostname; \time -v ~/tools/wfmash/build/bin/wfmash-wfplots '$ASSEMBLIES' '$ASSEMBLIES' -X -s '$s' -l 0 -p '$p' -n 12 -t 48 -i '$APPROX_PAF' -b 1 -u '$DIR_WFPLOTS' -z 5000 | pigz -c > '$UNFILTERED_PAF
  done
done

### Filtering
for s in 20k; do
  for p in 85; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
    
    p_threshold=$(echo "scale=2; $p/100.0" | bc)
    
    UNFILTERED_PAF=/lizardfs/guarracino/seqwish-paper/fish/alignment/fish12.s$s.l$l.p$p.n12.paf.gz
    PAF=/lizardfs/guarracino/seqwish-paper/fish/alignment/fish12.s$s.l$l.p$p.n12.filtered.paf.gz
    
    zcat $UNFILTERED_PAF | awk -v p=$p_threshold '{split($13, gi, /:/); if(gi[3] >= p) {print $0}}' | pigz -c > $PAF
  done
done
```

## Graph induction

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/fish/graphs/

ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/fish/assemblies/fish12.fasta.gz

for s in 50k; do
  for p in 85 80; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k
    
    PAF=/lizardfs/guarracino/seqwish-paper/fish/alignment/fish12.s$s.l$l.p$p.n12.paf.gz
    for k in 311 229 179 127 79 49 29 11 0; do
      GFA=/scratch/fish12.s$s.l$l.p$p.n12.k$k.B50M.gfa
      LOG=/scratch/fish12.s$s.l$l.p$p.n12.k$k.B50M.size.log
      #sbatch -p 386mem -c 48 --job-name fish --wrap 'hostname; cd /scratch; \time -v ~/tools/seqwish/bin/seqwish-ccfefb016fcfc9937817ce61dc06bbcf382be75e -t 48 -s '$ASSEMBLIES' -p '$PAF' -g '$GFA' -k '$k' -B50M -P; mv '$GFA' /lizardfs/guarracino/seqwish-paper/fish/graphs/'
    
      sbatch -p 386mem -c 48 --job-name fish --wrap 'bash /lizardfs/guarracino/seqwish-paper/scripts/seqwish_with_logging.sh '$ASSEMBLIES' '$PAF' '$GFA' '$k' 50M '$LOG' 10; mv '$GFA' /lizardfs/guarracino/seqwish-paper/fish/graphs/; mv '$LOG' /lizardfs/guarracino/seqwish-paper/logs/'
    done
  done
done
```

## Statistics

```shell
for s in 50k; do
  for p in 85 80; do
    s_no_k=${s::-1}
    l_no_k=$(echo $s_no_k '*' 3 | bc)
    l=${l_no_k}k

    for k in 311 229 179 127 79 49 29 11 0; do
      GFA=/lizardfs/guarracino/seqwish-paper/fish/graphs/fish12.s$s.l$l.p$p.n12.k$k.B50M.gfa
      sbatch -p workers -c 24 --job-name fish_stats --wrap 'hostname; cd /scratch && ~/tools/odgi/bin/odgi-67a7e5bb2f328888e194845a362cef9c8ccc488f stats -i '$GFA' -S -b -L -W -t 24 -P > '$GFA'.og.stats.txt';
    done
  done
done

# Compress GFA files
ls /lizardfs/guarracino/seqwish-paper/fish/graphs/*.gfa | while read f; do echo $f; pigz $f; done
```
