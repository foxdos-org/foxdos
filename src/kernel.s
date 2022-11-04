%include "config.s"

[map symbols kernel.map]

kjmp: ; MUST be a jmp due to loader config
	jmp kernel_entry
%include "int21/int21.s"

kernel_entry:
	mov si, hello_string
	mov bl, 0x70
	call print_string

	mov ah, 0x2
	mov dl, '!'
	int 0x21

	jmp $

hello_string: db "hello world!", 13, 10, '$'

%include "vga.s"
