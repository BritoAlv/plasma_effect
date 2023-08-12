use16

; start in VGA Mode
mov  ax, 0x13
int  10h

push 0xA000   ; start of video address
pop  es

call fix_vga_palette

gameLoop:
    mov bx, 0
    time_delay:
        xor ah, ah
        int 0x16
        cmp al, 32
        jne time_delay
    push bx
    call draw_frame
    pop  bx
    inc  bx
    and  bx, 0x3F
    jmp  time_delay

; [Inputs: bl = offset for time]
draw_frame:
    xor di, di
    mov dx, 200
    line_loop:
        mov cx, 320
        pixel_loop:
            xor  ax, ax
            push di            
            call get_color            
            pop  di 
            stosb
            loop pixel_loop
            dec  dx
        jnz line_loop

get_color:
    ; function 1: sin(  sqrt( ( x - 180)^2 + (y-180)^2 ) + time )
    push bx
    push cx
    push dx

    xor di, di
    
    mov bx, cx
    mov ax, 180
    call get_coordinate_distance
    add di, ax 

    mov bx, dx
    mov ax, 180
    call get_coordinate_distance
    add di, ax

    call get_sqrt

    pop dx
    pop cx
    pop bx


    ; I have at ax sqrt
    push di
    mov di, bx
    add ax, [precomputed_time_function + di]
    pop  di
    mov di, ax
    and di, 63
    xor al, al
    add al, [precomputed_sine_table + di]

    ; function 2: sin( sqrt( ( x - 140)^2 + (y-20)^2 ) + time )
    push ax
    push bx
    push cx
    push dx            
    xor di, di

    mov bx, cx
    mov ax, 140
    call get_coordinate_distance
    add di, ax 

    mov bx, dx
    mov ax, 20
    call get_coordinate_distance
    add di, ax

    call get_sqrt
    
    pop dx
    pop cx
    pop bx
    ; I have at ax sqrt
    push di
    mov di, bx
    add ax, [precomputed_time_function + di]
    pop  di
    mov di, ax
    and di, 63
    pop ax                                ; restore al
    add al, [precomputed_sine_table + di]                            ; mod it
    
    inc al
    ret
;[Input bx = coordinate1, ax = coordinate2]
;[Output ax = (coordinate1 - coordinate2)^2]
get_coordinate_distance:
    cmp bx, ax
    jge b1
    sub ax, bx
    mov bx, ax
    mul bl
    ret
    b1:
        sub bx, ax
        mov ax, bx
        mul bl
        ret

;[ Input di = number, Output ax = root]
get_sqrt:
    cmp di, 0
    jz end_sqrt
    mov ax, 255
    start_loop:
        mov bx, ax
        xor dx, dx
        mov ax, di
        div bx
        add ax, bx
        shr ax, 1
        mov cx, ax
        sub cx, bx
        cmp cx, 2
        ja  start_loop
        ret
    end_sqrt:
        mov ax, 0
        ret


fix_vga_palette:
    mov al, 1
    mov dx, 0x3c8
    out dx, al

    mov dx, 0x3c9

    mov ah, 255
    mov bl, 0

    mov cx, 84

    plasma_rg_loop:
    sub  ah, 3
    add  bl, 3
    mov  al, ah
    inc  al
    shr  al, 1
    shr  al, 1
    dec  al
    out  dx, al
    mov  al, bl
    inc  al
    shr  al, 1
    shr  al, 1
    dec  al
    out  dx, al
    xor  al, al
    out  dx, al
    loop plasma_rg_loop

    sub ah, 3
    add bl, 3

    xor al, al
    out dx, al
    mov al, 63
    out dx, al
    xor al, al
    out dx, al

    mov cx, 84

    plasma_gb_loop:
    add  ah, 3
    sub  bl, 3
    xor  al, al
    out  dx, al
    mov  al, bl
    inc  al
    shr  al, 1
    shr  al, 1
    dec  al
    out  dx, al
    mov  al, ah
    inc  al
    shr  al, 1
    shr  al, 1
    dec  al
    out  dx, al
    loop plasma_gb_loop

    mov ah, 63
    sub bl, 3

    xor al, al
    out dx, al
    out dx, al
    mov al, ah
    out dx, al

    mov cx, 84

    plasma_bw_loop:
    add  bl, 3
    mov  al, bl
    inc  al
    shr  al, 1
    shr  al, 1
    dec  al
    out  dx, al
    out  dx, al
    mov  al, ah
    out  dx, al
    loop plasma_bw_loop

    mov al, ah
    out dx, al
    out dx, al
    out dx, al
    ret


game_end:
    cli
    hlt

section.data:
    precomputed_sine_table:    db 63,69,75,81,87,93,98,103,108,112,116,119,122,124,125,126,127,126,125,124,122,119,116,112,108,103,98,93,87,81,75,69,63,57,51,45,39,33,28,23,18,14,10,7,4,2,1,0,0,0,1,2,4,7,10,14,18,23,28,33,39,45,51,57,
    precomputed_time_function: db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
times 510 - ($ - $$) db 0
dw 0xaa55