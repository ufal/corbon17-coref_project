SHELL=/bin/bash

L1=en
L2=ru
LPAIR=$(L1)_$(L2)

OFFICIAL_TRAIN_DATA_DIR=data/official/data/raw/$(L1)-$(L2)/$(L1)-$(L2)

ALITRAIN_DIR=data/align_train/$(LPAIR)
ALITRAIN_TMP=tmp/align_train/$(LPAIR)

############################################### STAGE 1-2 ####################################################
############ PREPARE ALL TRAINING DATA FOR L1-L2 WORD ALIGNMENT MODEL ON LEMMATIZED TEXTS ####################
##############################################################################################################

ALITRAIN_IN_DIR=$(ALITRAIN_DIR)/00.in
ALITRAIN_SPLIT_DIR=$(ALITRAIN_DIR)/01.split
ALITRAIN_FOR_GIZA_DIR=$(ALITRAIN_DIR)/02.for_giza
ALITRAIN_IN_DATA_en_ru:=$(addprefix data/align_train/en_ru/00.in/,MultiUN.en-ru.txt.gz OpenSubtitles2016.en-ru.txt.gz TED2013.en-ru.txt.gz Wikipedia.en-ru.txt.gz)
ALITRAIN_IN_DATA_en_de:=$(addprefix data/align_train/en_de/00.in/,DGT.de-en.txt.gz EUbookshop.de-en.txt.gz Europarl.de-en.txt.gz MultiUN.de-en.txt.gz News-Commentary11.de-en.txt.gz OpenSubtitles2016.de-en.txt.gz Wikipedia.de-en.txt.gz)

merge_all : $(ALITRAIN_IN_DIR)/all.$(LPAIR).txt.gz
$(ALITRAIN_IN_DIR)/all.$(LPAIR).txt.gz : $(ALITRAIN_IN_DATA_$(LPAIR))
	zcat $^ | gzip -c > $@

filter_long_for_giza : $(ALITRAIN_IN_DIR)/all.$(LPAIR).filtered.txt.gz
$(ALITRAIN_IN_DIR)/all.$(LPAIR).filtered.txt.gz : $(ALITRAIN_IN_DIR)/all.$(LPAIR).txt.gz
	zcat $< | perl -ne 'my ($$s1, $$s2) = split /\t/, $$_; print $$_ if (length($$s1) < 3000 && length($$s2) < 3000);' | gzip -c > $@

data_split : $(ALITRAIN_IN_DIR)/all.$(LPAIR).filtered.txt.gz
	mkdir -p $(ALITRAIN_SPLIT_DIR)/all.$(LPAIR)
	zcat $< | split -d -a 7 -l 2000 - $(ALITRAIN_SPLIT_DIR)/all.$(LPAIR)/src_

for_giza : $(ALITRAIN_FOR_GIZA_DIR)/all.$(LPAIR).for_giza.gz
$(ALITRAIN_FOR_GIZA_DIR)/all.$(LPAIR).for_giza.gz :
	mkdir -p $(dir $@)
	treex -p --jobs=200 --priority=0 --workdir='$(ALITRAIN_TMP)/02.for_giza.runs/{NNN}-run-{XXXX}' \
		Read::SentencesTSV from='!$(ALITRAIN_SPLIT_DIR)/all.$(LPAIR)/src_* $(OFFICIAL_TRAIN_DATA_DIR)/*.txt' langs=$(L1),$(L2) selector=src \
		Util::SetGlobal selector=src \
		scenario/$(L1).lemmatize.scen \
		scenario/$(L2).lemmatize.scen \
		Write::LemmatizedBitexts selector=src language=$(L1) to_language=$(L2) to_selector=src \
	| gzip -c > $@

#W2A::RU::Tokenize
#W2A::CS::Tokenize

############################################### STAGE 3 ######################################################
################ RUN GIZA++ TO OBTAIN WORD ALIGNMENT ON PCEDT_19 (CAN BE USED DIRECTLY) ######################
############ AS WELL AS CS-RU WORD ALIGNMENT MODEL (CAN BE USED BY MGIZA; PERFORMS WORSE) ####################
##############################################################################################################

ALITRAIN_GIZA_DIR=$(ALITRAIN_DIR)/03.giza

#		--continue-dir=$(ALITRAIN_TMP)/03.giza.tempdir/gizawrapO6KJ

giza : $(ALITRAIN_GIZA_DIR)/all.$(LPAIR).giza.gz
$(ALITRAIN_GIZA_DIR)/all.$(LPAIR).giza.gz : $(ALITRAIN_FOR_GIZA_DIR)/all.$(LPAIR).for_giza.filtered.gz
	mkdir -p $(dir $@)
	bin/gizawrapper.pl \
		--tempdir=$(ALITRAIN_TMP)/03.giza.tempdir \
		--bindir=$(shell pwd)/bin $< \
		--lcol=1 --rcol=2 \
		--keep \
		--dirsym=gdfa,int,left,right,revgdfa \
	| paste <(zcat $< | cut -f1 ) - \
	| gzip > $@


#============================ OLD STUFF TO BE REMOVED OR ADJUSTED FOLLOWS ===================================
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv


############################################### STAGE 3 ######################################################
############################## IMPORT RUSSIAN TRANSLATIONS TO PCEDT_19 #######################################
##############################################################################################################

PCEDT_19_LIST=/home/mnovak/projects/align_coref/data/train_19_00-49.orig.list

pcerdt_19 : out/pcerdt_19/full.list
out/pcerdt_19/full.list : $(PCEDT_19_LIST) data/pcedt_19/all.ru.untok.txt
	mkdir -p $(dir $@) 
	treex -Ssrc -Lru \
		Read::Treex from='@$(word 1,$^)' \
		Import::Sentences from='$(word 2,$^)' \
		Write::Treex storable=1 path='$(dir $@)'
	find $(dir $@) -name '*.streex' | sed 's|.*/||' | sort > $@

############################################### STAGE 4 ######################################################
############## PREPARE RU-CS WORD ALIGNMENT FOR PCEDT_19 TO BE IMPORTED INTO PCEDT_19  #######################
##############################################################################################################

out/pcedt_19.cs-ru.giza.gz : out/all.cs-ru.giza.gz out/pcerdt_19/full.list
	treex \
		Read::Treex from='@out/pcerdt_19/full.list' \
		Util::Eval bundle='print $$bundle->get_document->full_filename . ".streex-" . $$bundle->id . "\n";' \
	> out/pcerdt_19.bundle.ids
	sentnum=`cat out/pcerdt_19.bundle.ids | wc -l`; \
	zcat $(word 1,$^) | tail -n $$sentnum | cut -f1 --complement | cut -f1,2,6,7 | paste out/pcerdt_19.bundle.ids - | gzip -c > $@

# TODO: the following target swaping the order of cs-ru alignment to ru-cs is here only for the time being
# if GIZA is run again, ru-cs alignemnt should be created
# or the blocks Align::A::InsertAlignmentFromFile and Align::A::AlignMGiza should be extended with the link swaping mechanism

out/pcedt_19.ru-cs.giza.gz : out/pcedt_19.cs-ru.giza.gz
	zcat $< | \
		perl -ne 'my @cols = split /\t/, $$_; my @alis = splice @cols, 1, 2; my @new_alis = map {my @links = split / /, $$_; join " ", map {my ($$a, $$b) = split /-/, $$_; $$b."-".$$a} @links} @alis; unshift @new_alis, shift @cols; push @new_alis, @cols; print join "\t", @new_alis;' | \
		gzip -c > $@

############################################## STAGE 5a ######################################################
####### MORPHO-ANALYZE RUSSIAN TRANSLATIONS OF PCEDT_19 AND IMPORT RU-CS GIZA++ WORD ALIGNMENT   #############
##############################################################################################################

pcerdt_19_giza : out/pcerdt_19_giza/full.list
out/pcerdt_19_giza/full.list : out/pcerdt_19/full.list out/pcedt_19.ru-cs.giza.gz
	mkdir -p $(dir $@)
	treex -Ssrc -Lru \
		Read::Treex from='@$(word 1,$^)' \
		W2A::RU::Tokenize \
		W2A::TagTreeTagger lemmatize=1 \
		Align::A::InsertAlignmentFromFile from='$(word 2,$^)' \
			inputcols=gdfa_int_therescore_backscore \
			selector=src language=ru to_selector=src to_language=cs \
		Write::Treex storable=1 path='$(dir $@)'
	find $(dir $@) -name '*.streex' | sed 's|.*/||' | sort > $@

# TODO: the following target should be adjusted to produce ru-cs alignment, not cs-ru

############################################## STAGE 5b ######################################################
##### MORPHO-ANALYZE RUSSIAN TRANSLATIONS OF PCEDT_19 AND ANNOTATE RU-CS WORD ALIGNMENT WITH MGIZA   #########
##############################################################################################################

pcerdt_19_mgiza : out/pcerdt_19_mgiza/full.list
out/pcerdt_19_mgiza/full.list : out/pcerdt_19/full.list
	mkdir -p $(dir $@) 
	treex -p --jobs 50 -Ssrc -Lru \
		Read::Treex from='@$<' \
		W2A::RU::Tokenize \
		W2A::TagTreeTagger lemmatize=1 \
		Align::A::AlignMGiza from_language=cs from_selector=src to_language=ru to_selector=src \
			dir_or_sym=intersection,grow-diag-final-and model_from_share=cs-ru cpu_cores=1 \
		Write::Treex storable=1 path='$(dir $@)'
	find $(dir $@) -name '*.streex' | sed 's|.*/||' | sort > $@

#-------------------------------------------------------------------------------------------------------------
#----------------- PREPARE ALI_ANNOT FILES FOR MANUAL ANNOTATION OF WORD ALIGNMENT ---------------------------
#------------------- MOST LIKELY OBSOLETE, REPLACED BY PROCESSING IN ../PCEDT-R ------------------------------
#-------------------------------------------------------------------------------------------------------------

ALL_LANGUAGES=cs,en,ru
LANGUAGE=en
ANNOT_LANGUAGES=$(shell perl -e 'print join ",", grep {$$_ ne "$(LANGUAGE)"} split /,/, $$ARGV[0];' $(ALL_LANGUAGES))
ALIGN_TYPES=$(shell perl -e 'my $$types = {en => {cs => "gold", ru => ".*"}, cs => {en => "gold", ru => ".*"}, ru => {cs => ".*", en => "gold"}}; print join ",", map {$$types->{"$(LANGUAGE)"}{$$_}} split /,/, "$(ANNOT_LANGUAGES)"')
FILTER=poss

print_annot_files : annot/$(LANGUAGE)_$(FILTER)/align.src.sec19_00-49.all.clean.ali_annot
annot/$(LANGUAGE)_$(FILTER)/align.src.sec19_00-49.all.clean.ali_annot : out/pcerdt_19_giza/full.list
	mkdir -p $(dir $@)
	treex -Ssrc -L$(LANGUAGE) \
		Read::Treex from='@$<' \
		Print::AlignAnnot filter=$(FILTER) layer=a annot_langs='$(ANNOT_LANGUAGES)' align_types='$(ALIGN_TYPES)' to='-' \
	> $@


############################################### STAGE 6 ######################################################
############################ TRAIN UDPipe ON RUSSIAN PRAGUE-STYLE HAMLEDT   ##################################
######### NONE OF THE CURRENT SOLUTIONS FOR TAGGING AND PARSING IN TREEX ARE MUTUALLY COMPATIBLE #############
##############################################################################################################

# Prerequisities:
# * Russian model for Malt Parser was trained with the version 1.5 => check if the version is not newer and change it in a reversed way as it was done in commit "3080b9ea5d12" (see GitHub/treex)

HAMLEDT_RU_TREEX_DIR=/ha/projects/tectomt_shared/data/resources/hamledt/ru/treex/01
UDPIPE_TRAIN_TMP_DIR=/net/cluster/TMP/mnovak/ru_cs_prons/ru_udpipe_train_tmp

udpipe_ru_train_to_conll : $(UDPIPE_TRAIN_TMP_DIR)/hamledt_conllu/train.conll
udpipe_ru_dev_to_conll : $(UDPIPE_TRAIN_TMP_DIR)/hamledt_conllu/dev.conll
$(UDPIPE_TRAIN_TMP_DIR)/hamledt_conllu/%.conll : $(HAMLEDT_RU_TREEX_DIR)/%
	mkdir -p $(dir $@)/$*
	treex -p --jobs=100 -Lru \
		Read::Treex from='!$</*.treex.gz' \
		Write::CoNLLX pos_attribute='tag' deprel_attribute='deprel' is_member_within_afun=1 path='$(dir $@)/$*'
	cat $(dir $@)/$*/*.conll > $@

UDPIPE=/net/projects/udpipe/bin/udpipe-1.0.0-bin/bin-linux64/udpipe

$(UDPIPE_TRAIN_TMP_DIR)/ru.hamledt.prague.model : $(UDPIPE_TRAIN_TMP_DIR)/hamledt_conllu/train.conll $(UDPIPE_TRAIN_TMP_DIR)/hamledt_conllu/dev.conll
	$(UDPIPE) --train $@ --heldout=$(word 2,$^) $(word 1,$^)

############################################### STAGE 7 ######################################################
##################### RUN RUSSIAN UDPipe AND A2T ANALYSIS ON RUSSIAN PART OF PCEDT-R  ########################
####################### THIS BLOCK DELETES RUSSIAN MORPHO ANNOTATION CREATED SO FAR, #########################
############################## AS NO SYNTACTIC PARSER IS COMPATIBLE WITH IT ##################################
##############################################################################################################

pcerdt_19_tecto : out/pcerdt_19_tecto/full.list
out/pcerdt_19_tecto/full.list : out/pcerdt_19_giza/full.list
	mkdir -p $(dir $@)
	treex -p -Ssrc -Lru \
		Read::Treex from='@$<' \
		Util::Eval zone='$$.remove_tree("a");' \
		Scen::Analysis::RU unknown_afun_to_atr=0 default_functor='' \
		Write::Treex storable=1 path='$(dir $@)' \
		Write::PDT path='$(dir $@)'
	find $(dir $@) -name '*.t.gz' | sed 's|.*/||' | sort > $(dir $@)/full.t.list
	find $(dir $@) -name '*.streex' | sed 's|.*/||' | sort > $@
