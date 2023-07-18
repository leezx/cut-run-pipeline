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
# macs_no_IgG_bam=$out_dir6/macs_no_IgG_bam
# macs_no_IgG_bed_norm=$out_dir6/macs_no_IgG_bed_norm
macs_peak=$out_dir6/macs_tag_peak

# macs parameters
smooth_window=150 # default
shiftsize=$(( -$smooth_window/2 ))
pval_thresh=0.01

cd $out_dir4

### for TF
for tag in `ls *tagAlign`
do
echo $tag
macs3 callpeak -t $tag -f BED -n $tag -g hs -p $pval_thresh --shift $shiftsize --extsize $smooth_window --nomodel -B --SPMR --keep-dup all --call-summits --outdir ../$macs_peak
done

echo "peak calling by macs3 all done!"
