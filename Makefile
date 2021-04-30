# -*- mode: makefile-gmake -*-

.PHONY: clean
clean:
	rm -f sample.gz report.txt

wikipedia-article-titles.zip:
	kaggle datasets download residentmario/wikipedia-article-titles

titles.txt: wikipedia-article-titles.zip
	unzip -o $<
	touch $@

embeddings.csv.gz: titles.txt
	cat $? | \
	python -c "$$EMBEDDINGS" | \
	gzip > $@
define EMBEDDINGS
import csv
import numpy as np
import sys
import tensorflow as tf
import tensorflow_hub as hub
module_url = 'https://tfhub.dev/google/nnlm-en-dim50/2'
embed = hub.KerasLayer(module_url)
records = (" ".join(r.strip().lower().split("_")) for r in sys.stdin)
embeddings = ((r, "({0})".format(','.join(["%10.8f" % x for x in np.asarray(embed(tf.constant([r])))[0].tolist()]))) for r in records)
writer = csv.writer(sys.stdout)
writer.writerows(embeddings)
endef
export EMBEDDINGS

sample.gz: embeddings.csv.gz
	cat $< | \
	zcat | \
	shuf -n$(SAMPLES) | \
	gzip > $@

report.txt: sample.gz
	psql -c "drop table if exists item"
	psql -c "drop table if exists sample"
	psql -c "drop extension if exists cube"
	psql -c "create extension if not exists cube"
	psql -c "create table if not exists sample (id serial primary key, title text, embedding cube)"
	psql -c "\copy sample (title, embedding) from program 'cat $< | zcat' with (format csv, header true)"
	psql -c "create index on sample using gist (embedding)"
	psql -c "create table if not exists item as (select * from sample limit $(ITEMS))"
	pgbench -f test.sql -n -t $(TRANSACTIONS) -r -P 5 > $@
