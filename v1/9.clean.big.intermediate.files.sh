out_dir2=Ecoli_bam
out_dir3=bam
minQualityScore=2
out_dir4=bed

cat all.sample.labelled.csv | while IFS="," read sample fq1 fq2; do
echo "$sample : $fq1, $fq2"

rm $out_dir2/${sample}.Ecoli.bam
rm $out_dir3/${sample}.bam
rm $out_dir3/${sample}.sorted.bam
rm $out_dir3/${sample}.sorted.dupMark.bam
rm $out_dir3/${sample}.sorted.rmDup.bam
rm $out_dir3/${sample}.sorted.Score$minQualityScore.bam
rm $out_dir3/${sample}.Namesorted.mapped.bam

rm $out_dir4/${sample}.bed
rm $out_dir4/${sample}.clean.bed
rm $out_dir4/${sample}.fragments.bed

done

echo "removed all junk files!!!"


# cd bed/
# rm *auc* *.txt

# cd peak/
# mkdir macs3_from_bedgraph_norm seacr_with_IgG_norm seacr_top0.01_norm
# mv *bedgraph_macs3* macs3_from_bedgraph_norm
# mv *bedgraph_seacr_with_IgG* seacr_with_IgG_norm
# mv *bedgraph_seacr_top0.01* seacr_top0.01_norm
