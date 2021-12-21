# seqwish-paper


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


## tools to run the workflows

```shell
mkdir -p ~/tools $$ cd ~/tools

git clone --recursive https://github.com/ekg/fastix.git
cd fastix
git checkout 331c1159ea16625ee79d1a82522e800c99206834
cargo build --release
mv target/release/fastix target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834
cd ..

git clone --recursive https://github.com/ekg/wfmash.git
cd wfmash
git checkout 948f1683d14927745aef781cdabeb66ac6c7880b
cmake -H. -Bbuild && cmake --build build -- -j 48
mv build/bin/wfmash build/bin/wfmash-948f1683d14927745aef781cdabeb66ac6c7880b
cd ..

git clone --recursive https://github.com/ekg/seqwish.git
cd seqwish
git checkout ccfefb016fcfc9937817ce61dc06bbcf382be75e
cmake -H. -Bbuild && cmake --build build -- -j 48
mv bin/seqwish bin/seqwish-ccfefb016fcfc9937817ce61dc06bbcf382be75e
cd ..

git clone --recursive https://github.com/pangenome/odgi.git
cd odgi
git checkout 9e9c4811169760f64690e86619dbd1b088ec5955
cmake -H. -Bbuild && cmake --build build -- -j 48
mv bin/odgi bin/odgi-9e9c4811169760f64690e86619dbd1b088ec5955
cd ..
```

## Bioinformatics - Instructions to Authors

https://academic.oup.com/bioinformatics/pages/instructions_for_authors

Original Papers (up to 7 pages; this is approx. 5,000 words. excluding figures)
The abstracts should be succinct and contain only material relevant to the headings. A maximum of 150 words is
recommended.

Application Notes (up to 2 pages; this is approx. 1,300 words or 1,000 words plus one figure)
Abstracts for Applications Notes are much shorter than those for an Original Paper. They are structured with four
headings: Summary, Availability and Implementation, Contact and Supplementary Information.
