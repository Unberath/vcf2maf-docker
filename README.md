vcf2maf
=======

To convert a [VCF](http://samtools.github.io/hts-specs/) into a [MAF](https://wiki.nci.nih.gov/x/eJaPAQ), each variant must be mapped to only one of all possible gene transcripts/isoforms that it might affect. This selection of a single effect per variant, is often subjective. So this project is an attempt to make the selection criteria smarter, reproducible, and more configurable. And the default criteria must lean towards best practices. This Repository is an adapted version of the vcf2maf part of the [dockerized-tools Repository](https://github.com/ohsu-comp-bio/dockerized-tools).

Quick start
-----------

Clone this repo and build the image:
    
    docker build -t vcf2maf .
        
        
To view the vcf2maf source code, [click here](https://github.com/mskcc/vcf2maf/).

After building the image (and setting up the cache files), you can test it like so:

    docker run -v $VEP_DATA/homo_sapiens:/mnt/homo_sapiens -v $OUTPUT_DIR:/output vcf2maf perl vcf2maf.pl --input-vcf tests/test.vcf --output-maf /output/test.vep.maf --vep-data /mnt/ --ref-fasta /mnt/homo_sapiens/91_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa --filter-vcf 0 --cache-version 91

To map own files, you can use:
	
	docker run -v $HOME/.vep:/mnt -v $OUTPUT_DIR:/output -v $INPUT_DIR:/input vcf2maf perl vcf2maf.pl --input-vcf /input/YOUR_FILE.vcf --output-maf /output/YOUR_FILE.maf --vep-data /mnt --ref-fasta /mnt/homo_sapiens/91_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa --filter-vcf /mnt/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz --cache-version 91

Download and Prepare VEP Data Dependencies
-----------

Download and unpack VEP's offline cache for GRCh37

    export VEP_DATA=$HOME/.vep
	export OUTPUT_DIR=$HOME/vcf2maf/output
    mkdir $OUTPUT_DIR
	mkdir $VEP_DATA && cd $VEP_DATA
    curl --progress-bar -O ftp://ftp.ensembl.org/pub/release-91/variation/VEP/homo_sapiens_vep_91_GRCh37.tar.gz
    tar xzf homo_sapiens_vep_91_GRCh37.tar.gz
	cd homo_sapiens/91_GRCh37
    curl --progress-bar -O  ftp://ftp.ensembl.org/pub/release-75/fasta/homo_sapiens/dna/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz
    gunzip Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz

Convert the offline cache for use with tabix, that significantly speeds up the lookup of known variants:

    docker run -v $VEP_DATA:/mnt vcf2maf perl /root/vep/convert_cache.pl --species homo_sapiens --version 91_GRCh37 --dir /mnt

Download and index a custom ExAC r0.3 VCF, that skips variants overlapping known somatic hotspots (bcftools and tabix have to be installed):

    curl -L ftp://ftp.broadinstitute.org:/pub/ExAC_release/release0.3.1/subsets/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz > $VEP_DATA/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz
	echo "##FILTER=<ID=AC_Adj0_Filter,Description=\"Only low quality genotype calls containing alternate alleles are present\">" > header_line.tmp
    curl -LO https://raw.githubusercontent.com/mskcc/vcf2maf/v1.6.14/data/known_somatic_sites.bed
	bcftools annotate --header-lines header_line.tmp --remove FMT,^INF/AF,INF/AC,INF/AN,INF/AC_Adj,INF/AN_Adj,INF/AC_AFR,INF/AC_AMR,INF/AC_EAS,INF/AC_FIN,INF/AC_NFE,INF/AC_OTH,INF/AC_SAS,INF/AN_AFR,INF/AN_AMR,INF/AN_EAS,INF/AN_FIN,INF/AN_NFE,INF/AN_OTH,INF/AN_SAS $VEP_DATA/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz | bcftools filter --targets-file ^known_somatic_sites.bed --output-type z --output $VEP_DATA/ExAC_nonTCGA.r0.3.1.sites.fixed.vcf.gz
	mv -f $VEP_DATA/ExAC_nonTCGA.r0.3.1.sites.fixed.vcf.gz $VEP_DATA/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz
	tabix -p vcf $VEP_DATA/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz

License
-------
    
    Apache-2.0 | Apache License, Version 2.0 | https://www.apache.org/licenses/LICENSE-2.0
