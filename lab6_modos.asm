; lab6_modos.asm -- Demostracion de modos de direccionamiento x86
; Compilar: nasm -f bin lab6_modos.asm -o lab6_modos.com
;
; Programa .COM (org 100h). Crea un array de 5 enteros de 16 bits y un registro de
; 3 campos, y los accede con modos de direccionamiento distintos. El objetivo no es
; el resultado del calculo sino que cada modo produzca una direccion efectiva (EA)
; verificable con DEBUG:
;   inmediato  : el operando va dentro de la instruccion
;   directo    : EA = desplazamiento fijo en la instruccion
;   indirecto  : EA = registro (BX, SI, DI o BP)
;   indexado   : EA = base + indice + desplazamiento

org 100h                        ; offset de inicio para archivos .COM

; --- Datos de prueba -----------------------------------------------------------
    jmp inicio                  ; saltar sobre los datos hacia el codigo

; Array de 5 enteros de 16 bits (2 bytes por elemento, little-endian)
array    dw 10, 20, 30, 40, 50

; Registro de estudiante: nota1 (16 bits) + nota2 (16 bits) + promedio (16 bits)
nota1    dw 85                  ; offset 0 del registro
nota2    dw 73                  ; offset 2
promedio dw 0                   ; offset 4

; Variable simple para el direccionamiento directo
var_x    dw 0FFFFh

; Tabla de bytes (digitos hexadecimales en ASCII)
tabla_hex db 30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h
          db 38h, 39h, 41h, 42h, 43h, 44h, 45h, 46h

; Matriz de 3 filas x 3 columnas de enteros de 16 bits (3 elementos por fila)
; Direccion del elemento [fila][columna] = matriz + fila * 6 + columna * 2
matriz   dw 1, 2, 3
         dw 4, 5, 6
         dw 7, 8, 9

; --- Codigo --------------------------------------------------------------------
inicio:

; === MODO 1: INMEDIATO ==========================================================
; El operando es una constante incluida en el codigo de la instruccion: no se
; accede a memoria de datos. En DEBUG, U muestra el valor dentro del opcode.
modo1_inmediato:
    mov ax, 100                 ; AX = 100 (inmediato decimal; opcode B8 6400)
    mov bx, 0A5h                ; BX = 0A5h (inmediato hexadecimal)
    add cx, 55                  ; CX += 55 (inmediato en una operacion aritmetica)
    and dx, 00FFh               ; DX AND mascara inmediata

; === MODO 2: DIRECTO ============================================================
; La direccion del operando esta fija en la instruccion (EA = 0100h + offset
; del simbolo, calculada al ensamblar). Los corchetes indican acceso a memoria.
modo2_directo:
    mov ax, [var_x]             ; AX = mem[var_x] = 0FFFFh
    mov bx, [array]             ; BX = mem[array] = 10 (primer elemento)
    mov cx, [nota1]             ; CX = mem[nota1] = 85

    ; Escritura directa en memoria
    mov word [var_x], 0         ; mem[var_x] = 0

; === MODO 3: INDIRECTO POR REGISTRO =============================================
; El registro contiene la direccion del operando; el puntero puede cambiar en
; tiempo de ejecucion. EA = SI.
modo3_indirecto:
    mov si, nota1               ; SI = direccion de nota1 (no su valor)
    mov ax, [si]                ; AX = mem[SI] = 85

    mov si, nota2               ; SI = direccion de nota2
    mov bx, [si]                ; BX = mem[SI] = 73

    ; Promedio calculado con punteros
    add ax, bx                  ; AX = 85 + 73 = 158
    shr ax, 1                   ; AX = 158 / 2 = 79
    mov si, promedio            ; SI = direccion de promedio
    mov [si], ax                ; mem[SI] = 79 (guarda el promedio por el puntero)

; === MODO 4: INDEXADO (BASE + INDICE + DESPLAZAMIENTO) ===========================
; EA = base + indice + desplazamiento.
modo4_indexado:
    ; Elemento especifico: array[2] = 30
    mov bx, array               ; BX = direccion base del array
    mov si, 4                   ; SI = indice * tamano del elemento = 2 * 2 = 4
    mov ax, [bx + si]           ; AX = mem[BX + SI] = array[2] = 30

    ; Suma de todos los elementos del array
    xor ax, ax                  ; AX = 0 (acumulador)
    mov bx, array               ; BX = direccion base
    mov cx, 5                   ; CX = numero de elementos
    xor si, si                  ; SI = 0 (indice en bytes)

.bucle_array:
    add ax, [bx + si]           ; AX += array[SI / 2]
    add si, 2                   ; avanzar 2 bytes (un word)
    loop .bucle_array           ; AX = 10+20+30+40+50 = 150 = 96h al terminar

    ; Extension: recorrido inverso, de array[4] hacia array[0]
    ; Mismo modo indexado, pero SI parte del ultimo elemento y se decrementa de 2 en 2.
    xor ax, ax                  ; AX = 0 (acumulador)
    mov bx, array               ; BX = direccion base
    mov cx, 5                   ; CX = numero de elementos
    mov si, 8                   ; SI = 4 * 2 = desplazamiento en bytes de array[4]

.bucle_array_inverso:
    add ax, [bx + si]           ; AX += array[SI / 2], empezando por array[4]
    sub si, 2                   ; retroceder 2 bytes (un word)
    loop .bucle_array_inverso   ; AX = 50+40+30+20+10 = 150 = 96h al terminar

    ; Campos del registro con desplazamiento fijo (base + desplazamiento)
    mov bx, nota1               ; BX = base del registro (nota1, nota2, promedio)
    mov ax, [bx]                ; AX = nota1 = 85 (offset 0)
    mov cx, [bx + 2]            ; CX = nota2 = 73 (offset 2)
    mov dx, [bx + 4]            ; DX = promedio = 79 (offset 4)

; === MODO 3b: INDIRECTO POR REGISTRO BP -- marco de variables locales ============
; BP es el registro base convencional para datos relativos a la pila: por defecto
; direcciona el segmento SS, mientras que BX/SI/DI direccionan DS. En un .COM
; ambos segmentos coinciden, por lo que el resultado observable es el mismo.
modo3b_marco_bp:
    push bp                     ; preservar el BP del programa principal
    mov bp, sp                  ; BP = SP: define la base del nuevo marco de pila
    sub sp, 4                   ; reservar 4 bytes (2 palabras) para variables locales

    ; Variables locales: desplazamientos negativos respecto a BP (EA = BP + desp.)
    mov word [bp - 2], 99       ; local_1 = 99  (EA = BP - 2)
    mov word [bp - 4], 250      ; local_2 = 250 (EA = BP - 4)

    mov ax, [bp - 2]            ; AX = mem[BP - 2] = local_1 = 99
    add ax, [bp - 4]            ; AX += local_2 = 99 + 250 = 349 = 015Dh

    ; Liberar el marco y restaurar BP antes de continuar
    mov sp, bp                  ; SP = BP: libera las variables locales
    pop bp                      ; restaurar el BP del programa principal

; === ACCESO A MATRIZ: DOBLE INDEXACION (fila, columna) ===========================
; Elemento buscado: matriz[1][2] = 6
; EA = base + (fila * ancho_de_fila_en_bytes) + (columna * tamano_del_elemento)
acceso_matriz:
    mov ax, 1                   ; AX = fila = 1
    mov bx, 3                   ; BX = ancho de fila = 3 elementos (3 columnas)
    mul bx                      ; AX = fila * ancho_fila = 1 * 3 = 3 (en elementos)
    shl ax, 1                   ; AX = 3 * 2 bytes = 6 (desplazamiento de fila, en bytes)
    mov si, ax                  ; SI = desplazamiento de fila ya calculado

    mov cx, 2                   ; CX = columna = 2
    shl cx, 1                   ; CX = 2 * 2 bytes = 4 (desplazamiento de columna, en bytes)
    add si, cx                  ; SI = desplazamiento total = 6 + 4 = 10 = 0Ah

    mov bx, matriz              ; BX = direccion base de la matriz
    mov dx, [bx + si]           ; DX = mem[BX + SI] = matriz[1][2] = 6

; --- Fin del programa ----------------------------------------------------------
fin_programa:
    int 20h                     ; retornar a DOS
