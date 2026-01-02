%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "values.h"
#include "symtab.h"

extern int yylex();
extern int yylineno;
extern char *yytext;
void yyerror(const char *s);

/* Helper para guardar valores en la tabla */
void install_var(char *name, varType type) {
    value_info *v;
    /* 1. Mirar si ya existe (Pasamos &v porque symtab quiere puntero a puntero) */
    if (sym_lookup(name, &v) == SYMTAB_OK) {
        fprintf(stderr, "Error semántico (Línea %d): Variable '%s' ya declarada.\n", yylineno, name);
        return;
    }
    
    /* 2. Reservar memoria para el valor */
    v = (value_info *)malloc(sizeof(value_info));
    if (!v) { fprintf(stderr, "Out of memory\n"); return; }

    /* 3. Inicializar según tipo */
    v->type = type;
    switch(type) {
        case INTEGER: v->value.ival = 0; break;
        case FLOAT:   v->value.fval = 0.0; break;
        case BOOLEAN: v->value.bval = false; break;
        case STRING:  v->value.sval = NULL; break;
        default: break;
    }

    /* 4. Insertar en tabla (Pasamos &v) */
    if (sym_enter(name, &v) != SYMTAB_OK) {
        fprintf(stderr, "Error interno: Fallo al insertar '%s' en tabla.\n", name);
    }
}
%}

%union {
    struct {
        char *lexema;
        int line;
    } ident;
    
    int ival;
    float fval;
    value_info val_info;
}

%token ASSIGN PLUS MINUS MULT DIV MOD POW
%token AND OR NOT EQ NEQ GT GE LT LE
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON COMMA DOT
%token KW_INT KW_FLOAT KW_STRING KW_BOOL STRUCT

%token <ival> LIT_INT LIT_BOOL
%token <fval> LIT_FLOAT
%token <ident> ID LIT_STRING

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
                printf(">> Val: %s\n", s);
                free(s);
            }
          | error SEMICOLON { yyerrok; }
          ;

declaracion : KW_INT variable { install_var($2.lexema, INTEGER); }
            | KW_FLOAT variable { install_var($2.lexema, FLOAT); }
            | KW_STRING variable { install_var($2.lexema, STRING); }
            | KW_BOOL variable { install_var($2.lexema, BOOLEAN); }
            
            /* Declaración con inicialización */
            | KW_INT variable ASSIGN expressio { 
                install_var($2.lexema, INTEGER); 
                value_info *v;
                if (sym_lookup($2.lexema, &v) == SYMTAB_OK) {
                     if ($4.type == INTEGER) v->value.ival = $4.value.ival;
                     else if ($4.type == FLOAT) v->value.ival = (int)$4.value.fval;
                     printf(">> %s inicializada a %d\n", $2.lexema, v->value.ival);
                }
            }
            | KW_FLOAT variable ASSIGN expressio {
                install_var($2.lexema, FLOAT);
                value_info *v;
                if (sym_lookup($2.lexema, &v) == SYMTAB_OK) {
                     if ($4.type == FLOAT) v->value.fval = $4.value.fval;
                     else if ($4.type == INTEGER) v->value.fval = (float)$4.value.ival;
                     printf(">> %s inicializada a %.5f\n", $2.lexema, v->value.fval);
                }
            }
            | KW_STRING variable ASSIGN expressio {
                install_var($2.lexema, STRING);
                value_info *v;
                if (sym_lookup($2.lexema, &v) == SYMTAB_OK) {
                     if ($4.type == STRING && $4.value.sval) {
                        v->value.sval = strdup($4.value.sval);
                        printf(">> %s inicializada a \"%s\"\n", $2.lexema, v->value.sval);
                     }
                }
            }
            /* ... Añadir bool si quieres ... */
            ;

variable : ID ;

asignacion : variable ASSIGN expressio {
                value_info *dest;
                /* Pasamos &dest porque sym_lookup quiere value_info ** */
                if (sym_lookup($1.lexema, &dest) != SYMTAB_OK) {
                    fprintf(stderr, "Error semántico (Línea %d): Variable '%s' no declarada.\n", $1.line, $1.lexema);
                } else {
                    /* Chequeo de Tipos Básico */
                    if (dest->type == INTEGER) {
                        if ($3.type == INTEGER) dest->value.ival = $3.value.ival;
                        else if ($3.type == FLOAT) dest->value.ival = (int)$3.value.fval; 
                    } 
                    else if (dest->type == FLOAT) {
                        if ($3.type == FLOAT) dest->value.fval = $3.value.fval;
                        else if ($3.type == INTEGER) dest->value.fval = (float)$3.value.ival;
                    }
                    else if (dest->type == STRING) {
                         if ($3.type == STRING) {
                             if (dest->value.sval) free(dest->value.sval); 
                             dest->value.sval = strdup($3.value.sval);
                         }
                    }
                    
                    /* Feedback visual */
                    if (dest->type != ERROR_VAL) {
                        char *valStr = value_to_str(*dest);
                        printf(">> %s := %s\n", $1.lexema, valStr);
                        free(valStr);
                    }
                }
             }
           ;

/* --- PRECEDENCIA --- */

expressio : term
          | expressio PLUS term   { $$ = op_sum($1, $3); }
          | expressio MINUS term  { $$ = op_sub($1, $3); }
          ;

term : potencia
     | term MULT potencia { $$ = op_mult($1, $3); }
     | term DIV potencia  { $$ = op_div($1, $3); }
     ;

potencia : unario
         | unario POW potencia { $$ = op_pow($1, $3); }
         ;

unario : factor
       | MINUS factor { $$ = op_unary_minus($2); }
       | PLUS factor  { $$ = $2; }
       ;

factor : LPAREN expressio RPAREN { $$ = $2; }
       | LIT_INT      { $$ = create_int($1); }
       | LIT_FLOAT    { $$ = create_float($1); }
       | LIT_STRING   { $$ = create_string($1.lexema); }
       | LIT_BOOL     { $$ = create_bool($1); }
       | variable     { 
            value_info *val_ptr;
            /* Pasamos &val_ptr */
            if (sym_lookup($1.lexema, &val_ptr) == SYMTAB_OK) {
                $$ = *val_ptr; 
                if (val_ptr->type == STRING && val_ptr->value.sval) {
                    $$.value.sval = strdup(val_ptr->value.sval);
                }
            } else {
                fprintf(stderr, "Error semántico (Línea %d): Variable '%s' no definida.\n", $1.line, $1.lexema);
                $$ = create_error();
            }
       }
       ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error sintáctico en línea %d: %s\n", yylineno, s);
}