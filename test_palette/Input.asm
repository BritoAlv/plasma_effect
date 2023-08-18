use16

color1red   equ 255
color1green equ 103
color1blue  equ 0

color2red   equ 0
color2green equ 23
color2blue  equ 255

color3red   equ 0
color3green equ 255
color3blue  equ 49

color4red   equ 255
color4green equ 255
color4blue  equ 0


; start in VGA Mode
mov  ax, 0x13
int  10h

push 0xA000          ; start of video address
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
        call modify_default_colors
        call fix_vga_palette
        call draw_frame
        pop  bx
        inc  bx
        and  bx, 0xFF
        inc bx
        jmp  wait_space

    

; [Inputs: bl = offset for time]
draw_frame:
    xor di, di
    xor al, al
    mov dx, 200
    line_loop:
        mov cx, 256
        pixel_loop:
            stosb
            inc  al
            loop pixel_loop
            add  di, 64
            dec  dx
        jnz line_loop
    ret

fix_vga_palette:
    pusha
    xor al, al
    mov dx, 0x3c8
    out dx, al
    inc dx
    mov di, colors
    mov cx, 85
    call set_color_loop
    add di, 3
    mov cx, 86
    call set_color_loop
    add di, 3
    mov cx, 85
    call set_color_loop
    popa
    ret


set_color:
    pusha 
    xor ax, ax
    mov    al, bh
    mul    cl
    mov    di, ax
    mov    ax, 86
    sub    ax, cx
    mul    bl
    add    ax, di
    shr    ax, 9
    out    dx, al
    popa
    ret
    
game_end:
    cli
    hlt

;[ Inputs cx = number_of_iterations, di = start_offset, 
set_color_loop:
    pusha
    .looop:
    mov  bh, [di]
    mov  bl, [di+3]
    call set_color
    inc di
    mov  bh, [di]
    mov  bl, [di+3]
    call set_color
    inc di
    mov  bh, [di]
    mov  bl, [di+3]
    call set_color
    sub di, 2    
    loop .looop
    popa
    ret

modify_default_colors:
    ret

section.data:
    precomputed_sine_table: db 32,35,38,41,44,47,49,52,54,56,58,60,61,62,63,63,64,63,63,62,61,60,58,56,54,52,49,47,44,41,38,35,31,28,25,22,19,16,14,11,9,7,5,3,2,1,0,0,0,0,0,1,2,3,5,7,9,11,14,16,19,22,25,28
    colors:  db color1red, color1green, color1blue, color2red, color2green, color2blue, color3red, color3green, color3blue, color4red, color4green, color4blue  

times 510 - ($ - $$) db 0
dw 0xaa55
