BITS 16
ORG 32768

%include "mikedev.inc"

del_file:
        call os_string_parse
        cmp ax, 0                       ; Was a filename provided?
        jne .filename_provided

        mov si, nofilename_msg          ; If not, show error message
        call os_print_string
        ret

.filename_provided:
        call os_remove_file
        jc .failure

        mov si, .success_msg
        call os_print_string
        mov si, ax
        call os_print_string
        call os_print_newline
        ret

.failure:
        mov si, .failure_msg
        call os_print_string
        ret


.success_msg    db 'Deleted file: ', 0
.failure_msg    db 'Could not delete file - does not exist or write protected', 0
nofilename_msg  db 'No filename or not enough filenames', 13, 10, 0
