use16

color1red   equ 255
color1green equ 103
color1blue  equ 36

color2red   equ 45
color2green equ 23
color2blue  equ 255

color3red   equ 65
color3green equ 255
color3blue  equ 49

; start in VGA Mode
mov  ax, 0x13
int  10h

push 0xA000   ; start of video address
pop  es



gameLoop:
    mov bx, 0
    wait_space:
        xor ah, ah
        int 0x16
        cmp al, 32
        jne wait_space

    execute_action:
        push bx
        call modify_vga_palette
        call draw_frame
        pop  bx
        inc  bx
        and  bx, 0xFF
        jmp  wait_space

; [Inputs: bl = offset for time]
draw_frame:
    pusha
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
    popa
    ret        

get_color:
    ; function 1: sin(  sqrt( ( x - 180)^2 + (y-180)^2 ) + time )
    push bx
    push cx
    push dx

    xor di, di
    
    mov  bx, cx
    xor  ax, ax
    mov  al, byte [point1+1]
    call get_coordinate_distance
    add  di, ax

    mov  bx, dx
    xor  ax, ax
    mov  al, byte [point1]
    call get_coordinate_distance
    add  di, ax

    call get_sqrt

    pop dx
    pop cx
    pop bx

    ; I have at ax sqrt    
    mov di, ax
    add di, bx
    and di, 0x3F
    xor al, al
    add al, [precomputed_sine_table + di]

    ; function 2: sin( sqrt( ( x - 140)^2 + (y-20)^2 ) + time )
    push ax
    push bx
    push cx
    push dx
    xor  di, di

    mov  bx, cx
    xor  ax, ax
    mov  al, byte [point2+1]
    call get_coordinate_distance
    add  di, ax

    mov  bx, dx
    xor  ax, ax
    mov  al, byte [point2]
    call get_coordinate_distance
    add  di, ax

    call get_sqrt
    
    pop dx
    pop cx
    pop bx
    ; I have at ax sqrt
    
    mov di, ax
    add di, bx
    and di, 0x3F
    pop ax                                ; restore al
    add al, [precomputed_sine_table + di] ; mod it
    
    ; function 3: sin( 2x+y + time)
    mov di, cx
    shl di, 1
    add di, dx
    add di, bx
    and di, 0x3F
    add al, [precomputed_sine_table + di]
    
    ; function 4: sin( 2y - x + time)
    mov di, dx
    shl di, 1
    sub di, dx
    add di, bx
    and di, 0x3F
    add al, [precomputed_sine_table + di]


    
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
; this uses Newton method.
get_sqrt:
    cmp di, 0
    jz  end_sqrt
    mov ax, 255
    start_loop:
        mov bx, ax
        xor dx, dx     ; due to the division.
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

modify_vga_palette:
    pusha
    call modify_default_colors
    mov dx, 0x3c8
    xor al, al
    out dx, al
    inc dx
    mov  cx, 128
    mov  di, colors
    call set_color_loop
    add  di, 3
    mov  cx, 128
    call set_color_loop
    popa
    ret

modify_default_colors:    
    ret

set_color:
    pusha 
    xor ax, ax
    mov al, bh
    mul cl
    mov di, ax
    mov ax, 128
    sub ax, cx
    mul bl
    add ax, di
    shr ax, 9
    out dx, al
    popa
    ret

game_end:
    cli
    hlt

;[ Inputs cx = number_of_iterations, di = start_offset, 
set_color_loop:
    mov  bh, [di]
    mov  bl, [di+3]
    call set_color
    inc  di
    mov  bh, [di]
    mov  bl, [di+3]
    call set_color
    inc  di
    mov  bh, [di]
    mov  bl, [di+3]
    call set_color
    sub  di, 2
    loop set_color_loop
    ret


section.data:
    ; 64 values between 0 and 64 to be used for four functions
    precomputed_sine_table: db 32,35,38,41,44,47,49,52,54,56,58,60,61,62,63,63,64,63,63,62,61,60,58,56,54,52,49,47,44,41,38,35,31,28,25,22,19,16,14,11,9,7,5,3,2,1,0,0,0,0,0,1,2,3,5,7,9,11,14,16,19,22,25,28,
    point1:                 dw 0xB4B4
    point2:                 dw 0x8C14

    colors: db color1red, color1green, color1blue, color2red, color2green, color2blue, color3red, color3green, color3blue

times 510 - ($ - $$) db 0
dw 0xaa55
