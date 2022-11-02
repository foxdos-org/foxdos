int21:
	push ds
	push cs
	pop ds
	; your handler goes here
	; you could maybe make a jump table that takes ah as input?
	pop ds
	iret

retcode: dw 0
verify: db 0

; AH = 4dh
; get return code
; inputs:
; none
; outputs:
; AH: termination type (0 = normal, 1 = control-C abort, 2 = critical error abort, 3 = terminate and stay resident)
; AL: return code
get_retcode:
	mov ax, [retcode]
	xor ax, ax
	mov [retcode], ax
	retf

; AH = 30h
; get the DOS version number
; inputs:
; none
; outputs:
; AL: major version
; AH: minor version
get_version:
	mov ax, 8 ; if it is not zero indexed this indicates windows ME
	xor bx, bx ; update: what does that comment mean
	mov cx, bx
	retf

; AH = 54h
; get disk verify flag
; inputs:
; none
; outputs:
; AL: 0 if off, 1 if on
getverify:
	mov al, [verify]
	retf

; AH = 2eh
; set disk verify flag
; inputs:
; AL: 0 if off, 1 if on
; outputs:
; none
setverify:
	mov [verify], al
	retf

; AH = 35h
; get interrupt vector
; inputs:
; AL: interrupt number
; outputs:
; ES:BX: current interrupt handler
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
	retf

; AH = 25h
; set interrupt vector
; inputs:
; AL: interrupt number
; DS:DX: new interrupt handler
; outputs:
; none
setint:
	pusha
	xor ah, ah
	shl ax, 2
	mov di, ax
	xor ax, ax
	push ds
	mov ds, ax
	mov word [di], dx
	mov word [di+2], ds
	pop ds
	popa
	retf

; read from CMOS register
; inputs:
; AL: register
; outputs:
; AL: value
; TODO: handle bcd here to abstract it from the kernel
rdcmos:
	cli
	cmp al, 9 ; not rtc register, do not wait. if this function bugs out
	jg .rd    ; on a century boundary thats not on me. stop using dos
	xchg al, ah
.wait:	mov al, 0xA  ; msb specifies if rtc update is in progress
	out 0x70, al ; TODO: https://wiki.osdev.org/CMOS#RTC_Update_In_Progress
	in al, 0x71
	shl al, 1
	jc .wait
	xchg al, ah
.rd:	out 0x70, al
	in al, 0x71
	sti
	ret

; write to CMOS register
; inputs:
; BL: value
; BH: register
; outputs:
; none
wrcmos:
	cli
	push ax
	mov al, bh
	or al, 0x80 ; nmi always on
	out 0x70, al
	mov al, bl
	out 0x71, al
	pop ax
	sti
	ret

; AH = 2ch
; read system time from the CMOS
; inputs:
; none
; outputs:
; CH: hours
; CL: minutes
; DH: seconds
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
	retf

; AH = 2dh
; set system time in the CMOS
; inputs:
; CH: hours
; CL: minutes
; DH: seconds
; outputs:
; none
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
	iret
