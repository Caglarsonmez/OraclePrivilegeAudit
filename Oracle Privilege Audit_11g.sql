/*This script reports every privilege granted to roles/users in current database. User who runs this script must have select privilege to some catalog views in SYS object.
If script returns "Table or view does not exists" error it means that current user does not have sufficient privileges for certain views, thus auditing database privileges. Views that are used in this script are listed below;
dba_role_privs, dba_sys_privs, dba_tab_privs, DBA_COL_PRIVS
These views can/should be granted for select to auditors.
This script is meant to work on Oracle 11G databases. You can determine version of your current database with "SELECT * FROM V$VERSION" query.*/

select *

from (

select
tab.Privilege_Type,
tab.Grantee,
(case when tab.Grantee in ('SYS','OUTLN','SYSTEM','PERFSTAT', 'ANONYMOUS',  'APEX_040200',  'APEX_PUBLIC_USER',  'APPQOSSYS',  'AUDSYS',  'CTXSYS',  'DBSNMP',  'DIP',  'DVF',  'DVSYS',  'EXFSYS',  'FLOWS_FILES',  'GSMADMIN_INTERNAL',  'GSMCATUSER',  'GSMUSER',  'LBACSYS',  'MDDATA',  'MDSYS',  'ORACLE_OCM',  'ORDDATA',  'ORDPLUGINS',  'ORDSYS',  'OUTLN',  'SI_INFORMTN_SCHEMA',  'SPATIAL_CSW_ADMIN_USR',  'SPATIAL_WFS_ADMIN_USR',  'SYS',  'SYSBACKUP',  'SYSDG',  'SYSKM',  'SYSTEM',  'WMSYS',  'XDB',  'XS$NULL',  'OLAPSYS',  'OJVMSYS',  'DV_SECANALYST')  then 'System User'
       when tab.Grantee in ('DBA') then 'DBA'
        when r.ROLE is not null then 'Role'
         when u.username is not null then 'User/Object'
          when tab.Grantee='PUBLIC' then tab.Grantee
           else 'Other / Script Error' end) Grantee_Type,
tab.Privilege_or_Role Granted_role,
(case when tp2.grantee is not null then tp2.privilege else tab.Privilege_or_Role end) Privilege_or_Role,
(case when (case when tp2.grantee is not null then tp2.privilege else tab.Privilege_or_Role end) in ('ALTER','WRITE','INSERT','DELETE','UPDATE','BECOME USER','ALTER ANY MATERIALIZED VIEW','ALTER ANY ROLE','ALTER ANY TABLE','ALTER DATABASE','ALTER SESSION','ALTER SYSTEM','ALTER USER','CREATE ANY JOB','CREATE ANY MATERIALIZED VIEW','CREATE ANY PROCEDURE','CREATE ANY TABLE','CREATE ANY VIEW','CREATE MATERIALIZED VIEW','CREATE PROCEDURE','CREATE ROLE','CREATE TABLE','CREATE USER','CREATE VIEW','DELETE ANY TABLE','DROP ANY MATERIALIZED VIEW','DROP ANY ROLE','DROP ANY TABLE','DROP ANY VIEW','DROP PUBLIC DATABASE LINK','DROP USER','EXPORT FULL DATABASE','GRANT ANY OBJECT PRIVILEGE','GRANT ANY PRIVILEGE','GRANT ANY ROLE','INSERT ANY TABLE','MERGE ANY VIEW','UPDATE ANY TABLE') then 'Critical Privilege' when (case when tp2.grantee is not null then tp2.privilege else tab.Privilege_or_Role end) like '%SELECT%' then 'Select/View Privilege'  else 'Others' end) Privilege_or_Role_Critical_flg,
(case when tp2.grantee is not null then tp2.owner||'.'||tp2.table_name else tab.Granted_Object end) Granted_Object,
(case when tp2.owner like '%SYS%' or substr(tab.Granted_Object,0,instr(tab.Granted_Object,'.')-1) like '%SYS%' then 'System Object'
      when tp2.owner like '%XDB%' or substr(tab.Granted_Object,0,instr(tab.Granted_Object,'.')-1) like '%XDB%' then 'System Object'
      when tp2.owner like '%MASTER%' or substr(tab.Granted_Object,0,instr(tab.Granted_Object,'.')-1) like '%MASTER%' then 'System Object'
      when tp2.owner like '%SQLTXPLAIN%' or substr(tab.Granted_Object,0,instr(tab.Granted_Object,'.')-1) like '%SQLTXPLAIN%' then 'System Object'
      else 'Data Object' end) Privilege_or_Role_Type_Flag,
(case when tp2.grantee is not null then null else tab.Granted_Object_Type end) Granted_Object_Type
from
(
-- DBA_ROLE_PRIVS --
select 'Role Privileges' Privilege_Type,
rp.GRANTEE Grantee,
rp.granted_role Privilege_or_Role,
null Granted_Object,
null Granted_Object_Type
from dba_role_privs rp -- Privileges or roles granted to roles. Roles may also be granted to roles. See Readme for further explanation.
-- DBA_ROLE_PRIVS --
union all
-- DBA_SYS_PRIVS --
select 'System Defined Privileges' Privilege_Type,
sp.GRANTEE Grantee,
sp.privilege Privilege_or_Role,
null Granted_Object,
null Granted_Object_Type
from dba_sys_privs sp -- System defined privileges. see: https://docs.oracle.com/cd/B19306_01/network.102/b14266/admusers.htm#i1008788 and https://docs.oracle.com/cd/B28359_01/network.111/b28531/authorization.htm#g2199949
-- DBA_SYS_PRIVS --
union all
-- DBA_TAB PRIVS --
select 'Table Privileges' Privilege_Type,
TP.GRANTEE Grantee,
tp.privilege Privilege_or_Role,
tp.owner||'.'||tp.table_name Granted_Object,
null Granted_Object_Type
from dba_tab_privs tp -- Privileges that granted for spesific tables
-- DBA_TAB PRIVS --
union all
-- DBA_COL_PRIVS --
SELECT 'Column Privileges' Privilege_Type,
CP.GRANTEE Grantee,
CP.privilege Privilege_or_Role,
CP.owner||'.'||CP.table_name||'.'||cp.column_name Granted_Object,
'Column' Granted_Object_Type
FROM DBA_COL_PRIVS CP
-- DBA_COL_PRIVS --
) tab
left join dba_tab_privs tp2 on TP2.GRANTEE=tab.Privilege_or_Role --  This join is used to retrieve roles granted to roles. See Readme for further explanation
left join dba_roles r on (r.ROLE=tab.Grantee)
left join dba_users u on (u.username=tab.Grantee)
) x

where x.Privilege_or_Role_Type_Flag='Data Object' -- To exclude system objects
and x.Grantee_Type != 'System User' -- to exclude system users
/* Additional condition examples*/

--and x.Privilege_or_Role_Critical_flg='Critical Privilege' -- Excluding select and other privileges and reporting only critical change permissons granted to users
--and x.Privilege_or_Role_Critical_flg='Select/View Privilege' -- Excluding change and other privileges and reporting only table view permissions
--and x.Grantee ='DEVUSER' -- for reporting privileges or roles granted to a certain user/role
--and x.Grantee ='PUBLIC' -- for reporting privileges or roles granted to a PUBLIC; meaning every user on database
--and x.Privilege_or_Role='SELECT ANY TABLE' -- for reporting users/roles granted with certain roles/privileges
--and x.Privilege_or_Role like '%INSERT%' -- for reporting users/roles granted with certain roles/privileges but with like condition
--and x.Granted_Object = 'EDW.CMP_PROPOSAL' -- for reporting privileges granted to users and roles for certain tables (Caution: can be used only for grants given for spesific tables. Many roles/privileges on databases are effective on all tables)
--and x.Granted_Object like 'EDW%' -- for reporting privileges granted to users and roles for certain tables with like condition

order by Privilege_Type, Grantee, Granted_Object
