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

value_info op_sum(value_info a, value_info b) {
    if (a.type == INTEGER && b.type == INTEGER) return create_int(a.value.ival + b.value.ival);
    if (a.type == INTEGER && b.type == FLOAT)   return create_float(a.value.ival + b.value.fval);
    if (a.type == FLOAT   && b.type == INTEGER) return create_float(a.value.fval + b.value.ival);
    if (a.type == FLOAT   && b.type == FLOAT)   return create_float(a.value.fval + b.value.fval);
    
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