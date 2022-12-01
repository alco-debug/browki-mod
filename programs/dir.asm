BITS 16
ORG 32768

%include "mikedev.inc"

list_directory:
        mov cx, 0                       ; Counter

        mov ax, dirlist                 ; Get list of files on disk
        call os_get_file_list

        mov si, dirlist

.set_column:
        ; Put the cursor in the correct column.
        call os_get_cursor_pos

        mov ax, cx
        and al, 0x03
        mov bl, 20
        mul bl

        mov dl, al
        call os_move_cursor

        mov ah, 0Eh                     ; BIOS teletype function
.next_char:
        lodsb

        cmp al, ','
        je .next_filename

        cmp al, 0
        je .done

        int 10h
        jmp .next_char

.next_filename:
        inc cx

        mov ax, cx
        and ax, 03h

        cmp ax, 0                       ; New line every 4th filename.
        jne .set_column

        call os_print_newline
        jmp .set_column

.done:
        call os_print_newline
        ret

dirlist 	times 1024 db 0

