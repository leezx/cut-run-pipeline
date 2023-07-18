#!/bin/bash
source /etc/profile
#$ -S /bin/bash
#$ -pe pvm 2
#$ -cwd
#$ -N Run-1

module load bedtools2-2.27.1-gcc-5.4.0-iouh4nk
module load samtools-1.9-gcc-5.4.0-jjq5nua
module load py-macs2-2.1.1.20160309-gcc-5.4.0-xladdm4

export PATH=/home/zz950/softwares/self_bin:$PATH
source /home/zz950/softwares/miniconda3/bin/activate /home/zz950/softwares/miniconda3/envs/cutrun

SampleCSV=CutRun.csv

### parameter
# refencen of human/mouse and Ecoli
ref=/home/zz950/reference/bowtie2-ref/10x_GRCh38-2020-A/10x_GRCh38-2020-A
ref_ecoli=/home/zz950/reference/bowtie2-ref/Ecoli/Ecoli
cpu=12
# for fastqc
# raw_fastq=/home/zz950/projects/cut_run/HDAC-b2/20230203_HT115_MERCK60_ROMIDEPSIN/softlinks
# for bam rm Dup
picard=/home/zz950/softwares/self_bin/picard.jar

### create folders
out_dir_qc=0.fastqc_report
out_dir1=1.clean_fastq
out_dir2=2.Ecoli_bam
out_dir3=3.bam
out_dir4=4.frag
out_dir5=5.bigwig
out_dir6=6.peak # do it in another script

# [ -d $out_dir_qc $out_dir1 $out_dir2 $out_dir3 $out_dir4 $out_dir5 ] || mkdir newdir
mkdir $out_dir_qc $out_dir1 $out_dir2 $out_dir3 $out_dir4 $out_dir5 $out_dir6

# ######################### main loop #############################
cat $SampleCSV | while IFS="," read sample fq1 fq2; do
###################################################################
### this script support breakpoint resume!!! It's cool!
if [ -f $out_dir5/${sample}.bin5.bigwig ]; then
  echo "$sample is previously done, skipped!"
  continue
else
  echo "Processing: $sample : $fq1, $fq2"
fi

echo "trim fastq"
fastp -i $fq1 -I $fq2 -o $out_dir1/${sample}_1.fq.gz -O $out_dir1/${sample}_2.fq.gz --detect_adapter_for_pe &&\

# --------------------
echo "align to Ecoli"
bowtie2 --end-to-end --very-sensitive --no-overlap --no-dovetail --no-mixed --no-discordant --phred33 -I 10 -X 700 -p $cpu -x $ref_ecoli -1 $out_dir1/${sample}_1.fq.gz -2 $out_dir1/${sample}_2.fq.gz 2>$out_dir2/${sample}.Ecoli.Map2GenomeStat.xls | samtools view -b -S -o $out_dir2/${sample}.Ecoli.bam - &&\

echo "align to human or mouse genome, sort/rmDup of bam"
# bam align, sort, MarkDuplicates, extrat mapped reads
bowtie2 --local --very-sensitive --no-mixed --no-discordant --phred33 -I 10 -X 700 -p $cpu -x $ref -1 $out_dir1/${sample}_1.fq.gz -2 $out_dir1/${sample}_2.fq.gz 2>$out_dir3/${sample}.Map2GenomeStat.xls | samtools view -b -S -o $out_dir3/${sample}.bam - &&\
java -jar $picard SortSam I=$out_dir3/${sample}.bam O=$out_dir3/${sample}.sorted.bam SORT_ORDER=coordinate &&\
java -jar $picard MarkDuplicates I=$out_dir3/${sample}.sorted.bam O=$out_dir3/${sample}.sorted.dupMark.bam METRICS_FILE=$out_dir3/${sample}_picard.dupMark.txt &&\
java -jar $picard MarkDuplicates I=$out_dir3/${sample}.sorted.dupMark.bam O=$out_dir3/${sample}.sorted.rmDup.bam REMOVE_DUPLICATES=true METRICS_FILE=$out_dir3/${sample}_picard.rmDup.txt &&\

echo "fragmentLen for QC plot"
# for QC plot
## Extract the 9th column from the alignment sam file which is the fragment length
samtools view -F 0x04 $out_dir3/${sample}.bam | awk -F'\t' 'function abs(x){return ((x < 0.0) ? -x : x)} {print abs($9)}' | sort | uniq -c | awk -v OFS="\t" '{print $2, $1/2}' > $out_dir4/${sample}_fragmentLen.txt &&\

echo "filter bam by quality score and mapping"
# minQualityScore=2
# samtools view -@ 12 -b -q $minQualityScore $out_dir3/${sample}.sorted.bam -o $out_dir3/${sample}.sorted.Score$minQualityScore.bam &&\
samtools view -@ 12 -b -F 0x04 $out_dir3/${sample}.sorted.bam -o $out_dir3/${sample}.sorted.mapped.bam &&\

# --------------------
echo "bam to bigwig without normalization"
# bam to bigwig without normalization
samtools index $out_dir3/${sample}.sorted.mapped.bam  &&\
bamCoverage --binSize 10 --smoothLength 30 -p 20 --normalizeUsing RPGC --effectiveGenomeSize 2862010578 -b $out_dir3/${sample}.sorted.mapped.bam -of bigwig -o $out_dir5/${sample}.bigwig &&\
bamCoverage --binSize 5 -p 20 --normalizeUsing RPKM -b $out_dir3/${sample}.sorted.mapped.bam -of bigwig -o $out_dir5/${sample}.bin5.bigwig &&\

rm $out_dir2/${sample}.Ecoli.bam $out_dir3/${sample}.bam $out_dir3/${sample}.sorted.bam $out_dir3/${sample}.sorted.dupMark.bam $out_dir3/${sample}.sorted.rmDup.bam fastp.json fastp.html
###################################################################
done

# --------------------
# echo "fastqc report"
# fastqc -t 20 -o $out_dir_qc $out_dir1/*

echo "all done"
