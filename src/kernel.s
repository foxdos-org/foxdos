%include "config.s"

kernel_entry: ; MUST be a short jump due to loader config
	mov si, hello_string
	mov bl, 0x70
	call print_string
	jmp $

hello_string: db "hello world!", 13, 10, '$'

%include "int21.s"
%include "vga.s"
