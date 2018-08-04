# OraclePrivilegeAudit
Scripts for auditing Oracle DB Privileges

These scripts may be used for reporting Oracle database level privileges. 
Both scripts have extensive comments, explaining how to use them and what to expect moreover key points to pay attention.

Unfortunately, there is no silver bullet for database level auditing that can report every anomaly/finding with a single script. Also; auditors who are assigned to audit database privileges should have intermediate to advanced SQL language knowledge and how databases work. 

Having said that, I'll try to explain in simplest way I can which concepts auditors may seek;
+ No user should have privileges to change live/production data except application users. (insert, delete, update, create, alter privileges)
+ No privileges should be granted to PUBLIC user because these privileges would be granted to anybody that can connect to database.
+ System privileges such as "SELECT ANY ...", "INSERT ANY ...", "CRATE ANY ..." containing ANY clauses should not be granted to users because they will let their users run these privileges database-wide. This is generally against segregation of duties.
+ Users should be granted SELECT privileges only for tables according to their organizational duties. "Need-to-know" basis should be taken in consideration with SELECT grants.
+ Even though scripts report privileges granted to roles and users, roles which are granted with critical privileges should be examined thoroughly. (see below: How Roles Work:)

Some Notes:
- If you encounter a privilege that you don't know, simply google it like "FLASHBACK DATABASE oracle privilege". You can also use links in script comments.

How Roles Work:
+ Roles can be understood as containers of grants, namely privileges. To draw an analogy; roles are baskets carrying privileges. 
 + Example: R_EXAMPLE is a role crated by DBA's. R_EXAMPLE is granted with 3 privileges "SELECT ANY TABLE","SELECT ANY VIEW" and "INSERT ON CORE.CUSTOMERS"

+ When roles are granted to users, these users are able to use all privileges that came with this role.
 + Example: User_01 is a user and granted with R_EXAMPLE (which is a role). Thus; User_01 can run SELECT scripts on every table and view on this database and insert rows on CORE.CUSTOMERS table.
 
+ Roles may also be granted with roles like a chain reaction. End users who are granted with such roles can use every privilege with this chain.
 + Example: R_ADMIN is a role crated by DBA's. R_ADMIN is granted with 2 privileges: "CREATE ANY TABLE", "DROP ANY TABLE". And also 1 role: R_EXAMPLE. Ultimately R_ADMIN has 2 privileges and 1 role.
 + Example: User_02 is a user object and granted with role R_ADMIN. Hence User_02 can:
   
   +1) Create or drop tables with R_ADMIN's: "CREATE ANY TABLE", "DROP ANY TABLE" privileges
   +2) Select every table or views on database because R_EXAMPLE's: "SELECT ANY TABLE","SELECT ANY VIEW" privileges
   +3) INSERT new rows on table CORE.CUSTOMERS because R_EXAMPLE's: "INSERT ON CORE.CUSTOMERS" privilege
   
It should be noted that this role/privilege structure makes it difficult to understand users ultimate privileges and determine if any anomalies are present.
