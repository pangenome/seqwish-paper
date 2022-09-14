# Yeast chrV example of order bias

Get the data, which consist of chrV from S. cerevisiae assembled in [Yue et. al. 2017](https://doi.org/10.1038/ng.3847).

```shell
wget http://hypervolu.me/~erik/yeast/cerevisiae.chrV.fa
samtools faidx cerevisiae.chrV.fa
```

## divergence estimate

These have relatively low pairwise divergence:

```shell
ls *.fa | while read f; do mash sketch $f; done
mash triangle *.msh  | column -t  | tr ' ' '\n'  | grep ^0 | awk '{ sum += $1 } END { print sum/NR }'
# 0.00676819
```

We can estimate that the pairwise identity is ~99.32%.

## permutations

You'll also want to build the [multipermute](https://github.com/ekg/multipermute) command line tool.

We use this to make all possible permutations of cerevisiae chrVs.

```shell
cat ~/yeast/cerevisiae.chrV.fa.fai | cut -f 1 | while read f; do samtools faidx ~/yeast/cerevisiae.chrV.fa $f >$f.fa; done
~/multipermute/multipermute $(cat ~/yeast/cerevisiae.chrV.fa.fai | cut -f 1 | while read f; do echo -n ' '$f.fa; done) >orders.txt
```

We keep 100 random permutations for faster testing. This workflow is a proof of principle.

```shell
shuf --random-source=<(yes 42) orders.txt | head -100 >100_orders.txt
```

## graph builds

For each of the subset of permutations, we run minigraph v0.19, commit 86192499e80377df47993cb376e4773d4a7a76db.
This uses progressive alignment to generate a graph.
By changing the order of genome inclusion, we change both the base reference and the order in which variation in the genomes is discovered and added to the graph.

```shell
cat 100_orders.txt | awk '{ print "minigraph -c --ggen", $0, ">order"NR".gfa && " }' | while read f; do sh -c $f; done
```

For comparison, we generate seqwish graphs based on several alignment strategies.

First, minimap2 v2.24, commit 15cade0f067f669083805e3f9f7115b5d091309f, with a 1kb length filter.

```shell
cat 100_orders.txt | awk '{ print "cat", $0, ">x.fa && samtools faidx x.fa && minimap2 -t 16 -c --eqx -x asm20 -X -N 6 x.fa x.fa | fpa drop -l 1000 >x.paf && cp x.paf mm2_order"NR".paf && seqwish -t 16 -p x.paf -s x.fa -g seqwish_mm2_order"NR".gfa" }' | while read f; do sh -c $f; done
```

Second, wfmash, commit 0b11c8a5ab30cbd5a7247c6c0da017b1f4910d41 (master branch), running the alignment for each order.

```shell
cat 100_orders.txt | awk '{ print "cat", $0, ">x.fa && samtools faidx x.fa && wfmash -n 6 -t 16 x.fa >x.paf && cp x.paf wfmash_order"NR".paf && seqwish -t 16 -p x.paf -s x.fa -g seqwish_wf_order"NR".gfa" }' | while read f; do sh -c $f; done
```

Third, wfmash, commit 0b11c8a5ab30cbd5a7247c6c0da017b1f4910d41 (master branch), using a single collection of all-vs-all alignments established by pairwise alignment of all chromosomes to each other.

```shell
ls *.fa | while read a; do ls *.fa | while read b; do echo $a $b; done; done | while read x; do sh -c "wfmash -t 16 $x"; done >wfmash_all_vs_all.paf
100_orders.txt | awk '{ print "cat", $0, ">x.fa && samtools faidx x.fa && seqwish -t 16 -p wfmash_all_vs_all.paf -s x.fa -g seqwish_wf-ava_order"NR".gfa" }' | while read f; do sh -c $f; done
```

Fourth, wfmash, commit 013065a6a12fdbbff401585534266d393c006e93 (biwflambda branch), the current development branch for the wfmash manuscript.

```shell
cat 100_orders.txt | awk '{ print "cat", $0, ">x.fa && samtools faidx x.fa && wfmash -n 6 -t 16 x.fa >x.paf && cp x.paf wfmash-biwfaλ_order"NR".paf && seqwish -t 16 -p x.paf -s x.fa -g seqwish-biwfaλ_order"NR".gfa" }' | while read f; do sh -c $f; done
```

Fifth, [TwoPaCo](https://github.com/medvedevgroup/TwoPaCo) with `-k 19`, commit 2c46b3073b89124063c7619b3587482ef945b5f8.

```shell
cat 100_orders.txt | awk '{ print "cat", $0, ">x.fa && samtools faidx x.fa && twopaco -t 16 -f 4 -k 19 x.fa -o x.bin && graphdump x.bin -f gfa1 -k 19 -s x.fa | grep 'UR:Z:' -v > twopaco_order"NR".gfa" }' | while read f; do echo $f; sh -c $f; done
```

## collecting results

Finally, we'll bring all these outputs together, measuring graph properties such as size and node count to see if there is variation in graph structure.

```shell
( echo 'method length nodes edges paths steps' | tr ' ' '\t'; seq 100 | while read i; do echo minigraph $(sed 's/\ts/\t/g' minigraph_order$i.gfa >x.gfa && odgi build -g x.gfa -o - | odgi stats -i - -S | tail -n+2); done ; seq 100 | while read i ; do echo seqwish.mm2 $(odgi build -g seqwish_mm2_order$i.gfa -o - | odgi stats -i - -S | tail -n+2); done ; seq 100 | while read i ; do echo seqwish.wfm $(odgi build -g seqwish_wf_order$i.gfa -o - | odgi stats -i - -S | tail -n+2); done  ; seq 100 | while read i ; do echo seqwish.wfava $(odgi build -g seqwish_wf-ava_order$i.gfa -o - | odgi stats -i - -S | tail -n+2); done  ;  seq 100 | while read i ; do echo seqwish.biwfl $(odgi build -g seqwish-biwfaλ_order$i.gfa -o - | odgi stats -i - -S | tail -n+2); done; seq 100 | while read i ; do echo twopaco.k19 $(odgi build -g twopaco_order$i.gfa -o - | odgi stats -i - -S | tail -n+2); done ) | tr ' ' '\t' >results.tsv
paste results.tsv <(echo ref; for i in 1 2 3 4 5 6; do cat 100_orders.txt | cut -f 1 -d\  | awk '{ print $0 }' ; done ) >x.tsv
```

## plotting results

We plot the distribution of length across the different methods (excluding TwoPaCo, which is much larger than the others for reasons unclear).
Although two graphs can be different topologically and yet have the same length, this metric should show us gross changes in graph size that might correlate with the addition or subtraction of structural variant alleles.
For simplicity, we focus just on `minigraph`, `seqwish`+`minimap2`, and `seqwish`+`wfmash`.

```R
x <- read.delim('x.tsv')
x$method <- as.factor(x$method)
summary(x)
require(tidyverse)
ggplot(subset(x, method!="twopaco.k19" & method!="seqwish.wfava" & method!="seqwish.biwfl"), aes(y=length, x=method, color=ref)) + geom_boxplot() + geom_quasirandom(alpha=I(1/5)) + scale_color_discrete("first genome (reference)") + theme(axis.text.x = element_text(angle = 45, vjust=1, hjust=1)) ; ggsave("yeast_chrV_length_vs_100orders.png", height=4, width=6)
ggsave("yeast_chrV_length_vs_100orders.pdf", height=4, width=4)
```

<img src="https://raw.githubusercontent.com/pangenome/seqwish-paper/master/manuscript/yeast_chrV_length_vs_100orders.png" alt="chrV yeast order permutation results" height=30% width=30%>

We can also summarize the variance by category.

```R
subset(x, method!="seqwish.wfava" & method!="seqwish.biwfl") %>% group_by(method) %>% summarise(m = mean(length), sd = sqrt(var(length)))
```

This shows that the `minigraph` set has a standard deviation of 8112bp, which corresponds to about 1.2% of the graph length.
In contrast, both `TwoPaCo` and `seqwish`+`wfmash` are perfectly stable with respect to input genome order.
Curiously, the `minimap2`+`seqwish` graphs are also not stable to input genome order, indicating some dependence on order in the mapping step, although this effect is very small (sd=4bp).

```txt
  method             m      sd
  <fct>          <dbl>   <dbl>
1 minigraph    648967. 8112.
2 seqwish.mm2  609039.    4.08
3 seqwish.wfm  683470     0
4 twopaco.k19 1270115     0
```

The result shows that `minigraph`'s total length changes significantly based on which genome we begin with, and also with respect to the particular permutation of all genomes.

Both `seqwish` and `TwoPaCo` appear unbiased with respect to genome order.
`seqwish` is only unbiased if the input alignments are invariant with respect to the order of sequences in the FASTA given to the aligner.
`TwoPaCo` is also unbiased with respect to input genome order, but it returns a 1,270,115bp graph, while the other methods return graphs that are less than 700kbp.
