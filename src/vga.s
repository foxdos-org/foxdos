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
