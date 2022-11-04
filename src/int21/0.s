; 0x00 - 0x0F

; AH = 0x01
; read a character from stdin and print it to stdout
; inputs:
; 	none
; outputs:
; 	AL: character read from stdin
rdin_echo:
	push ax
	mov ah, 8
	int 0x21
	; TODO does echo go to stdout or to screen?
	pop ax
	ret
