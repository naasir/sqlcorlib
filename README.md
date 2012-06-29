```
               __                ___ __  
   _________ _/ /________  _____/ (_) /_ 
  / ___/ __ `/ / ___/ __ \/ ___/ / / __ \
 (__  ) /_/ / / /__/ /_/ / /  / / / /_/ /
/____/\__, /_/\___/\____/_/  /_/_/_.___/ 
        /_/                              
```
A library of useful T-SQL functions and stored procedures.

### Compatibility
- Tested against SQL Server 2000 & SQL Server 2008.
- SQL Server 2005 should probably work too.

### Highlights
A few of the things that sqlcorlib simplifies:

##### Dropping multiple database objects based on a pattern:
```sql
exec sqlcorlib_drop_tables     @pattern='my_%' 
-- drops all tables that start with 'my_'

exec sqlcorlib_drop_procedures @pattern='my_%' 
-- drops all sprocs that start with 'my_'

exec sqlcorlib_drop_all        @pattern='my_%' 
-- drops pretty much any db object that starts with 'my_'
```

##### Working with fully-qualified database object names:
```sql
select dbo.sqlcorlib_format_full_name('[CURRENT_SERVER].[CURRENT_DB].[DBO].[MY_TABLE]', '@schema.@table')
-- returns: dbo.my_table

select dbo.sqlcorlib_get_full_name(default, default, default, 'my_table')
-- returns: [CURRENT_SERVER].[CURRENT_DB].[DBO].[MY_TABLE]
```
