		.text
		.global _start

_start:		b	getArgs

@ ===== Get argument and store options & file's name =====
getArgs:	ldr	r5, [sp]	@ argc value :: length of arguments and also used as input flag mode
		mov	r8, #8		@ argc address
		ldr	r4, [sp, r8]

		cmp	r5, #1		@ no parameter >> goto stdin
		beq	stdinArg

		cmp	r5, #2		@ check flag as 1 argument via console
		beq	get1Arg

		cmp	r5, #3		@ check flag as 2 arguments via console
		beq	get2Args

@ ===== Alternatives :: get arguments through stdin =====
stdinArg:	bl	printMark	@ print console mark for receive arguments
		bl	getStdinArg	@ receive arguments via stdin

		ldr	r0, =args_buffer@ argument buffer
		ldrb	r1, [r0, #2]

		cmp	r1, #32		@ check space
		beq	std2Arg		@ set flag before process argument
		mov	r5, #4		@ set flag as 1 argument via stdin
		b	preFile1Arg

get1Arg:	mov	r1, r4		@ == receive 1 parameter
		mov	r8, #0
		bl	strlen

		b	preFile1Arg

get2Args:	mov	r1, r4		@ == receive 2 parameters
		mov	r8, #0		@ iterator for argument's buffer
		bl	strlen		@ read

		add	r4, r4, r0	@ shifting address
		add	r4, r4, #1
		mov	r1, r4
		bl	strlen		@ read

		b	assignArg

@ ===== Argument processing =====
std2Arg:	mov	r5, #5		@ set flag as 2 argument via stdin

assignArg:	ldr	r1, =args_buffer
		ldrb	r1, [r1, #1]

		ldr	r0, =args
		strb	r1, [r0, #0]

		b	preFile2Args

preFile1Arg:	mov	r9, #0		@ set offset/iterator to directory position
		ldr	r2, =file	@ file directory address
		b	getFileName

preFile2Args:	mov	r9, #3		@ set offset/iterator to directory position
		ldr	r2, =file	@ file directory address
		b	getFileName

getFileName:	ldr	r1, =args_buffer@ get file buffer
		ldrb	r0, [r1, r9]

		cmp	r0, #0		@ open file when out of string
		beq	open

		cmp	r5, #3		@ check for parameter type
		beq	shiftPos2Args	@ for two arguments (r5 = 3 or 5)
		cmp	r5, #5		@ seperate condition for reading
		beq	shiftPos2Args

		b	shiftPos1Arg

shiftPos1Arg:	add	r8, r9, #19	@ shifting position
		b	checkLF

shiftPos2Args:	add	r8, r9, #16	@ shifting position

checkLF:	cmp	r0, #10		@ check line feed
		beq	open

afterShift:	strb	r0, [r2, r8]	@ copy to directory location
		add	r9, r9, #1	@ add up iterator

		b	getFileName

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

		cmp	r1, #100
		beq	DflagEQ

lineNEQ:	bl	getOption

		cmp	r1, #117
		beq	UflagNEQ

		cmp	r1, #110
		beq	NflagNEQ

		cmp	r1, #100
		beq	DflagNEQ

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

@ ===== Exit program =====
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
		mov	r0, #0				@ stdin via keyboard
		mov	r2, #100			@ read characters
		ldr	r1, =args_buffer
		swi	0
		mov	pc, lr

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

@ == -d option :: equal ==
DflagEQ:	add	r12, r12, #1			@ add line count
		cmp	r12, #2
		beq	printRes
		b	preCopy

@ == -d option :: unequal ==
DflagNEQ:	mov	r12, #1
		b	preCopy


@ == print normal logic result (current text)
printRes:	bl	printCurr
		b	preCopy

@ == print previous text result
printRes2:	bl	printPrev
		mov	r12, #1

		add	r3, r4, #1			@ looking forward that it is end of file
		ldrb	r3, [r6, r3]
		cmp	r3, #0
		beq	printRes

		b	preCopy

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
markStdin:	.asciz	"> "
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
