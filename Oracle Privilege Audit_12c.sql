/*Çalýþtýrýldýðý veri tabanýnda bulunan rollere atanmýþ yetkileri listeler. Çalýþtýran kiþinin ilgili veri tabanýnda SYS þemasýndaki view'larda da görüntüleme yetkisi olmasý gerekir. 
Sorgu "Table or view does not exists" hatasý alýrsa çalýþtýran kullanýcýnýn bu tabloya yetkisi yok demektir. Yetki talep edilmeli veya DBA'lerden bu sorguyu çalýþtýrmalarý talep edilmelidir.*/
/*Bu script Oracle 12C ve öncesi veritabanlarý içindir. Çalýþtýðýnýz veritabaný versiyonunu öðrenmek için "SELECT * FROM V$VERSION" sorgusunu kullanabilirsiniz.*/

select * 

from (

select 
tab.Yetki_Türü,
tab.Yetkili,
(case when tab.Yetkili in ('SYS','OUTLN','SYSTEM','PERFSTAT', 'ANONYMOUS',  'APEX_040200',  'APEX_PUBLIC_USER',  'APPQOSSYS',  'AUDSYS',  'CTXSYS',  'DBSNMP',  'DIP',  'DVF',  'DVSYS',  'EXFSYS',  'FLOWS_FILES',  'GSMADMIN_INTERNAL',  'GSMCATUSER',  'GSMUSER',  'LBACSYS',  'MDDATA',  'MDSYS',  'ORACLE_OCM',  'ORDDATA',  'ORDPLUGINS',  'ORDSYS',  'OUTLN',  'SI_INFORMTN_SCHEMA',  'SPATIAL_CSW_ADMIN_USR',  'SPATIAL_WFS_ADMIN_USR',  'SYS',  'SYSBACKUP',  'SYSDG',  'SYSKM',  'SYSTEM',  'WMSYS',  'XDB',  'XS$NULL',  'OLAPSYS',  'OJVMSYS',  'DV_SECANALYST') or u.common='YES' then 'Sistem Kullanýcýsý'
       when tab.Yetkili in ('DBA') then 'DBA'
        when r.ROLE is not null then 'Rol' 
         when u.username is not null then 'User/Obje' 
          when tab.Yetkili='PUBLIC' then tab.Yetkili 
           else 'Diðer (sorguda sýkýntý var)' end) Yetkili_Türü,
tab.Yetki Yetki_Veya_Rol,
(case when tp2.grantee is not null then tp2.privilege else tab.Yetki end) Yetki,
(case when (case when tp2.grantee is not null then tp2.privilege else tab.Yetki end) in ('ALTER','WRITE','INSERT','DELETE','UPDATE','BECOME USER','ALTER ANY MATERIALIZED VIEW','ALTER ANY ROLE','ALTER ANY TABLE','ALTER DATABASE','ALTER SESSION','ALTER SYSTEM','ALTER USER','CREATE ANY JOB','CREATE ANY MATERIALIZED VIEW','CREATE ANY PROCEDURE','CREATE ANY TABLE','CREATE ANY VIEW','CREATE MATERIALIZED VIEW','CREATE PROCEDURE','CREATE ROLE','CREATE TABLE','CREATE USER','CREATE VIEW','DELETE ANY TABLE','DROP ANY MATERIALIZED VIEW','DROP ANY ROLE','DROP ANY TABLE','DROP ANY VIEW','DROP PUBLIC DATABASE LINK','DROP USER','EXPORT FULL DATABASE','GRANT ANY OBJECT PRIVILEGE','GRANT ANY PRIVILEGE','GRANT ANY ROLE','INSERT ANY TABLE','MERGE ANY VIEW','UPDATE ANY TABLE') then 'Kritik Deðiþiklik Yetkisi' when (case when tp2.grantee is not null then tp2.privilege else tab.Yetki end) like '%SELECT%' then 'Tablo Okuma Yetkisi'  else 'Diðer' end) Yetki_Kritikliði,
(case when tp2.grantee is not null then tp2.owner||'.'||tp2.table_name else tab.Yetkili_Olunan_Obje end) Yetkili_Olunan_Obje,
(case when tp2.owner like '%SYS%' or substr(tab.Yetkili_Olunan_Obje,0,instr(tab.yetkili_olunan_obje,'.')-1) like '%SYS%' then 'Sistem Þemasý' 
      when tp2.owner like '%XDB%' or substr(tab.Yetkili_Olunan_Obje,0,instr(tab.yetkili_olunan_obje,'.')-1) like '%XDB%' then 'Sistem Þemasý'
      when tp2.owner like '%MASTER%' or substr(tab.Yetkili_Olunan_Obje,0,instr(tab.yetkili_olunan_obje,'.')-1) like '%MASTER%' then 'Sistem Þemasý'
      when tp2.owner like '%SQLTXPLAIN%' or substr(tab.Yetkili_Olunan_Obje,0,instr(tab.yetkili_olunan_obje,'.')-1) like '%SQLTXPLAIN%' then 'Sistem Þemasý'
      else 'Veri Þemasý' end) Yetki_Þema_Tipi_FLG, 
(case when tp2.grantee is not null then TP2.TYPE else tab.Obje_tipi end) Obje_tipi
from
(
-- DBA_ROLE_PRIVS -- 
select 'Rol Yetkisi' Yetki_Türü,
rp.GRANTEE Yetkili,
rp.granted_role Yetki,
null Yetkili_Olunan_Obje,
null Obje_tipi
from dba_role_privs rp -- rollere verilen yetkiler. Bir role baþka bir rol de yetki gibi verilebilir.
-- DBA_ROLE_PRIVS --  
union all
-- DBA_SYS_PRIVS -- 
select 'Sistem Rol Yetkisi' Yetki_Türü,
sp.GRANTEE Yetkili,
sp.privilege Yetki,
null Yetkili_Olunan_Obje,
null Obje_tipi 
from dba_sys_privs sp -- Sistem rolleri. bkz: https://docs.oracle.com/cd/B19306_01/network.102/b14266/admusers.htm#i1008788 ve https://docs.oracle.com/cd/B28359_01/network.111/b28531/authorization.htm#g2199949
-- DBA_SYS_PRIVS -- 
union all
-- DBA_TAB PRIVS -- 
select 'Tablo Yetkisi' Yetki_Türü,
TP.GRANTEE Yetkili,
tp.privilege Yetki,
tp.owner||'.'||tp.table_name Yetkili_Olunan_Obje,
tp.type Obje_tipi
from dba_tab_privs tp -- Tablo bazýnda yetkilendirmeler
-- DBA_TAB PRIVS -- 
union all
-- DBA_COL_PRIVS -- 
SELECT 'Kolon Yetkisi' Yetki_Türü,
CP.GRANTEE Yetkili,
CP.privilege Yetki,
CP.owner||'.'||CP.table_name||'.'||cp.column_name Yetkili_Olunan_Obje,
'Kolon' Obje_tipi 
FROM DBA_COL_PRIVS CP
-- DBA_COL_PRIVS -- 
) tab
left join dba_tab_privs tp2 on TP2.GRANTEE=tab.YETKI -- bu join sayesinde bir role farklý bir rol yetki olarak verildiyse bu rol sayesinde kazanýlan tablo seviyesi yetkiler de getirilmektedir.
left join dba_roles r on (r.ROLE=tab.yetkili)
left join dba_users u on (u.username=tab.yetkili)
) x

where x.Yetki_Þema_Tipi_FLG='Veri Þemasý' -- Sistem þemalarýný elemek için
and x.Yetkili_türü != 'Sistem Kullanýcýsý' and x.Yetki_kritikliði='Kritik Deðiþiklik Yetkisi'
/* ek koþul örnekleri:*/
--and x.Yetkili ='DEVUSER' -- belli bir role ait rol, tablo ve/veya kolon seviyesi yetkileri (priviledge) getirmek için
--and x.Yetki_veya_rol='SELECT ANY TABLE' -- belirli bir yetkinin hangi rol/kullanýcýlara verildiðini getirmek için
--and x.Yetki_veya_rol like '%INSERT%' -- belirli bir yetkinin hangi rol/kullanýcýlara verildiðini getirmek için
--and x.Yetkili_Olunan_obje = 'EDW.CMP_PROPOSAL' -- belirli bir þema veya tablo/kolon üzerinde hangi yetkilerin olduðunu getirmek için (DÝKKAT: yalnýzca obje bazýnda verilen yetkiler için kullanýnýz. Create Table vb birçok yetki tablo/kolon seviyesinde deðil system priviledge seviyesinde verildiðinden bir üstteki aramada incelenmelidir)
--and x.Yetkili_Olunan_obje like 'EDW%' -- belirli bir þema veya tablo/kolon üzerinde hangi yetkilerin olduðunu getirmek için (DÝKKAT: yalnýzca obje bazýnda verilen yetkiler için kullanýnýz. Create Table vb birçok yetki tablo/kolon seviyesinde deðil system priviledge seviyesinde verildiðinden bir üstteki aramada incelenmelidir)
order by Yetki_türü, Yetkili, Yetkili_olunan_obje
