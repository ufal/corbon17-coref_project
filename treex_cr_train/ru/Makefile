NODETYPES=demonpron relpron reflpron.poss perspron noun

#################################################
########## MONOLINGUAL VERSION ##################
#################################################

######## REPLACE THE FOR SNIPPET #############
#		( cd $$i; make train_table CROSS_LINGUAL='' DATA_NAME=pcedt_bi; make train_test CROSS_LINGUAL='' DATA_NAME=pcedt_bi D='PCEDT.$(D)'; touch train.pcedt.done ) > $$i/train.pcedt.log 2>&1 & 
#		sleep 10; 

train_all_models :
	for i in $(NODETYPES); do \
		( cd $$i; make train_table; make train_test_allfeats D='$(D)'; touch train.done ) > $$i/train.log 2>&1 & \
		sleep 10; \
	done; \
	while [ `echo '$(NODETYPES)' | wc -w` -gt `ls */train.done | wc -l` ]; do \
		sleep 10; \
	done; \
	rm */train.done
