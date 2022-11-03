; 0x40 - 0x4F

; AH = 4dh
; get return code
; inputs:
; 	none
; outputs:
; 	AH: termination type (0 = normal, 1 = control-C abort, 2 = critical error abort, 3 = terminate and stay resident)
; 	AL: return code
getret:
	xor ax, ax
	xchg [retcode], ax
	ret
