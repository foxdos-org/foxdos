[org 0x500]
base equ $


mov sp, 0x7C00
xor ax, ax
push ax
push ax
pop es
pop ds
mov di, 0x500
mov cx, (dsize&0xFE)
cld
mov si, sp
repnz movsw
jmp 0:entry

entry:	mov bx, 0x7DBE
	mov cx, 4
.disk:	mov al, [bx]
	shl al, 1
	jc ldvbr
	add bx, 16
	dec cl
	jnz .disk
	int 18h
ldvbr:
	; https://twitter.com/mothcompute/status/1620626616325148672
	; should be mov dh, [bx+1]. but it is not
	mov dx, [bx]
	
	mov cx, [bx+2]
	mov di, 5
.loop:	push di
	mov bx, 0x7C00
	mov ax, 0x0201
	int 13h
	jnc chkvbr
	xor ax, ax
	int 13h
	pop di
	dec di
	jnz .loop
err:	int 18h
chkvbr:	mov bx, 0x7DFE
	cmp word [bx], 0xAA55
	jnz err
	jmp 0:0x7C00
dsize equ ($-base)|2

times 510 - ($-$$) db 0
dxr: dw 0xAA55
