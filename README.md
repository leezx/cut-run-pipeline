# Cut&Run pipeline
A standard analytic pipeline for cut&run data

## Step 0. ENV and softwares preparation, check by `step0.env.software.check.sh`.
```
# use most stable python
conda create -n cutrun python=3.8
conda activate cutrun
# if conda activate doesn't work
source /home/zz950/softwares/miniconda3/bin/activate /home/zz950/softwares/miniconda3/envs/cutrun
# install 
conda install -c bioconda fastp deeptools macs3
# conda install is often slow, you can try other approaches
# download the latest build
wget http://opengene.org/fastp/fastp
chmod a+x ./fastp
pip install deeptools
pip install macs3
```

## Step 1. Create a `all.sample.csv` file with sample name and paired absolute path of fastq files.
```
D_G1_CKDL220025889-1A_HCY2GDSX5_L1,/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/fastq/D_G1_CKDL220025889-1A_HCY2GDSX5_L1_1.fastq.gz,/home/da528/ATAC_Analysis/cut_run/zhixin_analysis/HDAC/fastq/D_G1_CKDL220025889-1A_HCY2GDSX5_L1_2.fastq.gz
```
see: https://github.com/leezx/ArchivedTools/blob/master/HKU/analyze.fastq.server.sh

```
# create a softlinks dir if all fastq are not in one folder
# gather all fastq files
ln -s ../01.RawData/*/*_1.fq.gz ./
ln -s ../01.RawData/*/*_2.fq.gz ./

# check number of fastq
ls | wc -l
112
# yes 56 samples, matched
```

## Step 2. Rename the sample (`all.sample.csv`) to biological meaningful name (such as M60a-IgG-1) `all.sample.labelled.csv`
- Naming method：`Treatment-Antibody-replicate`
- All downstream fq, bam, peak will be based on this name. It will great benefit for further analysis.
- Suggestion: go to R and modify the name, or you can edit it in Excel.

## Step 3. Run `run.1.qc.align.clean.sort.bed.bigwig.sh`
- This script will read `all.sample.labelled.csv` per line
- Process each fastq pairs, generate `bam frag bigwig`

## Step 4. Run ``
- This script will call peaks using macs3

