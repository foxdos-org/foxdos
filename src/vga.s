; print a character to the screen
; inputs:
; 	AL: ASCII character
; outputs:
; 	none
print_character:
	push ax
	push bx

	mov ah, 0x0E
	mov bh, 0x00
	int 0x10

	pop bx
	pop ax
	ret

; print a string to the screen
; inputs:
; 	DS:SI: pointer to '$'-terminated string
; 	BL: attribute
; outputs:
; 	none
print_string:
	pusha
	push es

	; get cursor position in DX
	mov ah, 0x03
	mov bh, 0x00
	int 0x10

	; calculate string length by iterating over it until we reach '$'
	; this sucks but we have to do it because the bios expects to be passed the string length directly
	xor cx, cx
	mov bp, si
	jmp .start_loop
.size_loop:
	inc cx
	inc si
.start_loop:
	cmp byte [si], '$'
	jnz .size_loop

	; print string and update cursor position
	mov ax, ds
	mov es, ax
	mov ax, 0x1301
	mov bh, 0x00
	int 0x10

	pop es
	popa
	ret

; print a u16 to the screen in hex
; inputs:
;	BX: value to print
; outputs:
;	none
print_hex:
	push ax
	push bx
	push cx
	mov cx, 4
.loop:
	mov al, bh
	shr al, 4
	cmp al, 9
	jng .num
	add al, 'A' - 10
	jmp .eloop
.num:
	add al, '0'
.eloop:
	call print_character
	shl bx, 4
	dec cx
	jnz .loop
	pop cx
	pop bx
	pop ax
	ret
