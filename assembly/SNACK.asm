assume cs:code, ds:data, ss:stack

; gpu prop byte
; 7    6  5  4  3  2  1  0
; BL   R  G  B  I  R  G  B
;  |   \_____/  |  \_____/
; 闪烁   背景  高亮  前景

; game map: 25 x 25
; snack bodys max: 23 x 23

data segment
  food dw 0              ; snack food: x|y
  body dw 529 dup(0)     ; snack bodys
data ends

stack segment
  dw 20 dup(0)
stack ends

code segment
start:
  mov ax, data
  mov ds, ax                ; init data seg
  
  mov ax, 0b800h            
  mov es, ax                ; save gpu base addr
  
  mov ax, stack
  mov ss, ax
  mov sp, 20                ; init stack
  
  call clear
  mov ah, 24
  mov al, 24
  push ax
  call draw_map
  
  mov cx, 30
t: ; test create food
  call create_food
  call sleep

  loop t
  
  mov ax, 4c00h
  int 21h

; # create a rand food
; fixed: map width and height
; void -> void
create_food:
  push ax
  push bx
  push dx

  mov bx, 23
  push bx
  call rand        ; get x
  inc dx           ; range: 1-[23]
  mov ah, dl
  
  push bx
  call rand        ; get y
  inc dx
  mov al, dl
  mov food, ax     ; save food xy
  
  push ax
  mov ah, 00100000b
  mov al, ' '
  push ax
  call draw_char   ; draw food
  
  pop dx
  pop bx
  pop ax
  ret

; # rand number
; 0: range -> dx: 0~(range)
rand:
  push bp
  mov bp, sp
  push ax

  mov ax, 0h
  out 43h, al
  
  in al, 40h
  in al, 40h
  in al, 40h
  
  mov bx, [bp + 4]
  div bl
  
  mov dh, 0
  mov dl, ah
  
  pop ax
  pop bp
  ret 2

; # sleep tiem
; void -> void
sleep:
  push cx
  mov cx, 50000
 s0:
  push cx
  mov cx, 20
 s1:
  loop s1
  pop cx
  loop s0
  
  pop cx
  ret
  
; # draw game map
; 0: width|height -> void
draw_map:
  push bp
  mov bp, sp
  ; draw top
  
  push cx
  push ax
  push bx
  push dx
  
  mov dx, [bp + 4]  ; get width
  
  mov ax, 0
  mov ch, 0
  mov cl, dh        ; set width
  inc cl
 d0:
  mov bh, al        ; draw top
  mov bl, 0
  push bx
  mov bh, 00010000b
  mov bl, ' '
  push bx
  call draw_char
  
  mov bh, al        ; draw bottom
  mov bl, dl
  push bx
  mov bh, 00010000b
  mov bl, ' '
  push bx
  call draw_char
  
  inc al
  loop d0
 
  mov cl, dl        ; set height
  dec cl            ; inside content height
  mov al, 1
  
 d1:
  mov bh, 0         ; draw left
  mov bl, al
  push bx
  mov bh, 00010000b
  mov bl, ' '
  push bx
  call draw_char

  mov bh, dh        ; draw bottom
  mov bl, al
  push bx
  mov bh, 00010000b
  mov bl, ' '
  push bx
  call draw_char

  inc al
  loop d1
  
  pop dx
  pop bx
  pop ax
  pop cx
  
  pop bp
  ret 2
  
; # draw char to screen
; 0: x|y, 1: prop|char -> void
draw_char:
  push bp
  mov bp, sp
  
  push ax
  push bx
  push si
  
  mov bx, [bp + 6]
  mov ah, 0
  mov al, 0a0h
  mul bl            ; set y
  
  mov bl, bh
  mov bh, 0
  add bl, bl
  add bl, bl
  add ax, bx        ; set x
  
  mov si, ax
  mov ax, [bp + 4]
  mov es:[si], ax   ; set prop and char
  mov es:[si + 2], ax
  
  pop si
  pop bx
  pop ax
  
  pop bp
  ret 4
  
; # clear screen
; void -> void
clear:
  mov ax, 3h
  int 10h
  ret
  
code ends
end start