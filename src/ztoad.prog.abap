*&---------------------------------------------------------------------*
*& Program : ZTOAD
*& Author  : S. Hermann
*& Date    : 25.02.2022
*& Version : 4.0.3
*& Required: Table ZTOAD
*&---------------------------------------------------------------------*
*& This program allow you to execute query directly on the server
*& 1/ Write your query in the editor window (ABAP SQL)
*& 2/ View the result in ALV window (in case of SELECT query)
*&
*3 Features :
*& The top center pane allow you to write your query in ABAP SQL format.
*= Query can be complex with JOIN, UNION and subqueries. You can write
*= query on several lines. You could also add spaces.
*= To add comment, start the line by * or prefix your comment by "
*&
*& You could write several queries in the query editor, separated by
*= dot ".". To execute one of them, highlight all the wanted query,
*= or just put the cursor anywhere inside the wanted query.
*= By default, the last query is executed.
*&
*& In case of error, you can display generated code to help you to
*= correct your query (only if you have S_DEVELOP access)
*&
*& F1 Help is managed to help you on ABAP SQL Syntax
*& Code completion is also available :
*& - TAB to autocomplete with tooltip word
*& - CTRL + ESPACE to display list of available words
*& Be carefull to not use with INSERT statement (see below)
*&
*& The top left pane allow you to store your query :
*& - You could save your query to reuse it later
*& - You could share your query : define users, usergroup, all
*& - You could export query into file to reuse it on another server
*&
*& The top right pane display ddic object that is currently used to help
*= you to write the proper query
*& Synergy with ZSPRO program : display tables defined in ZSPRO in the
*= ddic tree
*& Tips : You can search a table in the tree using header clic
*&
*3 Managed queries
*& SELECT, INSERT, UPDATE, DELETE, Any native SQL command
*&
*3 About New SQL Query Syntax
*& You could use new syntax (if your SAP system manage it)
*& ZTOAD autmatically detect if you are using new sytax when:
*& - You separated your selected fields with comma
*& - You prefixed your variable with @ in the INTO TABLE statement
*&
*3 Select Clause managed
*& SELECT [DISTINCT / SINGLE] select clause
*& FROM from clause
*& [UP TO x ROWS]
*& [WHERE cond1]
*& [GROUP BY fields1]
*& [HAVING cond2]
*& [ORDER BY fields2]
*& [UNION SELECT...]
*&
*& UP TO (Default max rows) ROWS added at end of query if omitted
*& You could force select without limits by adding UP TO 0 ROWS
*&
*& COUNT, AVG, MAX, MIN, SUM are managed
*& DO NOT FORGET SPACE in ( ) of aggregat
*&
*3 Insert special syntax
*& In ABAP, insert query is always used with given structure
*& In this SQL editor, you have 2 ways to do an INSERT :
*& - By passing each value, 1 by 1
*E INSERT SEOCLASSTX VALUES ( 'ZZMACLASS', ' ', 'Test claSS' )
*&
*& - By passing value of used fields only
*E INSERT SEOCLASSTX SET CLSNAME = 'ZZMACLASS' DESCRIPT = 'TeSt class'
*&
*3 Native SQL special syntax
*& To execute a native SQL command, please add the prefix NATIVE
*& before your query
*& NATIVE CREATE INDEX 'TESTINDEX' ON T001 (MANDT, WAERS, BUKRS)
*& NATIVE DROP INDEX 'TESTINDEX'
*&
*3 Sample of query :
*&
*E SELECT SINGLE * FROM VBAP WHERE VBELN = '00412345678'
*&
*E SELECT COUNT( * ) SUBC MAX( PROG ) FROM TRDIR GROUP BY SUBC
*&
*E SELECT VBAK~* from VBAK UP TO 3 ROWS ORDER BY VKORG.
*&
*E SELECT T1~VBELN T2~POSNR FROM VBAk AS T1
*E        JOIN VBAP AS T2 ON T1~VBELN = T2~VBELN
*&
*E INSERT SEOCLASSTX VALUES ( 'ZZMACLASS', ' ', 'Test claSS' )
*&
*E INSERT SEOCLASSTX SET CLSNAME = 'ZZMACLASS' DESCRIPT = 'TeSt class'
*&
*E UPDATE SEOCLASSTX SET DESCRIPT = 'txt' WHERE CLSNAME = 'ZZMACLASS'
*&
*E DELETE SEOCLASSTX WHERE CLSNAME = 'ZZMACLASS'
*&
*& Please send comment & improvements to http://quelquepart.biz
*&---------------------------------------------------------------------*
*& History :
*& 2017.12.31 v4.0.2:Fix dump in case of multiple aggregations
*&                       Thanks to Sabrina Villa for the fix
*& 2017.04.01 v4.0.1:Fix new Tab dump
*& 2016.12.17 v4.0  :Add Tab management. You can have up to 30 tabs
*&                   Fix Status corruption
*&                   Add Import/Export function for saved queries
*&                   Mod Code cleaning
*& 2016.09.10 v3.6  :Add New syntax management of "case"
*& 2016.07.06 v3.5.1:Fix Auth issue
*&                   Fix Dump on select with no empty selection part
*& 2016.03.28 v3.5  :Add Value Help on DDIC field. Select a value to
*&                       paste in editor
*&                   Add Button Execute into file to download results
*&                       instead of display it in ALV
*&                   Mod Use class CL_RSAWB_SPLITTER_FOR_TOOLBAR for
*&                       creation of DDIC toolbar
*&                   Add Refresh the DDIC tree when executing a query
*&                       even if error found
*& Thanks to Patrick Prime Reinoso for the following changes :
*&                   Fix Remove confirmation popup on display code for
*&                       no select statement
*&                   Add Option to display technical name in ALV
*&                   Mod Move option button to main toolbar
*&                   Mod Rename subroutines (code cleaning)
*&                   Mod Allow save on exit popup
*&                   Add New query button
*&                   Mod New query template changed
*& 2015.11.07 v3.4.3:Fix dump if cursor on first position
*&                   Fix prevent dump on too many sql run
*& 2015.11.07 v3.4.2:Fix cancel of save query popup
*&                   Fix Allow usage of " and . inside ''
*& 2015.11.01 v3.4.1:Fix issue with delete all history context menu
*& 2015.09.19 v3.4  :Add Code completion on SQL editor
*&                   Thanks to Benjamin Krencker for his code
*&                   Add Remove useless APPENDING TABLE statement in qry
*& 2015.09.13 v3.3  :Add New Options panel to save user preferences
*&                   Add Delete all history entries context menu
*&                   Add option to add linebreak after paste field from
*&                       ddic tree
*&                   Add Count column in alv grid display
*&                   Thanks again to Shai Sinai for his suggestions
*& 2015.09.06 v3.2.1:Mod Default limit to 100 rows is now optional
*& 2015.08.30 v3.2  :Add Manage new SQL Syntax introduced by NW7.40 SP5
*&                   Add Remove useless INTO TABLE statement in query
*&                   Add All NATIVE Sql commands
*&                   Mod Auth object use now the sap standard way
*&                   Fix Dump in case of up to xx rows in unioned query
*&                   Fix Dump at activation if ZSPRO does not exist
*&                   Fix Compatibility issues with older sap system
*& 2015.08.05 v3.1  :Add Manage drag&drop from DDIC tree to SQL Editor
*&                   Mod Double clic on field in DDIC tree paste field
*&                       in editor instead of filling clipboard
*&                   Thanks to Shai Sinai for his suggestions
*& 2015.06.13 v3.0  :Add INSERT, UPDATE, DELETE command
*&                   Add Authorization management
*&                   Add History tree display first query line if it
*&                       is a comment line
*&                   Mod Code cleaning
*& 2015.03.05 v2.1.1:Mod grid size is no more changed before display
*&                       query result
*& 2015.01.11 v2.1  :Add UNION instruction managed to merge 2 queries
*&                   Mod Do not refresh result grid for count(*)
*&                   Mod Back close the grid instead of leave program if
*&                       result grid is displayed
*&                   Add Display program header as default help
*&                   Add Run highlighted query
*&                   Mod Documentation rewritten
*& 2014.10.23 v2.0.2:Add Display number of entries found
*&                   Add Confirmation before exit for unsaved queries
*& 2014.10.19 v2.0.1:Fix bug on search ddic function
*& 2014.08.03 v2.0 : Completely rewritten version
*&                   - Save and share queries with colaborators
*&                   - Queries are now saved in database
*&                   - Display tables (+ fields) of the where clause
*&                   - Display ZSPRO entries in ddic tree
*&                   - Allow direct change in query after execution
*&                   - Count( * ) allowed
*&                   - Can display generated code
*&                   - Display query execution time
*&                   - Allow write of several queries (but 1 executed)
*& 2013.12.03 v1.3 : Allow case sensitive constant in where clause
*& 2012.08.30 v1.2 : Rewrite data definition to avoid dump on too long
*&                   fieldname
*& 2012.04.01 v1.1 : Updated to work also on BW system
*& 2009.10.26 v1.0 : Initial release
*&---------------------------------------------------------------------*

REPORT ztoad.
TYPE-POOLS abap.

*######################################################################*
*
*                        CUSTOMIZATION SECTION
*
*######################################################################*
DATA : BEGIN OF s_customize,                                "#EC NEEDED
* Default number of lines to return for SELECT if no "up to xxx rows"
* defined in the query.
* Set to 0 if you dont want default limit.
         default_rows    TYPE i VALUE 100,

* When you dblclic on a field in the ddic tree, field is pasted to
* editor at the cursor position
* You could choose to add a linebreak after the field pasted
         paste_break(1)  TYPE c VALUE space, "abap_true to break

* In ALV grid result, display technical name instead of column label
         techname(1)     TYPE c VALUE space, "abap_true for technical

* You could define your authorization object to restrict
* function usage by user
* If you dont define auth object, all users will have same access as
* defined bellow
* The auth object have 2 fields TABLE and ACTVT
* ACTVT can take 5 values that you could define here. By default :
* 01 for INSERT command
* 02 for UPDATE command
* 03 for SELECT command
* 06 for DELETE command
* 16 for EXECUTE NATIVE SQL command
* TABLE contain allowed table name pattern
* '*' to allow all table, 'Z*' to allow all specific tables...
         auth_object(20) TYPE c VALUE '', "'ZTOAD_AUTH',
         actvt_select    TYPE tactt-actvt VALUE '03',
         actvt_insert    TYPE tactt-actvt VALUE '01',
         actvt_update    TYPE tactt-actvt VALUE '02',
         actvt_delete    TYPE tactt-actvt VALUE '06',
         actvt_native    TYPE tactt-actvt VALUE '16',

* Bellow is default AUTH used if no auth_object is defined
* Allow SELECT query on SAP table (restricted by given pattern)
         auth_select     TYPE string VALUE '*',
* Allow INSERT query on SAP table (restricted by given pattern)
         auth_insert     TYPE string VALUE space, "'*',
* Allow UPDATE query on SAP table (restricted by given pattern)
         auth_update     TYPE string VALUE space, "'*',
* Allow DELETE query on SAP table (restricted by given pattern)
         auth_delete     TYPE string VALUE space, "'*',
* Allow any native sql command (set value to space to disable)
         auth_native(1)  TYPE c VALUE space, "abap_true,

       END OF s_customize.


*######################################################################*
*
*                             DATA SECTION
*
*######################################################################*
* Objects
CLASS lcl_application DEFINITION DEFERRED.

* Screen objects
DATA : o_handle_event         TYPE REF TO lcl_application,
       o_container            TYPE REF TO cl_gui_custom_container,
       o_splitter             TYPE REF TO cl_gui_splitter_container,
       o_splitter_top         TYPE REF TO cl_gui_splitter_container,
       o_splitter_top_right   TYPE REF TO cl_rsawb_splitter_for_toolbar,
       o_container_top        TYPE REF TO cl_gui_container,
       o_container_top_right  TYPE REF TO cl_gui_container,
       o_container_repository TYPE REF TO cl_gui_container,
       o_container_options    TYPE REF TO cl_gui_custom_container,
       o_container_query      TYPE REF TO cl_gui_container,
       o_container_ddic       TYPE REF TO cl_gui_container,
       o_container_result     TYPE REF TO cl_gui_container,

* Tabs objects (editor, ddic, alv)
       BEGIN OF s_tab_active,
         o_textedit             TYPE REF TO cl_gui_abapedit,
         o_tree_ddic            TYPE REF TO cl_gui_column_tree,
         t_node_ddic            TYPE treev_ntab,
         t_item_ddic            TYPE TABLE OF mtreeitm,
         o_alv_result           TYPE REF TO cl_gui_alv_grid,
         row_height             TYPE i,
       END OF s_tab_active,
       t_tabs LIKE TABLE OF s_tab_active,

* Repository data
       o_tree_repository      TYPE REF TO cl_gui_simple_tree,
       BEGIN OF s_node_repository.
        INCLUDE TYPE treev_node. "mtreesnode.
DATA :  text(100) TYPE c,
        edit(1)   TYPE c,
        queryid   TYPE ztoad-queryid,
        END OF s_node_repository,
        t_node_repository      LIKE TABLE OF s_node_repository,

* DDIC data
        w_dragdrop_handle_tree TYPE i,
* DDIC toolbar
        o_toolbar              TYPE REF TO cl_gui_toolbar,
* Option panel
        o_options              TYPE REF TO cl_wdy_wb_property_box,
* ZSPRO data
        t_node_zspro           LIKE s_tab_active-t_node_ddic,
        t_item_zspro           LIKE s_tab_active-t_item_ddic,

* Save option
        BEGIN OF s_options,
          name          TYPE ztoad-text,
          visibility    TYPE ztoad-visibility,
          visibilitygrp TYPE usr02-class,
        END OF s_options,

* Keep last loaded id
        w_last_loaded_query TYPE ztoad-queryid,

* Count number of runs
        w_run               TYPE i.

DATA : w_okcode LIKE sy-ucomm,
       BEGIN OF s_tab,
         title1 TYPE string VALUE 'Tab 1',                  "#EC NOTEXT
         title2 TYPE string VALUE 'Tab 2',                  "#EC NOTEXT
         title3 TYPE string VALUE 'Tab 3',                  "#EC NOTEXT
         title4 TYPE string VALUE 'Tab 4',                  "#EC NOTEXT
         title5 TYPE string VALUE 'Tab 5',                  "#EC NOTEXT
         title6 TYPE string VALUE 'Tab 6',                  "#EC NOTEXT
         title7 TYPE string VALUE 'Tab 7',                  "#EC NOTEXT
         title8 TYPE string VALUE 'Tab 8',                  "#EC NOTEXT
         title9 TYPE string VALUE 'Tab 9',                  "#EC NOTEXT
         title10 TYPE string VALUE 'Tab 10',                "#EC NOTEXT
         title11 TYPE string VALUE 'Tab 11',                "#EC NOTEXT
         title12 TYPE string VALUE 'Tab 12',                "#EC NOTEXT
         title13 TYPE string VALUE 'Tab 13',                "#EC NOTEXT
         title14 TYPE string VALUE 'Tab 14',                "#EC NOTEXT
         title15 TYPE string VALUE 'Tab 15',                "#EC NOTEXT
         title16 TYPE string VALUE 'Tab 16',                "#EC NOTEXT
         title17 TYPE string VALUE 'Tab 17',                "#EC NOTEXT
         title18 TYPE string VALUE 'Tab 18',                "#EC NOTEXT
         title19 TYPE string VALUE 'Tab 19',                "#EC NOTEXT
         title20 TYPE string VALUE 'Tab 20',                "#EC NOTEXT
         title21 TYPE string VALUE 'Tab 21',                "#EC NOTEXT
         title22 TYPE string VALUE 'Tab 22',                "#EC NOTEXT
         title23 TYPE string VALUE 'Tab 23',                "#EC NOTEXT
         title24 TYPE string VALUE 'Tab 24',                "#EC NOTEXT
         title25 TYPE string VALUE 'Tab 25',                "#EC NOTEXT
         title26 TYPE string VALUE 'Tab 26',                "#EC NOTEXT
         title27 TYPE string VALUE 'Tab 27',                "#EC NOTEXT
         title28 TYPE string VALUE 'Tab 28',                "#EC NOTEXT
         title29 TYPE string VALUE 'Tab 29',                "#EC NOTEXT
         title30 TYPE string VALUE 'Tab 30',                "#EC NOTEXT
       END OF s_tab.
CONTROLS w_tabstrip TYPE TABSTRIP.

* Global types
TYPES : BEGIN OF ty_fieldlist,
          field     TYPE string,
          ref_table TYPE string,
          ref_field TYPE string,
        END OF ty_fieldlist,
        ty_fieldlist_table TYPE STANDARD TABLE OF ty_fieldlist.

* Constants
CONSTANTS : c_ddic_col1            TYPE mtreeitm-item_name
                        VALUE 'col1',                       "#EC NOTEXT
            c_ddic_col2            TYPE mtreeitm-item_name
                        VALUE 'col2',                       "#EC NOTEXT
            c_visibility_all       TYPE ztoad-visibility VALUE '2',
            c_visibility_shared    TYPE ztoad-visibility VALUE '1',
            c_visibility_my        TYPE ztoad-visibility VALUE '0',
            c_nodekey_repo_my      TYPE mtreesnode-node_key VALUE 'MY',
            c_nodekey_repo_shared  TYPE mtreesnode-node_key
                                  VALUE 'SHARED',
            c_nodekey_repo_history TYPE mtreesnode-node_key
                                   VALUE 'HISTO',
            c_line_max             TYPE i VALUE 255,
            c_msg_success          TYPE c VALUE 'S',
            c_msg_error            TYPE c VALUE 'E',
            c_vers_active          TYPE as4local VALUE 'A',
            c_ddic_dtelm           TYPE comptype VALUE 'E',
            c_native_command       TYPE string VALUE 'NATIVE',
            c_query_max_exec       TYPE i VALUE 1000,

            c_xmlnode_root TYPE string VALUE 'root',        "#EC NOTEXT
            c_xmlnode_file TYPE string VALUE 'query',       "#EC NOTEXT
            c_xmlattr_visibility TYPE string VALUE 'visibility', "#EC NOTEXT
            c_xmlattr_text TYPE string VALUE 'description'. "#EC NOTEXT

*######################################################################*
*
*                             CLASS SECTION
*
*######################################################################*

*----------------------------------------------------------------------*
*       CLASS lcl_drag_object DEFINITION
*----------------------------------------------------------------------*
*       Class to store object on drag & drop from DDIC to sql editor
*----------------------------------------------------------------------*
CLASS lcl_drag_object DEFINITION FINAL.
  PUBLIC SECTION.
    DATA field TYPE string.
ENDCLASS."lcl_drag_object DEFINITION

*----------------------------------------------------------------------*
*       CLASS lcl_application DEFINITION
*----------------------------------------------------------------------*
*       Class to handle application events
*----------------------------------------------------------------------*
CLASS lcl_application DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS :
* Handle F1 call on ABAP editor
      hnd_editor_f1
         FOR EVENT f1 OF cl_gui_abapedit,
* Handle Node double clic on ddic tree
      hnd_ddic_item_dblclick
                    FOR EVENT item_double_click OF cl_gui_column_tree
        IMPORTING node_key,
* Handle context menu display on repository tree
      hnd_repo_context_menu
      FOR EVENT node_context_menu_request
                    OF cl_gui_simple_tree
        IMPORTING menu,
* Handle context menu clic on repository tree
      hnd_repo_context_menu_sel
      FOR EVENT node_context_menu_select
                    OF cl_gui_simple_tree
        IMPORTING fcode,
* Handle Node double clic on repository tree
      hnd_repo_dblclick
                    FOR EVENT node_double_click OF cl_gui_simple_tree
        IMPORTING node_key,
* Handle toolbar display on ALV result
      hnd_result_toolbar
                    FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object,
* Handle toolbar clic on ALV result
      hnd_result_user_command
                    FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,
* Handle DDIC tree drag
      hnd_ddic_drag
                    FOR EVENT on_drag OF cl_gui_column_tree
        IMPORTING node_key drag_drop_object,
* Handle editor drop
      hnd_editor_drop
                    FOR EVENT on_drop OF cl_gui_abapedit
        IMPORTING line pos dragdrop_object,
* Handle ddic toolbar clic
      hnd_ddic_toolbar_clic
                    FOR EVENT function_selected OF cl_gui_toolbar
        IMPORTING fcode.
ENDCLASS.                    "lcl_application DEFINITION

*----------------------------------------------------------------------*
*       CLASS LCL_APPLICATION IMPLEMENTATION
*----------------------------------------------------------------------*
*       Class to handle application events                             *
*----------------------------------------------------------------------*
CLASS lcl_application IMPLEMENTATION.
*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_repo_context_menu
*&---------------------------------------------------------------------*
*       Handle context menu display on repository tree
*----------------------------------------------------------------------*
  METHOD hnd_repo_context_menu.
    DATA l_node_key TYPE tv_nodekey.

    CALL METHOD o_tree_repository->get_selected_node
      IMPORTING
        node_key = l_node_key.
* For History node, add a "delete all" entry
* Only if there is at least 1 history entry
    IF l_node_key = 'HISTO'.
      READ TABLE t_node_repository TRANSPORTING NO FIELDS
        WITH KEY relatkey = 'HISTO'.
      IF sy-subrc = 0.
        CALL METHOD menu->add_function
          EXPORTING
            text  = 'Delete All'(m36)
            icon  = '@02@'
            fcode = 'DELETE_HIST'.
      ENDIF.
      RETURN.
    ENDIF.

* Add Delete option only for own queries
    READ TABLE t_node_repository INTO s_node_repository
               WITH KEY node_key = l_node_key.
    IF sy-subrc NE 0 OR s_node_repository-edit = space.
      RETURN.
    ENDIF.

    CALL METHOD menu->add_function
      EXPORTING
        text  = 'Delete'(m01)
        icon  = '@02@'
        fcode = 'DELETE_QUERY'.
  ENDMETHOD.                    "hnd_repo_context_menu

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_repo_context_menu_sel
*&---------------------------------------------------------------------*
*       Handle context menu clic on repository tree
*----------------------------------------------------------------------*
  METHOD hnd_repo_context_menu_sel.
    DATA : l_node_key TYPE tv_nodekey,
           l_subrc    TYPE i,
           ls_histo   LIKE s_node_repository,
           lw_queryid LIKE ls_histo-queryid.
* Delete stored query
    CASE fcode.
      WHEN 'DELETE_QUERY'.
        CALL METHOD o_tree_repository->get_selected_node
          IMPORTING
            node_key = l_node_key.
        PERFORM repo_delete_history USING l_node_key
                                    CHANGING l_subrc.
        IF l_subrc = 0.
          MESSAGE 'Query deleted'(m02) TYPE c_msg_success.
        ELSE.
          MESSAGE 'Error when deleting the query'(m03)
                  TYPE c_msg_success DISPLAY LIKE c_msg_error.
          RETURN.
        ENDIF.

      WHEN 'DELETE_HIST'.
        CONCATENATE sy-uname '+++' INTO lw_queryid.
        LOOP AT t_node_repository INTO ls_histo
                WHERE queryid CP lw_queryid.
          PERFORM repo_delete_history USING ls_histo-node_key
                                      CHANGING l_subrc.
          IF l_subrc NE 0.
            MESSAGE 'Error when deleting the query'(m03)
                    TYPE c_msg_success DISPLAY LIKE c_msg_error.
            RETURN.
          ENDIF.
        ENDLOOP.
        MESSAGE 'All history entries deleted'(m37) TYPE c_msg_success.
    ENDCASE.
  ENDMETHOD.                    "hnd_repo_context_menu_sel

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_editor_f1
*&---------------------------------------------------------------------*
*       Handle F1 call on ABAP editor
*----------------------------------------------------------------------*
  METHOD hnd_editor_f1.
    DATA : lw_cursor_line_from TYPE i,
           lw_cursor_line_to   TYPE i,
           lw_cursor_pos_from  TYPE i,
           lw_cursor_pos_to    TYPE i,
           lw_offset           TYPE i,
           lw_length           TYPE i,
           lt_query            TYPE soli_tab,
           ls_query            LIKE LINE OF lt_query,
           lw_sel              TYPE string.

* Find active query
    CALL METHOD s_tab_active-o_textedit->get_selection_pos
      IMPORTING
        from_line = lw_cursor_line_from
        from_pos  = lw_cursor_pos_from
        to_line   = lw_cursor_line_to
        to_pos    = lw_cursor_pos_to.

* If nothing selected, no help to display
    IF lw_cursor_line_from = lw_cursor_line_to
    AND lw_cursor_pos_to = lw_cursor_pos_from.
      RETURN.
    ENDIF.

* Get content of abap edit box
    CALL METHOD s_tab_active-o_textedit->get_text
      IMPORTING
        table  = lt_query[]
      EXCEPTIONS
        OTHERS = 1.


    READ TABLE lt_query INTO ls_query INDEX lw_cursor_line_from.
    IF lw_cursor_line_from = lw_cursor_line_to.
      lw_length = lw_cursor_pos_to - lw_cursor_pos_from.
      lw_offset = lw_cursor_pos_from - 1.
      lw_sel = ls_query+lw_offset(lw_length).
    ELSE.
      lw_offset = lw_cursor_pos_from - 1.
      lw_sel = ls_query+lw_offset.
    ENDIF.
    CALL FUNCTION 'ABAP_DOCU_START'
      EXPORTING
        word = lw_sel.
  ENDMETHOD.                    "hnd_editor_f1

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_ddic_item_dblclick
*&---------------------------------------------------------------------*
*       Handle Node double clic on ddic tree
*----------------------------------------------------------------------*
  METHOD hnd_ddic_item_dblclick.
    DATA : ls_node       LIKE LINE OF s_tab_active-t_node_ddic,
           lw_line_start TYPE i,
           lw_pos_start  TYPE i,
           lw_line_end   TYPE i,
           lw_pos_end    TYPE i,
           lw_data       TYPE string.

* Check clicked node is valid
    READ TABLE s_tab_active-t_node_ddic INTO ls_node
               WITH KEY node_key = node_key.
    IF sy-subrc NE 0 OR ls_node-isfolder = abap_true.
      RETURN.
    ENDIF.

* Get text for the node selected
    PERFORM ddic_get_field_from_node USING node_key ls_node-relatkey
                                     CHANGING lw_data.

* Get current cursor position/selection in editor
    CALL METHOD s_tab_active-o_textedit->get_selection_pos
      IMPORTING
        from_line = lw_line_start
        from_pos  = lw_pos_start
        to_line   = lw_line_end
        to_pos    = lw_pos_end
      EXCEPTIONS
        OTHERS    = 4.
    IF sy-subrc NE 0.
      MESSAGE 'Cannot get cursor position'(m35) TYPE c_msg_error.
    ENDIF.

*   If text is selected/highlighted, delete it
    IF lw_line_start NE lw_line_end
    OR lw_pos_start NE lw_pos_end.
      CALL METHOD s_tab_active-o_textedit->delete_text
        EXPORTING
          from_line = lw_line_start
          from_pos  = lw_pos_start
          to_line   = lw_line_end
          to_pos    = lw_pos_end.
    ENDIF.

    PERFORM editor_paste USING lw_data lw_line_start lw_pos_start.
  ENDMETHOD.                    "hnd_ddic_item_dblclick

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_repo_dblclick
*&---------------------------------------------------------------------*
*       Handle Node double clic on repository tree
*----------------------------------------------------------------------*
  METHOD hnd_repo_dblclick.
    DATA lt_query TYPE TABLE OF string.
    READ TABLE t_node_repository INTO s_node_repository
               WITH KEY node_key = node_key.
    IF sy-subrc = 0 AND NOT s_node_repository-relatkey IS INITIAL.
      PERFORM query_load USING s_node_repository-queryid
                         CHANGING lt_query.

      CALL METHOD s_tab_active-o_textedit->set_text
        EXPORTING
          table  = lt_query
        EXCEPTIONS
          OTHERS = 0.

      PERFORM ddic_refresh_tree.
    ENDIF.
  ENDMETHOD. "hnd_repo_dblclick

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_result_toolbar
*&---------------------------------------------------------------------*
*       Handle grid toolbar to add specific button
*----------------------------------------------------------------------*
  METHOD hnd_result_toolbar.
    DATA: ls_toolbar  TYPE stb_button.

* Add Separator
    CLEAR ls_toolbar.
    ls_toolbar-function = '&&SEP99'.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

* Add button to close the grid
    CLEAR ls_toolbar.
    ls_toolbar-function = 'CLOSE_GRID'.
    ls_toolbar-icon = '@3X@'.
    ls_toolbar-quickinfo = 'Close Grid'(m05).
    ls_toolbar-text = 'Close'(m06).
    ls_toolbar-butn_type = 0.
    ls_toolbar-disabled = space.
    APPEND ls_toolbar TO e_object->mt_toolbar.
  ENDMETHOD.                    "hnd_result_toolbar

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_result_user_command
*&---------------------------------------------------------------------*
*       Handle grid user command to manage specific fcode
*       (menus & toolbar)
*----------------------------------------------------------------------*
  METHOD hnd_result_user_command.
    IF e_ucomm = 'CLOSE_GRID'.
      CALL METHOD o_splitter->set_row_height
        EXPORTING
          id     = 1
          height = 100.
    ENDIF.
  ENDMETHOD. "hnd_result_user_command

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_ddic_drag
*&---------------------------------------------------------------------*
*       Handle drag on DDIC field (store fieldname)
*----------------------------------------------------------------------*
  METHOD hnd_ddic_drag.
    DATA : lo_drag_object TYPE REF TO lcl_drag_object,
           ls_node        LIKE LINE OF s_tab_active-t_node_ddic,
           lw_text        TYPE string.

    READ TABLE s_tab_active-t_node_ddic INTO ls_node
               WITH KEY node_key = node_key.
    IF sy-subrc NE 0 OR ls_node-isfolder = abap_true. "may not append
      MESSAGE 'Only fields can be drag&drop to editor'(m34)
               TYPE c_msg_success DISPLAY LIKE c_msg_error.
      RETURN.
    ENDIF.

* Get text for the node selected
    PERFORM ddic_get_field_from_node USING node_key ls_node-relatkey
                                     CHANGING lw_text.

* Store the node text
    CREATE OBJECT lo_drag_object.
    lo_drag_object->field = lw_text.
    drag_drop_object->object = lo_drag_object.

  ENDMETHOD."hnd_ddic_drag

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_editor_drop
*&---------------------------------------------------------------------*
*       Handle drop on SQL Editor : paste fieldname at cursor position
*----------------------------------------------------------------------*
  METHOD hnd_editor_drop.
    DATA lo_drag_object TYPE REF TO lcl_drag_object.

    lo_drag_object ?= dragdrop_object->object.
    IF lo_drag_object IS INITIAL OR lo_drag_object->field IS INITIAL.
      RETURN.
    ENDIF.

* Paste fieldname to editor at drop position
    PERFORM editor_paste USING lo_drag_object->field line pos.

  ENDMETHOD."hnd_editor_drop

*&---------------------------------------------------------------------*
*&      CLASS lcl_application
*&      METHOD hnd_ddic_toolbar_clic
*&---------------------------------------------------------------------*
*       Handle DDIC toolbar button clic
*----------------------------------------------------------------------*
  METHOD hnd_ddic_toolbar_clic.

    CASE fcode.
      WHEN 'REFRESH'.
        PERFORM ddic_refresh_tree.
      WHEN 'FIND'.
        PERFORM ddic_find_in_tree.
      WHEN 'F4'.
        PERFORM ddic_f4.
    ENDCASE.
  ENDMETHOD.                    "hnd_ddic_toolbar_clic

ENDCLASS.                    "lcl_application IMPLEMENTATION


*######################################################################*
*
*                             MAIN SECTION
*
*######################################################################*
START-OF-SELECTION.
  CALL SCREEN 10.


*######################################################################*
*
*                             PBO SECTION
*
*######################################################################*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0010  OUTPUT
*&---------------------------------------------------------------------*
*       Set status for main screen
*       and initialize custom container at first run
*----------------------------------------------------------------------*
MODULE status_0010 OUTPUT.
* Initialization of object screen
  IF o_container IS INITIAL.
    PERFORM screen_init.
    APPEND s_tab_active TO t_tabs.
  ENDIF.

  perform set_status_010.

ENDMODULE.                 " STATUS_0010  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*       Set status for modal box (save query)
*----------------------------------------------------------------------*
MODULE status_0200 OUTPUT.

* Fill dropdown listbox with values
  PERFORM screen_init_listbox_0200.

  SET PF-STATUS 'STATUS200'.
  SET TITLEBAR 'STATUS200'.

ENDMODULE.                 " STATUS_0200  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  STATUS_0300  OUTPUT
*&---------------------------------------------------------------------*
*       Set status for modal box (options)
*----------------------------------------------------------------------*
MODULE status_0300 OUTPUT.

* Create option screen
  IF o_container_options IS INITIAL.
    PERFORM options_init.
  ENDIF.

  SET PF-STATUS 'STATUS300'.
  SET TITLEBAR 'STATUS300'.

ENDMODULE.                 " STATUS_0200  OUTPUT

*######################################################################*
*
*                             PAI SECTION
*
*######################################################################*

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0010  INPUT
*&---------------------------------------------------------------------*
*       User command for main screen
*----------------------------------------------------------------------*
MODULE user_command_0010 INPUT.
  CASE w_okcode.
    WHEN 'EXIT'.
      PERFORM screen_exit.
    WHEN 'EXECUTE'.
      PERFORM query_process USING space space.
    WHEN 'DOWNLOAD'.
      PERFORM query_process USING space abap_true.
    WHEN 'SAVE'.
      PERFORM repo_save_query.
    WHEN 'SHOWCODE'.
      PERFORM query_process USING abap_true space.
    WHEN 'HELP'.
      PERFORM screen_display_help.
    WHEN 'OPTIONS'.
      PERFORM options_display.
    WHEN 'NEW'.
      PERFORM tab_new.
    WHEN 'XML'.
      PERFORM export_xml.
    WHEN 'XMLI'.
      PERFORM import_xml.
    WHEN OTHERS.
      IF w_okcode(3) = 'TAB' AND w_tabstrip-activetab NE w_okcode.
        PERFORM leave_current_tab.

        READ TABLE t_tabs INTO s_tab_active INDEX w_okcode+3.
* Display editor / ddic / alv
        CALL METHOD s_tab_active-o_textedit->set_visible
          EXPORTING
            visible = abap_true.
        CALL METHOD s_tab_active-o_tree_ddic->set_visible
          EXPORTING
            visible = abap_true.
        IF NOT s_tab_active-o_alv_result IS INITIAL.
          CALL METHOD s_tab_active-o_alv_result->set_visible
            EXPORTING
              visible = abap_true.
        ENDIF.
        CALL METHOD o_splitter->set_row_height
          EXPORTING
            id     = 1
            height = s_tab_active-row_height.
        w_tabstrip-activetab = w_okcode.
      ENDIF.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0010  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       PAI module for modal box (save query)
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  CASE w_okcode.
    WHEN 'CLOSE'.
      CLEAR s_options.
      LEAVE TO SCREEN 0.
    WHEN 'OK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0200  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*       PAI module for modal box (options)
*----------------------------------------------------------------------*
MODULE user_command_0300 INPUT.
  CASE w_okcode.
    WHEN 'CLOSE' OR 'OK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0200  INPUT

*######################################################################*
*
*                             FORM SECTION
*
*######################################################################*

*&---------------------------------------------------------------------*
*&      Form  SCREEN_INIT
*&---------------------------------------------------------------------*
*       Initialize all objects on the screen
*----------------------------------------------------------------------*
FORM screen_init.
* Get user default values
  PERFORM options_load.

* Create the handle object (required to catch events)
  CREATE OBJECT o_handle_event.

* Split the screen into 4 parts
  PERFORM screen_init_splitter.

* Init History Tree
  PERFORM repo_init.

* Init DDIC toolbar
  PERFORM ddic_toolbar_init.

* Init DDic tree
  PERFORM ddic_init.

* Init Query editor
  PERFORM editor_init.

* Init ALV result object
  PERFORM result_init.

ENDFORM.                    " SCREEN_INIT

*&---------------------------------------------------------------------*
*&      Form  SCREEN_INIT_SPLITTER
*&---------------------------------------------------------------------*
*       Split the main screen in 2 lines
* 1 line with 3 columns : Repository tree / Query code / Ddic tree
* 1 line with ALV result
*----------------------------------------------------------------------*
FORM screen_init_splitter.

* Create the custom container
  CREATE OBJECT o_container
    EXPORTING
      container_name = 'CUSTCONT'.

* Insert splitter into this container
  CREATE OBJECT o_splitter
    EXPORTING
      parent  = o_container
      rows    = 2
      columns = 1.

* Get the first row of the main splitter
  CALL METHOD o_splitter->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = o_container_top.

*  Spliter for the high part (first row)
  CREATE OBJECT o_splitter_top
    EXPORTING
      parent  = o_container_top
      rows    = 1
      columns = 3.

* Get the right part of the top part
  CALL METHOD o_splitter_top->get_container
    EXPORTING
      row       = 1
      column    = 3
    RECEIVING      "container = o_container_ddic.
      container = o_container_top_right.

* Add a toolbar to the DDIC container
  CREATE OBJECT o_splitter_top_right
    EXPORTING
      i_r_container = o_container_top_right.

* Affect an object to each "cell" of the high sub splitter
  CALL METHOD o_splitter_top->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = o_container_repository.

  CALL METHOD o_splitter_top->get_container
    EXPORTING
      row       = 1
      column    = 2
    RECEIVING
      container = o_container_query.

  CALL METHOD o_splitter_top_right->get_controlcontainer
    RECEIVING
      e_r_container_control = o_container_ddic.

  CALL METHOD o_splitter->get_container
    EXPORTING
      row       = 2
      column    = 1
    RECEIVING
      container = o_container_result.

* Initial repartition :
*   line 1 = 100% (code+repo+ddic)
*   line 2 = 0% (result)
*   line 1 col 1 & 3 = 20% (repo & ddic)
*   line 1 col 2 = 60% (code)
  CALL METHOD o_splitter->set_row_height
    EXPORTING
      id     = 1
      height = 100.

  CALL METHOD o_splitter_top->set_column_width
    EXPORTING
      id    = 1
      width = 20.
  CALL METHOD o_splitter_top->set_column_width
    EXPORTING
      id    = 3
      width = 20.

ENDFORM.                    " SCREEN_INIT_SPLITTER

*&---------------------------------------------------------------------*
*&      Form  ddic_toolbar_init
*&---------------------------------------------------------------------*
*       Initialize DDIC Toolbar
*
*----------------------------------------------------------------------*
FORM ddic_toolbar_init.
  DATA: lt_button TYPE ttb_button,
        ls_button LIKE LINE OF lt_button,
        lt_events TYPE cntl_simple_events,
        ls_events LIKE LINE OF lt_events.

*  Toolbar already created by class CL_RSAWB_SPLITTER_FOR_TOOLBAR
  o_toolbar = o_splitter_top_right->get_toolbar( ).

* Add buttons to toolbar
  CLEAR ls_button.
  ls_button-function = 'REFRESH'.
  ls_button-icon = '@42@'.
  ls_button-quickinfo = 'Refresh DDIC tree'(m41).
  ls_button-text = 'Refresh'(m40).
  ls_button-butn_type = 0.
  APPEND ls_button TO lt_button.

  CLEAR ls_button.
  ls_button-function = 'FIND'.
  ls_button-icon = '@13@'.
  ls_button-quickinfo = 'Search in DDIC tree'(m43).
  ls_button-text = 'Find'(m42).
  ls_button-butn_type = 0.
  APPEND ls_button TO lt_button.

  CLEAR ls_button.
  ls_button-function = 'F4'.
  ls_button-icon = '@6T@'.
  ls_button-quickinfo = 'Display values of sel. field'(m54).
  ls_button-text = 'Value list'(m55).
  ls_button-butn_type = 0.
  APPEND ls_button TO lt_button.

  CALL METHOD o_toolbar->add_button_group
    EXPORTING
      data_table = lt_button.

* Register events
  ls_events-eventid = cl_gui_toolbar=>m_id_function_selected.
  ls_events-appl_event = space.
  APPEND ls_events TO lt_events.
  CALL METHOD o_toolbar->set_registered_events
    EXPORTING
      events = lt_events.

  SET HANDLER o_handle_event->hnd_ddic_toolbar_clic FOR o_toolbar.

ENDFORM.                    "ddic_toolbar_init

*&---------------------------------------------------------------------*
*&      Form  EDITOR_INIT
*&---------------------------------------------------------------------*
*       Initialize the sql editor object
*       Fill it with last query, or template if no previous query
*----------------------------------------------------------------------*
FORM editor_init.
  DATA : lt_events     TYPE cntl_simple_events,
         ls_event      TYPE cntl_simple_event,
         lt_default    TYPE TABLE OF string,
         lw_queryid    TYPE ztoad-queryid,
         lo_dragrop    TYPE REF TO cl_dragdrop,
         lw_dummy_date TYPE timestamp.                      "#EC NEEDED

* For first tab, Get last query used
  IF t_tabs IS INITIAL.
    CONCATENATE sy-uname '#%' INTO lw_queryid.
* aedat is not used but added in select for compatibility reason
    SELECT queryid aedat
           INTO (lw_queryid, lw_dummy_date)
           FROM ztoad
           UP TO 1 ROWS
           WHERE queryid LIKE lw_queryid
           AND owner = sy-uname
           ORDER BY aedat DESCENDING.
    ENDSELECT.
    IF sy-subrc = 0.
      PERFORM query_load USING lw_queryid
                         CHANGING lt_default.
      PERFORM repo_focus_query USING lw_queryid.
    ENDIF.
  ENDIF.

* If no last query found, use default template
  IF lt_default IS INITIAL.
    PERFORM editor_get_default_query CHANGING lt_default.
  ENDIF.

* Create the sql editor
*  CREATE OBJECT s_tab_active-o_container_query
*    EXPORTING
*      parent = o_container_query.

  CREATE OBJECT s_tab_active-o_textedit
    EXPORTING
      parent = o_container_query.

* Register events
  SET HANDLER o_handle_event->hnd_editor_f1 FOR s_tab_active-o_textedit.
  SET HANDLER o_handle_event->hnd_editor_drop FOR s_tab_active-o_textedit.

  ls_event-eventid = cl_gui_textedit=>event_f1.
  APPEND ls_event TO lt_events.

  CALL METHOD s_tab_active-o_textedit->set_registered_events
    EXPORTING
      events                    = lt_events
    EXCEPTIONS
      cntl_error                = 1
      cntl_system_error         = 2
      illegal_event_combination = 3.
  IF sy-subrc <> 0.
    IF sy-msgno IS NOT INITIAL.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              DISPLAY LIKE c_msg_error
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 .
    ENDIF.
  ENDIF.

* Activate Code Completion and Quickinfo
* Comment the paragraph if CL_ABAP_PARSER doesnt exists on your system
* BEGIN OF ABAP PARSER
  DATA lo_completer TYPE REF TO cl_abap_parser.
  CALL METHOD s_tab_active-o_textedit->('INIT_COMPLETER').
  CALL METHOD s_tab_active-o_textedit->('GET_COMPLETER')
    RECEIVING
      m_parser = lo_completer.
  SET HANDLER lo_completer->handle_completion_request FOR s_tab_active-o_textedit.
  SET HANDLER lo_completer->handle_insertion_request FOR s_tab_active-o_textedit.
  SET HANDLER lo_completer->handle_quickinfo_request FOR s_tab_active-o_textedit.
  s_tab_active-o_textedit->register_event_completion( ).
  s_tab_active-o_textedit->register_event_quick_info( ).
  s_tab_active-o_textedit->register_event_insert_pattern( ).
* END OF ABAP PARSER

* Manage Drop on SQL editor
  CREATE OBJECT lo_dragrop.
  CALL METHOD lo_dragrop->add
    EXPORTING
      flavor     = 'EDIT_INSERT'
      dragsrc    = space
      droptarget = abap_true
      effect     = cl_dragdrop=>copy.
  CALL METHOD s_tab_active-o_textedit->set_dragdrop
    EXPORTING
      dragdrop = lo_dragrop.

* Set Default template
  CALL METHOD s_tab_active-o_textedit->set_text
    EXPORTING
      table  = lt_default
    EXCEPTIONS
      OTHERS = 0.

* Set focus
  CALL METHOD cl_gui_control=>set_focus
    EXPORTING
      control = s_tab_active-o_textedit
    EXCEPTIONS
      OTHERS  = 0.

  PERFORM ddic_refresh_tree.
ENDFORM.                    " EDITOR_INIT

*&---------------------------------------------------------------------*
*&      Form  query_process
*&---------------------------------------------------------------------*
*       Process selected query : execute or display code
*----------------------------------------------------------------------*
*      -->FW_DISPLAY : Flag abap_true to display code
*      -->FW_DOWNLOAD: Flag abap_true to save results into file
*----------------------------------------------------------------------*
FORM query_process USING fw_display TYPE c
                         fw_download TYPE c.
  DATA : lw_query         TYPE string,
         lw_select        TYPE string,
         lw_from          TYPE string,
         lw_where         TYPE string,
         lw_union         TYPE string,
         lw_query2        TYPE string,
         lw_command       TYPE string,
         lw_rows(6)       TYPE n,
         lw_program       TYPE sy-repid,
         lo_result        TYPE REF TO data,
         lo_result2       TYPE REF TO data,
         lt_fieldlist     TYPE ty_fieldlist_table,
         lt_fieldlist2    TYPE ty_fieldlist_table,
         lw_count_only(1) TYPE c,
         lw_time          TYPE p LENGTH 8 DECIMALS 2,
         lw_time2         LIKE lw_time,
         lw_count         TYPE i,
         lw_count2        LIKE lw_count,
         lw_charnumb(12)  TYPE c,
         lw_msg           TYPE string,
         lw_noauth(1)     TYPE c,
         lw_newsyntax(1)  TYPE c,
         lw_answer(1)     TYPE c,
         lw_from_concat   LIKE lw_from,
         lw_error(1)      TYPE c.

  FIELD-SYMBOLS : <lft_data>  TYPE STANDARD TABLE,
                  <lft_data2> TYPE STANDARD TABLE.

* Get only usefull code for current query
  PERFORM editor_get_query USING space CHANGING lw_query.

* Parse SELECT Query
  PERFORM query_parse USING lw_query
                      CHANGING lw_select lw_from lw_where
                               lw_union lw_rows lw_noauth
                               lw_newsyntax lw_error.
  IF lw_error NE space.
    MESSAGE 'Cannot parse the query'(m07) TYPE c_msg_error.
  ENDIF.

* Not a select query
  IF lw_select IS INITIAL.
    PERFORM query_parse_noselect USING    lw_query
                                 CHANGING lw_noauth
                                          lw_command
                                          lw_from
                                          lw_where.
    IF lw_noauth NE space.
      PERFORM ddic_set_tree USING lw_from.
      RETURN.
    ENDIF.

* For native sql command, execute it directly
    IF lw_command = c_native_command.
      PERFORM ddic_set_tree USING lw_from.
      PERFORM query_process_native USING lw_where.
      RETURN.
    ENDIF.

* For other no select command, generate program
    IF w_run LT c_query_max_exec.
      PERFORM query_generate_noselect USING lw_command lw_from
                                            lw_where fw_display
                                      CHANGING lw_program.
      w_run = w_run + 1.
    ELSE.
      MESSAGE 'No more run available. Please restart program'(m50)
              TYPE c_msg_error.
    ENDIF.
    IF fw_display IS INITIAL.
      PERFORM ddic_set_tree USING lw_from.
      CONCATENATE 'Are you sure you want to do a'(m31) lw_command
                  'on table'(m32) lw_from '?'(m33)
                  INTO lw_msg SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Warning : critical operation'(t04)
          text_question         = lw_msg
          default_button        = '2'
          display_cancel_button = space
        IMPORTING
          answer                = lw_answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.
      IF sy-subrc NE 0 OR lw_answer NE '1'.
        RETURN.
      ENDIF.
    ENDIF.
    lw_count_only = abap_true. "no result grid to display
  ELSEIF lw_noauth NE space.
    PERFORM ddic_set_tree USING lw_from.
    RETURN.
  ELSEIF lw_from IS INITIAL.
    PERFORM ddic_set_tree USING lw_from.
    MESSAGE 'Cannot parse the query'(m07) TYPE c_msg_error.
  ELSE.
* Generate SELECT subroutine
    IF w_run LT c_query_max_exec.
      PERFORM query_generate USING lw_select lw_from
                                   lw_where fw_display
                                   lw_newsyntax
                             CHANGING lw_program lw_rows
                                      lt_fieldlist lw_count_only.
      IF lw_program IS INITIAL.
        PERFORM ddic_set_tree USING lw_from.
        RETURN.
      ENDIF.
      w_run = w_run + 1.
    ELSE.
      MESSAGE 'No more run available. Please restart program'(m50)
              TYPE c_msg_error.
    ENDIF.
  ENDIF.


* Call the generated subroutine
  IF NOT lw_program IS INITIAL.
    PERFORM run_sql IN PROGRAM (lw_program)
                    CHANGING lo_result lw_time lw_count.
    lw_from_concat = lw_from.
* For union, process second (and further) query
    WHILE NOT lw_union IS INITIAL.
* Parse Query
      lw_query2 = lw_union.
      PERFORM query_parse USING lw_query2
                          CHANGING lw_select lw_from lw_where
                                   lw_union lw_rows lw_noauth
                                   lw_newsyntax lw_error.
      CONCATENATE lw_from_concat 'JOIN' lw_from INTO lw_from_concat.
      IF lw_noauth NE space.
        PERFORM ddic_set_tree USING lw_from_concat.
        RETURN.
      ELSEIF lw_select IS INITIAL OR lw_from IS INITIAL
      OR lw_error = abap_true.
        PERFORM ddic_set_tree USING lw_from_concat.
        MESSAGE 'Cannot parse the unioned query'(m08) TYPE c_msg_error.
        EXIT. "exit while
      ENDIF.
* Generate subroutine
      IF w_run LT c_query_max_exec.
        PERFORM query_generate USING lw_select lw_from
                                     lw_where fw_display
                                     lw_newsyntax
                               CHANGING lw_program lw_rows
                                        lt_fieldlist2 lw_count_only.
        IF lw_program IS INITIAL.
          PERFORM ddic_set_tree USING lw_from_concat.
          RETURN.
        ENDIF.
        w_run = w_run + 1.
      ELSE.
        MESSAGE 'No more run available. Please restart program'(m50)
                TYPE c_msg_error.
      ENDIF.
* Call the generated subroutine
      PERFORM run_sql IN PROGRAM (lw_program)
                      CHANGING lo_result2 lw_time2 lw_count2.

* Append lines of the further queries to the first query
      ASSIGN lo_result->* TO <lft_data>.
      ASSIGN lo_result2->* TO <lft_data2>.
      APPEND LINES OF <lft_data2> TO <lft_data>.
      REFRESH <lft_data2>.
      lw_time = lw_time + lw_time2.
      lw_count = lw_count + lw_count2.
    ENDWHILE.

    PERFORM ddic_set_tree USING lw_from_concat.

* Display message
    lw_charnumb = lw_time.
    CONCATENATE 'Query executed in'(m09) lw_charnumb INTO lw_msg
                SEPARATED BY space.
    lw_charnumb = lw_count.
    IF NOT lw_select IS INITIAL.
      CONCATENATE lw_msg 'seconds.'(m10)
                  lw_charnumb 'entries found'(m11)
                  INTO lw_msg SEPARATED BY space.
    ELSE.
      CONCATENATE lw_msg 'seconds.'(m10)
                  lw_charnumb 'entries affected'(m12)
                  INTO lw_msg SEPARATED BY space.
    ENDIF.
    CONDENSE lw_msg.
    MESSAGE lw_msg TYPE c_msg_success.


* Display result except for count(*)
    IF lw_count_only IS INITIAL.
      IF fw_download = space.
        PERFORM result_display USING lo_result lt_fieldlist lw_query.
      ELSE.
        PERFORM result_save_file USING lo_result lt_fieldlist.
      ENDIF.
    ENDIF.

    PERFORM repo_save_current_query.
  ENDIF.
ENDFORM.                    " QUERY_PROCESS

*&---------------------------------------------------------------------*
*&      Form  EDITOR_GET_QUERY
*&---------------------------------------------------------------------*
*       Return active query without comment
*----------------------------------------------------------------------*
*      -->FW_FORCE_LAST  Keep last request
*      <--FW_QUERY       Query code
*----------------------------------------------------------------------*
FORM editor_get_query USING fw_force_last TYPE c
                      CHANGING fw_query TYPE string.
  DATA : lt_query         TYPE soli_tab,
         ls_query         LIKE LINE OF lt_query,
         ls_find          TYPE match_result,
         lt_find          TYPE match_result_tab,
         lt_find_sub      TYPE match_result_tab,
         lw_lines         TYPE i,
         lw_cursor_line   TYPE i,
         lw_cursor_pos    TYPE i,
         lw_delto_line    TYPE i,
         lw_delto_pos     TYPE i,
         lw_cursor_offset TYPE i,
         lw_last          TYPE c.

  CLEAR fw_query.

* Get selected content
  CALL METHOD s_tab_active-o_textedit->get_selected_text_as_table
    IMPORTING
      table = lt_query[].

* if no selected content, get complete content of abap edit box
  IF lt_query[] IS INITIAL.
    CALL METHOD s_tab_active-o_textedit->get_text
      IMPORTING
        table  = lt_query[]
      EXCEPTIONS
        OTHERS = 1.
  ENDIF.

* Remove * comment
  LOOP AT lt_query INTO ls_query WHERE line(1) = '*'.
    CLEAR ls_query-line.
    MODIFY lt_query FROM ls_query.
  ENDLOOP.

* Remove " comment
  LOOP AT lt_query INTO ls_query WHERE line CS '"'.
*    condense ls_query-line.
    FIND ALL OCCURRENCES OF '"' IN ls_query-line RESULTS lt_find.
    IF sy-subrc NE 0. "may not occurs
      CONTINUE.
    ENDIF.
    LOOP AT lt_find INTO ls_find.
      IF ls_find-offset GT 0.
* Search open '
        FIND ALL OCCURRENCES OF '''' IN ls_query-line(ls_find-offset)
             RESULTS lt_find_sub.
        IF sy-subrc = 0.
          DESCRIBE TABLE lt_find_sub LINES lw_lines.
          lw_lines = lw_lines MOD 2.
          IF lw_lines = 1.
            CONTINUE.
          ENDIF.
        ENDIF.
        ls_query-line = ls_query-line(ls_find-offset).
        EXIT. "exit loop
      ELSE.
        CLEAR ls_query-line.
        EXIT. "exit loop
      ENDIF.
    ENDLOOP.
    MODIFY lt_query FROM ls_query.
  ENDLOOP.

* Find active query
  CALL METHOD s_tab_active-o_textedit->get_selection_pos
    IMPORTING
      from_line = lw_cursor_line
      from_pos  = lw_cursor_pos.
  lw_cursor_offset = lw_cursor_pos - 1.

  FIND ALL OCCURRENCES OF '.' IN TABLE lt_query RESULTS lt_find.
  CLEAR : lw_delto_line,
          lw_delto_pos,
          lw_last.
  LOOP AT lt_find INTO ls_find.
    AT LAST.
      lw_last = abap_true.
    ENDAT.
* Search for open '
    IF ls_find-offset GT 0.
      READ TABLE lt_query INTO ls_query INDEX ls_find-line.
      FIND ALL OCCURRENCES OF '''' IN ls_query(ls_find-offset)
           RESULTS lt_find_sub.
      DESCRIBE TABLE lt_find_sub LINES lw_lines.
      lw_lines = lw_lines MOD 2.
* If open ' found, ignore the dot
      IF lw_lines = 1.
        CONTINUE.
      ENDIF.
    ENDIF.

* Active Query
    IF ls_find-line GT lw_cursor_line
    OR ( ls_find-line = lw_cursor_line
         AND ls_find-offset GE lw_cursor_offset )
    OR ( lw_last = abap_true AND fw_force_last = abap_true ).
* Delete all query after query active
      ls_find-line = ls_find-line + 1.
      DELETE lt_query FROM ls_find-line.
      ls_find-line = ls_find-line - 1.
* Do not keep the . for active query
      IF ls_find-offset = 0.
        DELETE lt_query FROM ls_find-line.
      ELSE.
        ls_query-line = ls_query-line(ls_find-offset).
        MODIFY lt_query FROM ls_query INDEX ls_find-line.
      ENDIF.
      EXIT.
* Query before active
    ELSE.
      lw_delto_line = ls_find-line.
      lw_delto_pos = ls_find-offset + 1.
    ENDIF.
  ENDLOOP.

* Delete all query before query active
  IF NOT lw_delto_line IS INITIAL.
    IF lw_delto_line GT 1.
      lw_delto_line = lw_delto_line - 1.
      DELETE lt_query FROM 1 TO lw_delto_line.
    ENDIF.
    READ TABLE lt_query INTO ls_query INDEX 1.
    ls_query-line(lw_delto_pos) = ''.
    MODIFY lt_query FROM ls_query INDEX 1.
  ENDIF.

* Delete empty lines
  DELETE lt_query WHERE line CO ' .'.

* Build query string & Remove unnessential spaces
  LOOP AT lt_query INTO ls_query.
    CONDENSE ls_query-line.
    SHIFT ls_query-line LEFT DELETING LEADING space.
    CONCATENATE fw_query ls_query-line INTO fw_query SEPARATED BY space.
  ENDLOOP.
  IF NOT fw_query IS INITIAL.
    fw_query = fw_query+1.
  ENDIF.

* If no query selected, try to get the last one
  IF lt_query IS INITIAL AND fw_force_last = space.
    PERFORM editor_get_query USING abap_true
                             CHANGING fw_query.
  ENDIF.
ENDFORM.                    " EDITOR_GET_QUERY

*&---------------------------------------------------------------------*
*&      Form  QUERY_PARSE
*&---------------------------------------------------------------------*
*       Split the query into 3 parts : Select / From / Where
*       - Select : List of the fields to extract
*       - From   : List of the tables - with join condition
*       - Where  : List of filters + group, order, having clauses
*----------------------------------------------------------------------*
*      -->FW_QUERY   Query to parse
*      <--FW_SELECT  Select part of the query
*      <--FW_FROM    From part of the query
*      <--FW_WHERE   Where part of the query
*      <--FW_ROWS    Number of rows to display
*      <--FW_UNION   Union part of the query
*      <--FW_NOAUTH  Unallowed table entered
*      <--FW_NEWSYNTAX Use new SQL syntax introduced with NW7.40 SP5
*      <--FW_ERROR   Cannot parse the query
*----------------------------------------------------------------------*
FORM query_parse  USING    fw_query TYPE string
                  CHANGING fw_select TYPE string
                           fw_from TYPE string
                           fw_where TYPE string
                           fw_union TYPE string
                           fw_rows TYPE n
                           fw_noauth TYPE c
                           fw_newsyntax TYPE c
                           fw_error TYPE c.

  DATA : ls_find_select TYPE match_result,
         ls_find_from   TYPE match_result,
         ls_find_where  TYPE match_result,
         ls_sub         LIKE LINE OF ls_find_select-submatches,
         lw_offset      TYPE i,
         lw_length      TYPE i,
         lw_query       TYPE string,
         lo_regex       TYPE REF TO cl_abap_regex,
         lt_split       TYPE TABLE OF string,
         lw_string      TYPE string,
         lw_tabix       TYPE i,
         lw_table       TYPE tabname.

  CLEAR : fw_select,
          fw_from,
          fw_where,
          fw_rows,
          fw_union,
          fw_noauth,
          fw_newsyntax.

  lw_query = fw_query.

* Search union
  FIND FIRST OCCURRENCE OF ' UNION SELECT ' IN lw_query
       RESULTS ls_find_select IGNORING CASE.
  IF sy-subrc = 0.
    lw_offset = ls_find_select-offset + 7.
    fw_union = lw_query+lw_offset.
    lw_query = lw_query(ls_find_select-offset).
  ENDIF.

* Search UP TO xxx ROWS.
* Catch the number of rows, delete command in query
  CREATE OBJECT lo_regex
    EXPORTING
      pattern     = 'UP TO ([0-9]+) ROWS'
      ignore_case = abap_true.
  FIND FIRST OCCURRENCE OF REGEX lo_regex
       IN lw_query RESULTS ls_find_select.
  IF sy-subrc = 0.
    READ TABLE ls_find_select-submatches INTO ls_sub INDEX 1.
    IF sy-subrc = 0.
      fw_rows = lw_query+ls_sub-offset(ls_sub-length).
    ENDIF.
    REPLACE FIRST OCCURRENCE OF REGEX lo_regex IN lw_query WITH ''.
  ELSE.
* Set default number of rows
    fw_rows = s_customize-default_rows.
  ENDIF.

* Remove unused INTO (CORRESPONDING FIELDS OF)(TABLE)
* Detect new syntax in internal table name
  CONCATENATE '(INTO|APPENDING)( TABLE'
              '| CORRESPONDING FIELDS OF TABLE |'
              'CORRESPONDING FIELDS OF | )(\S*)'
              INTO lw_string SEPARATED BY space.
  CREATE OBJECT lo_regex
    EXPORTING
      pattern     = lw_string
      ignore_case = abap_true.
  FIND FIRST OCCURRENCE OF REGEX lo_regex
       IN lw_query RESULTS ls_find_select.
  IF sy-subrc = 0.
    IF ls_find_select-length NE 0
    AND fw_query+ls_find_select-offset(ls_find_select-length) CS '@'.
      fw_newsyntax = abap_true.
    ENDIF.
    REPLACE FIRST OCCURRENCE OF REGEX lo_regex IN lw_query WITH ''.
  ENDIF.

* Search SELECT
  FIND FIRST OCCURRENCE OF 'SELECT ' IN lw_query
       RESULTS ls_find_select IGNORING CASE.
  IF sy-subrc NE 0.
    RETURN.
  ENDIF.

* Search FROM
  FIND FIRST OCCURRENCE OF ' FROM '
       IN SECTION OFFSET ls_find_select-offset OF lw_query
       RESULTS ls_find_from IGNORING CASE.
  IF sy-subrc NE 0.
    fw_error = abap_true.
    RETURN.
  ENDIF.

* Search WHERE / GROUP BY / HAVING / ORDER BY
  FIND FIRST OCCURRENCE OF ' WHERE '
       IN SECTION OFFSET ls_find_from-offset OF lw_query
       RESULTS ls_find_where IGNORING CASE.
  IF sy-subrc NE 0.
    FIND FIRST OCCURRENCE OF ' GROUP BY ' IN lw_query
         RESULTS ls_find_where IGNORING CASE.
  ENDIF.
  IF sy-subrc NE 0.
    FIND FIRST OCCURRENCE OF ' HAVING ' IN lw_query
         RESULTS ls_find_where IGNORING CASE.
  ENDIF.
  IF sy-subrc NE 0.
    FIND FIRST OCCURRENCE OF ' ORDER BY ' IN lw_query
         RESULTS ls_find_where IGNORING CASE.
  ENDIF.

  lw_offset = ls_find_select-offset + 7.
  lw_length = ls_find_from-offset - ls_find_select-offset - 7.
  IF lw_length LE 0.
    fw_error = abap_true.
    RETURN.
  ENDIF.
  fw_select = lw_query+lw_offset(lw_length).

* Detect new syntax in comma field select separator
  IF fw_select CS ','.
    fw_newsyntax = abap_true.
  ENDIF.

  lw_offset = ls_find_from-offset + 6.
  IF ls_find_where IS INITIAL.
    fw_from = lw_query+lw_offset.
    fw_where = ''.
  ELSE.
    lw_length = ls_find_where-offset - ls_find_from-offset - 6.
    fw_from = lw_query+lw_offset(lw_length).
    lw_offset = ls_find_where-offset.
    fw_where = lw_query+lw_offset.
  ENDIF.

* Authority-check on used select tables
  IF s_customize-auth_object NE space OR s_customize-auth_select NE '*'.
    CONCATENATE 'JOIN' fw_from INTO lw_string SEPARATED BY space.
    TRANSLATE lw_string TO UPPER CASE.
    SPLIT lw_string AT space INTO TABLE lt_split.
    LOOP AT lt_split INTO lw_string.
      lw_tabix = sy-tabix + 1.
      CHECK lw_string = 'JOIN'.
* Read next line (table name)
      READ TABLE lt_split INTO lw_table INDEX lw_tabix.
      CHECK sy-subrc = 0.

      IF s_customize-auth_object NE space.
        AUTHORITY-CHECK OBJECT s_customize-auth_object
                 ID 'TABLE' FIELD lw_table
                 ID 'ACTVT' FIELD s_customize-actvt_select.
      ELSEIF s_customize-auth_select NE '*'
      AND NOT lw_table CP s_customize-auth_select.
        sy-subrc = 4.
      ENDIF.
      IF sy-subrc NE 0.
        CONCATENATE 'No authorisation for table'(m13) lw_table
                    INTO lw_string SEPARATED BY space.
        MESSAGE lw_string TYPE c_msg_success DISPLAY LIKE c_msg_error.
        CLEAR fw_from.
        fw_noauth = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " QUERY_PARSE

*&---------------------------------------------------------------------*
*&      Form  add_line_to_table
*&---------------------------------------------------------------------*
*       Add a string line in a table
*       Break line at 255 char, respecting words if possible
*----------------------------------------------------------------------*
*      -->FW_LINE    Line to add in table
*      <--FT_TABLE   Table to append
*----------------------------------------------------------------------*
FORM add_line_to_table USING fw_line TYPE string
                       CHANGING ft_table TYPE table.
  DATA : lw_length TYPE i,
         lw_offset TYPE i,
         ls_find   TYPE match_result.

  lw_length = strlen( fw_line ).
  lw_offset = 0.
  DO.
    IF lw_length LE c_line_max.
      APPEND fw_line+lw_offset(lw_length) TO ft_table.
      EXIT. "exit do
    ELSE.
      FIND ALL OCCURRENCES OF REGEX '\s' "search space
           IN SECTION OFFSET lw_offset LENGTH c_line_max
           OF fw_line RESULTS ls_find.
      IF sy-subrc NE 0.
        APPEND fw_line+lw_offset(c_line_max) TO ft_table.
        lw_length = lw_length - c_line_max.
        lw_offset = lw_offset + c_line_max.
      ELSE.
        ls_find-length = ls_find-offset - lw_offset.
        APPEND fw_line+lw_offset(ls_find-length) TO ft_table.
        lw_length = lw_length + lw_offset - ls_find-offset - 1.
        lw_offset = ls_find-offset + 1.
      ENDIF.
    ENDIF.
  ENDDO.

ENDFORM.                    "add_line_to_table

*&---------------------------------------------------------------------*
*&      Form  QUERY_GENERATE
*&---------------------------------------------------------------------*
*       Create SELECT SQL query in a new generated temp program
*----------------------------------------------------------------------*
*      -->FW_SELECT    Select part of the query
*      -->FW_FROM      From part of the query
*      -->FW_WHERE     Where part of the query
*      -->FW_DISPLAY   Display code instead of generated routine
*      -->FW_NEWSYNTAX Use new SQL syntax introduced with NW7.40 SP5
*      <--FW_PROGRAM   Name of the generated program
*      <--FW_ROWS      Number of rows to display
*      <--FT_FIELDLIST List of fields to display
*      <--FW_COUNT     = true if query is only count( * )
*----------------------------------------------------------------------*
FORM query_generate  USING    fw_select TYPE string
                              fw_from TYPE string
                              fw_where TYPE string
                              fw_display TYPE c
                              fw_newsyntax TYPE c
                     CHANGING fw_program TYPE sy-repid
                              fw_rows TYPE n
                              ft_fieldlist TYPE ty_fieldlist_table
                              fw_count TYPE c.

  DATA : lt_code_string TYPE TABLE OF string,
         lt_split       TYPE TABLE OF string,
         lw_string      TYPE string,
         lw_string2     TYPE string,
         BEGIN OF ls_table_alias,
           table(50) TYPE c,
           alias(50) TYPE c,
         END OF ls_table_alias,
         lt_table_alias      LIKE TABLE OF ls_table_alias,
         lw_select           TYPE string,
         lw_from             TYPE string,
         lw_index            TYPE i,
         lw_select_distinct  TYPE c,
         lw_select_length    TYPE i,
         lw_char_10(10)      TYPE c,
         lw_field_number(6)  TYPE n,
         lw_current_line     TYPE i,
         lw_current_length   TYPE i,
         lw_struct_line      TYPE string,
         lw_struct_line_type TYPE string,
         lw_select_table     TYPE string,
         lw_select_field     TYPE string,
         lw_dd03l_fieldname  TYPE dd03l-fieldname,
         lw_position_dummy   TYPE dd03l-position,
         lw_mess(255),
         lw_line             TYPE i,
         lw_word(30),
         ls_fieldlist        TYPE ty_fieldlist,
         lw_strlen_string    TYPE string,
         lw_explicit         TYPE string.

  DEFINE c.
    lw_strlen_string = &1.
    perform add_line_to_table using lw_strlen_string
                              changing lt_code_string.
  END-OF-DEFINITION.

  CLEAR : lw_select_distinct,
          fw_count.

* Write Header
  c 'PROGRAM SUBPOOL.'.
  c '** GENERATED PROGRAM * DO NOT CHANGE IT **'.
  c 'TYPE-POOLS: slis.'.                                    "#EC NOTEXT
  c ''.

  lw_select = fw_select.
  TRANSLATE lw_select TO UPPER CASE.

  lw_from = fw_from.
  TRANSLATE lw_from TO UPPER CASE.

* Search special term "single" or "distinct"
  lw_select_length = strlen( lw_select ).
  IF lw_select_length GE 7.
    lw_char_10 = lw_select(7).
    IF lw_char_10 = 'SINGLE'.
* Force rows number = 1 for select single
      fw_rows = 1.
      lw_select = lw_select+7.
      lw_select_length = lw_select_length - 7.
    ENDIF.
  ENDIF.
  IF lw_select_length GE 9.
    lw_char_10 = lw_select(9).
    IF lw_char_10 = 'DISTINCT'.
      lw_select_distinct = abap_true.
      lw_select = lw_select+9.
      lw_select_length = lw_select_length - 9.
    ENDIF.
  ENDIF.

* Search for special syntax "count( * )"
  IF lw_select = 'COUNT( * )'.
    fw_count = abap_true.
  ENDIF.

* Create alias table mapping
  SPLIT lw_from AT space INTO TABLE lt_split.
  LOOP AT lt_split INTO lw_string.
    IF lw_string IS INITIAL OR lw_string CO space.
      DELETE lt_split.
    ENDIF.
  ENDLOOP.
  DO.
    READ TABLE lt_split TRANSPORTING NO FIELDS WITH KEY = 'AS'.
    IF sy-subrc NE 0.
      EXIT. "exit do
    ENDIF.
    lw_index = sy-tabix - 1.
    READ TABLE lt_split INTO lw_string INDEX lw_index.
    ls_table_alias-table = lw_string.
    DELETE lt_split INDEX lw_index. "delete table field
    DELETE lt_split INDEX lw_index. "delete keywork AS
    READ TABLE lt_split INTO lw_string INDEX lw_index.
    ls_table_alias-alias = lw_string.
    DELETE lt_split INDEX lw_index. "delete alias field
    APPEND ls_table_alias TO lt_table_alias.
  ENDDO.
* If no alias table found, create just an entry for "*"
  IF lt_table_alias[] IS INITIAL.
    READ TABLE lt_split INTO lw_string INDEX 1.
    ls_table_alias-table = lw_string.
    ls_table_alias-alias = '*'.
    APPEND ls_table_alias TO lt_table_alias.
  ENDIF.
  SORT lt_table_alias BY alias.

* Write Data declaration
  c '***************************************'.              "#EC NOTEXT
  c '*      Begin of data declaration      *'.              "#EC NOTEXT
  c '*   Used to store lines of the query  *'.              "#EC NOTEXT
  c '***************************************'.              "#EC NOTEXT
  c 'DATA: BEGIN OF s_result'.                              "#EC NOTEXT
  lw_field_number = 1.

  lw_string = lw_select.
  IF fw_newsyntax = abap_true.
    TRANSLATE lw_string USING ', '.
    CONDENSE lw_string.
  ENDIF.
  SPLIT lw_string AT space INTO TABLE lt_split.

  LOOP AT lt_split INTO lw_string.
    lw_current_line = sy-tabix.
    IF lw_string IS INITIAL OR lw_string CO space.
      CONTINUE.
    ENDIF.
    IF lw_string = 'AS'.
      DELETE lt_split INDEX lw_current_line. "delete AS
      DELETE lt_split INDEX lw_current_line. "delete the alias name
      CONTINUE.
    ENDIF.
    lw_current_length = strlen( lw_string ).

    CLEAR ls_fieldlist.
    ls_fieldlist-ref_field = lw_string.

* Manage new syntax "Case"
    IF fw_newsyntax = abap_true AND lw_string = 'CASE'.
      lw_index = lw_current_line.
      DO.
        lw_index = lw_index + 1.
        READ TABLE lt_split INTO lw_string INDEX lw_index.
        IF sy-subrc NE 0.
          MESSAGE 'Incorrect syntax in Case statement'(m62)
                   TYPE c_msg_success DISPLAY LIKE c_msg_error.
          RETURN.
        ENDIF.
        IF lw_string = 'END'.
          lw_index = lw_index + 1.
          READ TABLE lt_split INTO lw_string INDEX lw_index.
          IF lw_string NE 'AS'.
            lw_index = lw_index - 1.
            CONTINUE.
          ENDIF.
          lw_index = lw_index + 1.
          READ TABLE lt_split INTO lw_string INDEX lw_index.

          CLEAR ls_fieldlist.
          CONCATENATE 'F' lw_field_number INTO ls_fieldlist-field.
          CONCATENATE ',' ls_fieldlist-field INTO lw_struct_line.
          CONCATENATE lw_struct_line 'TYPE string'          "#EC NOTEXT
                      INTO lw_struct_line SEPARATED BY space.
          c lw_struct_line.
          ls_fieldlist-ref_table = ''.
          ls_fieldlist-ref_field = lw_string.
          APPEND ls_fieldlist TO ft_fieldlist.
          lw_field_number = lw_field_number + 1.

          lw_index = lw_index - lw_current_line + 1.
          DO lw_index TIMES.
            DELETE lt_split INDEX lw_current_line. "delete the case element
          ENDDO.
          EXIT.
        ENDIF.
      ENDDO.
      CONTINUE.
    ENDIF.

* Manage "Count"
    IF lw_current_length GE 6.
      lw_char_10 = lw_string(6).
    ELSE.
      CLEAR lw_char_10.
    ENDIF.
    IF lw_char_10 = 'COUNT('.
      CONCATENATE 'F' lw_field_number INTO ls_fieldlist-field.
      CONCATENATE ',' ls_fieldlist-field INTO lw_struct_line.

      lw_index = lw_current_line + 1.
      DO.
        SEARCH lw_string FOR ')'.
        IF sy-subrc = 0.
          EXIT.
        ELSE.
* If there is space in the "count()", delete next lines
          READ TABLE lt_split INTO lw_string INDEX lw_index.
          IF sy-subrc NE 0.
            EXIT.
          ENDIF.
          CONCATENATE ls_fieldlist-ref_field lw_string
                      INTO ls_fieldlist-ref_field SEPARATED BY space.
          DELETE lt_split INDEX lw_index.
        ENDIF.
      ENDDO.
      CONCATENATE lw_struct_line 'TYPE i'                   "#EC NOTEXT
                  INTO lw_struct_line SEPARATED BY space.
      c lw_struct_line.
      APPEND ls_fieldlist TO ft_fieldlist.
      lw_field_number = lw_field_number + 1.
      CONTINUE.
    ENDIF.

* Manage Agregate AVG
    IF lw_current_length GE 4.
      lw_char_10 = lw_string(4).
    ELSE.
      CLEAR lw_char_10.
    ENDIF.
    IF lw_char_10 = 'AVG('.
      CONCATENATE 'F' lw_field_number INTO ls_fieldlist-field.
      CONCATENATE ',' ls_fieldlist-field INTO lw_struct_line.

      lw_index = lw_current_line + 1.
      DO.
        SEARCH lw_string FOR ')'.
        IF sy-subrc = 0.
          EXIT.
        ELSE.
* If there is space in the agregate, delete next lines
          READ TABLE lt_split INTO lw_string INDEX lw_index.
          IF sy-subrc NE 0.
            EXIT.
          ENDIF.
          CONCATENATE ls_fieldlist-ref_field lw_string
                      INTO ls_fieldlist-ref_field SEPARATED BY space.
          DELETE lt_split INDEX lw_index.
        ENDIF.
      ENDDO.
      CONCATENATE lw_struct_line 'TYPE f'                   "#EC NOTEXT
                  INTO lw_struct_line SEPARATED BY space.
      c lw_struct_line.
      APPEND ls_fieldlist TO ft_fieldlist.
      lw_field_number = lw_field_number + 1.
      CONTINUE.
    ENDIF.

* Manage agregate SUM, MAX, MIN
    IF lw_current_length GE 4.
      lw_char_10 = lw_string(4).
    ELSE.
      CLEAR lw_char_10.
    ENDIF.
    IF lw_char_10 = 'SUM(' OR lw_char_10 = 'MAX('
    OR lw_char_10 = 'MIN('.
      clear lw_string2.
      lw_index = lw_current_line + 1.
      DO.
        SEARCH lw_string FOR ')'.
        IF sy-subrc = 0.
          EXIT.
        ELSE.
* Search name of the field in next lines.
          READ TABLE lt_split INTO lw_string INDEX lw_index.
          IF sy-subrc NE 0.
            EXIT.
          ENDIF.
          CONCATENATE ls_fieldlist-ref_field lw_string
                      INTO ls_fieldlist-ref_field SEPARATED BY space.
          IF lw_string2 IS INITIAL.
            lw_string2 = lw_string.
          ENDIF.
* Delete lines of agregage in field table
          DELETE lt_split INDEX lw_index.
        ENDIF.
      ENDDO.
      lw_string = lw_string2.
    ENDIF.

* Now lw_string contain a field name.
* We have to find the field description
    SPLIT lw_string AT '~' INTO lw_select_table lw_select_field.
    IF lw_select_field IS INITIAL.
      lw_select_field = lw_select_table.
      lw_select_table = '*'.
    ENDIF.
* Search if alias table used
    CLEAR ls_table_alias.
    READ TABLE lt_table_alias INTO ls_table_alias
               WITH KEY alias = lw_select_table             "#EC WARNOK
               BINARY SEARCH.
    IF sy-subrc = 0.
      lw_select_table = ls_table_alias-table.
    ENDIF.
    ls_fieldlist-ref_table = lw_select_table.
    IF lw_string = '*' OR lw_select_field = '*'. " expansion table~*
      CLEAR lw_explicit.
      SELECT fieldname position
      INTO   (lw_dd03l_fieldname,lw_position_dummy)
      FROM   dd03l
      WHERE  tabname    = lw_select_table
      AND    fieldname <> 'MANDT'
      AND    as4local   = c_vers_active
      AND    as4vers    = space
      AND (  comptype   = c_ddic_dtelm
          OR comptype   = space )
      ORDER BY position.

        lw_select_field = lw_dd03l_fieldname.

        CONCATENATE 'F' lw_field_number INTO ls_fieldlist-field.
        ls_fieldlist-ref_field = lw_select_field.
        APPEND ls_fieldlist TO ft_fieldlist.
        CONCATENATE ',' ls_fieldlist-field INTO lw_struct_line.

        CONCATENATE lw_select_table '-' lw_select_field
                    INTO lw_struct_line_type.
        CONCATENATE lw_struct_line 'TYPE' lw_struct_line_type
                    INTO lw_struct_line
                    SEPARATED BY space.
        c lw_struct_line.
        lw_field_number = lw_field_number + 1.
* Explicit list of fields instead of *
* Generate longer query but mandatory in case of T1~* or MARA~*
* Required also in some special cases, for example if table use include
        IF ls_table_alias-alias = space OR ls_table_alias-alias = '*'.
          CONCATENATE lw_explicit lw_select_table
                      INTO lw_explicit SEPARATED BY space.
        ELSE.
          CONCATENATE lw_explicit ls_table_alias-alias
                      INTO lw_explicit SEPARATED BY space.
        ENDIF.
        CONCATENATE lw_explicit '~' lw_select_field INTO lw_explicit.
      ENDSELECT.
      IF sy-subrc NE 0.
        MESSAGE e701(1r) WITH lw_select_table. "table does not exist
      ENDIF.
      IF NOT lw_explicit IS INITIAL.
        REPLACE FIRST OCCURRENCE OF lw_string
                IN lw_select WITH lw_explicit.
      ENDIF.

    ELSE. "Simple field
      CONCATENATE 'F' lw_field_number INTO ls_fieldlist-field.
      ls_fieldlist-ref_field = lw_select_field.
      APPEND ls_fieldlist TO ft_fieldlist.

      CONCATENATE ',' ls_fieldlist-field INTO lw_struct_line.

      CONCATENATE lw_select_table '-' lw_select_field
                  INTO lw_struct_line_type.
      CONCATENATE lw_struct_line 'TYPE' lw_struct_line_type
                  INTO lw_struct_line
                  SEPARATED BY space.
      c lw_struct_line.
      lw_field_number = lw_field_number + 1.
    ENDIF.
  ENDLOOP.

* Add a count field
  CLEAR ls_fieldlist.
  ls_fieldlist-field = 'COUNT'.
  ls_fieldlist-ref_table = ''.
  ls_fieldlist-ref_field = 'Count'.                         "#EC NOTEXT
  APPEND ls_fieldlist TO ft_fieldlist.
  c ', COUNT type i'.                                       "#EC NOTEXT

* End of data definition
  c ', END OF s_result'.                                    "#EC NOTEXT
  c ', t_result like table of s_result'.                    "#EC NOTEXT
  c ', w_timestart type timestampl'.                        "#EC NOTEXT
  c ', w_timeend type timestampl.'.                         "#EC NOTEXT

* Write the dynamic subroutine that run the SELECT
  c 'FORM run_sql CHANGING fo_result TYPE REF TO data'.     "#EC NOTEXT
  c '                      fw_time type p'.                 "#EC NOTEXT
  c '                      fw_count type i.'.               "#EC NOTEXT
  c 'field-symbols <fs_result> like s_result.'.             "#EC NOTEXT
  c '***************************************'.              "#EC NOTEXT
  c '*            Begin of query           *'.              "#EC NOTEXT
  c '***************************************'.              "#EC NOTEXT
  c 'get TIME STAMP FIELD w_timestart.'.                    "#EC NOTEXT
  IF fw_count = abap_true.
    CONCATENATE 'SELECT SINGLE' lw_select                   "#EC NOTEXT
                INTO lw_select SEPARATED BY space.
    c lw_select.
    IF fw_newsyntax = abap_true.
      c 'INTO @s_result-f000001'.                           "#EC NOTEXT
    ELSE.
      c 'INTO s_result-f000001'.                            "#EC NOTEXT
    ENDIF.
  ELSE.
    IF lw_select_distinct NE space.
      CONCATENATE 'SELECT DISTINCT' lw_select               "#EC NOTEXT
                  INTO lw_select SEPARATED BY space.
    ELSE.
      CONCATENATE 'SELECT' lw_select                        "#EC NOTEXT
                  INTO lw_select SEPARATED BY space.
    ENDIF.
    c lw_select.
    IF fw_newsyntax = abap_true.
      c 'INTO TABLE @t_result'.                             "#EC NOTEXT
    ELSE.
      c 'INTO TABLE t_result'.                              "#EC NOTEXT
    ENDIF.

* Add UP TO xxx ROWS
    IF NOT fw_rows IS INITIAL.
      c 'UP TO'.                                            "#EC NOTEXT
      c fw_rows.
      c 'ROWS'.                                             "#EC NOTEXT
    ENDIF.
  ENDIF.

  c 'FROM'.                                                 "#EC NOTEXT
  c lw_from.

* Where, group by, having, order by
  IF NOT fw_where IS INITIAL.
    c fw_where.
  ENDIF.
  c '.'.

* Display query execution time
  c 'get TIME STAMP FIELD w_timeend.'.                      "#EC NOTEXT
  c 'fw_time = w_timeend - w_timestart.'.                   "#EC NOTEXT
  c 'fw_count = sy-dbcnt.'.                                 "#EC NOTEXT

* If select count( * ), display number of results
  IF fw_count NE space.
    c 'MESSAGE i753(TG) WITH s_result-f000001.'.            "#EC NOTEXT
  ENDIF.
  c 'loop at t_result assigning <fs_result>.'.              "#EC NOTEXT
  c ' <fs_result>-count = 1.'.                              "#EC NOTEXT
  c 'endloop.'.                                             "#EC NOTEXT
  c 'GET REFERENCE OF t_result INTO fo_result.'.            "#EC NOTEXT
  c 'ENDFORM.'.                                             "#EC NOTEXT
  CLEAR : lw_line,
          lw_word,
          lw_mess.
  SYNTAX-CHECK FOR lt_code_string PROGRAM sy-repid
               MESSAGE lw_mess LINE lw_line WORD lw_word.
  IF sy-subrc NE 0 AND fw_display = space.
    MESSAGE lw_mess TYPE c_msg_success DISPLAY LIKE c_msg_error.
    CLEAR fw_program.
    RETURN.
  ENDIF.

  IF fw_display = space.
    GENERATE SUBROUTINE POOL lt_code_string NAME fw_program.
  ELSE.
    IF lw_mess IS NOT INITIAL.
      lw_explicit = lw_line.
      CONCATENATE lw_mess '(line'(m28) lw_explicit ',word'(m29)
                  lw_word ')'(m30)
                  INTO lw_mess SEPARATED BY space.
      MESSAGE lw_mess TYPE c_msg_success DISPLAY LIKE c_msg_error.
    ENDIF.
    EDITOR-CALL FOR lt_code_string DISPLAY-MODE
                TITLE 'Generated code for current query'(t01).
  ENDIF.

ENDFORM.                    " QUERY_GENERATE

*&---------------------------------------------------------------------*
*&      Form  RESULT_DISPLAY
*&---------------------------------------------------------------------*
*       Display data table in the bottom ALV part of the screen
*----------------------------------------------------------------------*
*      -->FO_RESULT    Reference to data to display
*      -->FT_FIELDLIST List of fields to display
*      -->FW_TITLE     Title of the ALV
*----------------------------------------------------------------------*
FORM result_display  USING fo_result TYPE REF TO data
                           ft_fieldlist TYPE ty_fieldlist_table
                           fw_title TYPE string.
*  TYPE-POOLS lvc. "for older sap system only

  DATA : ls_layout    TYPE lvc_s_layo,
         lt_fieldcat  TYPE lvc_t_fcat,
         ls_fieldlist TYPE ty_fieldlist,
         ls_fieldcat  LIKE LINE OF lt_fieldcat.
  DATA : lo_descr_table TYPE REF TO cl_abap_tabledescr,
         lo_descr_line  TYPE REF TO cl_abap_structdescr,
         ls_compx       TYPE abap_compdescr,
         lw_height      TYPE i.

  FIELD-SYMBOLS: <lft_data> TYPE ANY TABLE.

  ASSIGN fo_result->* TO <lft_data>.

* Get data type for COUNT & AVG fields
  lo_descr_table ?=
    cl_abap_typedescr=>describe_by_data_ref( fo_result ).
  lo_descr_line ?= lo_descr_table->get_table_line_type( ).

  LOOP AT ft_fieldlist INTO ls_fieldlist.
    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = ls_fieldlist-field.

    IF NOT ls_fieldlist-ref_table IS INITIAL.
      ls_fieldcat-ref_field = ls_fieldlist-ref_field.
      ls_fieldcat-ref_table = ls_fieldlist-ref_table.
      IF s_customize-techname = space.
        ls_fieldcat-reptext = ls_fieldlist-ref_field.
      ELSE.
        ls_fieldcat-reptext = ls_fieldlist-ref_field.
        ls_fieldcat-scrtext_s = ls_fieldlist-ref_field.
        ls_fieldcat-scrtext_m = ls_fieldlist-ref_field.
        ls_fieldcat-scrtext_l = ls_fieldlist-ref_field.
      ENDIF.
    ELSE. "COUNT & AVG field
      CLEAR ls_compx.
      READ TABLE lo_descr_line->components INTO ls_compx
                 WITH KEY name = ls_fieldlist-field.        "#EC WARNOK
      ls_fieldcat-intlen = ls_compx-length.
      ls_fieldcat-decimals = ls_compx-decimals.
      ls_fieldcat-inttype = ls_compx-type_kind.
      ls_fieldcat-reptext = ls_fieldlist-ref_field.
      ls_fieldcat-scrtext_s = ls_fieldlist-ref_field.
      ls_fieldcat-scrtext_m = ls_fieldlist-ref_field.
      ls_fieldcat-scrtext_l = ls_fieldlist-ref_field.
    ENDIF.
    APPEND ls_fieldcat TO lt_fieldcat.
  ENDLOOP.

  ls_layout-smalltitle = abap_true.
  ls_layout-zebra = abap_true.
  ls_layout-cwidth_opt = abap_true.
  ls_layout-grid_title = fw_title.
  ls_layout-countfname = 'COUNT'.

* Set the grid config and content
  CALL METHOD s_tab_active-o_alv_result->set_table_for_first_display
    EXPORTING
      is_layout       = ls_layout
    CHANGING
      it_outtab       = <lft_data>
      it_fieldcatalog = lt_fieldcat.

* Search if grid is currently displayed
  CALL METHOD o_splitter->get_row_height
    EXPORTING
      id     = 1
    IMPORTING
      result = lw_height.
  CALL METHOD cl_gui_cfw=>flush.

* If grid is hidden, display it
  IF lw_height = 100.
    CALL METHOD o_splitter->set_row_height
      EXPORTING
        id     = 1
        height = 20.
  ENDIF.
ENDFORM.                    " RESULT_DISPLAY

*&---------------------------------------------------------------------*
*&      Form  DDIC_INIT
*&---------------------------------------------------------------------*
*       Initialize ddic tree
*----------------------------------------------------------------------*
FORM ddic_init.
  DATA : ls_header   TYPE treev_hhdr,
         ls_event    TYPE cntl_simple_event,
         lt_events   TYPE cntl_simple_events,
         lo_dragdrop TYPE REF TO cl_dragdrop,
         lw_mode     TYPE i.

  ls_header-heading = 'SAP Table/Fields'(t02).
  ls_header-width = 30.
  lw_mode = cl_gui_column_tree=>node_sel_mode_single.

  CREATE OBJECT s_tab_active-o_tree_ddic
    EXPORTING
      parent                      = o_container_ddic
      node_selection_mode         = lw_mode
      item_selection              = abap_true
      hierarchy_column_name       = c_ddic_col1
      hierarchy_header            = ls_header
    EXCEPTIONS
      cntl_system_error           = 1
      create_error                = 2
      failed                      = 3
      illegal_node_selection_mode = 4
      illegal_column_name         = 5
      lifetime_error              = 6.
  IF sy-subrc <> 0.
    MESSAGE a000(tree_control_msg).
  ENDIF.

* Column2
  CALL METHOD s_tab_active-o_tree_ddic->add_column
    EXPORTING
      name                         = c_ddic_col2
      width                        = 21
      header_text                  = 'Description'(t03)
    EXCEPTIONS
      column_exists                = 1
      illegal_column_name          = 2
      too_many_columns             = 3
      illegal_alignment            = 4
      different_column_types       = 5
      cntl_system_error            = 6
      failed                       = 7
      predecessor_column_not_found = 8.

* Manage Item clic event to copy value in clipboard
  ls_event-eventid = cl_gui_column_tree=>eventid_item_double_click.
  ls_event-appl_event = abap_true.
  APPEND ls_event TO lt_events.

  CALL METHOD s_tab_active-o_tree_ddic->set_registered_events
    EXPORTING
      events                    = lt_events
    EXCEPTIONS
      cntl_error                = 1
      cntl_system_error         = 2
      illegal_event_combination = 3.
  IF sy-subrc <> 0.
    MESSAGE a000(tree_control_msg).
  ENDIF.

* Manage Drag from DDIC editor
  CREATE OBJECT lo_dragdrop.
  CALL METHOD lo_dragdrop->add
    EXPORTING
      flavor     = 'EDIT_INSERT'
      dragsrc    = abap_true
      droptarget = space
      effect     = cl_dragdrop=>copy.
  CALL METHOD lo_dragdrop->get_handle
    IMPORTING
      handle = w_dragdrop_handle_tree.

  SET HANDLER o_handle_event->hnd_ddic_item_dblclick FOR s_tab_active-o_tree_ddic.
  SET HANDLER o_handle_event->hnd_ddic_drag FOR s_tab_active-o_tree_ddic.

* Calculate ZSPRO nodes to add at the bottom of the ddic tree
  PERFORM ddic_add_tree_zspro IN PROGRAM (sy-repid) IF FOUND.

ENDFORM.                    " DDIC_INIT

*&---------------------------------------------------------------------*
*&      Form  DDIC_SET_TREE
*&---------------------------------------------------------------------*
*       Refresh query with list of table/fields of the given query
*       Add User defined tree from ZSPRO (if relevant)
*----------------------------------------------------------------------*
*      -->FW_FROM  From part of the query
*----------------------------------------------------------------------*
FORM ddic_set_tree USING fw_from TYPE string.

  DATA : lw_from   TYPE string,
         lt_split  TYPE TABLE OF string,
         lw_string TYPE string,
         lw_tabix  TYPE i,
         BEGIN OF ls_table_list,
           table(30),
           alias(30),
         END OF ls_table_list,
         lt_table_list     LIKE TABLE OF ls_table_list,
         lw_node_number(6) TYPE n,
         ls_node           LIKE LINE OF s_tab_active-t_node_ddic,
         ls_item           LIKE LINE OF s_tab_active-t_item_ddic,
         lw_parent_node    LIKE ls_node-node_key,
         BEGIN OF ls_ddic_fields,
           tabname   TYPE dd03l-tabname,
           fieldname TYPE dd03l-fieldname,
           position  TYPE dd03l-position,
           keyflag   TYPE dd03l-keyflag,
           ddtext1   TYPE dd03t-ddtext,
           ddtext2   TYPE dd04t-ddtext,
         END OF ls_ddic_fields,
         lt_ddic_fields LIKE TABLE OF ls_ddic_fields.

  CONCATENATE 'FROM' fw_from INTO lw_from SEPARATED BY space.

  TRANSLATE lw_from TO UPPER CASE.

  SPLIT lw_from AT space INTO TABLE lt_split.
  LOOP AT lt_split INTO lw_string.
    lw_tabix = sy-tabix + 1.
    CHECK sy-tabix = 1 OR lw_string = 'JOIN'.
* Read next line (table name)
    READ TABLE lt_split INTO lw_string INDEX lw_tabix.
    CHECK sy-subrc = 0.

    CLEAR ls_table_list.
    ls_table_list-table = lw_string.

    lw_tabix = lw_tabix + 1.
* Read next line (search alias)
    READ TABLE lt_split INTO lw_string INDEX lw_tabix.
    IF sy-subrc = 0 AND lw_string = 'AS'.
      lw_tabix = lw_tabix + 1.
      READ TABLE lt_split INTO lw_string INDEX lw_tabix.
      IF sy-subrc = 0.
        ls_table_list-alias = lw_string.
      ENDIF.
    ENDIF.
    APPEND ls_table_list TO lt_table_list.
  ENDLOOP.

* Get list of fields for selected tables
  IF NOT lt_table_list IS INITIAL.
    SELECT dd03l~tabname dd03l~fieldname dd03l~position
           dd03l~keyflag dd03t~ddtext dd04t~ddtext
           INTO TABLE lt_ddic_fields
           FROM dd03l
           LEFT OUTER JOIN dd03t
           ON dd03l~tabname = dd03t~tabname
           AND dd03l~fieldname = dd03t~fieldname
           AND dd03l~as4local = dd03t~as4local
           AND dd03t~ddlanguage = sy-langu
           LEFT OUTER JOIN dd04t
           ON dd03l~rollname = dd04t~rollname
           AND dd03l~as4local = dd04t~as4local
           AND dd04t~ddlanguage = sy-langu
           FOR ALL ENTRIES IN lt_table_list
           WHERE dd03l~tabname = lt_table_list-table
           AND dd03l~as4local = c_vers_active
           AND dd03l~as4vers = space
           AND ( dd03l~comptype = c_ddic_dtelm
           OR    dd03l~comptype = space ).
    SORT lt_ddic_fields BY tabname keyflag DESCENDING position.
    DELETE ADJACENT DUPLICATES FROM lt_ddic_fields
                               COMPARING tabname fieldname.
  ENDIF.

* Build Node & Item tree
  REFRESH : s_tab_active-t_node_ddic,
            s_tab_active-t_item_ddic.
  lw_node_number = 0.
  LOOP AT lt_table_list INTO ls_table_list.
* Check table exists (has at least one field)
    READ TABLE lt_ddic_fields TRANSPORTING NO FIELDS
               WITH KEY tabname = ls_table_list-table.
    IF sy-subrc NE 0.
      DELETE lt_table_list.
      CONTINUE.
    ENDIF.

    lw_node_number = lw_node_number + 1.
    CLEAR ls_node.
    ls_node-node_key = lw_node_number.
    ls_node-isfolder = abap_true.
    ls_node-n_image = '@PO@'.
    ls_node-exp_image = '@PO@'.
    ls_node-expander = abap_true.
    APPEND ls_node TO s_tab_active-t_node_ddic.

    CLEAR ls_item.
    ls_item-node_key = lw_node_number.
    ls_item-class = cl_gui_column_tree=>item_class_text.
    ls_item-item_name = c_ddic_col1.
    IF ls_table_list-alias IS INITIAL.
      ls_item-text = ls_table_list-table.
    ELSE.
      CONCATENATE ls_table_list-table 'AS' ls_table_list-alias
                   INTO ls_item-text SEPARATED BY space.
    ENDIF.
    APPEND ls_item TO s_tab_active-t_item_ddic.
    ls_item-item_name = c_ddic_col2.
    SELECT SINGLE ddtext INTO ls_item-text
           FROM dd02t
           WHERE tabname = ls_table_list-table
           AND ddlanguage = sy-langu
           AND as4local = c_vers_active
           AND as4vers = space.
    IF sy-subrc NE 0.
      ls_item-text = ls_table_list-table.
    ENDIF.
    APPEND ls_item TO s_tab_active-t_item_ddic.

* Display list of fields
    lw_parent_node = ls_node-node_key.
    LOOP AT lt_ddic_fields INTO ls_ddic_fields
            WHERE tabname = ls_table_list-table.
      CLEAR ls_node.
      lw_node_number = lw_node_number + 1.
      ls_node-node_key = lw_node_number.
      ls_node-relatkey = lw_parent_node.
      ls_node-relatship = cl_gui_column_tree=>relat_last_child.
      IF ls_ddic_fields-keyflag = space.
        ls_node-n_image = '@3W@'.
        ls_node-exp_image = '@3W@'.
      ELSE.
        ls_node-n_image = '@3V@'.
        ls_node-exp_image = '@3V@'.
      ENDIF.
      ls_node-dragdropid = w_dragdrop_handle_tree.
      APPEND ls_node TO s_tab_active-t_node_ddic.

      CLEAR ls_item.
      ls_item-node_key = lw_node_number.
      ls_item-class = cl_gui_column_tree=>item_class_text.
      ls_item-item_name = c_ddic_col1.
      ls_item-text = ls_ddic_fields-fieldname.
      APPEND ls_item TO s_tab_active-t_item_ddic.
      ls_item-item_name = c_ddic_col2.
      IF NOT ls_ddic_fields-ddtext1 IS INITIAL.
        ls_item-text = ls_ddic_fields-ddtext1.
      ELSE.
        ls_item-text = ls_ddic_fields-ddtext2.
      ENDIF.
      APPEND ls_item TO s_tab_active-t_item_ddic.
    ENDLOOP.
  ENDLOOP.

* Add User defined tree from ZSPRO (if relevant)
  IF NOT t_node_zspro IS INITIAL.
    APPEND LINES OF t_node_zspro TO s_tab_active-t_node_ddic.
    APPEND LINES OF t_item_zspro TO s_tab_active-t_item_ddic.
  ENDIF.

  CALL METHOD s_tab_active-o_tree_ddic->delete_all_nodes.

  CALL METHOD s_tab_active-o_tree_ddic->add_nodes_and_items
    EXPORTING
      node_table                     = s_tab_active-t_node_ddic
      item_table                     = s_tab_active-t_item_ddic
      item_table_structure_name      = 'MTREEITM'
    EXCEPTIONS
      failed                         = 1
      cntl_system_error              = 3
      error_in_tables                = 4
      dp_error                       = 5
      table_structure_name_not_found = 6.
  IF sy-subrc <> 0.
    MESSAGE a000(tree_control_msg).
  ENDIF.

  DESCRIBE TABLE lt_table_list LINES lw_tabix.

* If no table found, display message
  IF lw_tabix = 0.
    MESSAGE 'No valid table found'(m15) TYPE c_msg_success
            DISPLAY LIKE c_msg_error.
* If 1 table found, expand it
  ELSEIF lw_tabix = 1.
    s_tab_active-o_tree_ddic->expand_root_nodes( ).
  ENDIF.
ENDFORM.                    " DDIC_SET_TREE

*&---------------------------------------------------------------------*
*&      Form  REPO_SAVE_QUERY
*&---------------------------------------------------------------------*
*       Save query
*----------------------------------------------------------------------*
FORM repo_save_query.
  DATA : lt_query         TYPE soli_tab,
         ls_query         LIKE LINE OF lt_query,
         lw_query_with_cr TYPE string,
         lw_guid          TYPE guid_32,
         ls_ztoad         TYPE ztoad,
         lw_timestamp(14) TYPE c.

* Set default options
  SELECT SINGLE class INTO s_options-visibilitygrp
         FROM usr02
         WHERE bname = sy-uname.
  s_options-visibility = '0'.

* Ask for options / query name
  CALL SCREEN 0200 STARTING AT 10 5
                   ENDING AT 60 7.
  IF s_options IS INITIAL.
    MESSAGE 'Action cancelled'(m14) TYPE c_msg_success
            DISPLAY LIKE c_msg_error.
    RETURN.
  ENDIF.

* Get content of abap edit box
  CALL METHOD s_tab_active-o_textedit->get_text
    IMPORTING
      table  = lt_query[]
    EXCEPTIONS
      OTHERS = 1.

* Serialize query into a string
  CLEAR lw_query_with_cr.
  LOOP AT lt_query INTO ls_query.
    CONCATENATE lw_query_with_cr ls_query cl_abap_char_utilities=>cr_lf
                INTO lw_query_with_cr.
  ENDLOOP.

* Generate new GUID
  DO 100 TIMES.
* Old function to get an unique id
    CALL FUNCTION 'GUID_CREATE'
      IMPORTING
        ev_guid_32 = lw_guid.
* New function to get an unique id (do not work on older sap system)
*    TRY.
*        lw_guid = cl_system_uuid=>create_uuid_c32_static( ).
*      CATCH cx_uuid_error.
*        EXIT. "exit do
*    ENDTRY.

* Check that this uid is not already used
    SELECT SINGLE queryid INTO ls_ztoad-queryid
           FROM ztoad
           WHERE queryid = lw_guid.
    IF sy-subrc NE 0.
      EXIT. "exit do
    ENDIF.
  ENDDO.

  ls_ztoad-queryid = lw_guid.
  ls_ztoad-owner = sy-uname.
  lw_timestamp(8) = sy-datum.
  lw_timestamp+8 = sy-uzeit.
  ls_ztoad-aedat = lw_timestamp.
  ls_ztoad-text = s_options-name.
  ls_ztoad-visibility = s_options-visibility.
  ls_ztoad-visibility_group = s_options-visibilitygrp.
  ls_ztoad-query = lw_query_with_cr.
  INSERT ztoad FROM ls_ztoad.
  IF sy-subrc = 0.
    MESSAGE s031(r9). "Query saved
  ELSE.
    MESSAGE e220(iqapi). "Error when saving the query
  ENDIF.

* Reset the modified status
  s_tab_active-o_textedit->set_textmodified_status( ).

* Refresh repository to display new saved query
  PERFORM repo_fill.

* Focus repository on new saved query
  PERFORM repo_focus_query USING lw_guid.
ENDFORM.                    " REPO_SAVE_QUERY

*&---------------------------------------------------------------------*
*&      Form  REPO_INIT
*&---------------------------------------------------------------------*
*       Initialize repository tree
*----------------------------------------------------------------------*
FORM repo_init.
  DATA: lt_event TYPE cntl_simple_events,
        ls_event TYPE cntl_simple_event.

* Create a tree control
  CREATE OBJECT o_tree_repository
    EXPORTING
      parent              = o_container_repository
      node_selection_mode = cl_gui_simple_tree=>node_sel_mode_single
    EXCEPTIONS
      lifetime_error      = 1
      cntl_system_error   = 2
      create_error        = 3
      failed              = 4
      OTHERS              = 5.
  IF sy-subrc <> 0.
    MESSAGE a000(tree_control_msg).
  ENDIF.

* Catch double clic to open query
  ls_event-eventid = cl_gui_simple_tree=>eventid_node_double_click.
  ls_event-appl_event = abap_true. " no PAI if event occurs
  APPEND ls_event TO lt_event.

* Catch context menu call
  ls_event-eventid = cl_gui_simple_tree=>eventid_node_context_menu_req.
  ls_event-appl_event = abap_true. " no PAI if event occurs
  APPEND ls_event TO lt_event.

  CALL METHOD o_tree_repository->set_registered_events
    EXPORTING
      events                    = lt_event
    EXCEPTIONS
      cntl_error                = 1
      cntl_system_error         = 2
      illegal_event_combination = 3.
  IF sy-subrc <> 0.
    MESSAGE a000(tree_control_msg).
  ENDIF.

* Assign event handlers in the application class to each desired event
  SET HANDLER o_handle_event->hnd_repo_dblclick
      FOR o_tree_repository.
  SET HANDLER o_handle_event->hnd_repo_context_menu
      FOR o_tree_repository.
  SET HANDLER o_handle_event->hnd_repo_context_menu_sel
      FOR o_tree_repository.

  PERFORM repo_fill.

ENDFORM.                    " REPO_INIT

*&---------------------------------------------------------------------*
*&      Form  REPO_FILL
*&---------------------------------------------------------------------*
*       Fill repository tree with all allowed queries
*----------------------------------------------------------------------*
FORM repo_fill.
  DATA : lw_usergroup TYPE usr02-class,
         BEGIN OF ls_query,
           queryid    TYPE ztoad-queryid,
           aedat      TYPE ztoad-aedat,
           visibility TYPE ztoad-visibility,
           text       TYPE ztoad-text,
           query      TYPE ztoad-query,
         END OF ls_query,
         lt_query_my     LIKE TABLE OF ls_query,
         lt_query_shared LIKE TABLE OF ls_query,
         lw_node_key(6)  TYPE n,
         lw_queryid      TYPE ztoad-queryid,
         lw_dummy(1)     TYPE c.                            "#EC NEEDED

* Get usergroup
  SELECT SINGLE class INTO lw_usergroup
         FROM usr02
         WHERE bname = sy-uname.

* Get all my queries
  SELECT queryid aedat visibility text query INTO TABLE lt_query_my
         FROM ztoad
         WHERE owner = sy-uname.

* Get all queries that i can use
  SELECT queryid aedat visibility text INTO TABLE lt_query_shared
         FROM ztoad
         WHERE owner NE sy-uname
         AND ( visibility = c_visibility_all
               OR ( visibility = c_visibility_shared
                    AND visibility_group = lw_usergroup )
             ).
  REFRESH t_node_repository.

  CALL METHOD o_tree_repository->delete_all_nodes.

  CLEAR s_node_repository.
  s_node_repository-node_key = c_nodekey_repo_my.
  s_node_repository-isfolder = abap_true.
  s_node_repository-text = 'My queries'(m16).
  APPEND s_node_repository TO t_node_repository.

  CLEAR lw_node_key.
  CONCATENATE sy-uname '+++' INTO lw_queryid.
  LOOP AT lt_query_my INTO ls_query WHERE queryid NP lw_queryid.
    lw_node_key = lw_node_key + 1.
    CLEAR s_node_repository.
    s_node_repository-node_key = lw_node_key.
    s_node_repository-relatkey = c_nodekey_repo_my.
    s_node_repository-relatship = cl_gui_simple_tree=>relat_last_child.
    IF ls_query-visibility = c_visibility_my.
      s_node_repository-n_image = s_node_repository-exp_image = '@LC@'.
    ELSE.
      s_node_repository-n_image = s_node_repository-exp_image = '@L9@'.
    ENDIF.
    s_node_repository-text = ls_query-text.
    s_node_repository-queryid = ls_query-queryid.
    s_node_repository-edit = abap_true.
    APPEND s_node_repository TO t_node_repository.
  ENDLOOP.

  CLEAR s_node_repository.
  s_node_repository-node_key = c_nodekey_repo_shared.
  s_node_repository-isfolder = abap_true.
  s_node_repository-text = 'Shared queries'(m17).
  APPEND s_node_repository TO t_node_repository.

  LOOP AT lt_query_shared INTO ls_query.
    lw_node_key = lw_node_key + 1.
    CLEAR s_node_repository.
    s_node_repository-node_key = lw_node_key.
    s_node_repository-relatkey = c_nodekey_repo_shared.
    s_node_repository-relatship = cl_gui_simple_tree=>relat_last_child.
    s_node_repository-n_image = s_node_repository-exp_image = '@L9@'.
    s_node_repository-text = ls_query-text.
    s_node_repository-queryid = ls_query-queryid.
    s_node_repository-edit = space.
    APPEND s_node_repository TO t_node_repository.
  ENDLOOP.

* Add history node
  CLEAR s_node_repository.
  s_node_repository-node_key = c_nodekey_repo_history.
  s_node_repository-isfolder = abap_true.
  s_node_repository-text = 'History'(m18).
  APPEND s_node_repository TO t_node_repository.

  DELETE lt_query_my WHERE queryid NP lw_queryid.
  SORT lt_query_my BY aedat DESCENDING.
  LOOP AT lt_query_my INTO ls_query.
    lw_node_key = lw_node_key + 1.
    CLEAR s_node_repository.
    s_node_repository-node_key = lw_node_key.
    s_node_repository-relatkey = c_nodekey_repo_history.
    s_node_repository-relatship = cl_gui_simple_tree=>relat_last_child.
    s_node_repository-n_image = s_node_repository-exp_image = '@LC@'.
    s_node_repository-text = ls_query-text.
    s_node_repository-queryid = ls_query-queryid.
    s_node_repository-edit = abap_true.
    IF ls_query-query(1) = '*'.
      SPLIT ls_query-query+1 AT cl_abap_char_utilities=>cr_lf
            INTO ls_query-query lw_dummy.
      CONCATENATE s_node_repository-text ':' ls_query-query
                  INTO s_node_repository-text SEPARATED BY space.
    ENDIF.
    APPEND s_node_repository TO t_node_repository.
  ENDLOOP.

  CALL METHOD o_tree_repository->add_nodes
    EXPORTING
      table_structure_name           = 'MTREESNODE'
      node_table                     = t_node_repository
    EXCEPTIONS
      failed                         = 1
      error_in_node_table            = 2
      dp_error                       = 3
      table_structure_name_not_found = 4
      OTHERS                         = 5.
  IF sy-subrc <> 0.
    MESSAGE a000(tree_control_msg).
  ENDIF.

* Exand all root nodes (my, shared, history)
  CALL METHOD o_tree_repository->expand_root_nodes.
ENDFORM.                    " REPO_FILL

*&---------------------------------------------------------------------*
*&      Form  REPO_SAVE_CURRENT_QUERY
*&---------------------------------------------------------------------*
*       Save query in the history area
*       Keep only 1000 last queries
*----------------------------------------------------------------------*
FORM repo_save_current_query.
  DATA : lt_query         TYPE soli_tab,
         ls_query         LIKE LINE OF lt_query,
         lw_query_with_cr TYPE string,
         ls_ztoad         TYPE ztoad,
         lw_number(3)     TYPE n,
         lw_timestamp(14) TYPE c,
         lw_dummy(1)      TYPE c,                           "#EC NEEDED
         lw_query_last    TYPE string,
         lw_date(10)      TYPE c,
         lw_time(8)       TYPE c,
         lw_dummy_date    TYPE timestamp.                   "#EC NEEDED

* Get content of abap edit box
  CALL METHOD s_tab_active-o_textedit->get_text
    IMPORTING
      table  = lt_query[]
    EXCEPTIONS
      OTHERS = 1.

* Serialize query into a string
  CLEAR lw_query_with_cr.
  LOOP AT lt_query INTO ls_query.
    CONCATENATE lw_query_with_cr ls_query cl_abap_char_utilities=>cr_lf
                INTO lw_query_with_cr.
  ENDLOOP.

* Define timestamp
  lw_timestamp(8) = sy-datum.
  lw_timestamp+8 = sy-uzeit.
  ls_ztoad-aedat = lw_timestamp.

* Search if query is same as last loaded
  SELECT SINGLE query INTO lw_query_last
         FROM ztoad
         WHERE queryid = w_last_loaded_query.
  IF sy-subrc = 0 AND lw_query_last = lw_query_with_cr.
    RETURN.
  ENDIF.

* Get usergroup
  SELECT SINGLE class INTO ls_ztoad-visibility_group
         FROM usr02
         WHERE bname = sy-uname.

  CLEAR lw_number.

* Get last query from history
  CONCATENATE sy-uname '#%' INTO ls_ztoad-queryid.
* aedat is not used but added in select for compatibility reason
  SELECT queryid aedat
         INTO (ls_ztoad-queryid, lw_dummy_date)
         FROM ztoad
         UP TO 1 ROWS
         WHERE queryid LIKE ls_ztoad-queryid
         AND owner = sy-uname
         ORDER BY aedat DESCENDING.
  ENDSELECT.
  IF sy-subrc = 0.
    SPLIT ls_ztoad-queryid AT '#' INTO lw_dummy lw_number.
  ENDIF.

  lw_number = lw_number + 1.

* For history query, guid = <sy-uname>#NN
  CONCATENATE sy-uname '#' lw_number INTO ls_ztoad-queryid.
  ls_ztoad-owner = sy-uname.
  ls_ztoad-visibility = c_visibility_my.

* Define text for query as timestamp
  WRITE sy-datlo TO lw_date.
  WRITE sy-timlo TO lw_time.
  CONCATENATE lw_date lw_time INTO ls_ztoad-text SEPARATED BY space.

  ls_ztoad-query = lw_query_with_cr.
  MODIFY ztoad FROM ls_ztoad.

  w_last_loaded_query = ls_ztoad-queryid.

* Reset the modified status
  s_tab_active-o_textedit->set_textmodified_status( ).

* Refresh repository
  PERFORM repo_fill.

* Focus on new query
  PERFORM repo_focus_query USING ls_ztoad-queryid.
ENDFORM.                    " REPO_SAVE_CURRENT_QUERY

*&---------------------------------------------------------------------*
*&      Form  QUERY_LOAD
*&---------------------------------------------------------------------*
*       Load query
*----------------------------------------------------------------------*
*      -->FW_QUERYID QueryID to load
*      <--FT_QUERY   Saved query
*----------------------------------------------------------------------*
FORM query_load USING fw_queryid TYPE ztoad-queryid
                CHANGING ft_query TYPE table.
  DATA lw_query_with_cr TYPE string.
  REFRESH ft_query.

  SELECT SINGLE query INTO lw_query_with_cr
         FROM ztoad
         WHERE queryid = fw_queryid.
  IF sy-subrc = 0.
    SPLIT lw_query_with_cr AT cl_abap_char_utilities=>cr_lf
                           INTO TABLE ft_query.
  ENDIF.
  w_last_loaded_query = fw_queryid.
ENDFORM.                    " QUERY_LOAD

*&---------------------------------------------------------------------*
*&      Form  REPO_FOCUS_QUERY
*&---------------------------------------------------------------------*
*       Focus repository tree on a given queryid
*----------------------------------------------------------------------*
*      -->FW_QUERYID  ID of the query to focus
*----------------------------------------------------------------------*
FORM repo_focus_query USING fw_queryid TYPE ztoad-queryid.

  READ TABLE t_node_repository INTO s_node_repository
             WITH KEY queryid = fw_queryid.
  IF sy-subrc NE 0.
    RETURN.
  ENDIF.

  CALL METHOD o_tree_repository->set_selected_node
    EXPORTING
      node_key = s_node_repository-node_key.

ENDFORM.                    " FOCUS_REPOSITORY

*&---------------------------------------------------------------------*
*&      Form  RESULT_INIT
*&---------------------------------------------------------------------*
*       Initialize ALV grid
*----------------------------------------------------------------------*
FORM result_init.

* Create ALV
  CREATE OBJECT s_tab_active-o_alv_result
    EXPORTING
      i_parent = o_container_result.

* Register event toolbar to add button
  SET HANDLER o_handle_event->hnd_result_toolbar FOR s_tab_active-o_alv_result.
  SET HANDLER o_handle_event->hnd_result_user_command FOR s_tab_active-o_alv_result.

ENDFORM.                    " RESULT_INIT

*&---------------------------------------------------------------------*
*&      Form  SCREEN_INIT_LISTBOX_0200
*&---------------------------------------------------------------------*
*       Fill dropdown listbox with value on screen 200
*----------------------------------------------------------------------*
FORM screen_init_listbox_0200.
  DATA lt_visibility TYPE vrm_values,
  TYPE-POOLS vrm.
  DATA : ls_visibility LIKE LINE OF lt_visibility.

  REFRESH lt_visibility.

  ls_visibility-key = c_visibility_my.
  ls_visibility-text = 'Personal'(m19).
  APPEND ls_visibility TO lt_visibility.

  ls_visibility-key = c_visibility_shared.
  ls_visibility-text = 'User group'(m20).
  APPEND ls_visibility TO lt_visibility.

  ls_visibility-key = c_visibility_all.
  ls_visibility-text = 'All'(m21).
  APPEND ls_visibility TO lt_visibility.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'S_OPTIONS-VISIBILITY'
      values = lt_visibility.

ENDFORM.                    " SCREEN_INIT_LISTBOX_0200

*&---------------------------------------------------------------------*
*&      Form  SCREEN_EXIT
*&---------------------------------------------------------------------*
*       Close the grid. If grid is closed, leave program
*       If sql text area is modified, ask confirmation before leave
*----------------------------------------------------------------------*
FORM screen_exit.
  DATA : lw_status    TYPE i,
         lw_answer(1) TYPE c,
         lw_size      TYPE i,
         lw_string    TYPE string.

* Check if grid is displayed
  CALL METHOD o_splitter->get_row_height
    EXPORTING
      id     = 1
    IMPORTING
      result = lw_size.
  CALL METHOD cl_gui_cfw=>flush.

* If grid is displayed, BACK action is only to close the grid
  IF lw_size < 100.
    CALL METHOD o_splitter->set_row_height
      EXPORTING
        id     = 1
        height = 100.
    RETURN.
  ENDIF.

* Check if textedit is modified
  CALL METHOD s_tab_active-o_textedit->get_textmodified_status
    IMPORTING
      status = lw_status.
  IF lw_status NE 0.
    CONCATENATE 'Current query is not saved. Do you want'(m22)
'to exit without saving or save into history then exit ?'(m56)
                INTO lw_string SEPARATED BY space.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        text_question         = lw_string
        text_button_1         = 'Exit'(m23)
        icon_button_1         = '@2M@'
        text_button_2         = 'Save & exit'(m24)
        icon_button_2         = '@2L@'
        default_button        = '2'
        display_cancel_button = space
      IMPORTING
        answer                = lw_answer.
    IF lw_answer = '2'.
      PERFORM repo_save_current_query.
    ENDIF.
  ENDIF.

  LEAVE TO SCREEN 0.
ENDFORM.                    " SCREEN_EXIT

*&---------------------------------------------------------------------*
*&      Form  SCREEN_DISPLAY_HELP
*&---------------------------------------------------------------------*
*       Display help for this program
*----------------------------------------------------------------------*
FORM screen_display_help.
  DATA : l_report          TYPE string,
         l_report_char1(1) TYPE c,
         l_report_char3(3) TYPE c,
         l_comment_found   TYPE i,
         lt_report         LIKE TABLE OF l_report,
         lt_lines          TYPE rcl_bag_tline,
         ls_line           LIKE LINE OF lt_lines,
         ls_help           TYPE help_info,
         lt_exclude        TYPE STANDARD TABLE OF string.

* Get program source code
  READ REPORT sy-repid INTO lt_report.

  ls_line-tdformat = 'U1'.
  ls_line-tdline = sy-title.
  APPEND ls_line TO lt_lines.

  ls_line-tdformat = 'U3'.
  ls_line-tdline = '&PURPOSE&'.
  APPEND ls_line TO lt_lines.

  LOOP AT lt_report INTO l_report.
    l_report_char1 = l_report.
    CHECK l_report_char1 = '*'.

* Keep only the second block of comment
* (first block is technical info, third is history)
    l_report_char3 = l_report.
    IF l_report_char3 = '*&-'.
      l_comment_found = l_comment_found + 1.
      IF l_comment_found LE 2.
        CONTINUE.
      ELSE. "l_comment_found > 2
        EXIT.
      ENDIF.
    ENDIF.
    IF l_comment_found = 2.
      l_report = l_report+1.
      l_report_char1 = l_report.
      CASE l_report_char1.
        WHEN '='.
          ls_line-tdformat = '='.
        WHEN '3'.
          ls_line-tdformat = 'U3'.
        WHEN 'E'.
          ls_line-tdformat = 'PE'.
        WHEN OTHERS.
          ls_line-tdformat = '*'.
      ENDCASE.
      IF NOT l_report_char1 IS INITIAL.
        l_report = l_report+1.
      ENDIF.
      IF l_report IS INITIAL.
        ls_line-tdformat = 'LZ'.
      ENDIF.
      ls_line-tdline = l_report.
      APPEND ls_line TO lt_lines.
    ENDIF.
  ENDLOOP.

  CALL FUNCTION 'HELP_DOCULINES_SHOW'
    EXPORTING
      help_infos = ls_help
    TABLES
      excludefun = lt_exclude
      helplines  = lt_lines.

ENDFORM.                    " SCREEN_DISPLAY_HELP

*&---------------------------------------------------------------------*
*&      Form  QUERY_PARSE_NOSELECT
*&---------------------------------------------------------------------*
*       Check if query is a known SQL command and if user is allowed
*----------------------------------------------------------------------*
*      -->FW_QUERY   Query to check
*      <--FW_NOAUTH  Unallowed table or command entered
*      <--FW_COMMAND Command to execute (INSERT, DELETE, ...)
*      <--FW_TABLE   Target table of the query
*      <--FW_PARAM   Parameters for the command (WHERE, SET, ...)
*----------------------------------------------------------------------*
FORM query_parse_noselect  USING    fw_query TYPE string
                           CHANGING fw_noauth TYPE c
                                    fw_command TYPE string
                                    fw_table TYPE string
                                    fw_param TYPE string.
  DATA : lw_query TYPE string,
         lw_table TYPE tabname.

  CLEAR : fw_noauth,
          fw_table,
          fw_command,
          fw_param.

  lw_query = fw_query.
  SPLIT lw_query AT space INTO fw_command lw_query.
  TRANSLATE fw_command TO UPPER CASE.
  CASE fw_command.
    WHEN 'INSERT'.
      SPLIT lw_query AT space INTO fw_table fw_param.
      TRANSLATE fw_table TO UPPER CASE.
      CLEAR sy-subrc.
      IF s_customize-auth_object NE space.
        lw_table = fw_table.
        AUTHORITY-CHECK OBJECT s_customize-auth_object
                 ID 'TABLE' FIELD lw_table
                 ID 'ACTVT' FIELD s_customize-actvt_insert.
      ELSEIF s_customize-auth_insert NE '*'
      AND fw_table NP s_customize-auth_insert.
        sy-subrc = 4.
      ENDIF.
      IF sy-subrc NE 0.
        CONCATENATE 'No authorisation for table'(m13) fw_table
                    INTO lw_query SEPARATED BY space.
        MESSAGE lw_query TYPE c_msg_success DISPLAY LIKE c_msg_error.
        fw_noauth = abap_true.
        RETURN.
      ENDIF.

    WHEN 'UPDATE'.
      SPLIT lw_query AT space INTO fw_table fw_param.
      TRANSLATE fw_table TO UPPER CASE.
      CLEAR sy-subrc.
      IF s_customize-auth_object NE space.
        lw_table = fw_table.
        AUTHORITY-CHECK OBJECT s_customize-auth_object
                 ID 'TABLE' FIELD lw_table
                 ID 'ACTVT' FIELD s_customize-actvt_update.
      ELSEIF s_customize-auth_update NE '*'
      AND fw_table NP s_customize-auth_update.
        sy-subrc = 4.
      ENDIF.
      IF sy-subrc NE 0.
        CONCATENATE 'No authorisation for table'(m13) fw_table
                    INTO lw_query SEPARATED BY space.
        MESSAGE lw_query TYPE c_msg_success DISPLAY LIKE c_msg_error.
        fw_noauth = abap_true.
        RETURN.
      ENDIF.

    WHEN 'DELETE'.
      SPLIT lw_query AT space INTO fw_table fw_param.
      TRANSLATE fw_table TO UPPER CASE.
      IF fw_table = 'FROM'.
        SPLIT fw_param AT space INTO fw_table fw_param.
        TRANSLATE fw_table TO UPPER CASE.
      ENDIF.
      CLEAR sy-subrc.
      IF s_customize-auth_object NE space.
        lw_table = fw_table.
        AUTHORITY-CHECK OBJECT s_customize-auth_object
                 ID 'TABLE' FIELD lw_table
                 ID 'ACTVT' FIELD s_customize-actvt_delete.
      ELSEIF s_customize-auth_delete NE '*'
      AND NOT fw_table CP s_customize-auth_delete.
        sy-subrc = 4.
      ENDIF.
      IF sy-subrc NE 0.
        CONCATENATE 'No authorisation for table'(m13) fw_table
                    INTO lw_query SEPARATED BY space.
        MESSAGE lw_query TYPE c_msg_success DISPLAY LIKE c_msg_error.
        fw_noauth = abap_true.
        RETURN.
      ENDIF.

    WHEN c_native_command.
      IF s_customize-auth_object NE space.
        AUTHORITY-CHECK OBJECT s_customize-auth_object
                 ID 'ACTVT' FIELD s_customize-actvt_native.
      ELSEIF s_customize-auth_native NE abap_true.
        sy-subrc = 4.
      ENDIF.
      IF sy-subrc NE 0.
        CONCATENATE 'SQL command not allowed :'(m25) fw_command
                    INTO lw_query.
        MESSAGE lw_query TYPE c_msg_success DISPLAY LIKE c_msg_error.
        fw_noauth = abap_true.
        RETURN.
      ENDIF.
* For native command, replace ' by "
      TRANSLATE lw_query USING '''"'.
      fw_param = lw_query.

    WHEN OTHERS.
      CONCATENATE 'SQL command not allowed :'(m25) fw_command
                  INTO lw_query.
      MESSAGE lw_query TYPE c_msg_success DISPLAY LIKE c_msg_error.
      fw_noauth = abap_true.
      RETURN.
  ENDCASE.
ENDFORM.                    " QUERY_PARSE_NOSELECT

*&---------------------------------------------------------------------*
*&      Form  QUERY_GENERATE_NOSELECT
*&---------------------------------------------------------------------*
*       Create all other than SELECT SQL query in a new generated
*       temp program
*----------------------------------------------------------------------*
*      -->FW_COMMAND Query type
*      -->FW_TABLE   Target table of the query
*      -->FW_PARAM   Parameters of the query
*      -->FW_DISPLAY   Display code instead of generated routine
*      <--FW_PROGRAM Name of the generated program
*----------------------------------------------------------------------*
FORM query_generate_noselect  USING    fw_command TYPE string
                                       fw_table TYPE string
                                       fw_param TYPE string
                                       fw_display TYPE c
                              CHANGING fw_program TYPE sy-repid.

  DATA : lt_code_string      TYPE TABLE OF string,
         lw_mess(255),
         lw_line             TYPE i,
         lw_word(30),
         lw_strlen_string    TYPE string,
         lw_explicit         TYPE string,
         lw_length           TYPE i,
         lw_pos              TYPE i,
         lw_fieldnum         TYPE i,
         lw_fieldval         TYPE string,
         lw_fieldname        TYPE string,
         lw_wait_name(1)     TYPE c,
         lw_char(1)          TYPE c,
         lw_started(1)       TYPE c,
         lw_started_field(1) TYPE c.

  DEFINE c.
    lw_strlen_string = &1.
    perform add_line_to_table using lw_strlen_string
                              changing lt_code_string.
  END-OF-DEFINITION.

* Write Header
  c 'PROGRAM SUBPOOL.'.                                     "#EC NOTEXT
  c '** GENERATED PROGRAM * DO NOT CHANGE IT **'.           "#EC NOTEXT
  c 'type-pools: slis.'.                                    "#EC NOTEXT
  c 'DATA : w_timestart type timestampl,'.                  "#EC NOTEXT
  c '       w_timeend type timestampl.'.                    "#EC NOTEXT
  c ''.
  IF fw_command = 'INSERT'.
    c 'DATA s_insert type'.                                 "#EC NOTEXT
    c fw_table.
    c '.'.                                                  "#EC NOTEXT
    c 'FIELD-SYMBOLS <fs> TYPE ANY.'.                       "#EC NOTEXT
    c '.'.                                                  "#EC NOTEXT
  ENDIF.

* Write the dynamic subroutine that run the SELECT
  c 'FORM run_sql CHANGING fo_result TYPE REF TO data'.     "#EC NOTEXT
  c '                      fw_time TYPE p'.                 "#EC NOTEXT
  c '                      fw_count TYPE i.'.               "#EC NOTEXT
  c '***************************************'.              "#EC NOTEXT
  c '*            Begin of query           *'.              "#EC NOTEXT
  c '***************************************'.              "#EC NOTEXT
  c 'CLEAR fw_count.'.                                      "#EC NOTEXT
  c 'GET TIME STAMP FIELD w_timestart.'.                    "#EC NOTEXT

  CASE fw_command.
    WHEN 'UPDATE'.
      c fw_command.
      c fw_table.
      c fw_param.
      c '.'.
    WHEN 'DELETE'.
      c fw_command.
      c 'FROM'.                                             "#EC NOTEXT
      c fw_table.
      c fw_param.
      c '.'.
    WHEN 'INSERT'.

      IF fw_param(6) = 'VALUES'.
        lw_length = strlen( fw_param ).
        lw_pos = 6.
        lw_fieldnum = 0.
        WHILE lw_pos < lw_length.
          lw_char = fw_param+lw_pos(1).
          lw_pos = lw_pos + 1.
          IF lw_started = space.
            IF lw_char NE '('. "begin of the list
              CONTINUE.
            ENDIF.
            lw_started = abap_true.
            CONTINUE.
          ENDIF.
          IF lw_started_field = space.
            IF lw_char = ')'. "end of the list
              EXIT. "exit while
            ENDIF.

            IF lw_char NE ''''. "field value must start by '
              CONTINUE.
            ENDIF.
            lw_started_field = abap_true.
            lw_fieldval = lw_char.
            lw_fieldnum = lw_fieldnum + 1.
            CONTINUE.
          ENDIF.
          IF lw_char = space.
            CONCATENATE lw_fieldval lw_char INTO lw_fieldval
                        SEPARATED BY space.
          ELSE.
            CONCATENATE lw_fieldval lw_char INTO lw_fieldval.
          ENDIF.
          IF lw_char = ''''. "end of a field ?
            IF lw_pos < lw_length.
              lw_char = fw_param+lw_pos(1).
            ELSE.
              CLEAR lw_char.
            ENDIF.
            IF lw_char = ''''. "not end !
              CONCATENATE lw_fieldval lw_char INTO lw_fieldval.
              lw_pos = lw_pos + 1.
              CONTINUE.
            ELSE. "end of a field!
              c 'ASSIGN COMPONENT'.                         "#EC NOTEXT
              c lw_fieldnum.
              c 'OF STRUCTURE s_insert TO <fs>.'.           "#EC NOTEXT
              c '<fs> = '.                                  "#EC NOTEXT
              c lw_fieldval.
              c '.'.                                        "#EC NOTEXT
              lw_started_field = space.
            ENDIF.
          ENDIF.
        ENDWHILE.
      ELSEIF fw_param(3) = 'SET'.


        lw_length = strlen( fw_param ).
        lw_pos = 3.
        lw_fieldnum = 0.
        lw_wait_name = abap_true.
        WHILE lw_pos < lw_length.
          lw_char = fw_param+lw_pos(1).
          lw_pos = lw_pos + 1.
          IF lw_wait_name = abap_true.
            TRANSLATE lw_char TO UPPER CASE.
            IF lw_char = space OR NOT sy-abcde CS lw_char.
              CONTINUE. "not a begin of fieldname
            ENDIF.
            lw_wait_name = space.
            lw_started = abap_true.
            CONCATENATE 's_insert-' lw_char
                        INTO lw_fieldname.                  "#EC NOTEXT
            CONTINUE.
          ENDIF.

          IF lw_started = abap_true.
            IF lw_char = space.
              CONCATENATE lw_fieldname lw_char INTO lw_fieldname
                          SEPARATED BY space.
            ELSE.
              CONCATENATE lw_fieldname lw_char INTO lw_fieldname.
            ENDIF.
            IF lw_char = '='. "end of the field name
              lw_started = space.
            ENDIF.

            CONTINUE.
          ENDIF.

          IF lw_started_field NE abap_true.
            IF lw_char NE ''''. "field value must start by '
              CONTINUE.
            ENDIF.
            lw_started_field = abap_true.
            lw_fieldval = lw_char.
            CONTINUE.
          ENDIF.

          IF lw_char = space.
            CONCATENATE lw_fieldval lw_char INTO lw_fieldval
                        SEPARATED BY space.
          ELSE.
            CONCATENATE lw_fieldval lw_char INTO lw_fieldval.
          ENDIF.
          IF lw_char = ''''. "end of a field ?
            IF lw_pos < lw_length.
              lw_char = fw_param+lw_pos(1).
            ELSE.
              CLEAR lw_char.
            ENDIF.
            IF lw_char = ''''. "not end !
              CONCATENATE lw_fieldval lw_char INTO lw_fieldval.
              lw_pos = lw_pos + 1.
              CONTINUE.
            ELSE. "end of a field!
              c lw_fieldname.
              c lw_fieldval.
              c '.'.
              lw_started_field = space.
              lw_wait_name = abap_true.
            ENDIF.
          ENDIF.
        ENDWHILE.
      ELSE.
        MESSAGE 'Error in INSERT syntax : VALUES / SET required'(m26)
                TYPE c_msg_error.
      ENDIF. "if fw_param(6) = 'VALUES'.
      c fw_command.
      c 'INTO'.                                             "#EC NOTEXT
      c fw_table.
      c 'VALUES s_insert.'.                                 "#EC NOTEXT
  ENDCASE.

* Get query execution time & affected lines
  c 'IF sy-subrc = 0.'.                                     "#EC NOTEXT
  c '  fw_count = sy-dbcnt.'.                               "#EC NOTEXT
  c 'ENDIF.'.                                               "#EC NOTEXT
  c 'GET TIME STAMP FIELD w_timeend.'.                      "#EC NOTEXT
  c 'fw_time = w_timeend - w_timestart.'.                   "#EC NOTEXT
  c 'ENDFORM.'.                                             "#EC NOTEXT

  CLEAR : lw_line,
          lw_word,
          lw_mess.
  SYNTAX-CHECK FOR lt_code_string PROGRAM sy-repid
               MESSAGE lw_mess LINE lw_line WORD lw_word.
  IF sy-subrc NE 0 AND fw_display = space.
    MESSAGE lw_mess TYPE c_msg_error.
  ENDIF.

  IF fw_display = space.
    GENERATE SUBROUTINE POOL lt_code_string NAME fw_program.
  ELSE.
    IF lw_mess IS NOT INITIAL.
      lw_explicit = lw_line.
      CONCATENATE lw_mess '(line'(m28) lw_explicit ',word'(m29)
                  lw_word ')'(m30)
                  INTO lw_mess SEPARATED BY space.
      MESSAGE lw_mess TYPE c_msg_success DISPLAY LIKE c_msg_error.
    ENDIF.
    EDITOR-CALL FOR lt_code_string DISPLAY-MODE
                TITLE 'Generated code for current query'(t01).
  ENDIF.
ENDFORM.                    " QUERY_GENERATE_NOSELECT

*&---------------------------------------------------------------------*
*&      Form  DDIC_GET_FIELD_FROM_NODE
*&---------------------------------------------------------------------*
*       Get text for a DDIC node
*       Format of the text : tablename~fieldname
*----------------------------------------------------------------------*
*      -->FW_NODE_KEY   DDIC node key
*      -->FW_RELAT_KEY  DDIC parent node key
*      -->FW_TEXT       Text
*----------------------------------------------------------------------*
FORM ddic_get_field_from_node  USING    fw_node_key TYPE tv_nodekey
                                        fw_relat_key TYPE tv_nodekey
                               CHANGING fw_text TYPE string.
  DATA : ls_item        LIKE LINE OF s_tab_active-t_item_ddic,
         ls_item_parent LIKE LINE OF s_tab_active-t_item_ddic,
         lw_table       TYPE string,
         lw_alias       TYPE string.

* Get field name
  READ TABLE s_tab_active-t_item_ddic INTO ls_item
             WITH KEY node_key = fw_node_key
                      item_name = c_ddic_col1.

* Get table name
  READ TABLE s_tab_active-t_item_ddic INTO ls_item_parent
             WITH KEY node_key = fw_relat_key
                      item_name = c_ddic_col1.

* Search for alias
  SPLIT ls_item_parent-text AT ' AS ' INTO lw_table lw_alias.
  IF NOT lw_alias IS INITIAL.
    lw_table = lw_alias.
  ENDIF.

* Build tablename~fieldname
  CONCATENATE lw_table '~' ls_item-text INTO fw_text.
  CONCATENATE space fw_text space INTO fw_text RESPECTING BLANKS.

ENDFORM.                    " DDIC_GET_FIELD_FROM_NODE

*&---------------------------------------------------------------------*
*&      Form  EDITOR_PASTE
*&---------------------------------------------------------------------*
*       Paste given text to SQL editor at given position
*----------------------------------------------------------------------*
*      -->FW_TEXT Text to paste in editor
*      -->FW_LINE Line in editor to paste
*      -->FW_POS  Position in the line in editor
*----------------------------------------------------------------------*
FORM editor_paste  USING fw_text TYPE string
                         fw_line TYPE i
                         fw_pos TYPE i.
  DATA : lt_text    TYPE TABLE OF string,
         lw_pos     TYPE i,
         lw_line    TYPE i,
         lw_message TYPE string.

*   Set text with new line
  APPEND fw_text TO lt_text.
  IF s_customize-paste_break = abap_true.
    lw_pos = fw_pos - 1.
    CLEAR lw_message.
    DO lw_pos TIMES.
      CONCATENATE lw_message space INTO lw_message RESPECTING BLANKS.
    ENDDO.
    APPEND lw_message TO lt_text.
  ENDIF.

  CALL METHOD s_tab_active-o_textedit->insert_block_at_position
    EXPORTING
      line     = fw_line
      pos      = fw_pos
      text_tab = lt_text
    EXCEPTIONS
      OTHERS   = 0.

* Set cursor at end of pasted field
  IF s_customize-paste_break = abap_true.
    lw_pos = fw_pos.
    lw_line = fw_line + 1.
  ELSE.
    lw_pos = strlen( fw_text ).
    lw_pos = lw_pos + fw_pos.
    lw_line = fw_line.
  ENDIF.

  CALL METHOD s_tab_active-o_textedit->set_selection_pos_in_line
    EXPORTING
      line   = lw_line
      pos    = lw_pos
    EXCEPTIONS
      OTHERS = 0.

* Focus on editor
  CALL METHOD cl_gui_control=>set_focus
    EXPORTING
      control = s_tab_active-o_textedit
    EXCEPTIONS
      OTHERS  = 0.

  CONCATENATE fw_text 'pasted to SQL Editor'(m27)
              INTO lw_message SEPARATED BY space.
  MESSAGE lw_message TYPE c_msg_success.
ENDFORM.                    " EDITOR_PASTE

*&---------------------------------------------------------------------*
*&      Form  QUERY_PROCESS_NATIVE
*&---------------------------------------------------------------------*
*       Execute a given native sql command
*----------------------------------------------------------------------*
*      -->FW_COMMAND Native SQL Command to execute
*----------------------------------------------------------------------*
FORM query_process_native USING fw_command TYPE string.
  DATA : lw_lines        TYPE i,
         lw_sql_code     TYPE i,
         lw_sql_msg(255) TYPE c,
         lw_row_num      TYPE i,
         lw_command(255) TYPE c,
         lw_msg          TYPE string,
         lw_timestart    TYPE timestampl,
         lw_timeend      TYPE timestampl,
         lw_time         TYPE p LENGTH 8 DECIMALS 2,
         lw_charnumb(12) TYPE c,
         lw_answer(1)    TYPE c.

* Have a user confirmation before execute Native SQL Command
  CONCATENATE 'Are you sure you want to do a'(m31) fw_command
              '?'(m33)
              INTO lw_msg SEPARATED BY space.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Warning : critical operation'(t04)
      text_question         = lw_msg
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lw_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc NE 0 OR lw_answer NE '1'.
    RETURN.
  ENDIF.

  lw_command = fw_command.
  lw_lines = strlen( lw_command ).
  GET TIME STAMP FIELD lw_timestart.
  CALL 'C_DB_EXECUTE'
       ID 'STATLEN' FIELD lw_lines
       ID 'STATTXT' FIELD lw_command
       ID 'SQLERR'  FIELD lw_sql_code
       ID 'ERRTXT'  FIELD lw_sql_msg
       ID 'ROWNUM'  FIELD lw_row_num.
  IF sy-subrc NE 0.
    MESSAGE lw_sql_msg TYPE c_msg_success DISPLAY LIKE c_msg_error.
    RETURN.
  ELSE.
    GET TIME STAMP FIELD lw_timeend.
    lw_time = cl_abap_tstmp=>subtract(
                tstmp1 = lw_timeend
                tstmp2 = lw_timestart
              ).
    lw_charnumb = lw_time.
    CONCATENATE 'Query executed in'(m09) lw_charnumb 'seconds.'(m10)
                INTO lw_msg SEPARATED BY space.
    CONDENSE lw_msg.
    MESSAGE lw_msg TYPE c_msg_success.
  ENDIF.
ENDFORM.                    " QUERY_PROCESS_NATIVE

*&---------------------------------------------------------------------*
*&      Form  ddic_add_tree_zspro
*&---------------------------------------------------------------------*
*       Add nodes from table ZSPRO
*       You can delete this form if not use ZSPRO or dont have a table
*       hierarchy in ZSPRO
*----------------------------------------------------------------------*
FORM ddic_add_tree_zspro.
  DATA : lo_zspro   TYPE REF TO data,
         ls_node    LIKE LINE OF s_tab_active-t_node_ddic,
         ls_item    LIKE LINE OF s_tab_active-t_item_ddic,
         lw_nodekey TYPE tv_nodekey,
         BEGIN OF ls_ddic_fields,
           tabname   TYPE dd03l-tabname,
           fieldname TYPE dd03l-fieldname,
           position  TYPE dd03l-position,
           keyflag   TYPE dd03l-keyflag,
           ddtext1   TYPE dd03t-ddtext,
           ddtext2   TYPE dd04t-ddtext,
         END OF ls_ddic_fields,
         lt_ddic_fields     LIKE TABLE OF ls_ddic_fields,
         lw_node_number(11) TYPE n,
         lw_found(1)        TYPE c.
  CONSTANTS lc_zspro(30) TYPE c VALUE 'ZSPRO'.
  FIELD-SYMBOLS : <ft_zspro> TYPE standard table,
                  <fs_zspro> TYPE any,
                  <fw_zspro> TYPE any.
  REFRESH : t_node_zspro, t_item_zspro.

* Try to create zspro internal table
  TRY.
      CREATE DATA lo_zspro TYPE TABLE OF (lc_zspro).
    CATCH cx_sy_create_data_error.
* If ZSPRO does not exist, leave the subroutine
      RETURN.
  ENDTRY.
  ASSIGN lo_zspro->* TO <ft_zspro>.

* Get all data from ZSPRO (node or table entry)
  SELECT * FROM (lc_zspro)
           INTO TABLE <ft_zspro>
           WHERE nodetype = 0
           OR nodetype = 1
           OR nodetype = space
           ORDER BY relatkey sort.
* If ZSPRO does not contain any valuable data, leave the subroutine
  IF sy-subrc NE 0.
    RETURN.
  ENDIF.

* Get field list for each table
  LOOP AT <ft_zspro> ASSIGNING <fs_zspro>.
    ASSIGN COMPONENT 'NODETYPE' OF STRUCTURE <fs_zspro> TO <fw_zspro>.
    IF sy-subrc NE 0 OR <fw_zspro> NE 1.
      CONTINUE.
    ENDIF.
    ASSIGN COMPONENT 'NODEPARAM' OF STRUCTURE <fs_zspro> TO <fw_zspro>.
    IF sy-subrc = 0.
      ls_ddic_fields-tabname = <fw_zspro>.
      APPEND ls_ddic_fields TO lt_ddic_fields.
    ENDIF.
  ENDLOOP.
  IF NOT lt_ddic_fields IS INITIAL.
    SELECT dd03l~tabname dd03l~fieldname dd03l~position
           dd03l~keyflag dd03t~ddtext dd04t~ddtext
           INTO TABLE lt_ddic_fields
           FROM dd03l
           LEFT OUTER JOIN dd03t
           ON dd03l~tabname = dd03t~tabname
           AND dd03l~fieldname = dd03t~fieldname
           AND dd03l~as4local = dd03t~as4local
           AND dd03t~ddlanguage = sy-langu
           LEFT OUTER JOIN dd04t
           ON dd03l~rollname = dd04t~rollname
           AND dd03l~as4local = dd04t~as4local
           AND dd04t~ddlanguage = sy-langu
           FOR ALL ENTRIES IN lt_ddic_fields
           WHERE dd03l~tabname = lt_ddic_fields-tabname
           AND dd03l~as4local = c_vers_active
           AND dd03l~as4vers = space
           AND ( dd03l~comptype = c_ddic_dtelm
           OR    dd03l~comptype = space ).
    SORT lt_ddic_fields BY tabname keyflag DESCENDING position.
    DELETE ADJACENT DUPLICATES FROM lt_ddic_fields
           COMPARING tabname fieldname.
  ENDIF.

  CLEAR ls_node.
  ls_node-node_key = 'ZSPRO'.
  ls_node-isfolder = abap_true.
  ls_node-expander = abap_true.
  APPEND ls_node TO t_node_zspro.

  CLEAR ls_item.
  ls_item-node_key = 'ZSPRO'.
  ls_item-class = cl_gui_column_tree=>item_class_text.
  ls_item-item_name = c_ddic_col1.
  ls_item-text = 'ZSPRO'.
  APPEND ls_item TO t_item_zspro.

  ls_item-item_name = c_ddic_col2.
  ls_item-text = space.
  APPEND ls_item TO t_item_zspro.

  LOOP AT <ft_zspro> ASSIGNING <fs_zspro>.
    ASSIGN COMPONENT 'NODE_KEY' OF STRUCTURE <fs_zspro> TO <fw_zspro>.
    CONCATENATE 'Z' <fw_zspro>+1 INTO lw_nodekey.
    CLEAR ls_node.
    ls_node-node_key = lw_nodekey.

    ASSIGN COMPONENT 'RELATKEY' OF STRUCTURE <fs_zspro> TO <fw_zspro>.
    IF <fw_zspro> IS INITIAL.
      ls_node-relatkey = 'ZSPRO'.
    ELSE.
      CONCATENATE 'Z' <fw_zspro>+1 INTO ls_node-relatkey.
    ENDIF.
    ls_node-isfolder = abap_true.

    ASSIGN COMPONENT 'NODETYPE' OF STRUCTURE <fs_zspro> TO <fw_zspro>.
    IF <fw_zspro> = 1. "table entry
      ls_node-n_image = '@PO@'.
      ls_node-exp_image = '@PO@'.
    ENDIF.
    ls_node-expander = abap_true.
    APPEND ls_node TO t_node_zspro.

    CLEAR ls_item.
    ls_item-node_key = lw_nodekey.
    ls_item-class = cl_gui_column_tree=>item_class_text.
    ls_item-item_name = c_ddic_col1.
    IF <fw_zspro> = 1. "table entry
      ASSIGN COMPONENT 'NODEPARAM' OF STRUCTURE <fs_zspro> TO <fw_zspro>.
      ls_item-text = <fw_zspro>.
    ELSE.
      ASSIGN COMPONENT 'TEXT' OF STRUCTURE <fs_zspro> TO <fw_zspro>.
      ls_item-text = <fw_zspro>.
    ENDIF.
    APPEND ls_item TO t_item_zspro.

    ls_item-item_name = c_ddic_col2.
    ASSIGN COMPONENT 'NODETYPE' OF STRUCTURE <fs_zspro> TO <fw_zspro>.
    IF <fw_zspro> = 1. "table entry
      ASSIGN COMPONENT 'TEXT' OF STRUCTURE <fs_zspro> TO <fw_zspro>.
      ls_item-text = <fw_zspro>.
    ELSE.
      ls_item-text = space.
    ENDIF.
    APPEND ls_item TO t_item_zspro.

* For each table entry, add all fields
    ASSIGN COMPONENT 'NODETYPE' OF STRUCTURE <fs_zspro> TO <fw_zspro>.
    IF <fw_zspro> = 1.
      ASSIGN COMPONENT 'NODEPARAM' OF STRUCTURE <fs_zspro>
                                   TO <fw_zspro>.
      LOOP AT lt_ddic_fields INTO ls_ddic_fields
                             WHERE tabname = <fw_zspro>.
        CLEAR ls_node.
        lw_node_number = lw_node_number + 1.
        CONCATENATE 'F' lw_node_number INTO ls_node-node_key.
        ls_node-relatkey = lw_nodekey.
        ls_node-relatship = cl_gui_column_tree=>relat_last_child.
        IF ls_ddic_fields-keyflag = space.
          ls_node-n_image = '@3W@'.
          ls_node-exp_image = '@3W@'.
        ELSE.
          ls_node-n_image = '@3V@'.
          ls_node-exp_image = '@3V@'.
        ENDIF.
        ls_node-dragdropid = w_dragdrop_handle_tree.
        APPEND ls_node TO t_node_zspro.

        CLEAR ls_item.
        ls_item-node_key = ls_node-node_key.
        ls_item-class = cl_gui_column_tree=>item_class_text.
        ls_item-item_name = c_ddic_col1.
        ls_item-text = ls_ddic_fields-fieldname.
        APPEND ls_item TO t_item_zspro.
        ls_item-item_name = c_ddic_col2.
        IF NOT ls_ddic_fields-ddtext1 IS INITIAL.
          ls_item-text = ls_ddic_fields-ddtext1.
        ELSE.
          ls_item-text = ls_ddic_fields-ddtext2.
        ENDIF.
        APPEND ls_item TO t_item_zspro.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

* Clean Empty nodes
  DO.
    lw_found = space.
    LOOP AT t_node_zspro INTO ls_node WHERE isfolder = abap_true.
      READ TABLE t_node_zspro WITH KEY relatkey = ls_node-node_key
                 TRANSPORTING NO FIELDS.
      IF sy-subrc NE 0.
        lw_found = abap_true.
        DELETE t_node_zspro.
        DELETE t_item_zspro WHERE node_key = ls_node-node_key.
      ENDIF.
    ENDLOOP.
    IF lw_found = space.
      EXIT.
    ENDIF.
  ENDDO.
ENDFORM.                    "ddic_add_tree_zspro

*&---------------------------------------------------------------------*
*&      Form  REPO_DELETE_HISTORY
*&---------------------------------------------------------------------*
*       Delete given history entry
*----------------------------------------------------------------------*
*      -->FW_NODE_KEY Node key of history to delete
*      <--FW_SUBRC    Return code
*----------------------------------------------------------------------*
FORM repo_delete_history USING fw_node_key TYPE tv_nodekey
                         CHANGING fw_subrc TYPE i.
  DATA ls_histo LIKE s_node_repository.

  READ TABLE t_node_repository INTO ls_histo
             WITH KEY node_key = fw_node_key.
  IF sy-subrc = 0 AND ls_histo-edit NE space.
    DELETE FROM ztoad WHERE queryid = ls_histo-queryid.
    IF sy-subrc = 0.
      CALL METHOD o_tree_repository->delete_node
        EXPORTING
          node_key = fw_node_key.
    ENDIF.
  ENDIF.
  fw_subrc = sy-subrc.
ENDFORM.                    " REPO_DELETE_HISTORY

*&---------------------------------------------------------------------*
*&      Form  options_load
*&---------------------------------------------------------------------*
*       Get saved options from user parameters table
*----------------------------------------------------------------------*
FORM options_load.
  DATA : lw_options  TYPE usr05-parva,
         lw_rows(10) TYPE c.
  GET PARAMETER ID 'ZTOAD' FIELD lw_options.                "#EC EXISTS
  IF sy-subrc = 0.
    SPLIT lw_options AT ';' INTO lw_rows
                                 s_customize-paste_break
                                 s_customize-techname
                                 lw_options. "dummy
    s_customize-default_rows = lw_rows.
  ENDIF.
ENDFORM.                    " options_load

*&---------------------------------------------------------------------*
*&      Form  options_save
*&---------------------------------------------------------------------*
*       Save user options in standard user parameters table
*----------------------------------------------------------------------*
FORM options_save.
  DATA : lw_options  TYPE usr05-parva,
         lw_rows(10) TYPE c.

  lw_rows =   s_customize-default_rows.
  CONDENSE lw_rows NO-GAPS.
  CONCATENATE lw_rows
              s_customize-paste_break
              s_customize-techname
              INTO lw_options
              SEPARATED BY ';'.

  CALL FUNCTION 'SMAN_SET_USER_PARAMETER'
    EXPORTING
      parameter_id    = 'ZTOAD'
      parameter_value = lw_options
    EXCEPTIONS
      OTHERS          = 2.
  IF sy-subrc <> 0.
    MESSAGE e082(s1). "Error saving parameter changes
  ENDIF.

ENDFORM.                    "options_save

*&---------------------------------------------------------------------*
*&      Form  DDIC_REFRESH_TREE
*&---------------------------------------------------------------------*
*       Refresh DDIC tree with current query
*----------------------------------------------------------------------*
FORM ddic_refresh_tree.
  DATA : lw_query        TYPE string,
         lw_query2       TYPE string,
         lw_select       TYPE string,
         lw_from         TYPE string,
         lw_from2        TYPE string,
         lw_where        TYPE string,
         lw_union        TYPE string,
         lw_rows(6)      TYPE n,
         lw_noauth(1)    TYPE c,
         lw_newsyntax(1) TYPE c,
         lw_error(1)     TYPE c.

* Get only usefull code for current query
  PERFORM editor_get_query USING space CHANGING lw_query.

* Parse Query
  PERFORM query_parse USING lw_query
                      CHANGING lw_select lw_from lw_where
                               lw_union lw_rows lw_noauth
                               lw_newsyntax lw_error.

  IF lw_noauth NE space OR lw_error NE space.
    RETURN.
  ELSEIF lw_select IS INITIAL.
    PERFORM query_parse_noselect USING lw_query
                                 CHANGING lw_noauth lw_select
                                          lw_from lw_where.
    IF lw_noauth NE space OR lw_select = c_native_command.
      RETURN.
    ENDIF.
  ENDIF.
* Manage unioned queries
  WHILE NOT lw_union IS INITIAL.
* Parse Query
    lw_query2 = lw_union.
    PERFORM query_parse USING lw_query2
                        CHANGING lw_select lw_from2 lw_where
                                 lw_union lw_rows lw_noauth
                                 lw_newsyntax lw_error.
    IF NOT lw_from2 IS INITIAL.
      CONCATENATE lw_from 'JOIN' lw_from2
                  INTO lw_from SEPARATED BY space.
    ENDIF.
    IF lw_noauth NE space OR lw_error NE space.
      RETURN.
    ENDIF.
  ENDWHILE.

  PERFORM tab_update_title USING lw_query.

* Refresh ddic tree with list of table/fields of the actual query
  PERFORM ddic_set_tree USING lw_from.
ENDFORM.                    " DDIC_REFRESH_TREE

*&---------------------------------------------------------------------*
*&      Form  DDIC_FIND_IN_TREE
*&---------------------------------------------------------------------*
*       Display popup to search a table in DDIC tree
*----------------------------------------------------------------------*
FORM ddic_find_in_tree.
  DATA : ls_sval        TYPE sval,
         lt_sval        LIKE TABLE OF ls_sval,
         lw_returncode  TYPE c,
         lw_search      TYPE string,
         lt_search      LIKE TABLE OF lw_search,
         ls_item_ddic   LIKE LINE OF s_tab_active-t_item_ddic,
         lw_search_term TYPE string,
         lw_search_line TYPE i,
         lw_rest        TYPE i,
         lw_node_key    TYPE tv_nodekey,
         lt_nodekey     TYPE TABLE OF tv_nodekey.

* Build search table
  REFRESH lt_search.
  LOOP AT s_tab_active-t_item_ddic INTO ls_item_ddic.
    lw_search = ls_item_ddic-text.
    APPEND lw_search TO lt_search.
    APPEND ls_item_ddic-node_key TO lt_nodekey.
  ENDLOOP.

* Ask for selection search
  ls_sval-tabname = 'RSDXX'.
  ls_sval-fieldname = 'FINDSTR'.
  ls_sval-value = space.
  APPEND ls_sval TO lt_sval.
  DO.
    CALL FUNCTION 'POPUP_GET_VALUES'
      EXPORTING
        popup_title     = space
      IMPORTING
        returncode      = lw_returncode
      TABLES
        fields          = lt_sval
      EXCEPTIONS
        error_in_fields = 1
        OTHERS          = 2.
    IF sy-subrc NE 0 OR lw_returncode NE space.
      EXIT. "exit do
    ENDIF.
    READ TABLE lt_sval INTO ls_sval INDEX 1.
    IF ls_sval-value = space.
      EXIT. "exit do
    ENDIF.

* For new search, start from line 1
    IF lw_search_term NE ls_sval-value.
      lw_search_term = ls_sval-value.
      lw_search_line = 1.
* For next result of same search, start from next line
    ELSE.
      lw_rest = lw_search_line MOD 2.
      lw_search_line = lw_search_line + 1 + lw_rest.
    ENDIF.

    FIND FIRST OCCURRENCE OF ls_sval-value IN TABLE lt_search
         FROM lw_search_line
         IN CHARACTER MODE IGNORING CASE
         MATCH LINE lw_search_line.

* Search string &1 not found
    IF sy-subrc NE 0 AND lw_search_line = 1.
      MESSAGE s065(0k) WITH lw_search_term DISPLAY LIKE c_msg_error.
      CLEAR lw_search_line.
      CLEAR lw_search_term.

* Last selected entry reached
    ELSEIF sy-subrc NE 0.
      MESSAGE s066(0k) DISPLAY LIKE c_msg_error.
      CLEAR lw_search_line.
      CLEAR lw_search_term.

* Found
    ELSE.
      MESSAGE 'String found'(m04) TYPE c_msg_success.
      READ TABLE lt_nodekey INTO lw_node_key INDEX lw_search_line.
      CALL METHOD s_tab_active-o_tree_ddic->set_selected_node
        EXPORTING
          node_key = lw_node_key.
      CALL METHOD s_tab_active-o_tree_ddic->ensure_visible
        EXPORTING
          node_key = lw_node_key.
    ENDIF.

  ENDDO.
ENDFORM.                    " DDIC_FIND_IN_TREE

*&---------------------------------------------------------------------*
*&      Form  OPTIONS_INIT
*&---------------------------------------------------------------------*
*       Create option panel
*----------------------------------------------------------------------*
FORM options_init.
  DATA : lt_ptab TYPE wdy_wb_property_tab,
         ls_ptab TYPE wdy_wb_property.

* Create a custom container linked to the custom controm on screen 300
  CREATE OBJECT o_container_options
    EXPORTING
      container_name              = 'CUSTCONT2'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

* Create the property object and link it to the custom controm
  CREATE OBJECT o_options
    EXPORTING
      parent                    = o_container_options
    EXCEPTIONS
      cntl_error                = 1
      cntl_system_error         = 2
      illegal_event_combination = 3
      OTHERS                    = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

* Define Column title of the property object
  CALL METHOD o_options->initialize
    EXPORTING
      property_column_title = 'Property'(m44)
      value_column_title    = 'Value'(m45)
      focus_row             = 1
      scrollable            = abap_true.

  o_options->set_enabled( abap_true ).

* paste_break
  ls_ptab-name = 'PB'.
  ls_ptab-type = cl_wdy_wb_property_box=>property_type_boolean.
  ls_ptab-enabled = abap_true.
  ls_ptab-value = s_customize-paste_break.
  CONCATENATE '@74\Q'
    'Add break line after pasting ddic field into sql editor'(m46)
    '@' 'Line Break'(m47) INTO ls_ptab-display_name.
  APPEND ls_ptab TO lt_ptab.

* default up to xxx rows
  ls_ptab-name = 'MAXROWS'.
  ls_ptab-type = cl_wdy_wb_property_box=>property_type_integer.
  ls_ptab-enabled = abap_true.
  ls_ptab-value = s_customize-default_rows.
  CONCATENATE '@3W\Q'
    'Default max number of displayed lines for SELECT'(m48)
    '@' 'Max Rows'(m49) INTO ls_ptab-display_name.
  APPEND ls_ptab TO lt_ptab.

* default up to xxx rows
  ls_ptab-name = 'TECH'.
  ls_ptab-type = cl_wdy_wb_property_box=>property_type_boolean.
  ls_ptab-enabled = abap_true.
  ls_ptab-value = s_customize-techname.
  CONCATENATE '@AJ\Q'
    'Display technical name in query result display'(m52)
    '@' 'Technical name'(m53) INTO ls_ptab-display_name.
  APPEND ls_ptab TO lt_ptab.

* Fill properties/values
  CALL METHOD o_options->set_properties
    EXPORTING
      properties = lt_ptab
      refresh    = abap_true.
ENDFORM.                    " OPTIONS_INIT

*&---------------------------------------------------------------------*
*&      Form  OPTIONS_DISPLAY
*&---------------------------------------------------------------------*
*       Display options panel
*----------------------------------------------------------------------*
FORM options_display.
  DATA : lt_ptab TYPE wdy_wb_property_tab,
         ls_ptab TYPE wdy_wb_property.

* If not first display, refresh properties values
  IF NOT o_options IS INITIAL.
    lt_ptab = o_options->get_properties( ).
    LOOP AT lt_ptab INTO ls_ptab.
      CASE ls_ptab-name.
        WHEN 'PB'.
          ls_ptab-value = s_customize-paste_break.
        WHEN 'MAXROWS'.
          ls_ptab-value = s_customize-default_rows.
        WHEN 'TECH'.
          ls_ptab-value = s_customize-techname.
      ENDCASE.
      CALL METHOD o_options->update_property
        EXPORTING
          property = ls_ptab.
    ENDLOOP.
  ENDIF.

* Display properties panel
  CALL SCREEN 300 STARTING AT 60 10
                  ENDING AT 90 16.
  IF w_okcode NE 'OK'.
    RETURN.
  ENDIF.

* Update values if not well refreshed in o_options
  CALL METHOD o_options->dispatch
    EXPORTING
      cargo             = w_okcode
      eventid           = 18
      is_shellevent     = space
      is_systemdispatch = space
    EXCEPTIONS
      OTHERS            = 0.

* Update values in s_customize
  lt_ptab = o_options->get_properties( ).
  LOOP AT lt_ptab INTO ls_ptab.
    CASE ls_ptab-name.
      WHEN 'PB'.
        s_customize-paste_break = ls_ptab-value.
      WHEN 'MAXROWS'.
        s_customize-default_rows = ls_ptab-value.
      WHEN 'TECH'.
        s_customize-techname = ls_ptab-value.
    ENDCASE.
  ENDLOOP.

* Save values in user parameters
  PERFORM options_save.
ENDFORM.                    " OPTIONS_DISPLAY

*&---------------------------------------------------------------------*
*&      Form  RESULT_SAVE_FILE
*&---------------------------------------------------------------------*
*       Save results into local file
*       - 1 line of header is written with technical column name
*       - Fields are separated by TAB
*       - Blank at end of char fields are removed
*----------------------------------------------------------------------*
*      -->FO_RESULT    Reference to data to display
*      -->FT_FIELDS    Field list
*----------------------------------------------------------------------*
FORM result_save_file USING fo_result TYPE REF TO data
                            ft_fields TYPE ty_fieldlist_table.

  DATA : lw_filename TYPE string,
         lt_file_f4  TYPE filetable,
         ls_file_f4  LIKE LINE OF lt_file_f4,
         lw_rc       TYPE i,
         lw_filter   TYPE string,
         lw_title    TYPE string,
         BEGIN OF ls_field_out,
           name TYPE char30,
         END OF ls_field_out,
         lt_fields   LIKE TABLE OF ls_field_out,
         ls_field_in LIKE LINE OF ft_fields.

  FIELD-SYMBOLS: <lft_data> TYPE ANY TABLE.

  lw_filter = 'CSV File (*.csv)|*.csv'(m51).
  lw_title = 'Download results into file'(m63).
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title = lw_title
      file_filter  = lw_filter
    CHANGING
      file_table   = lt_file_f4
      rc           = lw_rc
    EXCEPTIONS
      OTHERS       = 0.
  READ TABLE lt_file_f4 INTO ls_file_f4 INDEX 1.
  IF sy-subrc = 0.
    lw_filename = ls_file_f4.
  ENDIF.
  IF lw_filename IS INITIAL.
    RETURN.
  ENDIF.

  ASSIGN fo_result->* TO <lft_data>.
  LOOP AT ft_fields INTO ls_field_in.
    APPEND ls_field_in-ref_field TO lt_fields.
  ENDLOOP.
  CALL METHOD cl_gui_frontend_services=>gui_download
    EXPORTING
      filename              = lw_filename
      write_field_separator = abap_true
      trunc_trailing_blanks = abap_true
      fieldnames            = lt_fields
    CHANGING
      data_tab              = <lft_data>
    EXCEPTIONS
      OTHERS                = 0.

ENDFORM.                    " RESULT_SAVE_FILE

*&---------------------------------------------------------------------*
*&      Form  DDIC_F4
*&---------------------------------------------------------------------*
*       Display F4 help on selected DDIC tree field
*       Paste selected value in SQL Editor
*----------------------------------------------------------------------*
FORM ddic_f4.
  DATA : lw_table      TYPE dfies-tabname,
         lw_field      TYPE dfies-fieldname,
         lt_val        TYPE TABLE OF ddshretval,
         ls_val        LIKE LINE OF lt_val,
         lw_nodekey    TYPE tv_nodekey,
         lw_item       TYPE tv_itmname,                     "#EC NEEDED
         ls_node       LIKE LINE OF s_tab_active-t_node_ddic,
         ls_item       LIKE LINE OF s_tab_active-t_item_ddic,
         lw_line_start TYPE i,
         lw_pos_start  TYPE i,
         lw_line_end   TYPE i,
         lw_pos_end    TYPE i,
         lw_val        TYPE string,
         lw_dummy      type c.                              "#EC NEEDED

* Get selection in ddic tree
  CALL METHOD s_tab_active-o_tree_ddic->get_selected_node "line selected
    IMPORTING
      node_key = lw_nodekey.
  IF lw_nodekey IS INITIAL.
    CALL METHOD s_tab_active-o_tree_ddic->get_selected_item "item selected
      IMPORTING
        node_key  = lw_nodekey
        item_name = lw_item.
  ENDIF.
  IF lw_nodekey IS INITIAL.
    RETURN.
  ENDIF.

* Check selection is a field
  READ TABLE s_tab_active-t_node_ddic INTO ls_node
             WITH KEY node_key = lw_nodekey.
  IF sy-subrc NE 0 OR ls_node-isfolder = abap_true.
    RETURN.
  ENDIF.

* Get field name
  READ TABLE s_tab_active-t_item_ddic INTO ls_item
             WITH KEY node_key = lw_nodekey
                      item_name = c_ddic_col1.
  lw_field = ls_item-text.

* Get table name
  READ TABLE s_tab_active-t_item_ddic INTO ls_item
             WITH KEY node_key = ls_node-relatkey
                      item_name = c_ddic_col1.
  SPLIT ls_item-text AT ' AS ' INTO lw_table lw_dummy.

* Display standard value-list
  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      fieldname  = lw_field
      tabname    = lw_table
    TABLES
      return_tab = lt_val
    EXCEPTIONS
      OTHERS     = 1.

  IF sy-subrc = 0.
    READ TABLE lt_val INTO ls_val INDEX 1.
    CONCATENATE '''' ls_val-fieldval '''' INTO lw_val.
    CONCATENATE space lw_val INTO lw_val RESPECTING BLANKS.

* Get current cursor position/selection in editor
    CALL METHOD s_tab_active-o_textedit->get_selection_pos
      IMPORTING
        from_line = lw_line_start
        from_pos  = lw_pos_start
        to_line   = lw_line_end
        to_pos    = lw_pos_end
      EXCEPTIONS
        OTHERS    = 4.
    IF sy-subrc NE 0.
      MESSAGE 'Cannot get cursor position'(m35) TYPE c_msg_error.
    ENDIF.

*   If text is selected/highlighted, delete it
    IF lw_line_start NE lw_line_end
    OR lw_pos_start NE lw_pos_end.
      CALL METHOD s_tab_active-o_textedit->delete_text
        EXPORTING
          from_line = lw_line_start
          from_pos  = lw_pos_start
          to_line   = lw_line_end
          to_pos    = lw_pos_end.
    ENDIF.

    PERFORM editor_paste USING lw_val lw_line_start lw_pos_start.
  ENDIF.

ENDFORM.                    " DDIC_F4

*&---------------------------------------------------------------------*
*&      Form  EDITOR_GET_DEFAULT_QUERY
*&---------------------------------------------------------------------*
*       Get default query
*----------------------------------------------------------------------*
*      <--FT_QUERY  Default query content
*----------------------------------------------------------------------*
FORM editor_get_default_query  CHANGING ft_query TYPE table.
  DATA lw_string TYPE string.

  APPEND '* Type here your query title' TO ft_query.        "#EC NOTEXT
  APPEND '' TO ft_query.
  APPEND 'SELECT *' TO ft_query.                            "#EC NOTEXT
  APPEND 'FROM <table_name>' TO ft_query.                   "#EC NOTEXT

  IF s_customize-default_rows NE 0.
    lw_string = s_customize-default_rows.
    CONDENSE lw_string NO-GAPS.
    CONCATENATE 'UP TO'
                lw_string
                'ROWS'
                INTO lw_string SEPARATED BY space.
    APPEND lw_string TO ft_query.                           "#EC NOTEXT
  ENDIF.

  APPEND 'WHERE <conditions>' TO ft_query.                  "#EC NOTEXT
  APPEND '.' TO ft_query.                                   "#EC NOTEXT

ENDFORM.                    " EDITOR_GET_DEFAULT_QUERY

*&---------------------------------------------------------------------*
*&      Form  TAB_NEW
*&---------------------------------------------------------------------*
*       Open a new tab
*----------------------------------------------------------------------*
FORM tab_new.
  DATA : l_numb TYPE i,
         l_tab TYPE string.

  DESCRIBE TABLE t_tabs LINES l_numb.
  IF l_numb GE 30.
    MESSAGE 'You cannot open more than 30 tabs'(m64)
            TYPE c_msg_success DISPLAY LIKE c_msg_error.
    RETURN.
  ENDIF.

  PERFORM leave_current_tab.

* Hide alv pane if displayed
  s_tab_active-row_height = 100.
  CALL METHOD o_splitter->set_row_height
    EXPORTING
      id     = 1
      height = s_tab_active-row_height.

* Start new tab
  l_tab = l_numb + 1.
  CONCATENATE 'TAB' l_tab INTO l_tab.
  CONDENSE l_tab NO-GAPS.
  w_tabstrip-activetab = l_tab.
*  w_tabstrip-%_SCROLLPOSITION = l_tab. "bugged

* Initialize new editor / ddic / alv
  PERFORM ddic_init.
  PERFORM editor_init.
  PERFORM result_init.

* Tab management
  APPEND s_tab_active TO t_tabs.

ENDFORM.                    " TAB_NEW

*&---------------------------------------------------------------------*
*&      Form  LEAVE_CURRENT_TAB
*&---------------------------------------------------------------------*
*       Hide editor / ddic / alv for current tab and save state
*----------------------------------------------------------------------*
FORM leave_current_tab.
* Hide current editor / ddic / alv
  CALL METHOD s_tab_active-o_textedit->set_visible
    EXPORTING
      visible = space.

  CALL METHOD s_tab_active-o_tree_ddic->set_visible
    EXPORTING
      visible = space.

  IF NOT s_tab_active-o_alv_result IS INITIAL.
    CALL METHOD s_tab_active-o_alv_result->set_visible
      EXPORTING
        visible = space.
  ENDIF.
* Save ALV split height
  CALL METHOD o_splitter->get_row_height
    EXPORTING
      id     = 1
    IMPORTING
      result = s_tab_active-row_height.
  CALL METHOD cl_gui_cfw=>flush.

  PERFORM tab_update_title USING space.

  MODIFY t_tabs FROM s_tab_active INDEX w_tabstrip-activetab+3.
  CLEAR s_tab_active.
ENDFORM.                    " LEAVE_CURRENT_TAB

*&---------------------------------------------------------------------*
*&      Form  TAB_UPDATE_TITLE
*&---------------------------------------------------------------------*
*       Update tab title regarding current query
*       - Display first line query if it is a comment
*       - Display query as title in other cases
*----------------------------------------------------------------------*
*      -->FW_QUERY Complete query
*----------------------------------------------------------------------*
FORM tab_update_title USING fw_query TYPE string.
  DATA : lw_name(30) TYPE c,
         lt_query TYPE soli_tab,
         ls_query LIKE LINE OF lt_query,
         lw_query TYPE string.
  FIELD-SYMBOLS <fs> TYPE any.
  IF w_tabstrip-activetab IS INITIAL.
    lw_name = 'S_TAB-TITLE1'.
  ELSE.
    CONCATENATE 'S_TAB-TITLE' w_tabstrip-activetab+3 INTO lw_name.
  ENDIF.
  ASSIGN (lw_name) TO <fs>.
  IF sy-subrc NE 0.
    RETURN.
  ENDIF.

* Basic read query to check if first line is a comment
  CALL METHOD s_tab_active-o_textedit->get_text
    IMPORTING
      table  = lt_query[]
    EXCEPTIONS
      OTHERS = 1.
  READ TABLE lt_query INTO ls_query INDEX 1.
  IF sy-subrc NE 0.
    <fs> = 'Empty tab'(m65).
    RETURN.
  ENDIF.
  IF ls_query(1) = '*'.
    <fs> = ls_query+1.
    RETURN.
  ENDIF.

* Query given, use it as title
  IF NOT fw_query IS INITIAL.
    <fs> = fw_query.
    RETURN.
  ENDIF.

* If no query given, try to read it
  PERFORM editor_get_query USING space CHANGING lw_query.
  <fs> = lw_query.

ENDFORM.                    " TAB_UPDATE_TITLE

*&---------------------------------------------------------------------*
*&      Form  Export_xml
*&---------------------------------------------------------------------*
*       Export Saved Queries in xml format
*----------------------------------------------------------------------*
FORM export_xml.
  DATA : BEGIN OF ls_xml,
           line(256) TYPE x,
         END OF ls_xml,
         lt_xml LIKE TABLE OF ls_xml,

         lw_filename TYPE string,
         lw_path TYPE string,
         lw_fullpath TYPE string.
  DATA : lo_xml TYPE REF TO if_ixml,
         lo_document TYPE REF TO if_ixml_document,
         lo_root TYPE REF TO if_ixml_element,
         lo_element TYPE REF TO if_ixml_element,
         lw_string TYPE string,
         lo_streamfactory TYPE REF TO if_ixml_stream_factory,
         lo_ostream TYPE REF TO if_ixml_ostream,
         lo_renderer TYPE REF TO if_ixml_renderer,
         lw_title TYPE string,
         lw_filter TYPE string,
         lw_name TYPE string,
         BEGIN OF ls_ztoad,
           queryid TYPE ztoad-queryid,
           visibility TYPE ztoad-visibility_group,
           text TYPE ztoad-text,
           query TYPE ztoad-query,
         END OF ls_ztoad,
         lt_ztoad LIKE TABLE OF ls_ztoad.

* Ask name of file to generate
  lw_title = 'Choose file to create'(m57).
  lw_filter = 'XML File (*.xml)|*.xml'(m58).
  CALL METHOD cl_gui_frontend_services=>file_save_dialog
    EXPORTING
      window_title = lw_title
      file_filter  = lw_filter
    CHANGING
      path         = lw_path
      filename     = lw_filename
      fullpath     = lw_fullpath
    EXCEPTIONS
      OTHERS       = 1.
  IF sy-subrc NE 0 OR lw_filename IS INITIAL OR lw_path IS INITIAL.
    MESSAGE 'Action cancelled'(m14) TYPE c_msg_success
            DISPLAY LIKE c_msg_error.
    RETURN.
  ENDIF.

  CONCATENATE sy-uname '#%' INTO lw_name.
  CONDENSE lw_name NO-GAPS.

* Get all saved query (but not history)
  SELECT queryid visibility text query
         INTO TABLE lt_ztoad
         FROM ztoad
         WHERE owner = sy-uname
         AND NOT queryid LIKE lw_name.

  lo_xml = cl_ixml=>create( ).
  lo_document = lo_xml->create_document( ).

  lo_root  = lo_document->create_simple_element( name = c_xmlnode_root
                                                 parent = lo_document ).
  LOOP AT lt_ztoad INTO ls_ztoad.
    lo_element  = lo_document->create_simple_element( name = c_xmlnode_file
                                                      parent = lo_root ).
    lw_string = ls_ztoad-visibility.
    lo_element->set_attribute( name = c_xmlattr_visibility value = lw_string ).

    lw_string = ls_ztoad-text.
    lo_element->set_attribute( name = c_xmlattr_text value = lw_string ).

    lw_string = ls_ztoad-query.
    lo_element->set_value( lw_string ).
  ENDLOOP.

  lo_streamfactory = lo_xml->create_stream_factory( ).

  lo_ostream  = lo_streamfactory->create_ostream_itable( lt_xml ).

  lo_renderer = lo_xml->create_renderer( ostream  = lo_ostream
                                         document = lo_document ).
  lo_ostream->set_pretty_print( abap_true ).
  lo_renderer->render( ).

  CALL METHOD cl_gui_frontend_services=>gui_download
    EXPORTING
      filename = lw_fullpath
      filetype = 'BIN'
    CHANGING
      data_tab = lt_xml.
ENDFORM.                    "Export_xml

*&---------------------------------------------------------------------*
*&      Form  Import_xml
*&---------------------------------------------------------------------*
*       Import Saved Queries from xml format
*----------------------------------------------------------------------*
FORM import_xml.
  DATA : lt_filetab TYPE filetable,
         ls_file    TYPE file_table,
         lw_filename TYPE string,
         lw_subrc    LIKE sy-subrc,
         lw_xmldata   TYPE xstring,
         lo_xml TYPE REF TO if_ixml,
         lo_document TYPE REF TO if_ixml_document,
         lo_streamfactory TYPE REF TO if_ixml_stream_factory,
         lo_stream TYPE REF TO if_ixml_istream,
         lo_parser TYPE REF TO if_ixml_parser.
  DATA : lo_iterator TYPE REF TO if_ixml_node_iterator,
         lo_node  TYPE REF TO if_ixml_node,
         lw_node_name TYPE string,
         lo_element TYPE REF TO if_ixml_element,
         lw_title TYPE string,
         lw_filter TYPE string,
         lw_guid TYPE guid_32,
         lw_group TYPE usr02-class,
         lw_string TYPE string,
         ls_ztoad TYPE ztoad,
         lt_ztoad LIKE TABLE OF ls_ztoad.

* Choose file to import
  lw_title = 'Choose file to import'(m59).
  lw_filter = 'XML File (*.xml)|*.xml'(m58).
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title   = lw_title
      file_filter    = lw_filter
      multiselection = space
    CHANGING
      file_table     = lt_filetab
      rc             = lw_subrc.

* Check user action (1 OPEN, 2 CANCEL)
  IF lw_subrc NE 1.
    MESSAGE 'Action cancelled'(m14) TYPE c_msg_success
            DISPLAY LIKE c_msg_error.
    RETURN.
  ENDIF.

* Read filetable
  READ TABLE lt_filetab INTO ls_file INDEX 1.
  lw_filename = ls_file-filename.

* Get xml flow from file
* Or alternatively (if method does not exist) use the method
* cl_gui_frontend_services=>gui_upload and then convert the
* x-tab to xstring
  TRY.
      lw_xmldata = cl_openxml_helper=>load_local_file( lw_filename ).
    CATCH cx_openxml_not_found.
      MESSAGE 'Error when opening the input XML file'(m60)
              TYPE c_msg_error.
      RETURN.
  ENDTRY.

  lo_xml = cl_ixml=>create( ).

  lo_document = lo_xml->create_document( ).
  lo_streamfactory = lo_xml->create_stream_factory( ).
  lo_stream = lo_streamfactory->create_istream_xstring( string = lw_xmldata ).

  lo_parser = lo_xml->create_parser( stream_factory = lo_streamfactory
                                     istream        = lo_stream
                                     document       = lo_document ).
*-- parse the stream
  IF lo_parser->parse( ) NE 0.
    IF lo_parser->num_errors( ) NE 0.
      MESSAGE 'Error when parsing the input XML file'(m61)
              TYPE c_msg_error.
      RETURN.
    ENDIF.
  ENDIF.

*-- we don't need the stream any more, so let's close it...
  CALL METHOD lo_stream->close( ).
  CLEAR lo_stream.

* Get usergroup
  SELECT SINGLE class INTO lw_group
         FROM usr02
         WHERE bname = sy-uname.

* Rebuild itab t_zspro
  lo_iterator = lo_document->create_iterator( ).
  lo_node = lo_iterator->get_next( ).
  WHILE NOT lo_node IS INITIAL.
    lw_node_name = lo_node->get_name( ).
    IF lw_node_name = c_xmlnode_file.
* Cast node to element
      lo_element ?= lo_node. "->query_interface( ixml_iid_element ).
      CLEAR ls_ztoad.
      ls_ztoad-visibility_group = lw_group.
      ls_ztoad-owner = sy-uname.
      CONCATENATE sy-datum sy-uzeit INTO lw_string.
      ls_ztoad-aedat = lw_string.

* Generate new GUID
      DO 100 TIMES.
* Old function to get an unique id
        CALL FUNCTION 'GUID_CREATE'
          IMPORTING
            ev_guid_32 = lw_guid.
* New function to get an unique id (do not work on older sap system)
*    TRY.
*        lw_guid = cl_system_uuid=>create_uuid_c32_static( ).
*      CATCH cx_uuid_error.
*        EXIT. "exit do
*    ENDTRY.

* Check that this uid is not already used
        SELECT SINGLE queryid INTO ls_ztoad-queryid
               FROM ztoad
               WHERE queryid = lw_guid.
        IF sy-subrc NE 0.
          READ TABLE lt_ztoad WITH KEY queryid = lw_guid TRANSPORTING NO FIELDS.
          IF sy-subrc NE 0.
            EXIT. "exit do
          ENDIF.
        ENDIF.
      ENDDO.
      ls_ztoad-queryid = lw_guid.
      lw_string = lo_element->get_attribute( name = c_xmlattr_visibility ).
      ls_ztoad-visibility = lw_string.
      lw_string = lo_element->get_attribute( name = c_xmlattr_text ).
      ls_ztoad-text = lw_string.
      lw_string = lo_element->get_value( ).
      ls_ztoad-query = lw_string.
      APPEND ls_ztoad TO lt_ztoad.
    ENDIF.
    lo_node = lo_iterator->get_next( ).
  ENDWHILE.

  INSERT ztoad FROM TABLE lt_ztoad.
  IF sy-subrc = 0.
    MESSAGE s031(r9). "Query saved
  ELSE.
    MESSAGE e220(iqapi). "Error when saving the query
  ENDIF.

* Refresh repository to display new saved query
  PERFORM repo_fill.

ENDFORM.                    "import_xml

*&---------------------------------------------------------------------*
*&      Form  SET_STATUS_010
*&---------------------------------------------------------------------*
*       Set PF-STATUS for main scren
*       Adjust list of visible tabs
*----------------------------------------------------------------------*
FORM SET_STATUS_010 .
  DATA : lw_numb TYPE i,
         lw_max TYPE i.

  AUTHORITY-CHECK OBJECT 'S_DEVELOP' ID 'ACTVT' FIELD '03'
                                     ID 'DEVCLASS' DUMMY
                                     ID 'OBJTYPE' DUMMY
                                     ID 'OBJNAME' DUMMY
                                     ID 'P_GROUP' DUMMY.
  IF sy-subrc = 0.
    SET PF-STATUS 'STATUS010'.
  ELSE.
* If you dont have S_DEVELOP access in display, you probably dont
* understand the code generated => do not display the button
    SET PF-STATUS 'STATUS010' EXCLUDING 'SHOWCODE'.
  ENDIF.
  SET TITLEBAR 'STATUS010'.

  DESCRIBE TABLE t_tabs LINES lw_max.

  LOOP AT SCREEN.
    IF screen-name(6) = 'S_TAB-'.
      lw_numb = screen-name+11.
      IF lw_numb > lw_max.
        screen-invisible = 1.
      ELSE.
        screen-invisible = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " SET_STATUS_010
