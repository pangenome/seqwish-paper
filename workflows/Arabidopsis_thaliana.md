# Arabidopsis thaliana

## Tools

```shell
mkdir -p ~/tools $$ cd ~/tools

git clone --recursive https://github.com/ekg/fastix.git
cd fastix
git checkout 331c1159ea16625ee79d1a82522e800c99206834
cargo build --release
mv target/release/fastix target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834
cd ..
```


## Download the assemblies

Go to `https://www.ncbi.nlm.nih.gov/assembly/?term=txid3702%5BOrganism%3Anoexp%5D`, set the filters
(`Latests`, `Chromosome`, `Exclude partial`, `Exclude anomalous`, click `Send to`, `File`, `Format ID Table (text`),
`Sort by Accession`, `Create File`. Rename the file from `assembly_results.txt` to `assembly_results.arabidopsis_thaliana.txt`.

Install `sudo apt install ncbi-entrez-direct` and then get all the links for the download:

```shell
bash genbank2url.sh assembly_results.arabidopsis_thaliana.txt arabidopsis_thaliana.ftp_links.txt
```

Then, download the assemblies on `Octopus`:

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/arabidopsis/assemblies
cd /lizardfs/guarracino/seqwish-paper/arabidopsis/assemblies

# scp the `arabidopsis_thaliana.ftp_links.txt` file
cat arabidopsis_thaliana.ftp_links.txt | while read f; do
  echo $f
  wget -c $f
done

# Check integrity
ls *gz | while read f; do echo $f; gzip -t $f; done
```





















Reference:

```shell
wget -c https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/735/GCA_000001735.2_TAIR10.1/GCA_000001735.2_TAIR10.1_genomic.fna.gz
mv GCA_000001735.2_TAIR10.1_genomic.fna.gz TAIR10_1.genomic.fasta.gz
```

7 assemblies from https://www.nature.com/articles/s41467-020-14779-y:

```shell
wget -c https://1001genomes.org/data/MPIPZ/MPIPZJiao2020/releases/current/full_set/AMPRIL.genomes.version2.5.2019-10-09.tar.gz

tar -xvzf AMPRIL.genomes.version2.5.2019-10-09.tar.gz
mv version2.5.2019-10-09/*all.v2.0.fasta.gz .

rm AMPRIL.genomes.version2.5.2019-10-09.tar.gz
rm -rf version2.5.2019-10-09
```

1 assembly from https://www.sciencedirect.com/science/article/pii/S1672022921001741:

```shell
# Col-XJTU
wget --no-check-certificate -c https://download.cncb.ac.cn/gwh/Plants/Arabidopsis_thaliana_AT_GWHBDNP00000000.1/GWHBDNP00000000.1.genome.fasta.gz

# Trim headers
zcat GWHBDNP00000000.1.genome.fasta.gz | cut -f 1 | pigz -c > GWHBDNP00000000_1.fasta.gz

rm GWHBDNP00000000.1.genome.fasta.gz
```

From the Max Planck Institute for Developmental Biology:

```shell
wget -c https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/903/064/275/GCA_903064275.1_AT7213.Ler-0.PacBio/GCA_903064275.1_AT7213.Ler-0.PacBio_genomic.fna.gz
wget -c https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/903/064/325/GCA_903064325.1_AT7186.Kn-0.PacBio/GCA_903064325.1_AT7186.Kn-0.PacBio_genomic.fna.gz
wget -c https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/903/064/315/GCA_903064315.1_AT6911.Cvi-0.contigs/GCA_903064315.1_AT6911.Cvi-0.contigs_genomic.fna.gz
wget -c https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/903/064/295/GCA_903064295.1_AT5784.Ty-1.PacBio/GCA_903064295.1_AT5784.Ty-1.PacBio_genomic.fna.gz
wget -c https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/903/064/285/GCA_903064285.1_AT1741.KBS-Mac-74.PacBio/GCA_903064285.1_AT1741.KBS-Mac-74.PacBio_genomic.fna.gz
wget -c https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/902/825/305/GCA_902825305.1_AT6909.Col-0.PacBio/GCA_902825305.1_AT6909.Col-0.PacBio_genomic.fna.gz
```


Add prefixes:

```shell
ls *.fasta.gz | while read f; do
  prefix=$(echo $f | cut -f 1 -d '.');
  echo $prefix
  ~/tools/fastix/target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834 -p "${prefix}#" <(zcat $f) | bgzip -@ 48 -c > $prefix.fa.gz;
  samtools faidx $prefix.fa.gz
done

  rm $f
```


Number of contigs (1st column) for each assemblies:

```shell
wc *fai

  111   555  3813 An-1.fa.gz.fai
   99   495  3283 C24.fa.gz.fai
  102   510  3381 Cvi.fa.gz.fai
  142   710  4739 Eri.fa.gz.fai
    5    25   305 GWHBDNP00000000_1.fa.gz.fai
  184   920  6153 Kyo.fa.gz.fai
  105   525  3500 Ler.fa.gz.fai
   94   470  3150 Sha.fa.gz.fai
    7    35   300 TAIR10_1.fa.gz.fai
  849  4245 28624 total
```

Put all together:

```shell
zcat *fa.gz | bgzip -@ 48 -c > arabidopsis.fasta.gz; samtools faidx arabidopsis.fasta.gz
```

```shell
# guix install mash

cd /lizardfs/guarracino/seqwish-paper/arabidopsis/assemblies
ls *.fa.gz | while read f; do mash sketch $f; done
mash triangle *.fa.gz >9_asemblies.mash_triangle.txt
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

