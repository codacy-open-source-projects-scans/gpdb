show gp_resource_manager;

select rsgname, parent from pg_resgroup
  where rsgname not like 'rg_dump_test%'
  order by oid;
select avg(reslimittype)
  from pg_resgroupcapability
  where reslimittype <= 1;
select groupname from gp_toolkit.gp_resgroup_config
  where groupname not like 'rg_dump_test%'
  order by groupid;
select groupname from gp_toolkit.gp_resgroup_status
  where groupname not like 'rg_dump_test%'
  order by groupid;

alter resource group rg1 set cpu_max_percent 20;
alter resource group rg1 set cpu_max_percent 10;
drop resource group rg1;
create resource group rg1 with (cpu_max_percent=10, memory_quota=10);

alter resource group rg2 set cpu_max_percent 20;
alter resource group rg2 set cpu_max_percent 10;

-- TODO: change to the resgroup
