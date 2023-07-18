#!/bin/bash
source /etc/profile
#$ -S /bin/bash
#$ -pe pvm 2
#$ -cwd
#$ -N ATAC-1

module load bedtools2-2.27.1-gcc-5.4.0-iouh4nk
module load samtools-1.9-gcc-5.4.0-jjq5nua
module load py-macs2-2.1.1.20160309-gcc-5.4.0-xladdm4

export PATH=/home/zz950/softwares/self_bin:$PATH
source /home/zz950/softwares/miniconda3/bin/activate /home/zz950/softwares/miniconda3/envs/cutrun

SampleCSV=ATACseq.csv

### parameter
# refencen of human/mouse 
ref=/home/zz950/reference/bowtie2-ref/10x_GRCh38-2020-A/10x_GRCh38-2020-A
cpu=20
# for fastqc
# raw_fastq=/home/zz950/projects/cut_run/HDAC-b2/20230203_HT115_MERCK60_ROMIDEPSIN/softlinks
# for bam rm Dup
picard=/home/zz950/softwares/self_bin/picard.jar

### create folders
out_dir_qc=0.fastqc_report
out_dir1=1.clean_fastq
# out_dir2=2.Ecoli_bam
out_dir3=3.bam
out_dir4=4.frag
out_dir5=5.bigwig
out_dir6=6.peak # do it in another script

mkdir $out_dir_qc $out_dir1 $out_dir3 $out_dir4 $out_dir5 $out_dir6

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
# fastp -i $fq1 -I $fq2 -o $out_dir1/${sample}_1.fq.gz -O $out_dir1/${sample}_2.fq.gz -j $out_dir_qc/${sample}.fastp.json -h $out_dir_qc/${sample}.fastp.html --detect_adapter_for_pe &&\

# --------------------

echo "align to human or mouse genome, sort/rmDup of bam"
# bam align, sort, MarkDuplicates, extrat mapped reads
# bowtie2 -p 20 -x $ref --very-sensitive -X 2000 -1 $out_dir1/${sample}_1.fq.gz -2 $out_dir1/${sample}_2.fq.gz 2>$out_dir3/${sample}.Map2GenomeStat.xls | samtools sort -O bam -@ 20 -o - > $out_dir3/${sample}.bam
## Now that the alignment files contain only uniquely mapping reads
sambamba view -h -t 20 -f bam -F "[XS] == null and not unmapped and not duplicate" $out_dir3/${sample}.bam > $out_dir3/${sample}.filter.bam
# remove unpaired reads
# samtools view -f 1 -b -o $out_dir3/${sample}.filter2.bam $out_dir3/${sample}.filter.bam
## samtools flagstat $out_dir3/${sample}.bam > $out_dir3/${sample}_flagstat.txt
## samtools markdup -r $out_dir3/${sample}.bam $out_dir3/${sample}.rmDup.bam
## samtools flagstat $out_dir3/${sample}.rmDup.bam > $out_dir3/${sample}_rmdup_flagstat.txt

# don't use samtools markdup
## java -jar $picard SortSam I=$out_dir3/${sample}.bam O=$out_dir3/${sample}.sorted.bam SORT_ORDER=coordinate &&\
java -jar $picard MarkDuplicates I=$out_dir3/${sample}.filter.bam O=$out_dir3/${sample}.sorted.dupMark.bam METRICS_FILE=$out_dir3/${sample}_picard.dupMark.txt &&\
java -jar $picard MarkDuplicates I=$out_dir3/${sample}.sorted.dupMark.bam O=$out_dir3/${sample}.rmDup.bam REMOVE_DUPLICATES=true METRICS_FILE=$out_dir3/${sample}_picard.rmDup.txt &&\

echo "bam to bed to tagAlign"
# must sort by read name here!!!
samtools sort -n -O BAM -@ 20 $out_dir3/${sample}.rmDup.bam -o $out_dir3/${sample}.rmDup.sortByName.bam &&\
bedtools bamtobed -i $out_dir3/${sample}.rmDup.sortByName.bam -bedpe > $out_dir4/${sample}.bedpe
grep -P -v "^chrM" $out_dir4/${sample}.bedpe | awk 'BEGIN{OFS="\t"}{printf "%s\t%s\t%s\tN\t1000\t%s\n%s\t%s\t%s\tN\t1000\t%s\n",$1,$2,$3,$9,$4,$5,$6,$10}' > $out_dir4/${sample}.tagAlign


echo "filter bam by quality score and mapping"
samtools view -@ 20 -b -q 1 -F 0x04 $out_dir3/${sample}.rmDup.bam  -o $out_dir3/${sample}.sorted.mapped.bam &&\

# --------------------
echo "bam to bigwig without normalization"
# bam to bigwig without normalization
samtools index $out_dir3/${sample}.sorted.mapped.bam  &&\
bamCoverage --binSize 10 --smoothLength 30 -p 20 --normalizeUsing RPGC --effectiveGenomeSize 2862010578 -b $out_dir3/${sample}.sorted.mapped.bam -of bigwig -o $out_dir5/${sample}.bigwig &&\
bamCoverage --binSize 5 -p 20 --normalizeUsing RPKM -b $out_dir3/${sample}.sorted.mapped.bam -of bigwig -o $out_dir5/${sample}.bin5.bigwig &&\

echo "$sample test done!"
# rm $out_dir3/${sample}.bam $out_dir3/${sample}.rmDup.bam 
###################################################################
done

# --------------------
# echo "fastqc report"
# fastqc -t 20 -o $out_dir_qc $out_dir1/*

echo "all done"
