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
cpu=12
out_dir=/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/peak
SEACR=/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/software/SEACR/SEACR_1.3.sh

################################
# for TF
TF1=HDAC1
#macs3 callpeak -t bam/*HDAC1*sorted.mapped.bam -c bam/*_IgG*sorted.mapped.bam -f BAM -g hs -n $TF1 -B --outdir $out_dir &&\
TF2=HDAC2
#macs3 callpeak -t bam/*HDAC2*sorted.mapped.bam -c bam/*_IgG*sorted.mapped.bam -f BAM -g hs -n $TF2 -B --outdir $out_dir &&\
# for histone
histone1=K27Ac
#macs3 callpeak -t bam/*K27Ac*sorted.mapped.bam -c bam/*_IgG*sorted.mapped.bam --broad -g hs --broad-cutoff 0.1 -n $histone1  --outdir $out_dir &&\

################################
cd bam
for bam in `ls *HDAC*sorted.mapped.bam`
do
echo $bam
#macs3 callpeak -t $bam -f BAM -g hs -n $bam --outdir ../peak 
done

for bam in `ls *IgG*sorted.mapped.bam`
do
echo $bam
#macs3 callpeak -t $bam -f BAM -g hs -n $bam --outdir ../peak
done

for bam in `ls *K27Ac*sorted.mapped.bam`
do
echo $bam
#macs3 callpeak -t $bam --broad --broad-cutoff 0.1 -f BAM -g hs -n $bam --outdir ../peak
done

for bam in `ls *IgG*sorted.mapped.bam`
do
echo $bam
#macs3 callpeak -t $bam --broad --broad-cutoff 0.1 -f BAM -g hs -n $bam --outdir ../peak
done

################################
################################
ctrl1=DMSO_IgG_1.fragments.normalized.bedgraph
ctrl2=DMSO_IgG_2.fragments.normalized.bedgraph
cd /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/bed
for bed in `ls DMSO*fragments.normalized.bedgraph`
do
bash $SEACR $bed $ctrl1 non stringent $out_dir/${bed}_seacr_with_IgG1.peaks 
bash $SEACR $bed $ctrl2 non stringent $out_dir/${bed}_seacr_with_IgG2.peaks
macs3 callpeak --nomodel -t $bed -c $ctrl1 -f BED -g hs -n ${bed}_macs3_with_IgG1.peaks --outdir $out_dir
macs3 callpeak --nomodel -t $bed -c $ctrl2 -f BED -g hs -n ${bed}_macs3_with_IgG2.peaks --outdir $out_dir
done

ctrl1=M60_IgG_1.fragments.normalized.bedgraph
ctrl2=M60_IgG_2.fragments.normalized.bedgraph
cd /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/bed
for bed in `ls M60*fragments.normalized.bedgraph`
do
bash $SEACR $bed $ctrl1 non stringent $out_dir/${bed}_seacr_with_IgG1.peaks
bash $SEACR $bed $ctrl2 non stringent $out_dir/${bed}_seacr_with_IgG2.peaks
macs3 callpeak --nomodel -t $bed -c $ctrl1 -f BED -g hs -n ${bed}_macs3_with_IgG1.peaks --outdir $out_dir
macs3 callpeak --nomodel -t $bed -c $ctrl2 -f BED -g hs -n ${bed}_macs3_with_IgG2.peaks --outdir $out_dir
done

################################

cd /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/bed
for bed in `ls *fragments.normalized.bedgraph`
do
bash $SEACR $bed 0.01 non stringent $out_dir/${bed}_seacr_top0.01.peaks
macs3 callpeak --nomodel -t $bed -f BED -g hs -n ${bed}_macs3_no_IgG.peaks --outdir $out_dir
done

################################
# for K27Ac
ctrl1=DMSO_IgG_1.fragments.normalized.bedgraph
ctrl2=DMSO_IgG_2.fragments.normalized.bedgraph
cd /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/bed
for bed in `ls DMSO*K27Ac*fragments.normalized.bedgraph`
do
macs3 callpeak --nomodel -t $bed -c $ctrl1 -f BED -g hs -n ${bed}_macs3_with_IgG1.peaks --outdir $out_dir --broad --broad-cutoff 0.1
macs3 callpeak --nomodel -t $bed -c $ctrl2 -f BED -g hs -n ${bed}_macs3_with_IgG2.peaks --outdir $out_dir --broad --broad-cutoff 0.1
done

ctrl1=M60_IgG_1.fragments.normalized.bedgraph
ctrl2=M60_IgG_2.fragments.normalized.bedgraph
cd /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/bed
for bed in `ls M60*K27Ac*fragments.normalized.bedgraph`
do
macs3 callpeak --nomodel -t $bed -c $ctrl1 -f BED -g hs -n ${bed}_macs3_with_IgG1.peaks --outdir $out_dir --broad --broad-cutoff 0.1
macs3 callpeak --nomodel -t $bed -c $ctrl2 -f BED -g hs -n ${bed}_macs3_with_IgG2.peaks --outdir $out_dir --broad --broad-cutoff 0.1
done

cd /home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/bed
for bed in `ls *K27Ac*fragments.normalized.bedgraph`
do
macs3 callpeak --nomodel -t $bed -f BED -g hs -n ${bed}_macs3_no_IgG.peaks --outdir $out_dir --broad --broad-cutoff 0.1
done

echo "all done"
