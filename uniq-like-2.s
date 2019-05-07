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

		mov	r9, #3		@ iterator for getting filename
		ldr	r2, =file
getFileName:	ldr	r1, =args_buffer@ get file buffer
		ldrb	r0, [r1, r9]

		cmp	r0, #0
		beq	open

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
		mov	r12, #1				@ line count (for same text streak)
		ldr	r6, =file_buffer		@ file buffer address
		ldr	r1, =curr_text			@ current text address

loop:		ldrb	r8, [r6, r4]			@ read character
		strb	r8, [r1, r5]			@ add store at current text

		add	r4, r4, #1			@ add iterator
		add	r5, r5, #1

		cmp	r8, #0				@ check if it is null
		beq	exit

		cmp	r8, #10				@ check if it is line feed
		beq	preCompare

		b	loop

@ === compare current & previous line ===
preCompare:	cmp	r9, r5				@ short cut by check length of both string
		bne	lineNEQ				@ branch to NEQ case
		mov	r11, #0				@ iterator for string comparison
		b	compareLoop

compareLoop:	ldr	r1, =curr_text			@ load current text addr
		ldrb	r8, [r1, r11]			@ load current char
		ldr	r1, =prev_text			@ load previous text addr
		ldrb	r10,[r1, r11]			@ load previous char

		cmp	r8, r10				@ compare character
		bne	lineNEQ				@ branch to NEQ case

		cmp	r9, r11				@ check end of string
		beq	lineEQ				@ branch to EQ case

		add	r11, r11, #1			@ add iterator
		b	compareLoop

@ === distribute to each option ===
getOption:	ldr	r1, =args
		ldrb	r1, [r1, #0]
		mov	pc, lr

lineEQ:		bl	getOption

		cmp	r1, #117
		beq	UflagEQ

		cmp	r1, #110
		beq	NflagEQ

lineNEQ:	bl	getOption

		cmp	r1, #117
		beq	UflagNEQ

		cmp	r1, #110
		beq	NflagNEQ

@ == copy current line to previous line ==
preCopy:	ldr	r1, =curr_text			@ current text address
		ldr	r2, =prev_text			@ previous text address
		mov	r9, #0				@ reset previous line iterator
		bl	copyLoop

		mov	r5, #0				@ reset line iterator
		b	loop

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

@ == -n option :: equal ==
NflagEQ:	b	preCopy

@ == -n option :: unequal ==
NflagNEQ:	b	printRes

@ == -u option :: equal ==
UflagEQ:	add	r12, r12, #1			@ add line count
		b	preCopy

@ == -u option :: unequal ==
UflagNEQ:	cmp	r12, #1
		beq	printRes2
		mov	r12, #1
		b	preCopy

@ == print normal logic result (current text)
printRes:	bl	printCurr
		b	preCopy

@ == print previous text result
printRes2:	bl	printPrev
		mov	r12, #1
		b	preCopy

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

@ = debug : prompt equal =
_promptEq:	bl	_printEQ
		b	_printLine

@ = debug : prompt unequal =
_promptNeq:	bl	_printNEQ
		b	_printLine

@ = debug : prompt unequal since string length =
_promptNel:	bl	_printNEL
		b	_printLine

@ = debug : prompt line =
_printLine:	bl	_printCurr
		bl	printCurr
		bl	_printPrev
		bl	printPrev
		b	preCopy

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

@ = debug : equal!! =
_printEQ:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ monitor
		mov	r2, #5				@ length
		ldr	r1, =eq_msg			@ address
		swi	0
		mov	pc, lr

@ = debug : not equal =
_printNEQ:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ monitor
		mov	r2, #6				@ length
		ldr	r1, =neq_msg			@ address
		swi	0
		mov	pc, lr

@ = debug : not equal from string length =
_printNEL:	mov	r7, #4				@ syscall number
		mov	r0, #1				@ monitor
		mov	r2, #6				@ length
		ldr	r1, =nel_msg
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
eq_msg:		.asciz	"[EQ] "
neq_msg:	.asciz	"[NEQ] "
nel_msg:	.asciz	"[NEL] "
errmsg:		.asciz	"open failed T_T"
errmsgend:
args:		.asciz	"n"
line_feed:	.asciz	"\n"
file:		.asciz	"/home/pi/uniq-like/          "
file_end:
file_buffer:	.space	10000
file_eof:
payload:	.asciz  " "
curr_text:	.space	100
prev_text:	.space  100
