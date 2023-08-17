use16

%macro zeroit 1
    xor %1, %1
%endmacro

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

fix_vga_palette:
    pusha

    mov dx, 0x3c9
    mov cx, 128
    set_colors_loop1:
        ; red channel
        mov  bh, [color1r]
        mov  bl, [color2r]
        call set_color

        mov  bh, [color1g]
        mov  bl, [color2g]
        call set_color

        mov  bh, [color1b]
        mov  bl, [color2b]
        call set_color
        
        dec cx
        cmp cx, 0
        jne set_colors_loop1


    mov cx, 128
    set_colors_loop2:
        ; red channel
        mov  bh, [color2r]
        mov  bl, [color3r]
        call set_color

        mov  bh, [color2g]
        mov  bl, [color3g]
        call set_color

        mov  bh, [color2b]
        mov  bl, [color3b]
        call set_color
        
        dec cx
        cmp cx, 0
        jne set_colors_loop2



    popa
    ret

set_color:
    zeroit ax
    mov    al, bh
    mul    cl
    mov    di, ax
    mov    ax, 128
    sub    ax, cx
    mul    bl
    add    ax, di
    shr    ax, 10
    out    dx, al
    ret
    
game_end:
    cli
    hlt

section.data:

    color1r: db 0xff
    color1g: db 0x34
    color1b: db 0x12

    color2r: db 0xbb
    color2g: db 0xff
    color2b: db 0x00

    color3r: db 0xbb
    color3g: db 0xcc
    color3b: db 0xdd

times 510 - ($ - $$) db 0
dw 0xaa55