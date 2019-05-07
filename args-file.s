		.text
		.global _start

_start:		b	getArgs

@ ===== Get argument and store options & file's name =====
getArgs: 	ldr	r5, [sp]	@ argc value
		mov	r8, #8		@ argc address
		ldr	r4, [sp, r8]

		cmp	r4, #0
		beq	exit

		mov	r1, r4
		mov	r8, #0		@ iterator for argument's buffer
		bl	strlen		@ read

		add	r4, r4, r0	@ shifting address
		add	r4, r4, #1
		mov	r1, r4
		bl	strlen		@ read

@ ===== Argument processing =====
assignArg:	ldr	r1, =args_buffer
		ldrb	r1, [r1, #1]

		ldr	r0, =args
		strb	r1, [r0, #0]

		bl	_printOption

		mov	r9, #2		@ iterator for getting filename
		ldr	r2, =file
getFileName:	ldr	r1, =args_buffer@ get file buffer
		ldrb	r0, [r1, r9]

		cmp	r0, #0
		beq	postArgs

		add	r8, r9, #17	@ iterator for copy filename to directory
		strb	r0, [r2, r8]
		add	r9, r9, #1

		b	getFileName

postArgs:	bl	_printFileName

@ ===== Open & read file =====
open:		push	{r4, lr}
		ldr	r0, =file	@ file location
		mov	r1, #0x42	@ r/w
		mov	r2, #384	@ = 600 (octal)
		mov	r7, #5		@ open
		svc	0

		cmp	r0, #-1		@ check error
		beq	openErr

		mov	r4, r0		@ save file descriptor

		@ == lseek ==
		mov	r0, r4		@ file descriptor
		mov	r1, #0		@ position
		mov	r2, #0		@ seek_set : from start
		mov	r7, #19
		svc	0

		@ == load file ==
		mov	r0, r4		@ file descriptor
		ldr	r1, =file_buffer@ address
		mov	r2, #10000	@ size
		mov	r7, #3		@ load
		svc	0

		@ == close file ==
		mov	r7, #6
		svc	0
		mov	r0, r4		@ return file descriptor

exit:		pop	{r4, lr}
		mov	r7, #1
		swi	0

_write:		push 	{r0-r7}
		mov	r7, #4		@ syscall number
		mov	r0, #1		@ stdout is monitor
		mov	r1, r4 		@ string located
		swi	0
		pop	{r0-r7}
		mov	pc, lr

_writeBuffer:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ stdout
		mov	r2, #(args_eof-args_buffer)	@ string length
		ldr	r1, =args_buffer		@ address
		swi	0
		mov	pc, lr

_printOption:	mov	r7, #4		@ syscall number
		mov	r0, #1		@ stdout
		mov	r2, #2		@ length
		ldr	r1, =args	@ address
		swi	0
		mov	pc, lr

_printFileName:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ stdout
		mov	r2, #(file_end-file)		@ strign length
		ldr	r1, =file
		swi	0
		mov	pc, lr

@ ===== Find string length and get string =====
strlen:		mov	r0, #0

l2:		ldr	r3, =args_buffer
		ldrb	r2, [r1], #1	@ get current char and advance
		strb	r2, [r3, r8]
		cmp	r2, #0		@ check if it is end of string
		addne	r0, #1
		add	r8, r8, #1
		bne	l2
		mov	pc, lr

@ == prompt error from opening file ==
openErr:	mov	r4, r0
		mov	r0, #1
		ldr	r1, =errmsg
		mov	r2, #(errmsgend-errmsg)
		mov	r7, #4
		svc	0

		mov	r0, r4
		b	exit

		.data
args_buffer:	.space	100
args_eof:
errmsg:		.asciz	"open failed T_T"
errmsgend:
args:		.asciz	"n"
file:		.asciz	"/home/pi/uniq-like/test-1.txt"
file_end:
file_buffer:	.space	10000
file_eof:
payload:	.space 	1
