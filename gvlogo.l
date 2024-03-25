%{
#include <stdio.h>
#include <stdlib.h>
#include "gvlogo.tab.h"

extern void yyerror(const char* s);
%}

%%
\"[^"]*\"                          {yylval.s = yytext; return QSTRING;}
[A-Za-z]+[.]bmp                    {yylval.s = yytext; return STRING;}
[0-9]+([.][0-9]+)?                 {yylval.f = atof(yytext); return NUMBER;}
[a-z]+                             {yylval.c = yytext; return VAR;}
=                                  {return EQUAL;}
;                                  {return SEP;}
PENUP                              {return PENUP;}
PENDOWN                            {return PENDOWN;}
PRINT                              {return PRINT;}
SAVE                               {return SAVE;}
CHANGE_COLOR                       {return CHANGE_COLOR;}
CLEAR                              {return CLEAR;}
TURN                               {return TURN;}
MOVE                               {return MOVE;}
GOTO                               {return GOTO;}
WHERE                              {return WHERE;}
\+                                 {return PLUS;}
\-                                 {return SUB;}
\*                                 {return MULT;}
\/                                 {return DIV;}
[ \t\r\n]			                 {;}
.			{ yyerror("Lexing Syntax error.\n"); } 

%%
