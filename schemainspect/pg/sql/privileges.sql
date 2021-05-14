select
    n.nspname as schema, 
    c.relname as name,
    case
        when c.relkind in ('r', 'v', 'm', 'f', 'p') then 'table'
        when c.relkind = 'S' then 'sequence'
        else null end as object_type, 
    pg_get_userbyid(acl.grantee) as "user", 
    acl.privilege
from
    pg_catalog.pg_class c
    join pg_catalog.pg_namespace n
         on n.oid = c.relnamespace,
    lateral (select aclx.*, privilege_type as privilege
             from aclexplode(c.relacl) aclx
             union
             select aclx.*, privilege_type || '(' || a.attname || ')' as privilege
             from
                 pg_catalog.pg_attribute a
                 cross join aclexplode(a.attacl) aclx
             where attrelid = c.oid and not attisdropped and attacl is not null ) acl
where
    acl.grantee != acl.grantor
    and c.relkind in ('r', 'v', 'm', 'S', 'f', 'p')
-- SKIP_INTERNAL and nspname not in ('pg_internal', 'pg_catalog', 'information_schema', 'pg_toast')
-- SKIP_INTERNAL and nspname not like 'pg_temp_%' and nspname not like 'pg_toast_temp_%'
order by schema, name, "user";
