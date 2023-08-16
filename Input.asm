use16

; start in VGA Mode
mov  ax, 0x13
int  10h

push 0xA000   ; start of video address
pop  es

%macro zeroit 1
    xor %1, %1
%endmacro

gameLoop:
    mov bx, 0
    time_delay:
        zeroit ah
        int    0x16
        cmp    al, 32
        je     execute_action

        action1:        
            mov dx, [point1]
            cmp al, 119
            jne .branch1
            inc dh
            jmp .done
            .branch1:
            cmp al, 115
            jne .branch2
            dec dh
            jmp .done

            .branch2:
            cmp al, 97
            jne .branch3
            inc dl
            jmp .done

            .branch3:
            cmp al, 100
            jne action2
            dec dl
            jmp .done

            .done:
                mov [point1], dx
                jmp execute_action

        action2:        
            mov dx, [point2]
            cmp al, 105
            jne .branch1
            inc dh
            jmp .done
            .branch1:
            cmp al, 107
            jne .branch2
            dec dh
            jmp .done

            .branch2:
            cmp al, 106
            jne .branch3
            inc dl
            jmp .done

            .branch3:
            cmp al, 108
            jne end
            dec dl
            jmp .done

            .done:
                mov [point2], dx
                jmp execute_action

    end:
        jmp time_delay 

    execute_action:
        push bx
        call modify_vga_palette
        call draw_frame
        pop  bx
        inc  bx
        and  bx, 0x3F
        jmp  time_delay

; [Inputs: bl = offset for time]
draw_frame:
    zeroit di
    mov    dx, 200
    line_loop:
        mov cx, 320
        pixel_loop:
            zeroit ax
            push   di
            call   get_color
            pop    di
            stosb
            loop   pixel_loop
            dec    dx
        jnz line_loop

get_color:
    ; function 1: sin(  sqrt( ( x - 180)^2 + (y-180)^2 ) + time )
    push bx
    push cx
    push dx

    zeroit di
    
    mov    bx, cx
    zeroit ax
    mov    al, byte [point1+1]
    call   get_coordinate_distance
    add    di, ax

    mov    bx, dx
    zeroit ax
    mov    al, byte [point1]
    call   get_coordinate_distance
    add    di, ax

    call get_sqrt

    pop dx
    pop cx
    pop bx

    ; I have at ax sqrt
    add    ax, bx
    mov    di, ax
    and    di, 63
    zeroit al
    add    al, [precomputed_sine_table + di]

    ; function 2: sin( sqrt( ( x - 140)^2 + (y-20)^2 ) + time )
    push   ax
    push   bx
    push   cx
    push   dx
    zeroit di

    mov    bx, cx
    zeroit ax
    mov    al, byte [point2+1]
    call   get_coordinate_distance
    add    di, ax

    mov    bx, dx
    zeroit ax
    mov    al, byte [point2]
    call   get_coordinate_distance
    add    di, ax

    call get_sqrt
    
    pop  dx
    pop  cx
    pop  bx
    ; I have at ax sqrt
    add  ax, bx
    mov  di, ax
    and  di, 63
    pop  ax                                   ; restore al
    add  al, [precomputed_sine_table + di]    ; mod it
    
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
        mov    bx, ax
        zeroit dx         ; due to the division.
        mov    ax, di
        div    bx
        add    ax, bx
        shr    ax, 1
        mov    cx, ax
        sub    cx, bx
        cmp    cx, 2
        ja     start_loop
        ret
    end_sqrt:
        mov ax, 0
        ret

modify_vga_palette:
    pusha
    mov dx, 0x3c9
    mov cx, 255
    set_colors_loop:
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

        loop set_colors_loop
    popa
    ret

set_color:
    zeroit ax
    mov    al, bh
    mul    cl
    mov    di, ax
    zeroit ax
    mov    ah, bl
    add    di, ax
    mul    cl
    sub    di, ax
    mov    ax, di
    shr    ax, 8
    out    dx, al
    ret

game_end:
    cli
    hlt
;A
section.data:
    precomputed_sine_table:    db 63,69,75,81,87,93,98,103,108,112,116,119,122,124,125,126,127,126,125,124,122,119,116,112,108,103,98,93,87,81,75,69,63,57,51,45,39,33,28,23,18,14,10,7,4,2,1,0,0,0,1,2,4,7,10,14,18,23,28,33,39,45,51,57
    point1:                    dw 0xB4B4
    point2:                    dw 0x8C14

    color1r: db 0x00
    color1g: db 0xbb
    color1b: db 0xaa

    color2r: db 0xcc
    color2g: db 0xaa
    color2b: db 0xa0

times 510 - ($ - $$) db 0
dw 0xaa55