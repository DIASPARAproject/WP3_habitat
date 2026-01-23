select
    c.table_schema,
    c.table_name,
    c.column_name,
    c.udt_name , 
    c.character_maximum_length , 
    c.numeric_precision , 
    c.is_nullable,
    pgd.description
from pg_catalog.pg_statio_all_tables as st
inner join pg_catalog.pg_description pgd on (
    pgd.objoid = st.relid
)
inner join information_schema.columns c on (
    pgd.objsubid   = c.ordinal_position and
    c.table_schema = st.schemaname and
    c.table_name   = st.relname
)
where table_schema ='dat'

;

SELECT t.table_name , c.column_name , c.udt_name , c.character_maximum_length , c.numeric_precision , c.is_nullable
FROM information_schema.tables AS t
  join information_schema.columns as c on ( c.table_name = t.table_name )
where t.table_schema ='public'
order by t.table_name , c.ordinal_position