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
	mov al, dl
	mov bl, 0x70
	call print_character
	pop bx
	ret
