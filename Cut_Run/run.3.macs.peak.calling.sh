#!/bin/bash
source /etc/profile
#$ -S /bin/bash
#$ -pe pvm 2
#$ -cwd
#$ -N macs3

export PATH=/home/zz950/softwares/self_bin:$PATH
source /home/zz950/softwares/miniconda3/bin/activate /home/zz950/softwares/miniconda3/envs/cutrun

# parameter
out_dir3=3.bam
out_dir4=4.frag
out_dir6=6.peak
macs_no_IgG_bam=$out_dir6/macs_no_IgG_bam
macs_no_IgG_bed_norm=$out_dir6/macs_no_IgG_bed_norm

################ macs3 individual bam without IgG  ################
cd $out_dir3

### for TF
for bam in `ls *HDAC*sorted.mapped.bam *IgG*sorted.mapped.bam`
do
echo $bam
# macs3 callpeak -t $bam -f BAM -g hs -n $bam --outdir ../$macs_no_IgG_bam 
done

### for histone
for bam in `ls *Mvitro*sorted.mapped.bam *Mvivo*sorted.mapped.bam`
do
echo $bam
# macs3 callpeak -t $bam --broad --broad-cutoff 0.1 -f BAM -g hs -n $bam --outdir ../$macs_no_IgG_bam
done

### for histone
for bam in `ls *Mvitro*sorted.mapped.bam *Mvivo*sorted.mapped.bam`
do
echo $bam
macs3 callpeak -t $bam -f BAM -g hs -n $bam --outdir ../$macs_no_IgG_bam/chem_narrow
done

################ macs3 individual norm bed without IgG ###############

# cd ../$out_dir4

# ### for TF
# for bed in `ls *HDAC*fragments.normalized.bedgraph ls *IgG*fragments.normalized.bedgraph`
# do
# macs3 callpeak --nomodel -t $bed -f BED -g hs -n ${bed}_macs3_no_IgG.peaks --outdir ../$macs_no_IgG_bed_norm
# done

# ### for histone
# for bed in `ls *H3*fragments.normalized.bedgraph *H4*fragments.normalized.bedgraph *IgG*fragments.normalized.bedgraph`
# do
# macs3 callpeak --nomodel -t $bed -f BED -g hs -n ${bed}_macs3_no_IgG.peaks --outdir ../$macs_no_IgG_bed_norm --broad --broad-cutoff 0.1
# done

echo "peak calling by macs3 all done!"

# wc -l 6.peak/macs_no_IgG_bam/*.narrowPeak
# wc -l 6.peak/macs_no_IgG_bam/*.broadPeak