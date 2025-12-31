#ifndef VALUES_H
#define VALUES_H

#include <stdbool.h>

/* Definición de tipos de variables */
typedef enum {
    UNDEFINED = 0,
    INTEGER,
    FLOAT,
    STRING,
    BOOLEAN,
    ERROR_VAL /* Para controlar errores semánticos */
} varType;

/* Estructura para almacenar el valor y su tipo */
typedef struct {
    varType type;
    union {
        int ival;       /* Para INTEGER */
        float fval;     /* Para FLOAT */
        char *sval;     /* Para STRING */
        bool bval;      /* Para BOOLEAN */
    } value;
} value_info;

/* Prototipos de funciones */
char *type_to_str(varType type);
char *value_to_str(value_info v);

/* Constructores rápidos */
value_info create_int(int v);
value_info create_float(float v);
value_info create_string(char *v);
value_info create_bool(bool v);
value_info create_error(void);

/* Operaciones */
value_info op_sum(value_info a, value_info b);
value_info op_sub(value_info a, value_info b);
value_info op_mult(value_info a, value_info b);
value_info op_div(value_info a, value_info b);
value_info op_pow(value_info a, value_info b);
value_info op_unary_minus(value_info a);

#endif