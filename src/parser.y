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

void install_var(char *name, varType type);

/* --- BLOQUE DE STRUCTS --- */
typedef struct {
    char *name;
    varType type;
} FieldInfo;

FieldInfo struct_fields[50];
int field_count = 0;

void add_field(char *name, varType type) {
    if (field_count < 50) {
        struct_fields[field_count].name = strdup(name);
        struct_fields[field_count].type = type;
        field_count++;
    }
}

void install_struct_instance(char *instance_name) {
    char buffer[256];
    for (int i = 0; i < field_count; i++) {
        sprintf(buffer, "%s.%s", instance_name, struct_fields[i].name);
        /* guardar copia persistente del nombre */
        install_var(strdup(buffer), struct_fields[i].type);
    }
}

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
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON COMMA DOT EOL
%token KW_INT KW_FLOAT KW_STRING KW_BOOL STRUCT
%token KW_SIN KW_COS KW_TAN KW_LEN KW_SUBSTR

%token <ival> LIT_INT LIT_BOOL
%token <fval> LIT_FLOAT
%token <ident> ID LIT_STRING

%type <val_info> expressio term_and term_not relacion arith_exp arith_term potencia unario factor
%type <ident> variable

%start programa

%%

programa : lista_sentencias ;

lista_sentencias : /* vacio */
                 | lista_sentencias sentencia
                 | lista_sentencias EOL 
                 ;

/* para terminar con EOL (\n) */
sentencia : declaracion EOL
          | asignacion EOL
          | expressio EOL { 
                char *s = value_to_str($1);
                printf(">> Val: %s\n", s);
                free(s);
            }
          | error EOL { yyerrok; }
          ;

/* Helper para aceptar saltos de linea dentro de structs */
opt_eol : /* vacio */
        | opt_eol EOL
        ;

declaracion : KW_INT variable { install_var($2.lexema, INTEGER); }
            | KW_FLOAT variable { install_var($2.lexema, FLOAT); }
            | KW_STRING variable { install_var($2.lexema, STRING); }
            | KW_BOOL variable { install_var($2.lexema, BOOLEAN); }
            
            | KW_INT variable ASSIGN expressio { 
                install_var($2.lexema, INTEGER); 
                value_info *v;
                if (sym_lookup($2.lexema, &v) == SYMTAB_OK) {
                     if ($4.type == INTEGER) v->value.ival = $4.value.ival;
                     else if ($4.type == FLOAT) v->value.ival = (int)$4.value.fval;
                }
            }
            | KW_FLOAT variable ASSIGN expressio {
                install_var($2.lexema, FLOAT);
                value_info *v;
                if (sym_lookup($2.lexema, &v) == SYMTAB_OK) {
                     if ($4.type == FLOAT) v->value.fval = $4.value.fval;
                     else if ($4.type == INTEGER) v->value.fval = (float)$4.value.ival;
                }
            }
            | KW_STRING variable ASSIGN expressio {
                install_var($2.lexema, STRING);
                value_info *v;
                if (sym_lookup($2.lexema, &v) == SYMTAB_OK) {
                     if ($4.type == STRING && $4.value.sval) {
                        v->value.sval = strdup($4.value.sval);
                     }
                }
            }
            | KW_BOOL variable ASSIGN expressio {
                install_var($2.lexema, BOOLEAN);
                value_info *v;
                if (sym_lookup($2.lexema, &v) == SYMTAB_OK) {
                     if ($4.type == BOOLEAN) {
                        v->value.bval = $4.value.bval;
                     }
                }
            }
            | KW_INT variable COMMA variable {
                install_var($2.lexema, INTEGER);
                install_var($4.lexema, INTEGER);
            }
            
            /* STRUCT: usa opt_eol para permitir formato libre */
            | STRUCT ID LBRACE opt_eol { field_count = 0; } lista_campos RBRACE lista_instancias
            ;

lista_campos : campo SEMICOLON opt_eol lista_campos
             | campo SEMICOLON opt_eol
             ;

campo : KW_INT ID    { add_field($2.lexema, INTEGER); }
      | KW_FLOAT ID  { add_field($2.lexema, FLOAT); }
      | KW_STRING ID { add_field($2.lexema, STRING); }
      | KW_BOOL ID   { add_field($2.lexema, BOOLEAN); }
      ;

lista_instancias : ID { install_struct_instance($1.lexema); }
                 | ID COMMA lista_instancias { install_struct_instance($1.lexema); }
                 ;

variable : ID 
         | ID DOT ID { 
             /* construir el nombre compuesto para buscarlo en la tabla */
             char buffer[256];
             sprintf(buffer, "%s.%s", $1.lexema, $3.lexema);
             $$.lexema = strdup(buffer);
             $$.line = yylineno;
         }
         ;

asignacion : variable ASSIGN expressio {
                value_info *dest;
                if (sym_lookup($1.lexema, &dest) != SYMTAB_OK) {
                    fprintf(stderr, "Error semántico (Línea %d): Variable '%s' no declarada.\n", $1.line, $1.lexema);
                } else {
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
                    else if (dest->type == BOOLEAN) {
                        if ($3.type == BOOLEAN) dest->value.bval = $3.value.bval;
                    }
                    
                    if (dest->type != ERROR_VAL) {
                        char *valStr = value_to_str(*dest);
                        printf(">> %s := %s\n", $1.lexema, valStr);
                        free(valStr);
                    }
                }
             }
           ;

/* --- PRECEDENCIA --- */

/* Nivel 1: Lógico OR (Menor precedencia) */
expressio : term_and
          | expressio OR term_and { $$ = op_or($1, $3); }
          ;

/* Nivel 2: Lógico AND */
term_and : term_not
         | term_and AND term_not { $$ = op_and($1, $3); }
         ;

/* Nivel 3: Lógico NOT (Unario) */
term_not : relacion
         | NOT term_not { $$ = op_not($2); }
         ;

/* Nivel 4: Relacionales (Comparaciones) */
relacion : arith_exp
         | arith_exp EQ arith_exp  { $$ = op_eq($1, $3); }
         | arith_exp NEQ arith_exp { $$ = op_neq($1, $3); }
         | arith_exp GT arith_exp  { $$ = op_gt($1, $3); }
         | arith_exp GE arith_exp  { $$ = op_ge($1, $3); }
         | arith_exp LT arith_exp  { $$ = op_lt($1, $3); }
         | arith_exp LE arith_exp  { $$ = op_le($1, $3); }
         ;

/* Nivel 5: Aritmética Suma/Resta */
arith_exp : arith_term
          | arith_exp PLUS arith_term   { $$ = op_sum($1, $3); }
          | arith_exp MINUS arith_term  { $$ = op_sub($1, $3); }
          ;

/* Nivel 6: Aritmética Mult/Div */
arith_term : potencia
           | arith_term MULT potencia { $$ = op_mult($1, $3); }
           | arith_term DIV potencia  { $$ = op_div($1, $3); }
           ;

/* Nivel 7: Potencia */
potencia : unario
         | unario POW potencia { $$ = op_pow($1, $3); }
         ;

/* Nivel 8: Unarios Aritméticos */
unario : factor
       | MINUS factor { $$ = op_unary_minus($2); }
       | PLUS factor  { $$ = $2; }
       ;

/* Nivel 9: Átomos */
factor : LPAREN expressio RPAREN { $$ = $2; }
       | LIT_INT      { $$ = create_int($1); }
       | LIT_FLOAT    { $$ = create_float($1); }
       | LIT_STRING   { $$ = create_string($1.lexema); }
       | LIT_BOOL     { $$ = create_bool($1); }
       | KW_SIN LPAREN expressio RPAREN { $$ = fn_sin($3); }
       | KW_COS LPAREN expressio RPAREN { $$ = fn_cos($3); }
       | KW_TAN LPAREN expressio RPAREN { $$ = fn_tan($3); }
       | KW_LEN LPAREN expressio RPAREN { $$ = fn_len($3); }
       | KW_SUBSTR LPAREN expressio COMMA expressio COMMA expressio RPAREN { 
            $$ = fn_substr($3, $5, $7); 
         }
       | variable     { 
            value_info *val_ptr;
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