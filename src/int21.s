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

get_retcode:; ah=4dh
	mov ax, [retcode]
	retf 

get_version:; ah=30h
	mov ax, 8 ; if it is not zero indexed this indicates windows ME
	xor bx, bx ; update: what does that comment mean
	mov cx, bx
	retf

getverify:; ah=54h
	mov al, [verify]
	retf

setverify:; ah=2eh
	mov [verify], al
	retf

getint:; ah=35h
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

setint:; ah=25h
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

rdcmos:; input in al. TODO handle bcd here to abstractt it from the kernel
	cli
	cmp al, 9 ; not rtc register, do not wait. if this function bugs out
	jg .rd    ; on a century boundary thats not on me. stop using dos
	xchg al, ah
.wait:	mov al, 0xA  ; msb specifies if rtc update is in progress
	out 0x70, al ; TODO https://wiki.osdev.org/CMOS#RTC_Update_In_Progress
	in al, 0x71
	shl al, 1
	jc .wait
	xchg al, ah
.rd:	out 0x70, al
	in al, 0x71
	sti
	ret

wrcmos:; register in bh, value in bl
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

gettime:; ah=2ch
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

settime:; ah=2dh
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
	xor al, al ; it probably succeeded, its fine. TODO am i missing return codes anywhere else
	pop bx
	iret
