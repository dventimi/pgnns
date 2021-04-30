# -*- mode: makefile-gmake -*-

.PHONY: clean
clean:
	rm -f sample.csv.gz report_pgnns.txt report_anndb.jsonl

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

sample.csv.gz: embeddings.csv.gz
	cat $< | \
	zcat | \
	shuf -n$(SAMPLES) | \
	gzip > $@

report_pgnns.txt: sample.csv.gz
	psql -c "drop table if exists sample cascade"
	psql -c "drop extension if exists cube cascade"
	psql -c "create extension if not exists cube"
	psql -c "create table if not exists sample (id serial primary key, title text, embedding cube)"
	psql -c "\copy sample (title, embedding) from program 'cat $< | zcat' with (format csv, header true)"
	psql -c "create index on sample using gist (embedding)"
	pgbench -f test.sql -n -t $(TRANSACTIONS) -r -P 5 -DEMBEDDING="$$(psql -c 'select embedding from sample order by random() limit 1' -At)" > $@

anndb.csv.gz: sample.csv.gz
	cat $< | \
	zcat | \
	python -c "$$ANNDB_LOAD" | \
	gzip > $@
define ANNDB_LOAD
import anndb_api
import csv
import sys
from itertools import islice
def batch(iterable, n=10):
    i = iter(iterable)
    piece = list(islice(i, n))
    while piece:
        yield piece
        piece = list(islice(i, n))
client = anndb_api.Client('$(APIKEY)')
dataset = client.vector('$(DATASET)')
records = csv.reader(sys.stdin)
pairs = ([list(eval(r[1])), {'title': r[0]}] for r in records)
items = (anndb_api.VectorItem(None, p[0], p[1]) for p in pairs)
batches = batch(items, 10)
results = (dataset.insert_batch(b) for b in batches)
urns = (list(map(lambda x: x.id.urn, r)) for r in results)
writer = csv.writer(sys.stdout)
writer.writerows(urns)
endef
export ANNDB_LOAD

report_anndb.jsonl: sample.csv.gz
	cat $< | \
	zcat | \
	shuf -n10 | \
	python -c "$$ANNDB_TEST" > $@
define ANNDB_TEST
import anndb_api
import csv
import jsonlines
import sys
client = anndb_api.Client('$(APIKEY)')
dataset = client.vector('$(DATASET)')
records = csv.reader(sys.stdin)
pairs = ([list(eval(r[1])), {'title': r[0]}] for r in records)
results = ([p[1], list(map(lambda i: [i.id.urn, i.metadata['title']], dataset.search(p[0], 10)))] for p in pairs)
writer = jsonlines.Writer(sys.stdout)
writer.write_all(results)
endef
export ANNDB_TEST
