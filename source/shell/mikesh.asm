; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2019 MikeOS Developers -- see doc/LICENSE.TXT
;
; COMMAND LINE INTERFACE
; ==================================================================
; IF AX=0x1234 THEN THE FIRST COMMAND WILL BE EXECUTED NOT FROM
; USER INPUT BUT FROM SI REGISTER
BITS 16
ORG 23552

%include "mikedev.inc"



command_line:
	call os_clear_screen

	push si				; Preserve SI

	mov si, version_msg
	call os_print_string
	mov si, help_text
	call os_print_string

get_cmd:				; Main processing loop
	mov di, command			; Clear single command buffer
	mov cx, 32
	rep stosb

	cmp ax, 1234h
	jne .from_keyboard

.from_si:
	pop si				; Pop original SI
	mov di, input
	call os_string_copy
	jmp command_exec

.from_keyboard:
	pop si				; Pop for the purpose of not garbaging the stack
	mov si, prompt
	call os_print_string


	mov ax, input			; Get command string from user
	mov bx, 64
	call os_input_string

	call os_print_newline

	mov ax, input			; Remove trailing spaces
	call os_string_chomp

	mov si, input			; If just enter pressed, prompt again
	cmp byte [si], 0
	je get_cmd

command_exec:
	mov si, input			; Separate out the individual command
	mov al, ' '
	call os_string_tokenize

	mov word [param_list], di	; Store location of full parameters

	mov si, input			; Store copy of command for later modifications
	mov di, command
	call os_string_copy



	; First, let's check to see if it's an internal command...

	mov ax, input
	call os_string_uppercase

	mov si, input

	mov di, exit_string		; 'EXIT' entered?
	call os_string_compare
	jc near exit

	mov di, help_string		; 'HELP' entered?
	call os_string_compare
	jc near print_help

	mov di, ver_string		; 'VER' entered?
	call os_string_compare
	jc near print_version


	; If the user hasn't entered any of the above commands, then we
	; need to check for an executable file -- .BIN, and the
	; user may not have provided the extension

	mov ax, command
	call os_string_uppercase
	call os_string_length


	; If the user has entered, say, MEGACOOL.BIN, we want to find that .BIN
	; bit, so we get the length of the command, go four characters back to
	; the full stop, and start searching from there

	mov si, command
	add si, ax

	sub si, 4

	mov di, bin_extension		; Is there a .BIN extension?
	call os_string_compare
	jc bin_file

	jmp no_extension


bin_file:
	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

execute_bin:
	mov ax, 0			; Clear all registers
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov word si, [param_list]
	mov di, 0

	call 32768			; Call the external program

	call os_print_newline

	jmp get_cmd			; When program has finished, start again


no_extension:
	mov ax, command
	call os_string_length

	mov si, command
	add si, ax

	mov byte [si], '.'
	mov byte [si+1], 'B'
	mov byte [si+2], 'I'
	mov byte [si+3], 'N'
	mov byte [si+4], 0

	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

	jmp execute_bin

total_fail:
	mov si, invalid_msg
	call os_print_string

	jmp get_cmd

; ------------------------------------------------------------------

print_help:
	mov si, help_text
	call os_print_string
	jmp get_cmd
; ------------------------------------------------------------------

print_version:
	mov si, version_msg
	call os_print_string
	jmp get_cmd

; =====================================================================

exit:
	ret


; =====================================================================

	input			times 64 db 0
	command			times 32 db 0


	param_list		dw 0

	bin_extension		db '.BIN', 0

	prompt			db '# ', 0


	version_msg             db 'MikeOS ', MIKEOS_VER, 13, 10, 0
	help_text		db 'Commands: DIR, LS, COPY, REN, DEL, CAT, SIZE, CLS, HELP, TIME, DATE, VER, EXIT', 13, 10, 0
	invalid_msg		db 'No such command or program', 13, 10, 0

	exit_string		db 'EXIT', 0
	help_string		db 'HELP', 0
	ver_string		db 'VER', 0


; ==================================================================

