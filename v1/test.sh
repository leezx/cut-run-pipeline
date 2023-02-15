
cat all.sample.labelled.csv | while IFS="," read sample fq1 fq2; do
echo "$sample : $fq1, $fq2"

out_dir3=bam
seqDepthDouble=`samtools view -F 0x04 $out_dir3/${sample}.bam | wc -l`
seqDepth=$((seqDepthDouble/2))
echo $seqDepth 
max1=4000000
max2=800000
ratio=5746/7553

flag=`echo $sample | grep IgG`
if [[ "$flag" = "" ]]
then
    echo '$sample is not IgG!!!!'
    scale_factor=`echo "$max1 / $seqDepth" | bc -l`
    echo "Scaling factor for $sample is: $scale_factor!"
else
    echo '$sample is IgG'
    scale_factor=`echo "$max2 / $seqDepth * $ratio" | bc -l`
    echo "Scaling factor for $sample is: $scale_factor!"
fi

done
