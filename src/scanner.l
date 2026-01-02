%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "values.h"
#include "parser.tab.h"

void setup_id() {
    yylval.ident.lexema = strdup(yytext);
    yylval.ident.line = yylineno;
}
%}

%option yylineno
%option noyywrap
%option nounput
%option noinput

digit       [0-9]
enter       {digit}+
real        {digit}+\.{digit}*([eE][+-]?{digit}+)?|{digit}+[eE][+-]?{digit}+|\.{digit}+([eE][+-]?{digit}+)?
identif     [a-zA-Z]([a-zA-Z0-9_])*

%%

"//".* { /* comentario linea */ }
"#".* { /* comentario linea */ }
"/*"([^*]|(\*+[^*/]))*\*+\/ { /* comentario bloque */ }

"int"       { return KW_INT; }
"float"     { return KW_FLOAT; }
"string"    { return KW_STRING; }
"bool"      { return KW_BOOL; }
"struct"    { return STRUCT; }
"true"      { yylval.ival = 1; return LIT_BOOL; }
"false"     { yylval.ival = 0; return LIT_BOOL; }

":="        { return ASSIGN; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MULT; }
"/"         { return DIV; }
"%"         { return MOD; }
"**"        { return POW; }

"and"       { return AND; }
"or"        { return OR; }
"not"       { return NOT; }
">="        { return GE; }
"<="        { return LE; }
"<>"        { return NEQ; }
">"         { return GT; }
"<"         { return LT; }
"="         { return EQ; }

"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }
";"         { return SEMICOLON; }
","         { return COMMA; }
"."         { return DOT; }

"sin"       { return KW_SIN; }
"cos"       { return KW_COS; }
"tan"       { return KW_TAN; }
"LEN"       { return KW_LEN; }
"len"       { return KW_LEN; }
"SUBSTR"    { return KW_SUBSTR; }
"substr"    { return KW_SUBSTR; }

{enter}     { yylval.ival = atoi(yytext); return LIT_INT; }
{real}      { yylval.fval = atof(yytext); return LIT_FLOAT; }

\"[^\"\n]*\" { 
              /* saltar la primera comilla con yytext+1 */
              yylval.ident.lexema = strdup(yytext + 1);
              
              /* eliminar la ultima comilla poniendo un \0 al final */
              yylval.ident.lexema[yyleng - 2] = '\0';
              
              yylval.ident.line = yylineno;

              return LIT_STRING; 
            }

{identif}   { setup_id(); return ID; }

[ \t\r\n]+  { /* ignorar */ }

.           { printf("Lexical Error: %s\n", yytext); }

%%