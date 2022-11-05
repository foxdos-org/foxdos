; foxdos boot sector

%include "config.s"

[org 0x7C00]
[bits 16]

mov ax, KERNEL_SEG
push ax ; setup for ds
mov es, ax
mov gs, ax
mov fs, ax

xor cx, cx
mov ds, cx
mov word [0x21*4], 3 ; see kjmp in kernel.s
mov word [0x21*4+2], ax

mov ax, 0x200 | NUMSEG
mov cl, ah
xor dh, dh
int 13h

; 64kb stack
pop ds
mov ax, STACK_SEG
mov ss, ax
xor sp, sp
mov ax, sp
not sp

; kernel time(?)
push ds
push ax
retf

; TODO filesystem and reserve space for mbr partition table

times 446 - ($-$$) db 0
times bootpart*16 db 0

; some programs do not accept values with bits 0-6 set
status db 0

; chs offset :/
off_head db 0
off_sector_cyl db 0
off_cyl_low db 0

; https://en.wikipedia.org/wiki/Partition_type
type db 0

; chs... end?
end_head db 0
end_sector_cyl db 0
end_cyl_low db 0

; lba :)
lba_off dd 0
lba_len dd 0
	
times 510 - ($-$$) db 0
dw 0xAA55
