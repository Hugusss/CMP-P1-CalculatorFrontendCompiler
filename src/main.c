#include <stdio.h>
#include <stdlib.h>

extern int yyparse();
extern FILE *yyin;

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

    printf("--- Iniciando Análisis ---\n");
    if (yyparse() == 0) {
        printf("--- Análisis Completado con Éxito ---\n");
    } else {
        printf("--- Errores durante el análisis ---\n");
    }

    fclose(yyin);
    return 0;
}