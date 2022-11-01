; mothdos boot sector. should load kernel into segment 0x50 at 0x00. max size
; would be 64k but i doubt a dos needs more than that. stack is placed at
; 0x10500. i would suggest changing this to load the kernel into extended
; a20-gate memory so as not to overwrite the boot sector with larger kernels
; but i will leave that for you to do. code is public domain as always. i
; have not tested any of this so your mileage using it may vary

%include "config.s"

[org 0x7C00]
[bits 16]

mov ax, K_ADDR << 4
push ax ; setup for ds
mov es, ax
mov gs, ax
mov fs, ax

xor bx, bx
mov ds, bx
mov word [0x21*4], 2 ; see kernel_entry
mov word [0x21*4+2], ax
pop ds

mov ax, 0x200 | NUMSEG
mov cl, 2
xor dh, dh
int 13h

; 64kb stack
mov ax, STACK_SEG
mov ss, ax
xor sp, sp
mov ax, sp
not sp

; kernel time(?)
push ds
push ax
retf

; TODO we have lots of space for init code here

times 510 - ($-$$) db 0
dw 0xAA55
