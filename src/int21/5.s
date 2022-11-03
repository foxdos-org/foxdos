; 0x50 - 0x5F

; AH = 54h
; get disk verify flag
; inputs:
; 	none
; outputs:
; 	AL: 0 if off, 1 if on
getverify:
	mov al, [verify]
	ret
