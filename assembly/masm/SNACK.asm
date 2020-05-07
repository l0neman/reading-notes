assume cs:code, ds:data, ss:stack

; gpu prop byte
; 7    6  5  4  3  2  1  0
; BL   R  G  B  I  R  G  B
;  |   \_____/  |  \_____/
; 闪烁   背景  高亮  前景

; game map: 25 x 25
; snack bodys max: 23 x 23

data segment
  score dw 0             ; game score
  food dw 0              ; snack food: x|y
  sdct db 0              ; snack direction 0001-up 0010-down 0100-left 1000-right
  slen db 0              ; snack length
  dead db 'game over!'   ; game over
  body dw 529 dup(0)     ; snack bodys: x|y, ...
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
  
  call create_snack
  call draw_snack
  
  call create_food
  call draw_food

  call start_game

end_game:
  call game_over

  mov ax, 4c00h
  int 21h
  
; # start game
; void -> void
start_game:
  mov cx, 50 
sg0:
  call listen_key  
  call clear_last
  call move_snack
  call is_dead
  call show_score
  call draw_snack
  call sleep
  loop sg0
  ret

; # show game over alert
; void -> void
game_over:
  push ax
  push cx
  push si

  mov si, 28
  mov cx, 10  ; string length
go0:
  mov ax, si
  mov ah, al
  mov al, 12
  push ax
  mov ah, 00000111b
  mov al, dead[si - 28]
  push ax
  call draw_char
  inc si
  loop go0
  
  pop si
  pop cx
  pop ax
  ret

; # todo
show_score:
  
  ret

; # is the snack dead
; void -> void
is_dead:
  push ax
  push cx
  push si
  
  mov ax, body[0]  ; get head
  
  cmp ah, 0        ; touch the edge
  je end_game

  cmp ah, 24
  je end_game

  cmp al, 0
  je end_game
  
  cmp al, 24
  je end_game
  
  mov ch, 0
  mov cl, slen
  dec cx
  mov si, 2     ; start with second
  
id0:
  mov ax, body[si]
  cmp body[0], ax
  je end_game
  add si, 2
  loop id0
  
  pop si
  pop cx
  pop ax
  ret

; # listen to keys
; void -> void
listen_key:
  push ax
  
  mov ah, 1
  mov al, 0
  int 16h          ; keboard interrupt
  cmp ah, 1
  je lk0
  
  mov ax, 0
  int 16h
  cmp ax, 4800h    ; press up
  je kup
 
  cmp ax, 5000h    ; press down
  je kdown
  
  cmp ax, 4b00h    ; press left
  je kleft
  
  cmp ax, 4d00h    ; press right
  je kright
  
  jmp short lk0
  
kup:
  cmp sdct, 0010b  ; direction conflict
  je lk0
  mov sdct, 0001b  ; set direction
  jmp short lk0

kdown:
  cmp sdct, 0001b
  je lk0
  mov sdct, 0010b
  jmp short lk0

kleft:
  cmp sdct, 1000b
  je lk0
  mov sdct, 0100b
  jmp short lk0

kright:
  cmp sdct, 0100b
  je lk0
  mov sdct, 1000b
  
lk0:
  pop ax
  ret

; # clear last snack body
; void -> void
clear_last:
  push ax
  push si
  
  mov ah, 0
  mov al, slen
  mov si, ax
  add si, si

  mov ax, body[si - 2] ; last body
  push ax
  mov ah, 00000000b
  mov al, ' '
  push ax
  call draw_char       ; clear

  pop si
  pop ax
  ret

; # update snack bodys
; void -> void
move_snack:
  push ax
  push cx
  push si

  mov ch, 0
  mov cl, slen
  dec cx
  
  mov ah, 0
  mov al, slen
  mov si, ax
  add si, si
ms0:  
  mov ax, body[si - 4]
  mov body[si - 2], ax
  sub si, 2
  loop ms0
  
  mov ax, body[0]     ; upd head
  
  cmp sdct, 0001b     ; up
  je up
  
  cmp sdct, 0010b     ; down
  je down
  
  cmp sdct, 0100b     ; left
  je left
  
  cmp sdct, 1000b     ; right
  je right
    
up:
  dec al
  jmp short uok

down:
  inc al
  jmp short uok

left:
  dec ah
  jmp short uok
    
right:
  inc ah
  jmp short uok

uok:
  mov body[0], ax

  pop si
  pop cx
  pop ax
  ret

; # draw snack to map
; void -> void
draw_snack:
  push cx
  push si
  push ax
  
  mov ch, 0
  mov cl, slen
  mov si, 0
ds0:
  mov ax, body[si]
  push ax
  mov ah, 01110000b
  mov al, ' '
  push ax
  call draw_char       ; draw body
  add si, 2
  loop ds0

  pop ax
  pop si
  pop cx
  ret

; # create snack
; fixed: snack size is 3
; void -> void
create_snack:
  push cx
  push si
  push ax
  
  mov sdct, 1000b ; set direct is right
  mov ah, 1
  mov al, 1
  
  mov slen, 2     ; set snack length
  mov ch, 0
  mov cl, slen
  mov si, 0
  mov ah, 6       ; set snack head x
  mov al, 4       ; set snack head y
c0:
  mov body[si], ax
  
  dec ah
  add si, 2
  loop c0
  
  pop ax
  pop si
  pop cx
  ret

; draw food to map
; void -> void
draw_food:
  push ax  
  mov ax, food
  
  push ax
  mov ah, 00101000b
  mov al, ' '
  push ax
  call draw_char   ; draw food
  
  pop ax
  ret

; # create a food
; fixed: map width and height
; void -> void
create_food:
  push ax
  push bx
  push cx
  push dx
  push si

re0:
  mov bx, 23
  push bx
  call rand        ; get x
  inc dx           ; range: 1-[23]
  mov ah, dl
  
  push bx
  call rand        ; get y
  inc dx
  mov al, dl
  
  mov ch, 0
  mov cl, slen
  mov si, 0
sb0:               ; for snack body
  cmp ax, body[si]
  je re0           ; conflict with body, create again
  add si, 2
  loop sb0
  
  mov food, ax     ; save food xy
  
  pop si
  pop dx
  pop cx
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
  
  cmp al, ' '
  jne jm0
  mov es:[si + 2], ax  ; for edge, double draw.
  
jm0:                ; for normal char
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
