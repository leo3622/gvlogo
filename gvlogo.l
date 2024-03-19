%{
#include <stdio.h>
#include <stdlib.h>
#include "gvlogo.tab.h"

extern void yyerror(const char* s);
%}

%%
[A-Z]{1}[a-z]+                     { yylval.s = yytext; return STRING; } 
[0-9]+[.]{1}[0-9]+                 { yylval.f = atof(yytext); return NUMBER; }
[a-z]{1}			               { yylval.c = yytext[0]; return CHAR; }
;                                  {return SEP;}
PENUP                              {return PENUP;}
PENDOWN                            {return PENDOWN;}
PRINT                              {return PRINT;}
SAVE                               {return SAVE;}
COLOR                              {return CHANGE_COLOR;}
CLEAR                              {return CLEAR;}
TURN                               {return TURN;}
MOVE                               {return MOVE;}
GOTO                               {return GOTO;}
WHERE                              {return WHERE;}
\+                                 {return PLUS;}
\-                                 {return SUB;}
\*                                 {return MULT;}
=				                   {return EQUAL;}
\/                                 {return DIV;}
[ \t\r\n]			;
.			{ yyerror("Lexing Syntax error.\n"); } 

%%
