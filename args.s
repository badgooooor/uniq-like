		.text
		.global _start

_start:		b	getArgs

getArgs: 	ldr	r5, [sp]	@ argc value
		mov	r8, #8		@ argc address
		ldr	r4, [sp, r8]

		cmp	r4, #0
		beq	_exit

		mov	r1, r4
		mov	r8, #0		@ iterator for argument's buffer
		bl	strlen		@ read

		add	r4, r4, r0	@ shifting address
		add	r4, r4, #1
		mov	r1, r4
		bl	strlen		@ read

		bl	_writeBuffer

_exit:		mov	r7, #1
		swi	0

_write:		push 	{r0-r7}
		mov	r7, #4		@ syscall number
		mov	r0, #1		@ stdout is monitor
		mov	r1, r4 		@ string located
		swi	0
		pop	{r0-r7}
		mov	pc, lr

_writeBuffer:	mov	r7, #4		@ syscall number
		mov	r0, #1		@ stdout
		mov	r2, #(args_eof-args_buffer)	@ string length
		ldr	r1, =args_buffer
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

		.data
args_buffer:	.space	100
args_eof:
