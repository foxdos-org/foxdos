; print a string to the screen
; inputs:
; DS:SI: pointer to '$'-terminated string
; BL: attribute
; outputs:
; none
print_string:
	push ax
	push bx
	push cx
	push dx
	push bp
	push es

	; get cursor position in DX
	mov ah, 0x03
	mov bh, 0x00
	int 0x10

	; calculate string length by iterating over it until we reach '$'
	; this sucks but we have to do it because the bios expects to be passed the string length directly
	xor cx, cx
	push si
.size_loop:
	inc cx
	inc si
	cmp byte [si], '$'
	jnz .size_loop
	pop si
	mov bp, si

	; print string and update cursor position
	mov ax, ds
	mov es, ax
	mov ah, 0x13
	mov al, 0x01
	mov bh, 0x00
	int 0x10

	pop es
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	ret
