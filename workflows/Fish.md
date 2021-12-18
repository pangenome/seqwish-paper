# Fish

## Download the assemblies

Install `sudo apt install ncbi-entrez-direct` and then get all the links for the download:

```shell
bash genbank2url.sh assembly.fish.txt fish.ftp_links.txt
```

Download the assemblies on `Octopus`:

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

Number of contigs (1st column) for each assemblies:

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

