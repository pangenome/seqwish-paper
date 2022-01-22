# HPRC plus

## Resources

The *de novo* assemblies can be found at https://github.com/human-pangenomics/HPP_Year1_Data_Freeze_v1.0.
To obtain from these assemblies the input FASTA files used in `seqwish` analyses, follow the instructions at https://github.com/pangenome/HPRCyear1v2genbank.

## Preparation and preprocessing

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/hprc_plus/assemblies
cd /lizardfs/guarracino/seqwish-paper/hprc_plus/assemblies
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
( ~/tools/fastix/target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834 -p 'chm13#' <(zcat chm13.draft_v1.1.fasta.gz) | bgzip -@ 48 -c >chm13.fa.gz ) &
wait
```

Remove unplaced contigs from grch38 that are (hopefully) represented in chm13:

```shell
samtools faidx grch38_full.fa $(cat grch38_full.fa.fai | cut -f 1 | grep -v _ ) | bgzip -@ 48 -c >grch38.fa.gz
```

Put all together:

```shell
zcat chm13.fa.gz grch38.fa.gz *genbank.fa.gz | bgzip -@ 48 -c > HPRC_plus.fa.gz && samtools faidx hprcplus38.fasta.gz
```

Cleaning:

```shell
rm chm13.draft_v1.1.fasta.gz GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz grch38_full.fa*
```

## Explore the assemblies

```shell
# guix install mash

(echo grch38.fa.gz; echo chm13.fa.gz; ls *genbank.fa.gz) | while read f; do mash sketch $f; done
assemblies=$(echo grch38.fa.gz; echo chm13.fa.gz; ls *genbank.fa.gz)
mash triangle $assemblies > hprcplus38.mash_triangle.txt
```

Top distances:

```shell
sed 1,1d hprcplus38.mash_triangle.txt | tr '\t' '\n' | grep GCA -v | grep e -v | sort -g -k 1nr | head -n 5
0.0026025
0.00257463
0.0025468
0.00251903
0.00251903
```

## All-vs-all alignment

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/hprc_plus/alignment

sbatch -p lowmem -c 48 --wrap 'cd /scratch && ~/tools/wfmash/build/bin/wfmash-948f1683d14927745aef781cdabeb66ac6c7880b /lizardfs/guarracino/seqwish-paper/hprc_plus/assemblies/hprcplus38.fasta.gz /lizardfs/guarracino/seqwish-paper/hprc_plus/assemblies/hprcplus38.fasta.gz -X -s 100k -l 300k -p 98 -n 38 -k 16 -t 48 | pigz -c > /lizardfs/guarracino/seqwish-paper/hprc_plus/alignment/hprcplus38.s100k.l300k.p98.n38.k16.paf.gz'
```

## Graph induction

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/hprc_plus/graphs

ASSEMBLIES=/lizardfs/guarracino/seqwish-paper/hprc_plus/assemblies/hprcplus38.fasta.gz
PAF=/lizardfs/guarracino/seqwish-paper/hprc_plus/alignment/hprcplus38.s100k.l300k.p98.n38.k16.paf.gz

(echo 311; echo 229; echo 179; echo 127; echo 79; echo 49; echo 29; echo 11; echo 0;) | while read k; do
  GFA=/scratch/hprcplus38.s100k.l300k.p98.n38.k$k.B50M.gfa
  LOG=/scratch/hprcplus38.s100k.l300k.p98.n38.k$k.B50M.size.log
  #sbatch -p 386mem -c 48 --job-name seqwk$k --wrap 'hostname; cd /scratch && \time -v ~/tools/seqwish/bin/seqwish-ccfefb016fcfc9937817ce61dc06bbcf382be75e -t 48 -s /lizardfs/guarracino/seqwish-paper/hprc_plus/assemblies/hprcplus38.fasta.gz -p /lizardfs/guarracino/seqwish-paper/hprc_plus/alignment/hprcplus38.s100k.l300k.p98.n38.k16.paf.gz -k '$k' -B 50M -g hprcplus38.s100k.l300k.p98.n38.k'$k'.B50M.gfa -P && mv hprcplus38.s100k.l300k.p98.n38.k'$k'.B50M.gfa /lizardfs/guarracino/seqwish-paper/hprc_plus/graphs/';
  
  sbatch -p 386mem -c 48 --job-name hprcplus --wrap 'bash /lizardfs/guarracino/seqwish-paper/scripts/seqwish_with_logging.sh '$ASSEMBLIES' '$PAF' '$GFA' '$k' 50M '$LOG' 10; mv '$GFA' /lizardfs/guarracino/seqwish-paper/hprc_plus/graphs/; mv '$LOG' /lizardfs/guarracino/seqwish-paper/logs/'
done
```

## Statistics

```shell
(echo 311; echo 229; echo 179; echo 127; echo 79; echo 49; echo 29; echo 11; echo 0) | while read k; do
  GFA=/lizardfs/guarracino/seqwish-paper/hprc_plus/graphs/hprcplus38.s100k.l300k.p98.n38.k$k.B50M.gfa
  sbatch -p workers -c 48 --job-name odgik$k --wrap 'hostname; cd /scratch && ~/tools/odgi/bin/odgi-9e9c4811169760f64690e86619dbd1b088ec5955 build -g '$g' -o '$g'.og -t 48 -P; ~/tools/odgi/bin/odgi-67a7e5bb2f328888e194845a362cef9c8ccc488f stats -i '$g'.og -S -b -L -W -t 48 -P > '$g'.og.stats.txt';
done

# Compress GFA files
ls /lizardfs/guarracino/seqwish-paper/hprc_plus/graphs/*.gfa | while read f; do echo $f; pigz $f; done
```
