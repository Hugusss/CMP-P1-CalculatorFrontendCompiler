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
El proyecto incluye un Makefile automatizado. ¡Cualquier archivo que se quiera testear con las instrucciones del Makefile deberá estar en `test/in`, y debe tener un salto de línea al final del archivo!

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

## Comentarios
Esta propuesta trabaja según limitaciones obvias como no poder usar el mismo nombre para dos variables en el mismo input; también añadir que en la concatenación de strings, si se hace una suma númerica antes que la suma de concatenación, esta se hará como suma númerica y luego el resultado será concatenado con el string... Por otro lado, una funcionalidad conseguidad a destacar que no se especificaba en el enunciado es la capacidad de poder declarar una variable y hacerle una asignación en la misma línea
#### Autor: HUGO MIRANDA SERRANO