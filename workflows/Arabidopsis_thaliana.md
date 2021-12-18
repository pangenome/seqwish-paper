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
      sbatch -p workers -c 48 --wrap 'cd /scratch; \time -v ~/tools/wfmash/build/bin/wfmash-09e73eb3fcf24b8b7312b8890dd0741933f0d1cd '$ASSEMBLIES' '$ASSEMBLIES' -X -s '$s' -l '$l' -p '$p' -n 9 -t 48 > '$PAF'; \time -v ~/tools/seqwish/bin/seqwish-ccfefb016fcfc9937817ce61dc06bbcf382be75e -f '$ASSEMBLIES' -p '$PAF' -g '$GFA' -k '$k' -B50M -P'
    done
  done
done

```

