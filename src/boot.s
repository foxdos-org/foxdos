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

times 510 - ($-$$) db 0
dw 0xAA55
