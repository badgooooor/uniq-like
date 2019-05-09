		.text
		.global _start

_start:		b	getArgs

@ ===== Get argument and store options & file's name =====
getArgs:	ldr	r5, [sp]	@ argc value
		mov	r8, #8		@ argc address
		ldr	r4, [sp, r8]

		cmp	r5, #1		@ use r5 for determined arguments and mode
		beq	stdinArg

		cmp	r5, #2
		beq	get1Args

		cmp	r5, #3
		beq	get2Args

@ ===== Alternatives :: get arguments through stdin =====
stdinArg:	bl	printMark
		bl	getStdinArg
		bl	_writeBuffer

		ldr	r0, =args_buffer
		ldrb	r1, [r0, #2]

		cmp	r1, #32
		beq	std2Arg
		mov	r5, #4		@ stdin with 1 argument
		b	preFile1Args

get1Args:	mov	r1, r4		@ == get single argument via cmd
		mov	r8, #0
		bl	strlen

		bl	_writeBuffer
		b	preFile1Args

get2Args:	mov	r1, r4		@ == get double argument via cmd
		mov	r8, #0		@ iterator for argument's buffer
		bl	strlen		@ read

		add	r4, r4, r0	@ shifting address
		add	r4, r4, #1
		mov	r1, r4
		bl	strlen		@ read

		bl	_writeBuffer
		b	assignArg

@ ===== Argument processing =====
std2Arg:	mov	r5, #5		@ stdin with 2 argument

assignArg:	ldr	r1, =args_buffer
		ldrb	r1, [r1, #1]

		ldr	r0, =args
		strb	r1, [r0, #0]

		bl	_printOption
		b	preFile2Args

preFile1Args:	mov	r9, #0
		ldr	r2, =file
		b	getFileName

preFile2Args:	mov	r9, #3		@ offset adder for directory
		ldr	r2, =file
		b	getFileName

getFileName:	ldr	r1, =args_buffer@ get file buffer
		ldrb	r0, [r1, r9]

		cmp	r0, #0
		beq	postArgs

		cmp	r5, #3		@ check mode for setting offset
		beq	shiftPos2Arg	@ for two arguments (3 and 5)
		cmp	r5, #5
		beq	shiftPos2Arg

		b	shiftPos1Arg	@ for one argument (2 and 4)

shiftPos1Arg:	add	r8, r9, #19
		b	checkMode4

shiftPos2Arg:	add	r8, r9, #16	@ iterator for copy filename to directory

checkMode4:	cmp	r0, #10		@ check carriage return
		beq	postArgs

afterShift:	strb	r0, [r2, r8]	@ copy to file directory
		add	r9, r9, #1	@ add iterator

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

@ ===== Read file buffer =====
		mov	r4, #0				@ iterator
		ldr	r6, =file_buffer		@ file buffer address
		ldr	r1, =payload

loop:		ldrb	r5, [r6, r4]			@ read char
		strb	r5, [r1, #0]

		cmp	r5, #0				@ check if it is null
		beq	exit

		bl	_printPayload

		add	r4, r4, #1			@ add iterator
		b	loop

exit:		pop	{r4, lr}
		mov	r7, #1
		swi	0

@ =======================================================================
@ Component functions
@ =======================================================================

@ = prompt for incoming argument =
printMark:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ stdout
		mov	r2, #2				@ string length
		ldr	r1, =markStdin			@ address
		swi	0
		mov	pc, lr

@ = argument input through stdin =
getStdinArg:	mov	r7, #3				@ syscall number
		mov	r0, #0				@ stdin is keyboard
		mov	r2, #100			@ read character
		ldr	r1, =args_buffer
		swi	0
		mov	pc, lr

@ = debug : argument buffer =
_writeBuffer:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ stdout
		mov	r2, #(args_eof-args_buffer)	@ string length
		ldr	r1, =args_buffer		@ address
		swi	0
		mov	pc, lr

@ = debug : argument option =
_printOption:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ stdout
		mov	r2, #2				@ length
		ldr	r1, =args			@ address
		swi	0
		mov	pc, lr

@ = debug : argument file name =
_printFileName:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ stdout
		mov	r2, #(file_end-file)		@ strign length
		ldr	r1, =file			@ address
		swi	0
		mov	pc, lr

@ = debug : payload from file buffer =
_printPayload:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ stdout
		mov	r2, #2				@ length
		ldr	r1, =payload			@ address
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
markStdin:	.asciz	"> "
errmsg:		.asciz	"open failed T_T"
errmsgend:
args:		.asciz	"n"
file:		.asciz	"/home/pi/uniq-like/test-1.txt"
file_end:
file_buffer:	.space	10000
file_eof:
payload:	.asciz  " "
