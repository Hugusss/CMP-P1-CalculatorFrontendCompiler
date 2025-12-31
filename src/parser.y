%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "values.h"

extern int yylex();
extern int yylineno;
extern char *yytext;
void yyerror(const char *s);
%}

%union {
    /* Estructura para identificadores y strings */
    struct {
        char *lexema;
        int line;
    } ident;
    
    /* Tipos primitivos que vienen del scanner */
    int ival;
    float fval;
    
    /* Estructura completa para nodos no-terminales (expressiones) */
    value_info val_info;
}

/* Tokens simples */
%token ASSIGN PLUS MINUS MULT DIV MOD POW
%token AND OR NOT EQ NEQ GT GE LT LE
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON COMMA DOT
%token KW_INT KW_FLOAT KW_STRING KW_BOOL STRUCT

/* Tokens con valor */
%token <ival> LIT_INT LIT_BOOL
%token <fval> LIT_FLOAT
%token <ident> ID LIT_STRING

/* Tipos de los no-terminales */
%type <val_info> expressio term factor potencia unario
%type <ident> variable

%start programa

%%

programa : lista_sentencias ;

lista_sentencias : /* vacio */
                 | lista_sentencias sentencia
                 ;

sentencia : declaracion SEMICOLON
          | asignacion SEMICOLON
          | expressio SEMICOLON { 
                char *s = value_to_str($1);
                printf(">> Resultado: %s (%s)\n", s, type_to_str($1.type));
                free(s);
            }
          | error SEMICOLON { yyerrok; }
          ;

declaracion : tipo variable
            { 
                /* Caso: int a; */
                /* En la fase 3 aquí insertaremos en la tabla de símbolos */
                printf(">> Declaración: %s\n", $2.lexema);
            }
            | tipo variable ASSIGN expressio 
            {
                /* Caso: int a := 10; */
                char *v = value_to_str($4);
                printf(">> Declaración e inic.: %s := %s\n", $2.lexema, v);
                free(v);
            }
            | tipo variable COMMA variable
            {
                /* Caso simplificado: int a, b; */
                printf(">> Declaración múltiple: %s, %s\n", $2.lexema, $4.lexema);
            }
            ;

tipo : KW_INT | KW_FLOAT | KW_STRING | KW_BOOL ;

variable : ID ;

asignacion : variable ASSIGN expressio {
                char *v = value_to_str($3);
                printf(">> Asignación: %s := %s\n", $1.lexema, v);
                free(v);
             }
           ;

/* --- PRECEDENCIA MANUAL --- */

/* Nivel 1: Suma/Resta */
expressio : term
          | expressio PLUS term   { $$ = op_sum($1, $3); }
          | expressio MINUS term  { $$ = op_sub($1, $3); }
          ;

/* Nivel 2: Prod/Div */
term : potencia
     | term MULT potencia { $$ = op_mult($1, $3); }
     | term DIV potencia  { $$ = op_div($1, $3); }
     ;

/* Nivel 3: Potencia */
potencia : unario
         | unario POW potencia { $$ = op_pow($1, $3); }
         ;

/* Nivel 4: Unarios */
unario : factor
       | MINUS factor { $$ = op_unary_minus($2); }
       | PLUS factor  { $$ = $2; }
       ;

/* Nivel 5: Átomos */
factor : LPAREN expressio RPAREN { $$ = $2; }
       | LIT_INT      { $$ = create_int($1); }
       | LIT_FLOAT    { $$ = create_float($1); }
       | LIT_STRING   { $$ = create_string($1.lexema); }
       | LIT_BOOL     { $$ = create_bool($1); }
       | variable     { 
            /* Dummy lookup por ahora */
            $$ = create_int(0); 
       }
       ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error sintáctico en línea %d: %s\n", yylineno, s);
}