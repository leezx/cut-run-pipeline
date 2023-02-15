#!/bin/bash
source /etc/profile
#$ -S /bin/bash
#$ -pe pvm 2
#$ -cwd
#$ -N HDAC

module load bedtools2-2.27.1-gcc-5.4.0-iouh4nk
module load samtools-1.9-gcc-5.4.0-jjq5nua
module load py-macs2-2.1.1.20160309-gcc-5.4.0-xladdm4

export PATH=/home/da528/miniconda3/bin:$PATH

# parameter
ref=/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/reference/bowtie2-ref/10x_GRCh38-2020-A/10x_GRCh38-2020-A
ref_ecoli=/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/reference/bowtie2-ref/Ecoli/Ecoli
cpu=12

# ######################### main loop #############################
cat all.sample.labelled.csv | while IFS="," read sample fq1 fq2; do
echo "$sample : $fq1, $fq2"
###################################################################
# --------------------
out_dir_qc=fastqc_report
# /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/software/FastQC/fastqc -t 20 -o $out_dir_qc fastq/*.gz

out_dir1=clean_fastq
# fastp -i $fq1 -I $fq2 -o $out_dir1/${sample}_1.fq.gz -O $out_dir1/${sample}_2.fq.gz --detect_adapter_for_pe &&\

# --------------------
out_dir2=Ecoli_bam
# bowtie2 --end-to-end --very-sensitive --no-overlap --no-dovetail --no-mixed --no-discordant --phred33 -I 10 -X 700 -p $cpu -x $ref_ecoli -1 $out_dir1/${sample}_1.fq.gz -2 $out_dir1/${sample}_2.fq.gz 2>$out_dir2/${sample}.Ecoli.Map2GenomeStat.xls | samtools view -b -S -o $out_dir2/${sample}.Ecoli.bam - &&\

# bam align, sort, MarkDuplicates, extrat mapped reads
out_dir3=bam
# bowtie2 --local --very-sensitive --no-mixed --no-discordant --phred33 -I 10 -X 700 -p $cpu -x $ref -1 $out_dir1/${sample}_1.fq.gz -2 $out_dir1/${sample}_2.fq.gz 2>$out_dir3/${sample}.Map2GenomeStat.xls | samtools view -b -S -o $out_dir3/${sample}.bam - &&\
# java -jar /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/software/picard.jar SortSam I=$out_dir3/${sample}.bam O=$out_dir3/${sample}.sorted.bam SORT_ORDER=coordinate &&\
# java -jar /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/software/picard.jar MarkDuplicates I=$out_dir3/${sample}.sorted.bam O=$out_dir3/${sample}.sorted.dupMark.bam METRICS_FILE=$out_dir3/${sample}_picard.dupMark.txt &&\
# java -jar /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/software/picard.jar MarkDuplicates I=$out_dir3/${sample}.sorted.dupMark.bam O=$out_dir3/${sample}.sorted.rmDup.bam REMOVE_DUPLICATES=true METRICS_FILE=$out_dir3/${sample}_picard.rmDup.txt &&\

# for QC plot
## Extract the 9th column from the alignment sam file which is the fragment length
# samtools view -F 0x04 $out_dir3/${sample}.bam | awk -F'\t' 'function abs(x){return ((x < 0.0) ? -x : x)} {print abs($9)}' | sort | uniq -c | awk -v OFS="\t" '{print $2, $1/2}' > $out_dir3/${sample}_fragmentLen.txt &&\

minQualityScore=2
# samtools view -@ 12 -b -q $minQualityScore $out_dir3/${sample}.sorted.bam -o $out_dir3/${sample}.sorted.Score$minQualityScore.bam &&\
# samtools view -@ 12 -b -F 0x04 $out_dir3/${sample}.sorted.bam -o $out_dir3/${sample}.sorted.mapped.bam &&\

# --------------------
# bam to bigwig without normalization
out_dir5=bigwig
# samtools index $out_dir3/${sample}.sorted.mapped.bam  &&\
# bamCoverage --binSize 10 --smoothLength 30 -p 20 --normalizeUsing RPGC --effectiveGenomeSize 2862010578 -b $out_dir3/${sample}.sorted.mapped.bam -of bigwig -o $out_dir5/${sample}.bigwig &&\
# bamCoverage --binSize 5 -p 20 --normalizeUsing RPKM -b $out_dir3/${sample}.sorted.mapped.bam -of bigwig -o $out_dir5/${sample}.bin5.bigwig &&\

# correlation plot
binLen=500
# awk -v w=$binLen '{print $1, int(($2 + $3)/(2*w))*w + w/2}' $out_dir4/${sample}.fragments.bed | sort -k1,1V -k2,2n | uniq -c | awk -v OFS="\t" '{print $2, $3, $1}' |  sort -k1,1V -k2,2n  > $out_dir4/${sample}.fragmentsCount.bin$binLen.bed &&\


echo "QC - Align - bigwig, done for $sample"
###################################################################
done

echo "all done"
