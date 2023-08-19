use16

; start in VGA Mode
mov  ax, 0x13
int  10h

push 0xA000   ; start of video address
pop  es

gameLoop:
    xor bx, bx
    
    wait_space:
        xor ah, ah
        int 0x16
        cmp al, 32
        jne wait_space

    execute_action:
        mov si, 85 ; use SI as an read only register.
        call modify_default_colors
        call modify_vga_palette
        mov si, 0x3f ; use SI as an read only register.
        call draw_frame
        inc  bx
        xor bh, bh
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

;[Inputs : bl = time, cx = x, dx = y coordinates, si = 63]
get_color:
    xor ax, ax

    mov di, point1
    call .radial_wave


    mov di, point2
    call .radial_wave

    mov di, params_f3
    call .sine_wave

    mov di, params_f4
    call .sine_wave

    mov di, time_factor
    call generate_random_number

    ret

    .sine_wave:
        push ax
        mov ax, [di+1]
        mul cl
        push ax
        mov ax, [di]
        mul dl
        pop di
        add di, ax
        add di, bx
        push di
        mov di, [time_factor]
        and di, si
        mov al, [precomputed_sine_table + di]
        pop di
        add di, ax
        and di, si 
        pop ax
        add al, [precomputed_sine_table + di]
        ret

    .radial_wave:
        push ax
        push bx
        push cx
        push dx

        mov  bx, cx
        xor  ax, ax
        mov  al, [di+1]
        call get_coordinate_distance    
        
        push ax

        mov  bx, dx
        xor  ax, ax
        mov  al, [di]
        call get_coordinate_distance
        
        pop di
        
        add di, ax

        call get_sqrt

        pop dx
        pop cx
        pop bx

        ; I have at ax sqrt    
        mov di, ax
        add di, bx
        
        push di
        mov di, [time_factor]
        and di, si
        mov al, [precomputed_sine_table + di]
        pop di
        
        add di, ax
        and di, si
        
        pop ax
        add al, [precomputed_sine_table + di]
        ret


;[Input bx = coordinate1, ax = coordinate2]
;[Output ax = (coordinate1 - coordinate2)^2]
get_coordinate_distance:
    cmp bx, ax
    jge b1
    xchg ax, bx
    b1:
        sub bx, ax
        mov ax, bx
        mul bl
        ret

;[ Input di = number, Output ax = root]
; this uses Newton method.
get_sqrt:
    jz  .end_sqrt
    mov ax, 255 ; a nice guess 
    .start_loop:
        mov bx, ax
        xor dx, dx ; due to the division.
        mov ax, di
        div bx
        add ax, bx
        shr ax, 1
        mov cx, ax
        sub cx, bx
        cmp cx, 2
        ja  .start_loop
    .end_sqrt:
        ret

;[ di = input address to write a random number]
generate_random_number:
    push bx
    mov bx, [0x046c] ; start_state in di
    mov [di], bl
    pop bx
    ret

modify_default_colors:    
    xor cx, cx
    .loopp:
        mov di, color_param
        call generate_random_number
        mov di, [color_param]
        shr di, cl   
        and di, 0x3f
        mov al, [precomputed_sine_table + di]
        shl al, 2
        mov di, cx
        mov ah, [colors+di] 
        
        push bx
        mov dh, ah
        
        xor ah, ah
        mul cl
        mov bx, ax
        mov al, 32
        sub al, cl 
        mul dh
        add ax, bx
        shr ax, 5
        pop bx
        mov [colors + di], al
        inc cl
        cmp cl, 9
        jne .loopp

    inc di
    push bx
    mov bx, colors
    push si
    xor si, si
    mov cx, 3
    rep call .procedure
    pop si
    pop bx
    ret

    .procedure:
        mov al, [si + bx]
        mov [di + bx], al
        inc di
        inc si
        ret

; [Inputs: si = 85]
modify_vga_palette:
    pusha
    mov  dx, 0x3c8
    xor  al, al
    out  dx, al
    inc  dx
    mov  di, colors
    mov  cx, si
    call set_color_loop
    inc cx
    call set_color_loop
    call set_color_loop
    popa
    ret

;[ Inputs cx = number_of_iterations, di = start_offset, 
set_color_loop:
    push di
    call .procedure
    call .procedure
    call .procedure
    pop di
    loop set_color_loop
    add di, 3
    mov  cx, si    
    ret

    .procedure:
        mov  bh, [di]
        mov  bl, [di+3]
        call set_color
        inc  di
        ret    

set_color:
    pusha 
    xor ax, ax
    mov al, bh
    mul cl
    mov di, ax
    mov ax, si
    inc ax
    sub ax, cx
    mul bl
    add ax, di
    shr ax, 9
    out dx, al
    popa
    ret

section.data:
    ; 64 values between 0 and 64 to be used for four functions.
    precomputed_sine_table: db 32,35,38,41,44,47,49,52,54,56,58,60,61,62,63,63,64,63,63,62,61,60,58,56,54,52,49,47,44,41,38,35,31,28,25,22,19,16,14,11,9,7,5,3,2,1,0,0,0,0,0,1,2,3,5,7,9,11,14,16,19,22,25,28
    point1:                 dw 0xB4B4
    point2:                 dw 0x8C14

    colors: db 205, 103, 36, 60, 23, 88, 11, 255, 120, 205, 103, 36
    params_f3: dw 0x0101
    params_f4: dw 0x03a1

    color_param: db 100

    time_factor: db 1

times 510 - ($ - $$) db 0
dw 0xaa55
