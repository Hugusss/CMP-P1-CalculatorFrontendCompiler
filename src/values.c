#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "values.h"

char *type_to_str(varType type) {
    switch(type) {
        case INTEGER: return strdup("Integer");
        case FLOAT:   return strdup("Float");
        case STRING:  return strdup("String");
        case BOOLEAN: return strdup("Boolean");
        case ERROR_VAL: return strdup("Error");
        default:      return strdup("Undefined");
    }
}

char *value_to_str(value_info v) {
    char buffer[256];
    switch(v.type) {
        case INTEGER: snprintf(buffer, 256, "%d", v.value.ival); break;
        case FLOAT:   snprintf(buffer, 256, "%.5f", v.value.fval); break;
        case STRING:  snprintf(buffer, 256, "\"%s\"", v.value.sval ? v.value.sval : ""); break;
        case BOOLEAN: snprintf(buffer, 256, "%s", v.value.bval ? "true" : "false"); break;
        default:      snprintf(buffer, 256, "Error/Undef"); break;
    }
    return strdup(buffer);
}

/* Constructores */
value_info create_int(int v) {
    value_info out; out.type = INTEGER; out.value.ival = v; return out;
}
value_info create_float(float v) {
    value_info out; out.type = FLOAT; out.value.fval = v; return out;
}
value_info create_string(char *v) {
    value_info out; out.type = STRING; out.value.sval = strdup(v); return out;
}
value_info create_bool(bool v) {
    value_info out; out.type = BOOLEAN; out.value.bval = v; return out;
}
value_info create_error() {
    value_info out; out.type = ERROR_VAL; return out;
}

/* --- OPERACIONES --- */

/* Helper interno: Convierte cualquier valor a un string nuevo (malloc) */
char* val_to_str_alloc(value_info v) {
    char buffer[256]; /* buffer temporal */
    
    switch(v.type) {
        case INTEGER: 
            sprintf(buffer, "%d", v.value.ival); 
            break;
        case FLOAT:   
            sprintf(buffer, "%.5f", v.value.fval);
            break;
        case STRING:  
            // si ya es string, hacer copia para poder liberarla igual que los otros
            return v.value.sval ? strdup(v.value.sval) : strdup("");
        case BOOLEAN: 
            sprintf(buffer, "%s", v.value.bval ? "true" : "false"); 
            break;
        default:      
            sprintf(buffer, "undef"); 
            break;
    }
    return strdup(buffer);
}

value_info op_sum(value_info a, value_info b) {
    /* CASO 1: Ambos son números -> Suma Aritmética */
    if (a.type == INTEGER && b.type == INTEGER) return create_int(a.value.ival + b.value.ival);
    if (a.type == INTEGER && b.type == FLOAT)   return create_float(a.value.ival + b.value.fval);
    if (a.type == FLOAT   && b.type == INTEGER) return create_float(a.value.fval + b.value.ival);
    if (a.type == FLOAT   && b.type == FLOAT)   return create_float(a.value.fval + b.value.fval);
    
    /* CASO 2: Concatenación (Si al menos uno es STRING) */
    if (a.type == STRING || b.type == STRING) {
        char *s1 = val_to_str_alloc(a);
        char *s2 = val_to_str_alloc(b);
        
        /* Reservar memoria para la unión + null terminator */
        char *res = (char*)malloc(strlen(s1) + strlen(s2) + 1);
        
        strcpy(res, s1);
        strcat(res, s2);
        
        /* vaciar strings temporales */
        free(s1);
        free(s2);
           
        value_info v;
        v.type = STRING;
        v.value.sval = res; // asignar directo el puntero
        return v;
    }

    printf("Error: Tipos incompatibles en suma (y no son strings).\n");
    return create_error();
}

value_info op_sub(value_info a, value_info b) {
    if (a.type == INTEGER && b.type == INTEGER) return create_int(a.value.ival - b.value.ival);
    /* Lógica mixta */
    float v1 = (a.type == INTEGER) ? (float)a.value.ival : (a.type == FLOAT ? a.value.fval : 0);
    float v2 = (b.type == INTEGER) ? (float)b.value.ival : (b.type == FLOAT ? b.value.fval : 0);
    
    if ((a.type == INTEGER || a.type == FLOAT) && (b.type == INTEGER || b.type == FLOAT))
        return create_float(v1 - v2);
        
    return create_error();
}

value_info op_mult(value_info a, value_info b) {
    if (a.type == INTEGER && b.type == INTEGER) return create_int(a.value.ival * b.value.ival);
    
    float v1 = (a.type == INTEGER) ? (float)a.value.ival : (a.type == FLOAT ? a.value.fval : 0);
    float v2 = (b.type == INTEGER) ? (float)b.value.ival : (b.type == FLOAT ? b.value.fval : 0);
    
    if ((a.type == INTEGER || a.type == FLOAT) && (b.type == INTEGER || b.type == FLOAT))
        return create_float(v1 * v2);

    return create_error();
}

value_info op_div(value_info a, value_info b) {
    float v1 = (a.type == INTEGER) ? (float)a.value.ival : (a.type == FLOAT ? a.value.fval : 0);
    float v2 = (b.type == INTEGER) ? (float)b.value.ival : (b.type == FLOAT ? b.value.fval : 0);

    if (v2 == 0) { printf("Error: Div by zero\n"); return create_error(); }
    return create_float(v1 / v2);
}

value_info op_pow(value_info a, value_info b) {
    float v1 = (a.type == INTEGER) ? (float)a.value.ival : (a.type == FLOAT ? a.value.fval : 0);
    float v2 = (b.type == INTEGER) ? (float)b.value.ival : (b.type == FLOAT ? b.value.fval : 0);
    return create_float(powf(v1, v2));
}

value_info op_unary_minus(value_info a) {
    if (a.type == INTEGER) return create_int(-a.value.ival);
    if (a.type == FLOAT)   return create_float(-a.value.fval);
    return create_error();
}


/* --- OPERADORES LÓGICOS --- */

value_info op_and(value_info a, value_info b) {
    if (a.type == BOOLEAN && b.type == BOOLEAN) 
        return create_bool(a.value.bval && b.value.bval);
    printf("Error: AND requiere operandos booleanos.\n");
    return create_error();
}

value_info op_or(value_info a, value_info b) {
    if (a.type == BOOLEAN && b.type == BOOLEAN) 
        return create_bool(a.value.bval || b.value.bval);
    printf("Error: OR requiere operandos booleanos.\n");
    return create_error();
}

value_info op_not(value_info a) {
    if (a.type == BOOLEAN) 
        return create_bool(!a.value.bval);
    printf("Error: NOT requiere operando booleano.\n");
    return create_error();
}

/* --- OPERADORES RELACIONALES --- */

/* Helper para obtener valor numérico float de int/float */
float get_val(value_info v) {
    if (v.type == INTEGER) return (float)v.value.ival;
    if (v.type == FLOAT) return v.value.fval;
    return 0.0;
}
bool is_num(value_info v) { return v.type == INTEGER || v.type == FLOAT; }

value_info op_eq(value_info a, value_info b) {
    if (is_num(a) && is_num(b)) return create_bool(get_val(a) == get_val(b));
    if (a.type == BOOLEAN && b.type == BOOLEAN) return create_bool(a.value.bval == b.value.bval);
    if (a.type == STRING && b.type == STRING) return create_bool(strcmp(a.value.sval, b.value.sval) == 0);
    return create_bool(false); /* Tipos distintos no son iguales */
}

value_info op_neq(value_info a, value_info b) {
    value_info res = op_eq(a, b);
    if (res.type == BOOLEAN) res.value.bval = !res.value.bval;
    return res;
}

value_info op_gt(value_info a, value_info b) {
    if (is_num(a) && is_num(b)) return create_bool(get_val(a) > get_val(b));
    return create_error();
}

value_info op_lt(value_info a, value_info b) {
    if (is_num(a) && is_num(b)) return create_bool(get_val(a) < get_val(b));
    return create_error();
}

value_info op_ge(value_info a, value_info b) {
    if (is_num(a) && is_num(b)) return create_bool(get_val(a) >= get_val(b));
    return create_error();
}

value_info op_le(value_info a, value_info b) {
    if (is_num(a) && is_num(b)) return create_bool(get_val(a) <= get_val(b));
    return create_error();
}

/* --- FUNCIONES PREDEFINIDAS --- */

/* Helper para obtener float */
float to_float_val(value_info v) {
    if (v.type == INTEGER) return (float)v.value.ival;
    if (v.type == FLOAT) return v.value.fval;
    return 0.0;
}

value_info fn_sin(value_info a) {
    if (!is_num(a)) return create_error();
    return create_float(sinf(to_float_val(a)));
}

value_info fn_cos(value_info a) {
    if (!is_num(a)) return create_error();
    return create_float(cosf(to_float_val(a)));
}

value_info fn_tan(value_info a) {
    if (!is_num(a)) return create_error();
    return create_float(tanf(to_float_val(a)));
}

value_info fn_len(value_info a) {
    if (a.type == STRING && a.value.sval) {
        return create_int(strlen(a.value.sval));
    }
    printf("Error: LEN espera un string.\n");
    return create_error();
}

value_info fn_substr(value_info s, value_info idx, value_info len) {
    if (s.type != STRING || idx.type != INTEGER || len.type != INTEGER) {
        printf("Error: Uso SUBSTR(string, int, int)\n");
        return create_error();
    }
    
    char *origen = s.value.sval;
    int inicio = idx.value.ival;
    int longitud = len.value.ival;
    int max_len = strlen(origen);

    if (inicio < 0 || inicio >= max_len) return create_string(""); /* Fuera de rango */
    
    /* Ajustar longitud si se pasa */
    if (inicio + longitud > max_len) longitud = max_len - inicio;
    if (longitud <= 0) return create_string("");

    char *res = (char*)malloc(longitud + 1);
    strncpy(res, origen + inicio, longitud);
    res[longitud] = '\0';
    
    /* crear el value_info manualmente para no hacer doble strdup con create_string */
    value_info v; 
    v.type = STRING; 
    v.value.sval = res;
    return v;
}