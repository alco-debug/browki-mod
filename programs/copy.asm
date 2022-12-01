BITS 16
ORG 32768

%include "mikedev.inc"

copy_file:
        call os_string_parse
        mov word [.tmp], bx

        cmp bx, 0                       ; Were two filenames provided?
        jne .filename_provided

        mov si, nofilename_msg          ; If not, show error message
        call os_print_string
        ret

.filename_provided:
        mov dx, ax                      ; Store first filename temporarily
        mov ax, bx
        call os_file_exists
        jnc .already_exists

        mov ax, dx
        mov cx, 32768
        call os_load_file
        jc .load_fail

        mov cx, bx
        mov bx, 32768
        mov word ax, [.tmp]
        call os_write_file
        jc .write_fail

        mov si, .success_msg
        call os_print_string
        ret

.load_fail:
        mov si, notfound_msg
        call os_print_string
        ret

.write_fail:
        mov si, writefail_msg
        call os_print_string
        ret

.already_exists:
        mov si, exists_msg
        call os_print_string
        ret


        .tmp            dw 0
        .success_msg    db 'File copied successfully', 13, 10, 0

nofilename_msg          db 'No filename or not enough filenames', 13, 10, 0
notfound_msg            db 'File not found', 13, 10, 0
writefail_msg           db 'Could not write file. Write protected or invalid filename?', 13, 10, 0
exists_msg              db 'Target file already exists!', 13, 10, 0
