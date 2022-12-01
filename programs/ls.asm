BITS 16
ORG 32768

%include "mikedev.inc"
%include "mikedisk.inc"

ParaPerEntry    equ 2                   ; 32 bytes/entry => 2 paragraphs
disk_buffer	equ 24576

dir_list:
        push es
        pusha

        call disk_read_root_dir
        jnc .cont1
        mov si, .readfail_msg
        call os_print_string
        jmp short .done

  .cont1:
;       mov di, bx                      ; ES:DI points to directory buffer
        mov di, disk_buffer             ; ES:DI points to directory buffer

  .outer_loop:
        mov si, .header_msg
        call os_print_string
        mov cx, 20

  .page_loop:
        mov al, [es:di+11]              ; get attributes
        cmp al, 0x0f                    ; Win marker
        je .next_entry

        test al, 0x18                   ; directory or volume label => skip
        jnz .next_entry

        mov al, [es:di]                 ; first char of name
        cmp al, 0                       ; first unused, should be unused here to end
        je .done

        cmp al, 0x5e                    ; skip deleted
        je .next_entry

        cmp al, ' '                     ; skip if starts with space or control (Win UTF-8?)
        jle .next_entry

        cmp al, '~'                     ; skip if not normal 7-bit ASCII
        jae .next_entry

        cmp al, '.'                     ; skip if '.' or '..'
        je .next_entry

        call dir_entry_dump             ; ES:DI points to entry
        dec cx

  .next_entry:
        mov dx, es
        add dx, ParaPerEntry
        mov es, dx

        cmp cx, 0
        jne .page_loop

  .cont2:
        mov si, .footer_msg
        call os_print_string
        call os_wait_for_key
        cmp al, 27                      ; was key <esc>?
        je .done
        call os_clear_screen
        jmp .outer_loop

  .done:
        call os_print_newline
        popa
        pop es
        ret


        .readfail_msg   db 'Unable to read disk directory', 0
        .header_msg     db '    Name         attr         created          last write      first     bytes', 13, 10, 0
        .footer_msg     db 'Press key for next page', 0


; ---------------------------------------------------------------------

; listing helper subroutines



; ------------------------------------------------------------------

; dir_entry_dump -- print out the contents of a directory entry

;   output must correspond to header (above)

; IN: ES:DI = points to directory entry

; OUT: no changes



dir_entry_dump:

	pusha



	call type_name

	call os_get_cursor_pos		; line up columns

	mov dl, 15

	call os_move_cursor



	mov bh, [es:di+11]		; display attributes

	mov ax, 0x0e2e			; '.'

	test bh, 0x80			; reserved (should not be set)

	jz .attr1

	mov al, '*'

  .attr1:

	int 10h

	mov ax, 0x0e2e

	test bh, 0x40			; internal only (should not be set)

	jz .attr2

	mov al, '*'

  .attr2:

	int 10h

	mov ax, 0x0e2e

	test bh, 0x20

	jz .attr3

	mov al, 'A'			; archive

  .attr3:

	int 10h

	mov ax, 0x0e2e

	test bh, 0x10

	jz .attr4

	mov al, 'D'			; subdirectory

  .attr4:

	int 10h

	mov ax, 0x0e2e

	test bh, 8

	jz .attr5

	mov al, 'V'			; volume ID

  .attr5:

	int 10h

	mov ax, 0x0e2e

	test bh, 4

	jz .attr6

	mov al, 'S'			; system

  .attr6:

	int 10h

	mov ax, 0x0e2e

	test bh, 2

	jz .attr7

	mov al, 'H'			; hidden

  .attr7:

	int 10h

	mov ax, 0x0e2e

	test bh, 1

	jz .attr8

	mov al, 'R'			; read only

  .attr8:

	int 10h

	call os_print_space

	call os_print_space		; at column 25?



	mov dx, [es:di+16]		; created date & time (US and 24-hr format)

	call type_date

	call os_print_space

	mov dx, [es:di+14]

	call type_time

	call os_print_space

	call os_print_space		; at column 44?



	mov dx, [es:di+24]		; last written date & time (US and 24-hr format)

	call type_date

	call os_print_space

	mov dx, [es:di+22]

	call type_time			; at column 61?



	mov ax, [es:di+26]		; starting cluster

	call os_int_to_string

	mov si, ax

	call os_string_length

	neg ax

	add ax, 7			; 2 space separation + 5 characters, max.

	mov cx, ax

	jle .cluster_left

  .loop1:

	call os_print_space

	loop .loop1

  .cluster_left:

	call os_print_string



	mov dx, [es:di+30]		; file size (bytes)

	mov ax, [es:di+28]

	push es

	push ds

	pop es				; ES = DS = program seg

	push di

	mov bx, 10

	mov di, .number

	call os_long_int_to_string

	mov si, di

	mov ax, di

	call os_string_length

	neg ax

	add ax, 10			; 2 space separation + 8 characters, max.

	mov cx, ax

	jle .size_left

  .loop2:

	call os_print_space

	loop .loop2

  .size_left:

	call os_print_string

	call os_print_newline

	pop di

	pop es				; ES = directory seg



	popa

	ret



	.number		times 13 db 0



; ---------------------------------------------------------------------

; Type directory format time and print in 24-hr format (hh:mm:ss)

; There is a normal 2 second granularity

; IN: DX = time number

type_time:

	pusha



	mov ax, dx

	shr ax, 11			; 11 (start in word)

	cmp al, 10			; always 'hh'

	jae .hh

	push ax

	mov ax, 0x0e30			; '0'

	int 10h

	pop ax

  .hh:

	call os_int_to_string

	mov si, ax

	call os_print_string

	mov ax, 0x0e3a			; ':'

	int 10h



	mov ax, dx

	shr ax, 5			; 5 bits for seconds/2

	and ax, 0x3f			; 6 bits for minutes

	cmp al, 10

	jae .mm

	push ax

	mov ax, 0x0e30

	int 10h

	pop ax

  .mm:

	call os_int_to_string

	mov si, ax

	call os_print_string

	mov ax, 0x0e3a

	int 10h



	mov ax, dx

	and ax, 0x1f			; 5 bits for seconds/2

	shl ax, 1

	cmp al, 10

	jae .ss

	push ax

	mov ax, 0x0e30

	int 10h

	pop ax

  .ss:

	call os_int_to_string

	mov si, ax

	call os_print_string



	popa

	ret



; DOS format directory entry

; IN: DX = date number

; Uses USA date output format mm/dd/yy

type_date:

	pusha

	mov ax, dx		; separate out month

	shr ax, 5

	and ax, 0x0F

	cmp al, 1

	jl .mon_00

	cmp al, 12

	jbe .month

  .mon_00:

	mov al, 0

  .month:

	cmp al,10		; always 'mm'

	jge .mm

	push ax

	mov ax, 0x0e30

	int 10h

	pop ax

  .mm:

	call os_int_to_string

	mov si, ax

	call os_print_string

	mov ax, 0x0e2f		; '/'

	int 10h



	mov ax,dx		; separate out day

	and ax,0x1F

	cmp al, 10		; always 'dd'

	jae .dd

	push ax

	mov ax, 0x0e30

	int 10h

	pop ax

  .dd:

	call os_int_to_string

	mov si, ax

	call os_print_string

	mov ax, 0x0e2f

	int 10h



	mov ax,dx		; separate out year

	shr ax,9

	and ax,0x3F

	add ax,1980

	xor dx, dx

	mov bx, 100

	div bx

	mov ax, dx

	cmp al, 10

	jae .yy

	push ax

	mov ax, 0x0e30

	int 10h

	pop ax

  .yy:

	call os_int_to_string

	mov si, ax

	call os_print_string



	popa

	ret



; type a DOS format (short, 8.3) file name

; based on ASCII-7 file string (no UTF)

; allows a few more characters then PCDOS (ignores control, space, <del> and graphics)

; IN: ES:DI points to name in directory entry

type_name:

	pusha

	mov bx, di

	mov cx, 8

	add bx, cx		; point to extension



  .name_str1:

	mov al, [es:di]

	inc di

	cmp al,' '		; must be between '!' and '~'

	je .q_extend		; <space> is an unused slot

	jle .name_end		; 0 = entry not used, control not allowed

	cmp al,'~'		; no <del>, bit 8 set on delete (should be ASCII-7)

	ja .name_end

	mov ah, 0x0e

	int 10h

	loop .name_str1



  .q_extend:

	mov al,'.'		; output only if valid extension

	cmp byte [es:bx],' '	; space => no extension

	jle .name_end

	mov ah, 0x0e

	int 10h

	mov di, bx

	mov cx,3



  .name_str2:

	mov al, [es:di]

	inc di

	cmp al,' '		; must be between '!' and '~'

	jle .name_end

	cmp al,'~'		; no <del> or above

	ja .name_end

	mov ah, 0x0e

	int 10h

	loop .name_str2



  .name_end:

	popa

	ret
