; 0x20 - 0x2F

; AH = 0x25
; set interrupt vector
; inputs:
; 	AL: interrupt number
; 	DS:DX: new interrupt handler
; outputs:
; 	none
setint:
	pusha
	xor ah, ah
	shl ax, 2
	mov di, ax
	xor ax, ax
	push es
	mov es, ax
	mov word es:[di], dx
	mov word es:[di+2], ds
	pop es
	popa
	ret

; AH = 0x2C
; read system time from the CMOS
; inputs:
; 	none
; outputs:
; 	CH: hours
; 	CL: minutes
; 	DH: seconds
gettime:
	push ax
	xor dl, dl

	mov al, dl ; seconds
	call rdcmos
	mov dh, al

	mov al, 2h ; minutes
	call rdcmos
	mov cl, al

	mov al, 4h ; hours
	call rdcmos
	mov ch, al

	shl al, 1 ; adjust for 12 hour time
	jnc .end
	add ch, 12

.end:	pop ax
	ret

; AH = 0x2D
; set system time in the CMOS
; inputs:
; 	CH: hours
; 	CL: minutes
; 	DH: seconds
; outputs:
; 	none
settime:
	push bx
	mov bl, ch
	mov bh, 0x4
	call wrcmos
	mov bl, cl
	shr bh, 1
	call wrcmos
	mov bl, dh
	cmp dl, 50 ; rtc cannot hold hundredths of a second so we round
	jng .f
	inc bl
.f:	xor bh, bh
	call wrcmos
	xor al, al ; it probably succeeded, its fine. TODO: am i missing return codes anywhere else
	pop bx
	ret

; AH = 0x2E
; set disk verify flag
; inputs:
; 	AL: 0 if off, 1 if on
; outputs:
; 	none
setverify:
	mov [verify], al
	ret
