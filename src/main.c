#include <stdio.h>
#include <stdlib.h>
#include "values.h"
#include "symtab.h" //para sym_enter

extern int yyparse();
extern FILE *yyin;

/* Helper para inicializar constantes */
void install_const(char *name, float val) {
    value_info *v = (value_info*)malloc(sizeof(value_info));
    v->type = FLOAT;
    v->value.fval = val;
    sym_enter(name, &v); /* pasar &v igual que en parser.y */
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <fichero_entrada>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("Error al abrir el fichero");
        return 1;
    }

    /* --- INICIALIZAR CONSTANTES --- */
    install_const("PI", 3.141592);
    install_const("E",  2.718281);

    printf("--- Iniciando Análisis ---\n");
    if (yyparse() == 0) {
        printf("--- Análisis Completado ---\n");
    } else {
        printf("--- Errores durante el análisis ---\n");
    }

    fclose(yyin);
    return 0;
}