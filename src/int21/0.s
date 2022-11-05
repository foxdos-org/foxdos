; 0x00 - 0x0F

; AH = 0x01
; read a character from stdin and print it to stdout
; inputs:
; 	none
; outputs:
; 	AL: character read from stdin
rdin_echo:
	mov ah, 8
	int 0x21
	; TODO does echo go to stdout or to screen?
	ret

; AH = 0x02
; write character to stdout
; inputs:
; 	DL: character
; outputs:
; 	AL: last character output
wrout:
	; TODO handle ^C and stuff
	; TODO handle stdout properly
	push bx
	cmp dl, 9
	jnz .print
	mov dl, ' ' ; "tabs are expanded to blanks"
.print:
	mov al, dl
	call print_character
	pop bx
	ret

; AH = 0x09
; write string to stdout
; inputs:
; 	DS:DX: pointer to '$'-terminated string
; outputs:
; 	AL: 0x24 ('$')
wrout_str:
	push si
	mov si, dx
	jmp .start_loop
.print_loop:
	mov dl, byte [si]
	call wrout
	inc si
.start_loop:
	cmp byte [si], '$'
	jnz .print_loop
	mov al, '$'
	pop si
	ret
