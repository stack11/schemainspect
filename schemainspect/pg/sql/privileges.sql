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
-- SKIP_INTERNAL    and nspname not in ('pg_internal', 'pg_catalog', 'information_schema', 'pg_toast')
-- SKIP_INTERNAL    and nspname not like 'pg_temp_%' and nspname not like 'pg_toast_temp_%'
union
select
    routine_schema as schema,
    routine_name   as name,
    'function'     as object_type,
    grantee        as "user",
    privilege_type as privilege
from information_schema.role_routine_grants
where
    grantor != grantee
    and grantee != 'PUBLIC'
-- SKIP_INTERNAL    and routine_schema not in ('pg_internal', 'pg_catalog', 'information_schema', 'pg_toast')
-- SKIP_INTERNAL    and routine_schema not like 'pg_temp_%' and routine_schema not like 'pg_toast_temp_%'
union
SELECT '' as schema,
       n.nspname AS name,
       'schema' as object_type,
       r.rolname AS user,
       p.perm AS privilege
FROM pg_catalog.pg_namespace AS n
    CROSS JOIN pg_catalog.pg_roles AS r
    CROSS JOIN (VALUES ('USAGE'), ('CREATE')) AS p(perm)
WHERE has_schema_privilege(r.oid, n.oid, p.perm)
      AND NOT r.rolsuper
-- SKIP_INTERNAL    and n.nspname not in ('pg_internal', 'pg_catalog', 'information_schema', 'pg_toast')
-- SKIP_INTERNAL    and n.nspname not like 'pg_temp_%' and n.nspname not like 'pg_toast_temp_%'
order by schema, name, "user";
