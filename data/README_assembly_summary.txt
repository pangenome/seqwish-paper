################################################################################
README for the assembly_summary_genbank.txt, assembly_summary_refseq.txt and 
assembly_summary.txt files found on the NCBI genomes FTP site:
  ftp://ftp.ncbi.nlm.nih.gov/genomes 

Last updated: October 28, 2021
################################################################################

======================
ASSEMBLY SUMMARY FILES
======================

The assembly_summary files report metadata for the genome assemblies on the 
NCBI genomes FTP site.

Four master files reporting data for either GenBank or RefSeq genome assemblies 
are available under ftp://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS/
assembly_summary_genbank.txt            - current GenBank genome assemblies
assembly_summary_genbank_historical.txt - replaced and suppressed GenBank genome
                                          assemblies
assembly_summary_refseq.txt             - current RefSeq genome assemblies
assembly_summary_refseq_historical.txt  - replaced and suppressed RefSeq genome
                                          assemblies

assembly_summary_genbank.txt and assembly_summary_genbank_historical.txt are 
also available at:
ftp://ftp.ncbi.nlm.nih.gov/genomes/genbank/assembly_summary_genbank.txt
ftp://ftp.ncbi.nlm.nih.gov/genomes/genbank/assembly_summary_genbank_historical.txt


assembly_summary_refseq.txt and assembly_summary_refseq_historical.txt are 
also available at:
ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/assembly_summary_refseq.txt
ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/assembly_summary_refseq_historical.txt

The assembly_summary.txt files in the directories named for taxonomic groups or
species contain the relevant subsets of the data from the master files.


=====================
COLUMN SPECIFICATIONS
=====================

The assembly_summary.txt files have 22 tab-delimited columns. 
Header rows begin with '#".

Column  1: "assembly_accession"
   Assembly accession: the assembly accession.version reported in this field is 
   a unique identifier for the set of sequences in this particular version of 
   the genome assembly.
  
Column  2: "bioproject"
   BioProject: accession for the BioProject which produced the sequences in the 
   genome assembly. A BioProject is a collection of biological data related to a
   single initiative, originating from a single organization or from a 
   consortium. A BioProject record provides users a single place to find links 
   to the diverse data types generated for that project. The record can be 
   retrieved from the NCBI BioProject resource:
   https://www.ncbi.nlm.nih.gov/bioproject/
   
Column  3: "biosample"
   BioSample: accession for the BioSample from which the sequences in the genome
   assembly were obtained. A BioSample record contains a description of the 
   biological source material used in experimental assays. The record can be 
   retrieved from the NCBI BioSample resource:
   https://www.ncbi.nlm.nih.gov/biosample/
   
Column  4: "wgs_master"
   WGS-master: the GenBank Nucleotide accession and version for the master 
   record of the Whole Genome Shotgun (WGS) project for the genome assembly. The
   master record can be retrieved from the NCBI Nucleotide resource: 
   https://www.ncbi.nlm.nih.gov/nuccore
   Genome assemblies that are complete genomes, and those that are clone-based,
   do not have WGS-master records in which case this field will be empty.
   
Column  5: "refseq_category"
   RefSeq Category: whether the assembly is a reference or representative genome
   in the NCBI Reference Sequence (RefSeq) project classification. 
   Values:
           reference genome      - a manually selected high quality genome 
                                   assembly that NCBI and the community have 
                                   identified as being important as a standard 
                                   against which other data are compared
           representative genome - a genome computationally or manually selected
                                   as a representative from among the best 
                                   genomes available for a species or clade that
                                   does not have a designated reference genome
           na                    - no RefSeq category assigned to this assembly
   Prokaryotes may have more than one reference or representative genome per 
   species. For more information see: 
   https://www.ncbi.nlm.nih.gov/refseq/about/prokaryotes/#referencegenome
   Eukaryotes have no more than one reference or representative genome per 
   species. If there are no assemblies in RefSeq for a particular eukaryotic 
   species, then the GenBank assembly that RefSeq would select as the best 
   available for that species will be designated as the representative genome.
   Viruses may have one or more reference genomes per species. The 
   representative genome designation is not applied to viruses.

Column  6: "taxid"
   Taxonomy ID: the NCBI taxonomy identifier for the organism from which the 
   genome assembly was derived. The NCBI Taxonomy Database is a curated 
   classification and nomenclature for all of the organisms in the public 
   sequence databases. The taxonomy record can be retrieved from the NCBI 
   Taxonomy resource:
   https://www.ncbi.nlm.nih.gov/taxonomy/
   
Column  7: "species_taxid"
   Species taxonomy ID: the NCBI taxonomy identifier for the species from which 
   the genome assembly was derived. The species taxid will differ from the 
   organism taxid (column 6) only when the organism was reported at a sub-
   species or strain level.
   
Column  8: "organism_name"
   Organism name: the scientific name of the organism from which the sequences 
   in the genome assembly were derived. This name is taken from the NCBI 
   Taxonomy record for the taxid specified in column 6. Some older taxids were 
   assigned at the strain level and for these the organism name will include the
   strain. Current practice is only to assign taxids at the species level; for 
   these the organism name will be just the species, however, the strain name 
   will be reported in the infraspecific_name field (column 9).

Column  9: "infraspecific_name"
   Infraspecific name: the strain, breed, cultivar or ecotype of the organism 
   from which the sequences in the genome assembly were derived. Data are 
   reported in the form tag=value, e.g. strain=AF16. Strain, breed, cultivar 
   and ecotype are not expected to be used together, however, if they are then 
   they will be reported in a list separated by ", /". Empty if no strain, 
   breed, cultivar or ecotype is specified on the genomic sequence records.
  
Column 10: "isolate"
   Isolate: the individual isolate from which the sequences in the genome 
   assembly were derived. Empty if no isolate is specified on the genomic 
   sequence records.

Column 11: "version_status"
   Version status: the release status for the genome assembly version.
   Values:
           latest     - the most recent of all the versions for this assembly 
                        chain
           replaced   - this version has been replaced by a newer version of the
                        assembly in the same chain
           suppressed - this version of the assembly has been suppressed 
   An assembly chain is the collection of all versions for the same assembly 
   accession.

Column 12: "assembly_level"
   Assembly level: the highest level of assembly for any object in the genome 
   assembly.
   Values:
      Complete genome - all chromosomes are gapless and have no runs of 10 or 
                        more ambiguous bases (Ns), there are no unplaced or 
                        unlocalized scaffolds, and all the expected chromosomes
                        are present (i.e. the assembly is not noted as having 
                        partial genome representation). Plasmids and organelles
                        may or may not be included in the assembly but if 
                        present then the sequences are gapless.
      Chromosome      - there is sequence for one or more chromosomes. This 
                        could be a completely sequenced chromosome without gaps
                        or a chromosome containing scaffolds or contigs with 
                        gaps between them. There may also be unplaced or 
                        unlocalized scaffolds.
      Scaffold        - some sequence contigs have been connected across gaps to
                        create scaffolds, but the scaffolds are all unplaced or 
                        unlocalized.
      Contig          - nothing is assembled beyond the level of sequence 
                        contigs

Column 13: "release_type"
   Release type: whether this version of the genome assembly is a major, minor 
   or patch release.
   Values:
           Major - changes from the previous assembly version result in a 
                   significant change to the coordinate system. The first 
                   version of an assembly is always a major release. Most 
                   subsequent genome assembly updates are also major releases.
           Minor - changes from the previous assembly version are limited to the
                   following changes, none of which result in a significant 
                   change to the coordinate system of the primary assembly-unit:
                   - adding, removing or changing a non-nuclear assembly-unit
                   - dropping unplaced or unlocalized scaffolds
                   - adding up to 50 unplaced or unlocalized scaffolds which are
                     shorter than the current scaffold-N50 value
                   - replacing a component with a gap of the same length
           Patch - the only change is the addition or modification of a patch 
                   assembly-unit. 
   See the NCBI Assembly model web page (https://www.ncbi.nlm.nih.gov/assembly/
   model/#asmb_def) for definitions of assembly-units and genome patches.

Column 14: "genome_rep"
   Genome representation: whether the goal for the assembly was to represent the
   whole genome or only part of it.
   Values:
      Full    - the data used to generate the assembly was obtained from the 
                whole genome, as in Whole Genome Shotgun (WGS) assemblies for 
                example. There may still be gaps in the assembly.
      Partial - the data used to generate the assembly came from only part of 
                the genome. 
   Most assemblies have full genome representation with a minority being partial
   genome representation. See the Assembly help web page 
   (https://www.ncbi.nlm.nih.gov/assembly/help/) for reasons that the genome 
   representation would be set to partial.

Column 15: "seq_rel_date"
   Sequence release date: the date the sequences in the genome assembly were 
   released in the International Nucleotide Sequence Database Collaboration 
   (INSDC) databases, i.e. DDBJ, ENA or GenBank.

Column 16: "asm_name"
   Assembly name: the submitter's name for the genome assembly, when one was 
   provided, otherwise a default name, in the form ASM#####v#, is provided by 
   NCBI. Assembly names are not unique.

Column 17: "submitter"
   Submitter: the submitting consortium or first position if a list of 
   organizations. The full submitter information is available in the NCBI 
   BioProject resource: www.ncbi.nlm.nih.gov/bioproject/

Column 18: "gbrs_paired_asm"
   GenBank/RefSeq paired assembly: the accession.version of the GenBank assembly
   that is paired to the given RefSeq assembly, or vice-versa. "na" is reported 
   if the assembly is unpaired.

Column 19: "paired_asm_comp"
   Paired assembly comparison: whether the paired GenBank & RefSeq assemblies 
   are identical or different.
   Values:
      identical - GenBank and RefSeq assemblies are identical
      different - GenBank and RefSeq assemblies are not identical
      na        - not applicable since the assembly is unpaired

Column 20: "ftp_path"
   FTP path: the path to the directory on the NCBI genomes FTP site from which 
   data for this genome assembly can be downloaded.

Column 21: "excluded_from_refseq"
   Excluded from RefSeq: reasons the assembly was excluded from the NCBI 
   Reference Sequence (RefSeq) project, including any assembly anomalies. See:
   https://www.ncbi.nlm.nih.gov/assembly/help/anomnotrefseq/

Column 22: "relation_to_type_material"
   Relation to type material: contains a value if the sequences in the genome 
   assembly were derived from type material.
   Values:
      assembly from type material - the sequences in the genome assembly were 
         derived from type material
      assembly from synonym type material - the sequences in the genome assembly
         were derived from synonym type material
      assembly from pathotype material - the sequences in the genome assembly
         were derived from pathovar material
      assembly designated as neotype - the sequences in the genome assembly 
         were derived from neotype material
      assembly designated as reftype - the sequences in the genome assembly 
         were derived from reference material where type material never was 
         available and is not likely to ever be available
      ICTV species exemplar - the International Committee on Taxonomy of Viruses
         (ICTV) designated the genome assembly as the exemplar for the virus 
         species
      ICTV additional isolate - the International Committee on Taxonomy of 
         Viruses (ICTV) designated the genome assembly an additional isolate for
         the virus species
		 
Column 23: "asm_not_live_date" 
	Assembly no longer live date: the date the assembly transitioned from 
	version_status latest to either replaced or suppressed. When the assembly is
	in status latest, "na" is reported. 
	


=====================================
HOW TO USE THE ASSEMBLY SUMMARY FILES
=====================================

The metadata provided in the assembly_summary.txt files can be used to identify
assemblies of interest for subsequent download. 

The Genomes FTP FAQ provides examples of how to use the assembly_summary.txt 
files to download sets of assemblies. See: 

How can I download only the current version of each assembly?
https://www.ncbi.nlm.nih.gov/genome/doc/ftpfaq/#current

How can I download RefSeq data for all complete bacterial genomes?
https://www.ncbi.nlm.nih.gov/genome/doc/ftpfaq/#allcomplete

Other sets of assemblies of interest can be downloaded using variations on 
these instructions.

________________________________________________________________________________
National Center for Biotechnology Information (NCBI)
National Library of Medicine
National Institutes of Health
8600 Rockville Pike
Bethesda, MD 20894, USA
tel: (301) 496-2475
fax: (301) 480-9241
e-mail: info@ncbi.nlm.nih.gov
________________________________________________________________________________
