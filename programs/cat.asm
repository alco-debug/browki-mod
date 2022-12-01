BITS 16
ORG 32768

%include "mikedev.inc"

LoadFileAt equ 33000

cat_file:
        call os_string_parse
        cmp ax, 0                       ; Was a filename provided?
        jne .filename_provided

        mov si, nofilename_msg          ; If not, show error message
        call os_print_string
        ret

.filename_provided:
        call os_file_exists             ; Check if file exists
        jc .not_found

        mov cx, LoadFileAt                   ; Load file into second 32K
        call os_load_file

        mov word [file_size], bx

        cmp bx, 0                       ; Nothing in the file?
        je finish

        mov si, LoadFileAt
        mov ah, 0Eh                     ; int 10h teletype function
.loop:
        lodsb                           ; Get byte from loaded file

        cmp al, 0Ah                     ; Move to start of line if we get a newline char
        jne .not_newline

        call os_get_cursor_pos
        mov dl, 0
        call os_move_cursor

.not_newline:
        int 10h                         ; Display it
        dec bx                          ; Count down file size
        cmp bx, 0                       ; End of file?
        jne .loop

        ret

.not_found:
        mov si, notfound_msg
        call os_print_string
finish:
        ret


notfound_msg            db 'File not found', 13, 10, 0
nofilename_msg          db 'No filename', 13, 10, 0
file_size		dw 0
