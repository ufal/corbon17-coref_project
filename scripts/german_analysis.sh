#!/bin/bash

infile=$1
outdir=$2

filename=`basename $infile`
mkdir -p /COMP.TMP/mnovak
tmpdir=`mktemp -d --tmpdir='/COMP.TMP/mnovak' 'wmt16.de_analysis.XXXXX'`
cat $infile | cut -f3 > $tmpdir/de.words.txt
java -Xmx2G -classpath tools/transition-1.30.jar is2.util.Split $tmpdir/de.words.txt > $tmpdir/de.words.conll
java -Xmx2G -classpath tools/transition-1.30.jar is2.lemmatizer2.Lemmatizer -test $tmpdir/de.words.conll -out $tmpdir/de.words.lemmas.conll -model tools/models/lemma-ger-3.6.model
cat $tmpdir/de.words.lemmas.conll | cut -f4 | sed ':a;N;$!ba;s/\n\n/__NEWLINE__/g' | sed ':a;N;$!ba;s/\n/ /g' | sed 's/__NEWLINE__/\n/g' > $tmpdir/de.lemmas.txt
cat $infile | cut -f1,2 | paste - $tmpdir/de.lemmas.txt > $outdir/$filename
rm -rf $tmpdir
