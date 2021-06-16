"      *--------------------------------------------------------------------*"
"      *      FIFTECH - Agosto 2020                                         *"
"      *--------------------------------------------------------------------*"
"      * Sistema  : Az7                                                     *"
"      * Modulo   : Interfaces                                              *"
"      * Programa : FFAR0040                                                *"
"      * Fecha    :    08/2020                                              *"
"      * Autor    : Jorge Carmona G                                         *"
"      *--------------------------------------------------------------------*"
"      * Objetivo                                                           *"
"      *                                                                    *"
"      *     Generar descarga de journal ATMs por rango de fechas y         *"
"      *     número de cajero. Deja resultado en IFS.    (CAMBIO)           *"
"      *                                                                    *"
"      *--------------------------------------------------------------------*"
"      * Mantenciones                                                       *"
"      *--------------------------------------------------------------------*"
"     H OPTION(*NODEBUGIO:*SRCSTMT)"
"      *--------------------------------------------------------------------*"
"      * Definición de prototipos                                           *"
"      *--------------------------------------------------------------------*"
"     * Definición de Parámetros de Entrada.                             *"
"     D PgmAct          PR                  extpgm('FFAR0040')"
"     D Pr_NomBib                     10A"
"     D Pr_FecDes                      8A"
"     D Pr_FecHas                      8A"
"     D Pr_NroCaj                      8A"
"     D Pr_NomUsr                     10A"
""
"     * Ejecutar comando                                                 *"
"     D Comando         PR                  extpgm('QCMDEXC')"
"     D Pr_Cmd                       200    options(*varsize)"
"     D Pr_CmdLen                     15P 5 const"
""
"     *------------------------------------------------------------------*"
"     * Definición de Interfaces de procedimientos y del pgm.            *"
"     *------------------------------------------------------------------*"
"     * Definición parámetros del pgm"
"     D PgmAct          PI"
"     D Pi_NomBib                     10A"
"     D Pi_FecDes                      8A"
"     D Pi_FecHas                      8A"
"     D Pi_NroCaj                      8A"
"     D Pi_NomUsr                     10A"
""
"     *------------------------------------------------------------------*"
"     * Definición estructuras de datos                                  *"
"     *------------------------------------------------------------------*"
"     *------------------------------------------------------------------*"
"     * Definición variable del programa                                 *"
"     *------------------------------------------------------------------*"
"     D W_NomTabJRN     S             25A   Inz"
"     D W_NomTabCTR     S             25A   Inz"
"     D W_TabJRN        S             25A   Inz"
"     D W_TabCTR        S             25A   Inz"
"     D W_SQL_Stm       S            400A   Inz"
"     D W_SQL_Label     S             50A   Inz"
"     D W_IFS_Nombre    S             70A   Inz"
"     D W_IFS_Carpeta   S             30A   Inz"
"     D W_Comando       S            250A   Inz"
"     D W_PosIniNom     S              3S 0 Inz"
"     *------------------------------------------------------------------*"
"     * Proceso principal                                                *"
"     *------------------------------------------------------------------*"
"      /free"
"          exsr CrearNomTabJRN;"
"          exsr CrearNomTabCTR;"
"          exsr EliminarTabJRN;"
"          exsr EliminarTabCTR;"
"          exsr GenerarTabJRN;"
"          exsr LabelTabJRN;"
"          exsr GenerarTabCTR;"
"          exsr LabelTabCTR;"
"          exsr CopiaraIFS;"
"          exsr CopiaraIFSCTR;"
"          exsr EliminarTabJRN;"
"          exsr EliminarTabCTR;"
""
"          *inlr = *on;"
"       //------------------------------------------------------------------"
"       // CrearNomTabJRN - crear nombre de la tabla Journal"
"       //------------------------------------------------------------------"
"       begsr CrearNomTabJRN;"
"          clear W_NomTabJRN;"
""
"          W_NomTabJRN = %trim(Pi_NomBib) + '.' + 'JATM' +"
"                        %subst(%char(%timestamp(*SYS)):21:6);"
"       endsr;"
""
"       //------------------------------------------------------------------"
"       // CrearNomTabCTR - crear nombre de la tabla de control del Journal"
"       //------------------------------------------------------------------"
"       begsr CrearNomTabCTR;"
"          clear W_NomTabCTR;"
""
"          W_NomTabCTR = %trim(Pi_NomBib) + '.' + 'JCTR' +"
"                        %subst(%char(%timestamp(*SYS)):21:6);"
""
"       endsr;"
""
"       //------------------------------------------------------------------"
"       // EliminarTabJRN - eliminar Journal"
"       //------------------------------------------------------------------"
"       begsr EliminarTabJRN;"
"          clear W_SQL_Stm;"
""
"          W_SQL_Stm =  'drop table ' + %trim(W_NomTabJRN);"
""
"          exec sql"
"            prepare JRN from :W_SQL_Stm;"
""
"          exec sql"
"            execute JRN;"
""
"       endsr;"
""
"       //------------------------------------------------------------------"
"       // EliminarTabCTR - eliminar tabla control Journal"
"       //------------------------------------------------------------------"
"       begsr EliminarTabCTR;"
"          clear W_SQL_Stm;"
""
"          W_SQL_Stm =  'drop table ' + %trim(W_NomTabCTR);"
""
"          exec sql"
"            prepare CTR from :W_SQL_Stm;"
""
"          exec sql"
"            execute CTR;"
""
"       endsr;"
""
"       //------------------------------------------------------------------"
"       // GenerarTabJRN - generar tabla Journal"
"       //------------------------------------------------------------------"
"       begsr GenerarTabJRN;"
"          clear W_SQL_Stm;"
""
"          W_SQL_Stm ="
"          'create table ' + %trim(W_NomTabJRN) + ' as ('                    +"
"          'select substr(EDCDAT, 34, 1000) as EDCDATA from ADEDC2 where '   +"
"          'EDCFEC between ' + Pi_FECDES + ' and ' + Pi_FECHAS + ' and '     +"
"          'EDCLNO = ' + '''' + %trim(Pi_NroCaj) + '''' +"
"          ' order by edclno, edcfec, edchor, edcedc, edcsec) with data';"
""
"          exec sql"
"            prepare JRN from :W_SQL_Stm;"
""
"          exec sql"
"            execute JRN;"
""
"       endsr;"
""
"       //------------------------------------------------------------------"
"       // LabelTabJRN - asignar descripción a la tabla Journal generada"
"       //------------------------------------------------------------------"
"       begsr LabelTabJRN;"
"          clear W_SQL_Stm;"
"          clear W_SQL_Label;"
""
"          W_SQL_Label = 'ATM - Journal ' + %char(%date()) + ' ' +"
"                         %char(%time()) + ' ' + %trim(Pi_NroCaj);"
""
"          W_SQL_Stm =  'label on table ' + %trim(W_NomTabJRN) + ' is ' +"
"                       '''' + %trim(W_SQL_Label) + '''';"
""
"          exec sql"
"            prepare JRN from :W_SQL_Stm;"
""
"          exec sql"
"            execute JRN;"
""
"       endsr;"
""
"       //------------------------------------------------------------------"
"       // GenerarTabCTR - generar tabla control Journal"
"       //------------------------------------------------------------------"
"       begsr GenerarTabCTR;"
"          clear W_SQL_Stm;"
""
"          W_SQL_Stm ="
"          'create table ' + %trim(W_NomTabCTR) + ' (CRTMSG char(100) not null' +"
"          ' with default)';"
""
"          exec sql"
"            prepare CTR from :W_SQL_Stm;"
""
"          exec sql"
"            execute CTR;"
""
"          clear W_SQL_Stm;"
""
"          W_SQL_Stm ="
"          'insert into  ' + %trim(W_NomTabCTR) + ' values '                 +"
"          '(' + '''' + %trim(W_Sql_Label) + '''' + ')';"
""
"          exec sql"
"            prepare CTR from :W_SQL_Stm;"
""
"          exec sql"
"            execute CTR;"
"       endsr;"
""
"       //------------------------------------------------------------------"
"       // LabelTabCTR - asignar descripción a la tabla control Journal"
"       //------------------------------------------------------------------"
"       begsr LabelTabCTR;"
"          clear W_SQL_Stm;"
"          clear W_SQL_Label;"
""
"          W_SQL_Label = 'ATM - Journal ' + %char(%date()) + ' ' +"
"                         %char(%time()) + ' ' + %trim(Pi_NroCaj);"
""
"          W_SQL_Stm =  'label on table ' + %trim(W_NomTabCTR) + ' is ' +"
"                       '''' + %trim(W_SQL_Label) + '''';"
""
"          exec sql"
"            prepare JRN from :W_SQL_Stm;"
""
"          exec sql"
"            execute JRN;"
""
"       endsr;"
"       //------------------------------------------------------------------"
"       // CopiaraIFS - copiar archivo hacia IFS"
"       //------------------------------------------------------------------"
"       begsr CopiaraIFS;"
"          clear W_IFS_Nombre;"
"          clear W_Comando;"
""
"          W_PosIniNom = %scan('JATM':w_NomTabJRN);"
"          W_TabJRN    = %subst(w_NomTabJRN:W_PosIniNom:%size(w_NomTabJRN) -"
"                        W_PosIniNom);"
""
"          W_IFS_Carpeta = '/home/ATMJournal/' + %trim(Pi_NomUsr);"
""
"          W_IFS_Nombre = 'JATM_'                         +"
"                         %subst(W_SQL_Label:15:10) + '_' +"
"                         %trim(Pi_NomUsr)          + '_' +"
"                         %trim(Pi_NroCaj)                +"
"                         '_'                             +"
"                         Pi_FecDes                       +"
"                         '_'                             +"
"                         Pi_Fechas                       +"
"                         '.txt';"
""
"          W_Comando  = 'CPYTOIMPF FROMFILE(' + %trim(Pi_NomBib) + '/' +"
"                       %trim(W_TabJRN) + ')' + ' TOSTMF(' + ''''      +"
"                       %trim(W_IFS_Carpeta)  + '/' +"
"                       %trim(W_IFS_Nombre)   + '''' +"
"                       ') MBROPT(*REPLACE) FROMCCSID(1208)' +"
"                       ' STMFCCSID(*PCASCII) RCDDLM(*LF)';"
""
"          Comando(W_Comando:%len(W_Comando));"
"       endsr;"
""
"       //------------------------------------------------------------------"
"       // CopiaraIFSCTR - copiar archivo control hacia IFS"
"       //------------------------------------------------------------------"
"       begsr CopiaraIFSCTR;"
"          clear W_IFS_Nombre;"
"          clear W_Comando;"
""
"          W_PosIniNom = %scan('JCTR':w_NomTabCTR);"
"          W_TabCTR    = %subst(w_NomTabCTR:W_PosIniNom:10);"
""
""
"          W_IFS_Carpeta = '/home/ATMJournal/' + %trim(Pi_NomUsr);"
""
"          W_IFS_Nombre = 'JCTR_'                         +"
"                         %subst(W_SQL_Label:15:10) + '_' +"
"                         %trim(Pi_NomUsr)          + '_' +"
"                         %trim(Pi_NroCaj)                +"
"                         '_'                             +"
"                         Pi_FecDes                       +"
"                         '_'                             +"
"                         Pi_Fechas                       +"
"                         '.ctr';"
""
"          W_Comando  = 'CPYTOIMPF FROMFILE(' + %trim(Pi_NomBib) + '/' +"
"                       %trim(W_TabCTR) + ')' + ' TOSTMF(' + ''''      +"
"                       %trim(W_IFS_Carpeta)  + '/' +"
"                       %trim(W_IFS_Nombre)   + '''' +"
"                       ') STMFCCSID(*PCASCII) RCDDLM(*LF)';"
""
"          Comando(W_Comando:%len(W_Comando));"
"       endsr;"
""
"      /end-free"
