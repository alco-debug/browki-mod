BITS 16
ORG 32768

%include "mikedev.inc"

size_file:
        call os_string_parse
        cmp ax, 0                       ; Was a filename provided?
        jne .filename_provided

        mov si, nofilename_msg          ; If not, show error message
        call os_print_string
        ret

.filename_provided:
        call os_get_file_size
        jc .failure

        mov si, .size_msg
        call os_print_string

        mov ax, bx
        call os_int_to_string
        mov si, ax
        call os_print_string
        call os_print_newline
        ret


.failure:
        mov si, notfound_msg
        call os_print_string
        ret


        .size_msg       db 'Size (in bytes) is: ', 0

nofilename_msg          db 'No filename or not enough filenames', 13, 10, 0
notfound_msg            db 'File not found', 13, 10, 0
