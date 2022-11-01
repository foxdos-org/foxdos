%include "config.s"
[org K_ADDR]
kernel_entry: ; MUST be a short jump due to loader config
	jmp $ ; TODO stub because os doesnt actually exist yet

%include "int21.s"
