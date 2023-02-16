# Cut&Run pipeline
A standard analytic pipeline for cut&run data

## Step 0. ENV and softwares preparation, check by `step.0.env.software.check.sh`.
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
pip install multiqc # I love it!
```

## Step 0. Check the fastq files.
```
# some fastq files may be broken during data transfering, and lead to the break of the pipeline
# should check them before running the pipeline, some good sequencer may provide MD5 files
cat CR*/MD5.txt > ../softlinks/MD5.txt
md5sum -c MD5.txt
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

## Step 3. Run `run.1.qc.clean.align.rmDup.sort.Mapped.bam.bigwig.sh` [~30 mins per sample]
- This script will read `all.sample.labelled.csv` per line
- Process each fastq pairs, generate `bam frag bigwig`

Parameters needed as input:
```
### parameter
# refencen of human/mouse and Ecoli
ref=/home/zz950/reference/bowtie2-ref/10x_GRCh38-2020-A/10x_GRCh38-2020-A
ref_ecoli=/home/zz950/reference/bowtie2-ref/Ecoli/Ecoli
cpu=12
# for fastqc
raw_fastq=/home/zz950/projects/cut_run/HDAC-b2/20230203_HT115_MERCK60_ROMIDEPSIN/softlinks
# for bam rm Dup
picard=/home/zz950/softwares/self_bin/picard.jar
```

## Step 4. Bam to bed. Run `run.2.1.bam.to.frag.bed.sh` [~1 min per sample]
- This script will transform bam file to fragment file
- output seqDepth of Ecoli mapping
- Pls run `HDAC-b2-Cut&Run_in_R.ipynb` to get the scale factor for IgG (if don't scale the noise will be very high in bigwig)

## Step 5. Normalization library size by spike-in. Run `run.2.2.spikeIn.normalize.bigwig.sh` [~1 min per sample]
- This script will scale down IgG by spike-in fragment number and generate normalized bigwig file

## Step 6. Peak calling. Run `run.3.peak.calling.sh` [very fast: ~1 min per sample]
- This script will call peaks using macs3

## Step 7. Check if all samples have reasonable output and pass QC.
- alignment rate for TF, hitone, IgG

## Step 8. Clean intermediate big files. Run `9.clean.big.intermediate.files.sh`
```
# integrate all QC information for our samples
multiqc .
# keep important log files, move to log folder
mv HDAC.o2599325 HDAC.e2599325 log
```

## What're the core output file?
- bam (always too big, we will not keep it)
- bigwig (good for peak visualization and diff analysis)
- peak (diff analysis, annotation)

## What fancy downstream analysis can be performed?
- individual gene/peak visualizaiton among samples (IGV)
- gene set/signature heatmap (centered by TSS)
- integrated with RNA-seq

