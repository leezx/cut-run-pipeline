#!/bin/bash
source /etc/profile
#$ -S /bin/bash
#$ -pe pvm 2
#$ -cwd
#$ -N HDAC


module load bedtools2-2.27.1-gcc-5.4.0-iouh4nk
module load samtools-1.9-gcc-5.4.0-jjq5nua
module load py-macs2-2.1.1.20160309-gcc-5.4.0-xladdm4

export PATH=/home/zz950/softwares/self_bin:$PATH
source /home/zz950/softwares/miniconda3/bin/activate /home/zz950/softwares/miniconda3/envs/cutrun


# ######################### main loop #############################
cat all.sample.labelled.csv | while IFS="," read sample fq1 fq2; do
echo "$sample : $fq1, $fq2"
###################################################################

out_dir3=3.bam
out_dir4=4.frag

## sort bam by name
samtools sort -n -@ 20 -m 1G -O BAM $out_dir3/${sample}.sorted.mapped.bam -o $out_dir3/${sample}.Namesorted.mapped.bam &&\

## Convert into bed file format, for peak calling
bedtools bamtobed -i $out_dir3/${sample}.Namesorted.mapped.bam -bedpe > $out_dir4/${sample}.bed &&\

## Keep the read pairs that are on the same chromosome and fragment length less than 1000bp.
awk '$1==$4 && $6-$2 < 2000 {print $0}' $out_dir4/${sample}.bed > $out_dir4/${sample}.clean.bed &&\

## Only extract the fragment related columns
cut -f 1,2,6 $out_dir4/${sample}.clean.bed | sort -k1,1 -k2,2n -k3,3n  > $out_dir4/${sample}.fragments.bed &&\

#-----------------------------------------------
# spike-in
# only use spike-in to normalize control and expriment, inside group we use library size
chromSize=genome.hg38.txt

seqDepthDouble=`samtools view -F 0x04 $out_dir3/${sample}.bam | wc -l`
seqDepth=$((seqDepthDouble/2))
echo $seqDepth

# parameters needs
max1=4000000 # median num for expriments
max2=800000 # median num for IgG
ratio=5746/7553 # spike-in ratio IgG/expriments

flag=`echo $sample | grep IgG`
if [[ "$flag" = "" ]]
then
    echo "$sample is not IgG!!!!"
    scale_factor=`echo "$max1 / $seqDepth" | bc -l`
    echo "Scaling factor for $sample is: $scale_factor!"
    bedtools genomecov -bg -scale $scale_factor -i $out_dir4/${sample}.fragments.bed -g $chromSize > $out_dir4/${sample}.fragments.normalized.bedgraph
else
    echo "$sample is IgG"
    scale_factor=`echo "$max2 / $seqDepth * $ratio" | bc -l`
    echo "Scaling factor for $sample is: $scale_factor!"
    bedtools genomecov -bg -scale $scale_factor -i $out_dir4/${sample}.fragments.bed -g $chromSize > $out_dir4/${sample}.fragments.normalized.bedgraph
fi

# normalized fragment to bigwig
LC_COLLATE=C sort -k1,1 -k2,2n $out_dir4/${sample}.fragments.normalized.bedgraph > test.sort.bed &&\
/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/software/bedGraphToBigWig test.sort.bed genome.hg38.txt bigwig/${sample}.normalized.bw &&\

# correlation plot
echo "fragment count for correlation plot"
binLen=500
awk -v w=$binLen '{print $1, int(($2 + $3)/(2*w))*w + w/2}' $out_dir4/${sample}.fragments.bed | sort -k1,1V -k2,2n | uniq -c | awk -v OFS="\t" '{print $2, $3, $1}' |  sort -k1,1V -k2,2n  > $out_dir4/${sample}.fragmentsCount.bin$binLen.bed &&\

echo "done for $sample"
###################################################################
done

echo "all done"

