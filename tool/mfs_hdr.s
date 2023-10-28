; TODO implement boot via chs for old bioses (even ones
; as new as 1996 lack support for lba via bios call)
[bits 16]
[org 0x7C00]

jmp entry
times 4 - ($-$$) db 0

; 16mb shown as example
db "MOTHFS",0
db 0
sz:	dd 32768	; 32768 * 512 = 16mb disk image
off:	dd 1		; immediately follows mbr
	db "mkmothfs",0,0,0,0,0,0,0
rsv:	db 127		; 64kb of boot code
abm:	dd 4096		; 16mb/(512*8)

entry:

	xor ax, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov sp, 0x7BFE	; 30kb stack until 0x500
	mov bp, sp
	push ax
	pop ds

	mov dx, 0x80	; change disk number to 80 because every bios is the worst
	push dx

	; enable a20 a few different ways
	in al, 0xEE

	; bios call
	mov ax, 0x2401	; l is real
	int 0x15

	; fast a20 gate
	in al, 0x92
	or al, 2
	out 0x92, al

	mov eax, [off]
	mov dword [dapw], eax

	; check for lba support
	mov ah, 0x41
	mov bx, 0x55AA
	int 0x13	; dl is drive number - mbr should pass this value
	jc .nde
	shr cx, 2	; wikipedia says bit 1 is disk packet support
	jnc .nde

	; load kernel flat binary into hma using lba
	pop dx
	mov ah, 0x42
	mov si, dap
	int 0x13

	; jump to FFFF:0010, the start of HMA. this limits the kernel
	; size to 65520 bytes but we are actually loading 496 bytes
	; less than that and even that should be more than enough for
	; foxdos and any more would probably blow up some garbage bios
	mov ax, 0xFFFF
	push ax
	mov ax, 16
	push ax
	retf
	
.nde:	mov eax, [sz]
	add eax, [off]
	cmp eax, 0xFB0400 ; max chs sectors
	jg $		; too big to use chs
	jmp $		; TODO load via chs

dap:	dw 0x10		; size of disk packet
	dw 127		; foxdos will always load 127 segments
	dw 16, 0xFFFF	; offset:segment to start of HMA - foxdos loads high
dapw:	dd 0, 0

times 510 - ($-$$) db 0
dw 0xAA55
