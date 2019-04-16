		.text
		.global _start

_start:		push 	{r4, lr}
		bl	open
		b	exit

open:		@ == open file ==
		ldr	r0, =file	@ file location
		mov	r1, #0x42	@ create r/w
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
		mov	r7, #6		@ close
		svc	0
		mov	r0, r4		@ return file descriptor

@ ===== Main loop for reading through file =====
preloop:	mov	r4, #0		@ main iterator
		mov	r5, #0		@ current line iterator
		mov	r9, #0		@ previous line iterator
		ldr	r6, =file_buffer	@ file buffer address.
		ldr	r1, =curr_text		@ current text address

loop:		ldrb	r8, [r6, r4]	@ read first char.
		strb	r8, [r1, r5]

		add	r4, r4, #1	@ add 1 to main iterator
		add	r5, r5, #1	@ add 1 to store iterator

		cmp	r8, #0		@ check if it is null
		beq	exit

		cmp	r8, #10		@ check if it is \n
		beq 	preCompare

		b	loop

		@ ==> add compare string ==
preCompare:	cmp	r9, r5		@ short cut by checking length before loop
		bne	promptNeq
		mov	r11, #0		@ iterator for compare string
		bl	compareLoop
		b	printLine

		@ == Compare Loop ==
compareLoop:	ldr	r1, =curr_text
		ldrb	r8, [r1, r11]	@ Load current string
		ldr	r1, =prev_text
		ldrb	r10,[r1, r11]	@ Load previous string

		cmp	r8, r10		@ compare character
		bne	promptNeq

		cmp	r9, r5		@ check if end of string
		beq	promptEq

		add	r11, r11, #1	@ add iterator
		b	compareLoop

		@ == DEBUG Prompt current string and previous string ==
printLine:	bl	printPrev
		bl	printCurr

		@ == Copy string ==
preCopy:	ldr	r2, =prev_text	@ previous text address
		mov	r9, #0		@ reset previous line iterator
		bl	copyLoop

		mov	r5, #0		@ reset line iterator
		b	loop

		@ ==  Copy current line to previous line ==
copyLoop:	cmp	r5, r9
		beq	endCopyLoop

		ldrb	r8, [r1, r9]	@ load text
		strb	r8, [r2, r9]	@ copy

		add	r9, r9, #1
		b	copyLoop

endCopyLoop:	mov	pc, lr

promptNeq:	bl	printNeq
		b	printLine

promptEq:	bl	printEq
		b	printLine

		@ == Print current line ==
printCurr:	mov	r7, #4		@ syscall
		mov	r0, #1		@ monitor
		mov	r2, #(curr_end-curr_msg)	@ string length
		ldr	r1, =curr_msg	@ string address
		swi	0

		mov	r7, #4		@ syscall
		mov	r0, #1		@ monitor
		mov	r2, r5		@ string length
		ldr	r1, =curr_text	@ string address
		swi	0

		bx	lr

		@ == Print previous line ==
printPrev:	mov	r7, #4		@ syscall
		mov	r0, #1		@ monitor
		mov	r2, #(prev_end-prev_msg)	@ string length
		ldr	r1, =prev_msg
		swi	0

		mov	r7, #4		@ syscall
		mov	r0, #1		@ monitor
		mov	r2, r9		@ string length
		ldr	r1, =prev_text	@ string address
		swi	0

		bx	lr

		@ == Prompt equal ==
printEq:	mov	r7, #4		@ syscall
		mov	r0, #1		@ monitor
		mov	r2, #(eq_end-eq_msg)		@ string length
		ldr	r1, =eq_msg
		swi	0

		bx	lr

		@ == Prompt not-equal ==
printNeq:	mov	r7, #4		@ syscall
		mov	r0, #1		@ monitor
		mov	r2, #(neq_end-neq_msg)		@ string length
		ldr	r1, =neq_msg
		swi	0

		bx	lr

exit:		pop	{r4, lr}
		mov	r7, #1		@ exit
		svc	0

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
errmsg:		.asciz	"open failed T_T"
errmsgend:
curr_msg:	.asciz	"Current Line : "
curr_end:
prev_msg:	.asciz	"Previous Line : "
prev_end:
eq_msg:		.asciz	"[EQ] "
eq_end:
neq_msg:	.asciz	"[NE] "
neq_end:
file:		.asciz	"/home/pi/uniq-like/test-1.txt"
file_buffer:	.space	10000
file_eof:
payload:	.space  1
curr_text:	.space	100
prev_text:	.space  100
