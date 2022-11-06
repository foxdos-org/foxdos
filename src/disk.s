SECTOR_SEG  equ 0x0000
SECTOR_ADDR equ 0x7C00

; get and store drive parameters
; inputs:
; 	none
; outputs:
; 	none
disk_init:
	push es
	xor ax, ax
	mov es, ax ; ES:DI should be zero to prevent some BIOS bugs apparently
	mov di, ax
	mov ah, 0x08
	mov dl, byte [bootdisk]
	int 0x13
	inc dh
	movzx bx, dh
	mov word [bootdisk_heads], bx
	and cx, 63
	mov word [bootdisk_sectorspt], cx
	pop es
	ret

; read a sector into the sector buffer
; inputs:
; 	SI: LBA
; outputs:
; 	none
read_sector:
	push ax
	push bx
	push es
.retry:
	mov es, SECTOR_SEG
	mov bx, SECTOR_ADDR
	call lba2chs
	mov ax 0x0201
	int 0x13
	jc .retry
	pop es
	pop bx
	pop ax
	ret

; convert LBA addressing to CHS addressing
; these outputs can be fed directly into int 0x13, AH 0x02
; based on this StackOverflow answer:
; https://stackoverflow.com/questions/45434899/why-isnt-my-root-directory-being-loaded-fat12/45495410#45495410
; sector:   (LBA mod SPT) + 1
; head:     (LBA / SPT) mod heads
; cylinder: (LBA / SPT) / heads
; inputs:
; 	SI: LBA
; outputs:
; 	DH: head
; 	CH: cylinder
; 	CL: sector/cylinder
lba2chs:
    push ax
    mov ax, si
    xor dx, dx
    div word [bootdisk_sectorspt] ; LBA / SPT
    mov cl, dl
    inc cl                        ; CL = (LBA mod SPT) + 1
    xor dx, dx
    div word [bootdisk_heads]     ; (LBA / SPT) / heads
    mov dh, dl                    ; DH = (LBA / SPT) mod heads
    mov ch, al                    ; CH = (LBA / SPT) / heads
    shl ah, 6                     ; store upper 2 bits of 10-bit cylinder into...
    or cl, ah                     ; ...upper 2 bits of cector (CL)
    pop ax
    ret

bootdisk: db 0
bootdisk_heads: dw 0
bootdisk_sectorspt: dw 0
