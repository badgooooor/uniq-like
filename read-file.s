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

		@ test reading
		ldrb	r3, [r1, #0]
		ldrb	r5, [r1, #1]

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
file:		.asciz	"/home/pi/uniq-like/test-1.txt"
file_buffer:	.space	10000
file_eof:
