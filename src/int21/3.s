; 0x30 - 0x3F

; AH = 30h
; get the DOS version number
; inputs:
; 	none
; outputs:
; 	AL: major version
; 	AH: minor version
getver:
	mov ax, 8 ; if it is not zero indexed this indicates windows ME
	xor bx, bx ; update: what does that comment mean
	mov cx, bx
	ret

; AH = 35h
; get interrupt vector
; inputs:
; 	AL: interrupt number
; outputs:
; 	ES:BX: current interrupt handler
getint:
	push ds
	push di
	push ax
	xor ah, ah
	shl ax, 2
	mov di, ax
	xor ax, ax
	mov ds, ax
	pop ax
	mov word bx, [di]
	mov word es, [di+2]
	pop di
	pop ds
	ret
