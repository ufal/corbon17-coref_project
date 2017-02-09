#!/bin/bash

infile=$1
outdir=$2
is_conll=${3:-0}


filename=`basename $infile`
mkdir -p /COMP.TMP/mnovak
tmpdir=`mktemp -d --tmpdir='/COMP.TMP/mnovak' 'wmt16.de_analysis.XXXXX'`
echo $tmpdir >&2
if [ $is_conll == 0 ]; then 
    cat $infile | cut -f2 > $tmpdir/de.words.txt
    java -Xmx2G -classpath tools/transition-1.30.jar is2.util.Split $tmpdir/de.words.txt > $tmpdir/de.words.conll
else
    cat $infile | grep -v '^#' | perl -ne 'chomp $_; my ($ord, $word, @rest) = split /\t/, $_; for (my $i=0; $i<@rest; $i++) { $rest[$i] =~ s/-/_/g; }; $rest[12] = "_"; print join "\t", ($ord, $word, @rest); print "\n";' > $tmpdir/de.words.conll
fi
java -Xmx2G -classpath tools/transition-1.30.jar is2.lemmatizer2.Lemmatizer -test $tmpdir/de.words.conll -out $tmpdir/de.words.lemmas.conll -model tools/models/lemma-ger-3.6.model
java -Xmx40G -classpath tools/transition-1.30.jar is2.transitionS2a.Parser -test $tmpdir/de.words.lemmas.conll -out $tmpdir/de.parse.conll -model tools/pet-ger-S2a-40-0.25-0.1-2-2-ht4-hm4-kk0
cp $tmpdir/de.parse.conll $outdir/$filename
rm -rf $tmpdir
