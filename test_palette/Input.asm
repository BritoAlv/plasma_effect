use16

; start in VGA Mode
mov  ax, 0x13
int  10h

push 0xA000          ; start of video address
pop  es

call fix_vga_palette

gameLoop:
    call draw_frame
    jmp  gameLoop


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

; I will use colors so they should be at positions 0, 64, 128, 192, 255, first and last colour is the same due to mod.
fix_vga_palette:
    mov dx, 0x3c8
    mov al, 0
    out dx, al
    inc dx    
    ; 0
    mov  ah, 0x00
    mov  bx, 0xFFFF
    call set_color_vga
        
    ; 1 to 63
    mov cx, 63
    first_loop:
        call set_color_vga
        loop first_loop
    
    ; 64
    mov  ah, 0x22
    mov  bx, 0xFF44
    call set_color_vga

    ; 65 to 127
    mov cx, 63
    second_loop:
        call set_color_vga
        loop second_loop

    ; 128
    mov  ah, 0x33
    mov  bx, 0xEEFF
    call set_color_vga

    ; 129 to 191
    mov cx, 63
    third_loop:
        call set_color_vga
        loop third_loop

    ; 192
    mov  ah, 0x22
    mov  bx, 0x99AA
    call set_color_vga

    ; 193 to 254
    mov cx, 62
    four_loop:
        call set_color_vga
        loop four_loop
    
    ; 255
    mov  ah, 0x00
    mov  bx, 0xFFFF
    call set_color_vga

    ret

; [ Inputs: ah = red, bh = green, bl = blue]
set_color_vga:
    mov al, ah
    out dx, al
    mov al, bh
    out dx, al
    mov al, bl
    out dx, al
    ret
    

game_end:
    cli
    hlt


times 510 - ($ - $$) db 0
dw 0xaa55