#!/bin/bash

inputdir=$1
outputdir=$2
analysistype=${3:-analysis}

mkdir -p log/de_$analysistype
job_count=`find $inputdir -name '*.txt' 2> /dev/null | wc -l`
i=0
for infile in $inputdir/*.txt; do
    echo "Processing $infile ..." >&2
    outfile=$outputdir/`basename $infile`
    if [ ! -e $outfile ]; then
        if [ $i -eq 0 ]; then
            if [ `qstat | wc -l` -gt 50 ]; then
                echo "sleep 60" >&2
                sleep 60
            fi
        fi
        qsubmit --jobname="de_$analysistype" --mem="50g" --queue="ms-all.q@*" --logdir="log/de_$analysistype" \
            "scripts/german_"$analysistype".sh $infile $outputdir"
        i=$((i++))
        if [ $i -gt 10 ]; then
            i=0
        fi
    fi
done
while [ `find $outputdir -name "*.txt"  2> /dev/null | wc -l` -lt $job_count ]; do
    sleep 10
done
