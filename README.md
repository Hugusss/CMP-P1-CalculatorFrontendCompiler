# Práctica 1: Calculadora / Intérprete

## Descripción
Compilador frontend capaz de interpretar operaciones aritméticas, lógicas, manipulación de cadenas y uso de estructuras simples.

## Funcionalidades
- **Tipos de datos:** int, float, string, bool.
- **Estructuras:** Soporte básico para structs (ej: `p1.x`).
- **Control de flujo:** Operadores lógicos (and, or, not) y relacionales.
- **Librería estándar:**
  - Matemáticas: sin, cos, tan, PI, E.
  - Strings: LEN, SUBSTR.
- **Gestión de errores:** Léxicos, sintácticos y semánticos (variables no declaradas, tipos incompatibles).

## Compilación y Ejecución
El proyecto incluye un Makefile automatizado.

1. **Compilar:**
    ```bash
    cd src/
    make
    ```

    **(OPCIONAL: para limpiar archivos temporales o de testing)**

        make clean


2. **Ejecutar tests:**
    ```bash
    make test
    ```
    Esto procesará todos los archivos de pruebas ubicados dentro de `test/in` y generará los resultados en `test/out`.

3. **Ejecución manual:**
    ```bash
    ./calculadora ../test/in/{archivo_a_testear}.txt
    ```

#### Autor: HUGO MIRANDA SERRANO