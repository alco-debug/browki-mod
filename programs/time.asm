BITS 16
ORG 32768

%include "mikedev.inc"

print_time:
        mov bx, tmp_string
        call os_get_time_string
        mov si, bx
        call os_print_string
        call os_print_newline
	ret

tmp_string	times 15 db 0
