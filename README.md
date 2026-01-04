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
    Esto procesará todos los archivos de pruebas ubicados dentro de `test/in` y generará los resultados en `test/out`. Ya se incluyen gran variedad de archivos que prueban distintas funcionalidades.

3. **Ejecución manual:**
    ```bash
    ./calculadora ../test/in/{archivo_a_testear}.txt
    ```


## Notas de Diseño y Limitaciones

### 1. Gestión de Memoria y Ámbito (Scope)

El compilador utiliza una **tabla de símbolos global única**. Esto implica una limitación de diseño consciente:

* **No se permite la redeclaración:** No es posible declarar dos variables con el mismo nombre en el mismo fichero, incluso si son de tipos distintos.
* **Persistencia:** Una vez declarada una variable, su nombre queda reservado en memoria durante toda la ejecución del programa.

### 2. Polimorfismo del Operador `+` (Concatenación)

El operador `+` ha sido sobrecargado para soportar tanto suma aritmética como concatenación de cadenas. El comportamiento depende de la **asociatividad por la izquierda** del análisis sintáctico:

* El compilador evalúa las expresiones de izquierda a derecha.
* **Comportamiento Mixto:**
    * `10 + 10 + " euros"`  Primero suma (`20`), luego concatena  Resultado: `"20 euros"`.
    * `"euros " + 10 + 10`  Primero concatena (`"euros 10"`), luego concatena de nuevo  Resultado: `"euros 1010"`.

* Esta decisión permite realizar cálculos matemáticos dentro de una línea de impresión sin necesidad de paréntesis explícitos al inicio.

### 3. Inicialización en Línea

Aunque el enunciado sugería separar la declaración (`int a`) de la asignación (`a := 10`), este compilador implementa **inicialización en declaración**.

* Permite construcciones como `int a := 10` o `string s := "Hola"`.
* Esto optimiza la escritura de código y reduce el número de accesos a la tabla de símbolos (se realiza la inserción y la asignación de valor en una sola regla gramatical).

### 4. Estructuras mediante "Aplanamiento de Nombres"

La gestión de `struct` se realiza mediante una técnica de *name flattening* en la tabla de símbolos.

* Al declarar `struct P { int x; } p1`, el compilador genera internamente la variable `"p1.x"`.
* Esto permite simular el acceso a campos complejos sin necesidad de implementar tablas de símbolos jerárquicas o anidadas.

---
#### Autor: HUGO MIRANDA SERRANO