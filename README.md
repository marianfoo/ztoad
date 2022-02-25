# ZTOAD

## Overview
Open SQL Editor

   Program : ZTOAD  
   Author  : S. Hermann  
   Date    : 31.12.2017  
   Version : 4.0.2  

This is just a clone of the original [ZTOAD](http://quelquepart.biz/article7/ztoad-requeteur-open-sql), an Open SQL editor.

The original ZTOAD version is available as a [SAPlink nugget](http://quelquepart.biz/telechargements&file=L2RhdGEvZG9jdW1lbnRzL3p0b2FkLnppcCozZThiNjE) and can be installed on a SAP System with [SAPlink](http://saplink.org).

This version can easily be installed on a SAP System with [abapGit](https://github.com/larshp/abapGit).

![image](https://user-images.githubusercontent.com/13335743/155726476-0145978c-539d-4408-a22b-3a41b7b7ac6f.png)



## Description

This program allow you to execute query directly on the server
1. Write your query in the editor window (ABAP SQL)
2. View the result in ALV window (in case of SELECT query)

Features :
The top center pane allow you to write your query in ABAP SQL format.
Query can be complex with JOIN, UNION and subqueries. You can write
query on several lines. You could also add spaces.
To add comment, start the line by * or prefix your comment by "

You could write several queries in the query editor, separated by
dot ".". To execute one of them, highlight all the wanted query,
or just put the cursor anywhere inside the wanted query.
By default, the last query is executed.

In case of error, you can display generated code to help you to
correct your query (only if you have S_DEVELOP access)

F1 Help is managed to help you on ABAP SQL Syntax
Code completion is also available :
- TAB to autocomplete with tooltip word
- CTRL + ESPACE to display list of available words
Be carefull to not use with INSERT statement (see below)

The top left pane allow you to store your query :
- You could save your query to reuse it later
- You could share your query : define users, usergroup, all
- You could export query into file to reuse it on another server

The top right pane display ddic object that is currently used to help
you to write the proper query
Synergy with ZSPRO program : display tables defined in ZSPRO in the
ddic tree
Tips : You can search a table in the tree using header clic

Managed queries  
SELECT, INSERT, UPDATE, DELETE, Any native SQL command

About New SQL Query Syntax
You could use new syntax (if your SAP system manage it)
ZTOAD autmatically detect if you are using new sytax when:
- You separated your selected fields with comma
- You prefixed your variable with @ in the INTO TABLE statement

Select Clause managed  
SELECT [DISTINCT / SINGLE] select clause  
FROM from clause  
[UP TO x ROWS]  
[WHERE cond1]  
[GROUP BY fields1]  
[HAVING cond2]  
[ORDER BY fields2]  
[UNION SELECT...]  

UP TO (Default max rows) ROWS added at end of query if omitted
You could force select without limits by adding UP TO 0 ROWS

COUNT, AVG, MAX, MIN, SUM are managed  
DO NOT FORGET SPACE in ( ) of aggregat  

Insert special syntax
In ABAP, insert query is always used with given structure
In this SQL editor, you have 2 ways to do an INSERT :
- By passing each value, 1 by 1  
`INSERT SEOCLASSTX VALUES ( 'ZZMACLASS', ' ', 'Test claSS' )`

- By passing value of used fields only  
`INSERT SEOCLASSTX SET CLSNAME = 'ZZMACLASS' DESCRIPT = 'TeSt class'`

Native SQL special syntax
To execute a native SQL command, please add the prefix NATIVE
before your query
`NATIVE CREATE INDEX 'TESTINDEX' ON T001 (MANDT, WAERS, BUKRS)`
`NATIVE DROP INDEX 'TESTINDEX'`

## Sample queries:

`SELECT SINGLE * FROM VBAP WHERE VBELN = '00412345678'`

`SELECT COUNT( * ) SUBC MAX( PROG ) FROM TRDIR GROUP BY SUBC`

`SELECT VBAK~* from VBAK UP TO 3 ROWS ORDER BY VKORG.`

`SELECT T1~VBELN T2~POSNR FROM VBAk AS T1`
       `JOIN VBAP AS T2 ON T1~VBELN = T2~VBELN`

`INSERT SEOCLASSTX VALUES ( 'ZZMACLASS', ' ', 'Test claSS' )`

`INSERT SEOCLASSTX SET CLSNAME = 'ZZMACLASS' DESCRIPT = 'TeSt class'`

`UPDATE SEOCLASSTX SET DESCRIPT = 'txt' WHERE CLSNAME = 'ZZMACLASS'`

`DELETE SEOCLASSTX WHERE CLSNAME = 'ZZMACLASS'`


## Changelog
- 2022.02.25 v4.0.3:
   - Increase max queries to 1000
   - change master language to english
- 2017.12.31 v4.0.2:
   - Fix dump in case of multiple aggregations
- 2017.04.01 v4.0.1:
   - Fix new Tab dump
- 2016.12.17 v4.0  :
   - Add Tab management. 
   - You can have up to 30 tabs
   - Fix Status corruption
   - Add Import/Export function for saved queries
   - Mod Code cleaning
- 2016.09.10 v3.6 :
   - Add New syntax management of "case"
- 2016.07.06 v3.5.1:
   - Fix Auth issue
   - Fix Dump on select with no empty selection part
- 2016.03.28 v3.5 :
   - Add Value Help on DDIC field. Select a value tompaste in editor
   - Add Button Execute into file to download results instead of display it in ALV
   - Mod Use class CL_RSAWB_SPLITTER_FOR_TOOLBAR for creation of DDIC toolbar
   - Add Refresh the DDIC tree when executing a query even if error found
   - Fix Remove confirmation popup on display code for no select statement
   - Add Option to display technical name in ALV
   - Mod Move option button to main toolbar
   - Mod Rename subroutines (code cleaning)
   - Mod Allow save on exit popup
   - Add New query button
   - Mod New query template changed
- 2015.11.07 v3.4.3:
   - Fix dump if cursor on first position
   - Fix prevent dump on too many sql run
- 2015.11.07 v3.4.2:
   - Fix cancel of save query popup
   - Fix Allow usage of " and . inside ''
- 2015.11.01 v3.4.1:
   - Fix issue with delete all history context menu
- 2015.09.19 v3.4 :
   - Add Code completion on SQL editor
   - Thanks to Benjamin Krencker for his code
   - Add Remove useless APPENDING TABLE statement in qry
- 2015.09.13 v3.3 :
   - Add New Options panel to save user preferences
   - Add Delete all history entries context menu
   - Add option to add linebreak after paste field from ddic tree
   - Add Count column in alv grid display
- 2015.09.06 v3.2.1:
   - Mod Default limit to 100 rows is now optional
- 2015.08.30 v3.2  :
   - Add Manage new SQL Syntax introduced by NW7.40 SP5
   - Add Remove useless INTO TABLE statement in query
   - Add All NATIVE Sql commands
   - Mod Auth object use now the sap standard way
   - Fix Dump in case of up to xx rows in unioned query
   - Fix Dump at activation if ZSPRO does not exist
   - Fix Compatibility issues with older sap system
- 2015.08.05 v3.1  :
   - Add Manage drag&drop from DDIC tree to SQL Editor
   - Mod Double clic on field in DDIC tree paste field in editor instead of filling clipboard
   - 2015.06.13 v3.0  :
   - Add INSERT, UPDATE, DELETE command
   - Add Authorization management
   - Add History tree display first query line if it is a comment line
   - Mod Code cleaning
- 2015.03.05 v2.1.1:
   - Mod grid size is no more changed before display query result
- 2015.01.11 v2.1  :
   - Add UNION instruction managed to merge 2 queries
   - Mod Do not refresh result grid for count(*)
   - Mod Back close the grid instead of leave program if result grid is displayedAdd Display program header as default help
   - Add Run highlighted query
   - Mod Documentation rewritten
- 2014.10.23 v2.0.2:
   - Add Display number of entries found
   - Add Confirmation before exit for unsaved queries
- 2014.10.19 v2.0.1:
   - Fix bug on search ddic function
- 2014.08.03 v2.0 : 
   - Completely rewritten version
   - Save and share queries with colaborators
   - Queries are now saved in database
   - Display tables (+ fields) of the where clause
   - Display ZSPRO entries in ddic tree
   - Allow direct change in query after execution
   - Count( * ) allowed
   - Can display generated code
   - Display query execution time
   - Allow write of several queries (but 1 executed)
- 2013.12.03 v1.3: 
   - Allow case sensitive constant in where clause
- 2012.08.30 v1.2:
   - Rewrite data definition to avoid dump on too long fieldname
- 2012.04.01 v1.1: 
   - Updated to work also on BW system
- 2009.10.26 v1.0: 
   - Initial release
