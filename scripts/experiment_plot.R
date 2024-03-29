#!/usr/bin/env Rscript

require(tidyverse)
require(ggrepel)

x <- read.delim('stats/stats.tsv')

ggplot(subset(x, input.fasta=="athaliana16" & min.mapping.len=="l60k" | input.fasta=="hprcplus38" | input.fasta=="hpylori250" & min.mapping.len=="l15k" & seqwish.B=="B50M" | input.fasta=="zmays41" & min.mapping.len=="l60k"),
       aes(x=graph.length.Gbps/(Gbps/n), y=time.seconds/3600, shape=map.ident, color=as.factor(k), label=min.mapping.len)) +
geom_point() +
facet_wrap(~input.fasta, scales="free") +
scale_x_continuous("graph length / average genome length") +
scale_y_continuous("runtime (hours)") +
scale_color_discrete("seqwish -k") +
scale_shape_discrete("wfmash -p")
#+ geom_text_repel(size=2)

ggsave("manuscript/fig_experiment_stats.pdf", height=4, width=5.5)
