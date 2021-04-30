# pgnns

# Quick Start #

## Download Embeddings ##

Download the pre-computed embeddings file `embeddings.csv.gz` from the following location on Google Drive.

https://drive.google.com/file/d/1XQa74OCJlun2e3CVbyhOuaMu7Mq6Ww3l/view?usp=sharing

## Create Environment Script ##

Create the file `setenv.sh` in the following way.  You're free to choose whatever values you like.  Note the following.

  * `SAMPLES` is the number of `(title, embedding)` pairs to import into the database.
  * `ITEMS` is the number of documents that can be treated as search targets.
  * `TRANSACTIONS` is the actual number of benchmark operations to perform, referring to the number of queries to make.

```sh
export PGHOST=localhost
export PGPORT=6432
export PGDATABASE=pgbench
export PGUSER=pgbench
export PGPASSWORD=pgbench
export SAMPLES=10000000
export ITEMS=1000
export TRANSACTIONS=10
```

## Start PostgreSQL Database ##

In one terminal window, run the following command to run an instance of PostgreSQL in a Docker image, using the environment variables established in `setenv.sh`.

```sh
source setenv.sh && docker run -e POSTGRES_DB=$PGDATABASE -e POSTGRES_USER=$PGUSER -e POSTGRES_PASSWORD=$PGPASSWORD -p $PGPORT:5432 postgres:13.2
```

## Run Benchmark ##

In another terminal window, run the following command to run the benchmark, using the same environment variables established in `setenv.sh`.

```sh
source setenv.sh && time make clean report.txt 
```

# Setup #

## Install Conda ##

## Create Conda Environment ##

## Install Conda Packages ##

## Set up Kaggle CLI ##

## Create Environment Script ##

## Start PostgreSQL Database ##

## Run Benchmark ##
