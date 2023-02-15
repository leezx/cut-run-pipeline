module load bedtools2-2.27.1-gcc-5.4.0-iouh4nk
module load samtools-1.9-gcc-5.4.0-jjq5nua
module load py-macs2-2.1.1.20160309-gcc-5.4.0-xladdm4

export PATH=/home/da528/miniconda3/bin:$PATH

# parameter
ref=/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/reference/bowtie2-ref/10x_GRCh38-2020-A/10x_GRCh38-2020-A
ref_ecoli=/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/reference/bowtie2-ref/Ecoli/Ecoli

fastqc
fastp
bowtie2
java -jar /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/software/picard.jar
samtools
bamCoverage
macs3
/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/software/SEACR/SEACR_1.3.sh
bedtools
/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/software/bedGraphToBigWig
