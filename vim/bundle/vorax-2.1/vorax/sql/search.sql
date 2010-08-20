set termout off
define vorax_param_query=''
column param_query new_value vorax_param_query
select 'union select rpad(name, 81) || '' :PARAM'' from v$parameter where upper(name) like ''%&1%''' param_query from all_views where owner='SYS' and view_name='V_$PARAMETER';
set termout on

select distinct rpad(object_name, 81) || ' :' || object_type
  from all_objects
 where object_type in ('SEQUENCE',
                       'PROCEDURE',
                       'PACKAGE',
                       'TYPE',
                       'CONTEXT',
                       'TRIGGER',
                       'DIRECTORY',
                       'MATERIALIZED VIEW',
                       'TABLE',
                       'INDEX',
                       'VIEW',
                       'FUNCTION',
                       'CLUSTER',
                       'SYNONYM',
                       'JOB')
  and object_name not like '/%' and
  upper(object_name) like '%&1%' &vorax_param_query
;

undefine vorax_param_query

