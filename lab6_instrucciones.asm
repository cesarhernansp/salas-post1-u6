; lab6_instrucciones.asm -- Demostracion de las categorias de instrucciones x86
; Compilar: nasm -f bin lab6_instrucciones.asm -o lab6_instrucciones.com
;
; Programa .COM: un unico segmento de 64 KB (CS = DS = ES = SS) que DOS carga en
; el desplazamiento 0100h, despues de los 256 bytes del PSP. El programa recorre
; cuatro categorias de instrucciones en bloques consecutivos y termina con INT 20h.

org 100h                        ; offset de inicio para archivos .COM

; --- Datos ---------------------------------------------------------------------
; Los datos van al principio del archivo; el primer salto los evita para que la
; ejecucion empiece en el codigo.
    jmp inicio                  ; saltar sobre los datos hacia el codigo

valor_a   dw 45                 ; primer operando
valor_b   dw 12                 ; segundo operando
resultado dw 0                  ; almacena un resultado
contador  db 5                  ; numero de iteraciones de los bucles
mascara   db 0Fh                ; mascara de los 4 bits bajos

; --- Codigo --------------------------------------------------------------------
inicio:

; === BLOQUE 1: Transferencia de datos ===========================================
bloque1_transferencia:
    ; MOV carga el contenido de memoria en un registro
    mov ax, [valor_a]           ; AX = 45 (contenido de valor_a)
    mov bx, [valor_b]           ; BX = 12 (contenido de valor_b)

    ; MOV entre registros
    mov cx, ax                  ; CX = AX = 45
    mov dx, bx                  ; DX = BX = 12

    ; LEA carga la direccion, no el contenido
    lea si, [valor_a]           ; SI = direccion de valor_a (no su valor)
    mov ax, [si]                ; AX = mem[SI] = 45 (acceso indirecto por SI)

    ; XCHG intercambia dos registros
    xchg cx, dx                 ; CX = 12, DX = 45
    xchg cx, dx                 ; se restaura: CX = 45, DX = 12

    ; PUSH/POP preservan y restauran un registro
    push ax                     ; guarda AX = 45 en la pila
    mov ax, 0FFFFh              ; modifica AX temporalmente
    pop ax                      ; restaura AX = 45

; === BLOQUE 2: Operaciones aritmeticas ==========================================
bloque2_aritmetica:
    ; ADD: suma con actualizacion de flags
    mov ax, [valor_a]           ; AX = 45
    add ax, [valor_b]           ; AX = 45 + 12 = 57 (ZF=0, CF=0, OF=0)
    mov [resultado], ax         ; guarda 57 en memoria

    ; SUB: resta; el resultado negativo activa SF y el prestamo activa CF
    mov ax, [valor_b]           ; AX = 12
    sub ax, [valor_a]           ; AX = 12 - 45 = -33 = 0FFDFh (SF=1, CF=1, OF=0)

    ; INC y DEC: incremento y decremento (no modifican CF)
    mov ax, [valor_a]           ; AX = 45
    inc ax                      ; AX = 46
    dec ax                      ; AX = 45

    ; MUL: multiplicacion sin signo, AX = AL * operando
    mov al, 10                  ; AL = 10
    mov bl, 7                   ; BL = 7
    mul bl                      ; AX = AL * BL = 70

    ; DIV: division sin signo, AL = cociente y AH = resto
    mov ax, 100                 ; AX = 100
    mov bl, 7                   ; BL = 7
    div bl                      ; AL = 14, AH = 2 (100 = 7 * 14 + 2)

; === BLOQUE 3: Operaciones logicas ==============================================
bloque3_logica:
    mov al, 0B7h                ; AL = 1011 0111b = 0B7h

    ; AND: mascara de limpieza, conserva solo los 4 bits bajos
    and al, [mascara]           ; AL = 0B7h AND 0Fh = 0111b = 07h

    mov al, 0B7h                ; se restaura AL

    ; OR: activa bits; aqui activa los 4 bits altos
    or al, 0F0h                 ; AL = 0B7h OR 0F0h = 1111 0111b = 0F7h

    mov al, 0AAh                ; AL = 1010 1010b

    ; XOR con 0FFh: inversion de todos los bits
    xor al, 0FFh                ; AL = NOT AL = 0101 0101b = 55h

    ; XOR reg, reg: forma estandar de poner a cero un registro
    xor bx, bx                  ; BX = 0 (mas corta que MOV BX, 0)

    ; TEST: AND que no guarda el resultado, solo actualiza flags
    mov al, 0B7h
    test al, 01h                ; ZF = 0 si el bit 0 vale 1 (numero impar)
                                ; AL sigue valiendo 0B7h

    ; SHL/SHR: desplazamiento = multiplicar / dividir por 2
    mov al, 08h                 ; AL = 8
    shl al, 2                   ; AL = 8 << 2 = 32 = 20h
    shr al, 1                   ; AL = 32 >> 1 = 16 = 10h

; === BLOQUE 4: Control de flujo =================================================
bloque4_control_flujo:
    ; Estructura if/else: comparar valor_a con valor_b
    mov ax, [valor_a]           ; AX = 45
    cmp ax, [valor_b]           ; AX - valor_b = 45 - 12 = 33 > 0
    jg .mayor                   ; salta si AX > valor_b (con signo)
    je .igual                   ; salta si AX == valor_b

    ; caso AX < valor_b (no se alcanza con estos datos)
    xor cx, cx                  ; CX = 0 como indicador
    jmp .fin_comparacion

.mayor:
    mov cx, 1                   ; CX = 1: indica valor_a > valor_b
    jmp .fin_comparacion

.igual:
    mov cx, 2                   ; CX = 2: indica igualdad

.fin_comparacion:

    ; Bucle contado: suma acumulada de 1 a 5 (resultado esperado: 15)
    xor ax, ax                  ; AX = 0 (acumulador)
    mov cl, [contador]          ; CL = 5 (numero de iteraciones)
    xor ch, ch                  ; CX = 5: contador del bucle
    mov bx, 1                   ; BX = siguiente valor a sumar

.bucle_suma:
    add ax, bx                  ; AX += BX
    inc bx                      ; BX++ (siguiente valor)
    loop .bucle_suma            ; CX--; si CX != 0 vuelve a .bucle_suma
                                ; al terminar AX = 1+2+3+4+5 = 15

; === BLOQUE 4b: Variante del bucle -- factorial de 5 ============================
; Mismo esqueleto que el bucle de suma, con MUL en lugar de ADD: el acumulador
; parte de 1 (elemento neutro del producto) y se multiplica por BX = 1, 2, 3, 4, 5.
bloque4b_factorial:
    mov ax, 1                   ; AX = 1 (acumulador del producto)
    mov cl, [contador]          ; CL = 5
    xor ch, ch                  ; CX = 5: contador del bucle
    mov bx, 1                   ; BX = factor actual

.bucle_factorial:
    mul bx                      ; DX:AX = AX * BX (DX = 0 mientras el producto cabe en 16 bits)
    inc bx                      ; BX++ (siguiente factor)
    loop .bucle_factorial       ; CX--; si CX != 0 vuelve a .bucle_factorial
                                ; al terminar AX = 1*1*2*3*4*5 = 120 = 78h
    mov [resultado], ax         ; guarda 5! en memoria

; === BLOQUE 5: Rotacion -- ROL/ROR frente a SHL/SHR ==============================
; SHL/SHR descartan el bit que sale del registro (solo queda en CF). ROL/ROR
; reinsertan ese bit por el extremo opuesto, de modo que no se pierde ninguno.
; Las cuatro instrucciones se aplican al mismo valor de entrada para compararlas.
bloque5_rotacion:
    mov al, 81h                 ; AL = 1000 0001b: bits 7 y 0 en 1, para que
                                ; ambos extremos del registro se vean afectados

    ; SHL: el bit que sale por la izquierda se pierde (solo queda en CF)
    mov bl, al                  ; se conserva el valor original en BL
    shl bl, 1                   ; BL = 0000 0010b = 02h; CF = 1 (bit 7 original)

    ; ROL: el bit que sale por la izquierda se reinserta por la derecha
    mov cl, al                  ; se conserva el valor original en CL
    rol cl, 1                   ; CL = 0000 0011b = 03h; CF = 1, y ese bit queda en el bit 0

    ; El mismo contraste por el extremo derecho
    mov dl, al                  ; DL = AL = 1000 0001b
    shr dl, 1                   ; DL = 0100 0000b = 40h; CF = 1 (bit 0 original perdido)

    mov bh, al                  ; BH = AL = 1000 0001b
    ror bh, 1                   ; BH = 1100 0000b = 0C0h; CF = 1, y ese bit pasa a ser el bit 7

    ; Uso practico de ROL: intercambiar los nibbles de un byte (alto <-> bajo)
    mov al, 0A5h                ; AL = 1010 0101b (nibble alto = A, nibble bajo = 5)
    rol al, 4                   ; AL = 0101 1010b = 5Ah: nibbles intercambiados;
                                ; SHL no puede lograrlo porque descartaria el nibble alto

; --- Fin del programa ----------------------------------------------------------
fin_programa:
    int 20h                     ; retornar a DOS
