		.text
		.global _start

_start:		b	getArgs

@ ===== Get argument and store options & file's name =====
getArgs:	ldr	r5, [sp]	@ argc value
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

		mov	r9, #3		@ iterator for getting filename
		ldr	r2, =file
getFileName:	ldr	r1, =args_buffer@ get file buffer
		ldrb	r0, [r1, r9]

		cmp	r0, #0
		beq	postArgs

		add	r8, r9, #16	@ iterator for copy filename to directory
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

@ ===== Main Loop for reading throught file =====
preLoop:	mov	r4, #0				@ main iterator
		mov	r5, #0				@ current line iterator
		mov	r9, #0				@ previous line iterator
		ldr	r6, =file_buffer		@ file buffer address
		ldr	r1, =curr_text			@ current text address

loop:		ldrb	r8, [r6, r4]			@ read character
		strb	r8, [r1, r5]			@ add store at current text

		add	r4, r4, #1			@ add iterator
		add	r5, r5, #1

		cmp	r8, #0				@ check if it is null
		beq	exit

		cmp	r8, #10				@ check if it is line feed
		beq	printLine

		b	loop

printLine:	bl	_printPrev
		bl	printPrev			@ debug : print what is on the line
		bl	_printCurr
		bl	printCurr

		@ add compare string

		@ == copy string ==
		ldr	r2, =prev_text			@ previous text address
		mov	r9, #0				@ reset previous line iterator
		bl	copyLoop

		mov	r5, #0				@ reset line iterator
		b	loop

@ === copy current line to previous line ===
copyLoop:	cmp	r5, r9
		beq	endCopyLoop

		ldrb	r8, [r1, r9]			@ load current char
		strb	r8, [r2, r9]			@ store at previous text

		add	r9, r9, #1			@ add iterator
		b	copyLoop

endCopyLoop:	mov	pc, lr

exit:		pop	{r4, lr}
		mov	r7, #1
		swi	0

@ =======================================================================
@ Component functions
@ =======================================================================

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

@ = debug : current line beautifully :) =
_printCurr:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ stdout
		mov	r2, #(curr_end-curr_msg)	@ length
		ldr	r1, =curr_msg
		swi	0
		mov	pc, lr

@ = debug : previous line beautifully :) =
_printPrev:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ stdout
		mov	r2, #(prev_end-prev_msg)	@ length
		ldr	r1, =prev_msg
		swi	0
		mov	pc, lr

@ = current line =
printCurr:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ stdout
		mov	r2, r5				@ string length
		ldr	r1, =curr_text			@ address
		swi	0
		mov	pc, lr

@ = previous line =
printPrev:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ stdout
		mov	r2, r9				@ string length
		ldr	r1, =prev_text			@ address
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
curr_msg:	.asciz	"Current Line : "
curr_end:
prev_msg:	.asciz	"Previous Line : "
prev_end:
errmsg:		.asciz	"open failed T_T"
errmsgend:
args:		.asciz	"n"
file:		.asciz	"/home/pi/uniq-like/test-1.txt"
file_end:
file_buffer:	.space	10000
file_eof:
payload:	.asciz  " "
curr_text:	.space	100
prev_text:	.space  100
