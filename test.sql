-- -*- sql-product: postgres; -*-

select sample.title from sample order by sample.embedding <-> cube(':EMBEDDING') limit 10;


