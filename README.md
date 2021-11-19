# seqwish-paper

## resources

The *de novo* assemblies can be found at https://github.com/human-pangenomics/HPP_Year1_Data_Freeze_v1.0.
To obtain from these assemblies the input FASTA files used in `seqwish` analyses, follow the instructions at https://github.com/pangenome/HPRCyear1v2genbank.

## building the manuscript

```bash
# Dependencies
sudo apt-get -y install texlive texlive-latex-recommended \
        texlive-pictures texlive-latex-extra texlive-fonts-extra \
        texlive-science

sudo apt install graphviz

git clone https://github.com/pangenome/seqwish-paper
cd seqwish-paper/manuscript && make -k
```

## Bioinformatics - Instructions to Authors

https://academic.oup.com/bioinformatics/pages/instructions_for_authors

Original Papers (up to 7 pages; this is approx. 5,000 words. excluding figures)
The abstracts should be succinct and contain only material relevant to the headings. A maximum of 150 words is
recommended.

Application Notes (up to 2 pages; this is approx. 1,300 words or 1,000 words plus one figure)
Abstracts for Applications Notes are much shorter than those for an Original Paper. They are structured with four
headings: Summary, Availability and Implementation, Contact and Supplementary Information.
