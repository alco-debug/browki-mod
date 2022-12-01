BITS 16
ORG 32768

%include "mikedev.inc"

ren_file:
        call os_string_parse

        cmp bx, 0                       ; Were two filenames provided?
        jne .filename_provided

        mov si, nofilename_msg          ; If not, show error message
        call os_print_string
        ret

.filename_provided:
        mov cx, ax                      ; Store first filename temporarily
        mov ax, bx                      ; Get destination
        call os_file_exists             ; Check to see if it exists
        jnc .already_exists

        mov ax, cx                      ; Get first filename back
        call os_rename_file
        jc .failure

        mov si, .success_msg
        call os_print_string
        ret

.already_exists:
        mov si, exists_msg
        call os_print_string
        ret

.failure:
        mov si, .failure_msg
        call os_print_string
        ret

        .success_msg    db 'File renamed successfully', 0
        .failure_msg    db 'Operation failed - file not found or invalid filename', 0

nofilename_msg          db 'No filename or not enough filenames', 13, 10, 0
exists_msg              db 'Target file already exists!', 13, 10, 0
