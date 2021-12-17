# Zea mays

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

Go to `https://www.ncbi.nlm.nih.gov/assembly/?term=txid4577%5BOrganism%3Anoexp%5D`, set the filters 
(`Latests`, `Chromosome`, `Exclude partial`, `Exclude anomalous`, click `Send to`, `File`, `Format ID Table (text`), 
`Sort by Accession`, `Create File`. Rename the file from `assembly_results.txt` to `assembly_results.zea_mays.txt`.

Install `sudo apt install ncbi-entrez-direct` and then get all the links for the download:

```shell
bash genbank2url.sh assembly_results.zea_mays.txt zea_mays.ftp_links.txt
```

Then, download the assemblies on `Octopus`:

```shell
mkdir -p /lizardfs/guarracino/seqwish-paper/zea/assemblies
cd /lizardfs/guarracino/seqwish-paper/zea/assemblies

# scp the `zea_mays.ftp_links.txt` file
cat zea_mays.ftp_links.txt | while read f; do
  echo $f
  wget -c $f
done

# Check integrity
ls *gz | while read f; do echo $f; gzip -t $f; done
```


