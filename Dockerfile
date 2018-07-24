#################################################################
# Dockerfile
#
# Software:         vcf2maf
# Software Version: 1.6.10
# Description:      Convert a VCF into a MAF, where each variant is annotated 
#                   to only one of all possible gene isoforms
# Website:          https://github.com/mskcc/vcf2maf
# Base Image:       ubuntu 16.04
# Run Cmd:          docker run vcf2maf perl vcf2maf.pl --man
# Adapted from Adam Struck <strucka@ohsu.edu>
#################################################################
FROM ubuntu:16.04

MAINTAINER Philipp Unberath <philipp.unberath@fau.de>

USER root
ENV VEP_PATH /root/vep
ENV PATH $VEP_PATH/htslib:$VEP_PATH/samtools/bin:$PATH
ENV PERL5LIB $VEP_PATH:/opt/lib/perl5:$PERL5LIB

# Install compiler and other dependencies
RUN apt-get update && \
    apt-get install --yes \
    build-essential \
    libarchive-zip-perl \
    libdbd-mysql-perl \
    libjson-perl \
    libwww-perl \
    cpanminus \
    zlib1g-dev \
    libncurses5-dev \
    git \
    curl \
    unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/

# download vep
RUN curl -LO https://github.com/Ensembl/ensembl-vep/archive/release/91.tar.gz && \
    tar -zxvf 91.tar.gz && \
    mkdir $VEP_PATH && \
    mv ensembl-vep-release-91/* $VEP_PATH && \
    rm -rf *

# install htslib, samtools, and bcftools
WORKDIR $VEP_PATH

# install ensempl api, BioPerl and ensembl io
RUN mkdir $VEP_PATH/src && cd $VEP_PATH/src && \
    curl -LOOO ftp://ftp.ensembl.org/pub/ensembl-api.tar.gz && \
    curl -LOOO https://cpan.metacpan.org/authors/id/C/CJ/CJFIELDS/BioPerl-1.6.924.tar.gz  && \
    curl -LOOO https://github.com/Ensembl/ensembl-io/archive/release/91.zip  && \
    tar -zxvf ensembl-api.tar.gz &&\
    tar -zxvf BioPerl-1.6.924.tar.gz &&\
	unzip 91.zip &&\
	mv ensembl-io-release-91 ensembl-io &&\
    cd ..

ENV PERL5LIB $VEP_PATH/src/bioperl-1.6.924:$PERL5LIB
ENV PERL5LIB $VEP_PATH/src/ensembl/modules:$PERL5LIB
ENV PERL5LIB $VEP_PATH/src/ensembl-compara/modules:$PERL5LIB
ENV PERL5LIB $VEP_PATH/src/ensembl-variation/modules:$PERL5LIB
ENV PERL5LIB $VEP_PATH/src/ensembl-funcgen/modules:$PERL5LIB
ENV PERL5LIB $VEP_PATH/src/ensembl-io/modules:$PERL5LIB

	
# install htslib, samtools, and bcftools
RUN mkdir $VEP_PATH/samtools && cd $VEP_PATH/samtools && \
    curl -LOOO https://github.com/samtools/{samtools/releases/download/1.3.1/samtools-1.3.1,bcftools/releases/download/1.3.1/bcftools-1.3.1,htslib/releases/download/1.3.2/htslib-1.3.2}.tar.bz2 && \
    cat *tar.bz2 | tar -ijxf - &&\
	cd htslib-1.3.2 && make && make prefix=$VEP_PATH/samtools install && cd .. &&\
    cd samtools-1.3.1 && make && make prefix=$VEP_PATH/samtools install && cd .. && \
    cd bcftools-1.3.1 && make && make prefix=$VEP_PATH/samtools install && cd .. && \
    cd ..


# install liftOver
RUN curl -L http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/liftOver > $VEP_PATH/samtools/bin/liftOver && \
    chmod a+x $VEP_PATH/samtools/bin/liftOver

# install perl dependencies
RUN cpanm --mirror http://cpan.metacpan.org -l /opt/ File::Copy::Recursive Module::Build Bio::PrimarySeqI && \
    rm -rf ~/.cpanm

# install VEP and plugins
RUN cd $VEP_PATH && \
    perl INSTALL.pl --AUTO ap --SPECIES homo_sapiens --ASSEMBLY GRCh37,GrCh38 --PLUGINS ExAC

# install vcf2maf
WORKDIR /home/

RUN curl -ksSL -o tmp.tar.gz https://github.com/mskcc/vcf2maf/archive/v1.6.16.tar.gz && \
    tar --strip-components 1 -zxf tmp.tar.gz && \
    rm tmp.tar.gz

CMD ["perl", "vcf2maf.pl", "--man"]
