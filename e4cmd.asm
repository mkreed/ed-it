;========================================
;  Command Module for Model 4 ED-IT
;	copyright (c) 1995 by Mark Reed
;	all rights reserved
;========================================
;
;---------------------------------------------------------
;  BREAK:  <BREAK> display main menu routine
;	Entry:	None
;
BREAK	CALL	BLANK		; blank menu line
	LD	HL,MAIN$	; HL => main menu string
	CALL	DSPLY		; display it
	CALL	GETKEY		; wait for a keystroke
	LD	HL,MDISP$	; HL => dispatch table
	JP	DSPATCH		; interpret keystroke
;
;---------------------------------------------------------
;  CLEARDN:  <CLEAR><DOWN ARROW> bottom of file routine
;	Entry:	None
;
CLEARDN	LD	HL,(TXTEND)	; HL => text end
	LD	(TXTCSR),HL	; store as text cursor
	RET
;
;---------------------------------------------------------
;  CLEARLT:  <CLEAR><LEFT ARROW> backspace routine
;	Entry:	HL => text cursor
;
CLEARLT	DEC	HL		; back up one char
	LD	A,(HL)		; A => char at HL
	OR	A		; check A for zero
	RET	Z		; exit if A = 0
	LD	(TXTCSR),HL	; store new text cursor
	JP	CTRLD		; delete one char
;
;---------------------------------------------------------
;  CLEARRT:  <CLEAR><RIGHT ARROW> insert tab routine
;	Entry:	None
;
CLEARRT	LD	A,9		; A => tab char
	JP	INSERT		; insert it at TXTCSR
;
;---------------------------------------------------------
;  CLEARUP:  <CLEAR><UP ARROW> top of file routine
;	Entry:	None
;
CLEARUP	LD	HL,TEXT$	; HL => text start
	LD	(TXTCSR),HL	; store as text cursor
	LD	(FIRST),HL	; store as first char
	RET
;
;---------------------------------------------------------
;  CTRLB:  <CTRL><B> backward word routine
;	Entry:	None
;
CTRLB	DEC	HL		; back up ptr
	LD	A,(HL)		; A => current char
	OR	A		; check A for leading zero
	JR	Z,CTRLB20	; exit if A = 0
	CALL	DELIM		; check A for delimiter
	JR	Z,CTRLB		; loop back if found
CTRLB10	DEC	HL		; back up ptr
	LD	A,(HL)		; A => current char
	OR	A		; check A for leading zero
	JR	Z,CTRLB20	; exit if A = 0
	CALL	DELIM		; check A for delimiter
	JR	NZ,CTRLB10	; loop back if not found
CTRLB20	INC	HL		; advance past delimiter
	LD	(TXTCSR),HL	; store new text cursor
	RET
;
;---------------------------------------------------------
;  CTRLC:  <CTRL><C> control character routine
;	Entry:	None
;
CTRLC	CALL	CCHAR		; get control char
	OR	A		; check A for zero
	CALL	NZ,PUTCHAR	; put char if A <> 0
	RET
;
;---------------------------------------------------------
;  CTRLD:  <CTRL><D> delete character routine
;	Entry:	None
;
CTRLD	LD	BC,1		; delete one char
	JP	DLBLOCK		; do it
;
;---------------------------------------------------------
;  CTRLF:  <CTRL><F> forward word routine
;	Entry:	None
;
CTRLF	LD	A,(HL)		; A => current char
	OR	A		; check A for ending zero
	RET	Z		; exit if found
CTRLF10	INC	HL		; advance ptr
	LD	A,(HL)		; A => char at HL
	OR	A		; check A for ending zero
	JR	Z,CTRLF30	; go if A = 0
	CALL	DELIM		; check A for delimiter
	JR	NZ,CTRLF10	; loop back if not found
CTRLF20	INC	HL		; advance ptr
	LD	A,(HL)		; A => char at HL
	OR	A		; check A for ending zero
	JR	Z,CTRLF30	; go if A = 0
	CALL	DELIM		; check A for delimiter
	JR	Z,CTRLF20	; loop back if found
CTRLF30	LD	(TXTCSR),HL	; store new text cursor
	RET
;
;---------------------------------------------------------
;  CTRLL:  <CTRL><L> delete line routine
;	Entry:	None
;
CTRLL	CALL	ELINE		; move to end of line
	LD	HL,(TXTCSR)	; HL => text cursor
	LD	A,H		; check HL for zero
	OR	L
	JR	NZ,CTRLL10	; bypass if HL > 0
	LD	HL,(TXTEND)	; HL => file end
	DEC	HL		; adjust for deletion
CTRLL10	CALL	BLINE		; move to start of line
	LD	BC,(TXTCSR)	; BC => text cursor
	LD	A,B		; check BC for zero
	OR	C
	RET	Z		; exit if BC = 0
	OR	A		; reset carry flag
	SBC	HL,BC		; find the difference
	INC	HL		; adjust for deletion
	PUSH	HL		; BC => block length
	POP	BC
	JP	DLBLOCK		; delete a block
	RET
;
;---------------------------------------------------------
;  CTRLS:  <CTRL><S> delete spaces routine
;	Entry:	HL => text cursor
;
CTRLS	LD	BC,0		; BC => counter
CTRLS10	LD	A,(HL)		; A  => char at TXTCSR
	OR	A		; check for end of file
	JR	Z,CTRLS20	; go if end of file
	CP	' '		; check for space
	JR	NZ,CTRLS20	; go if no space
	INC	HL		; advance ptr
	INC	BC		; increase counter
	JR	CTRLS10		; loop back
CTRLS20	LD	A,B		; check BC for zero
	OR	C
	CALL	NZ,DLBLOCK	; delete block if BC > 0
	RET
;
;---------------------------------------------------------
;  CTRLW:  <CTRL><W> delete word routine
;	Entry:	HL => text cursor
;
CTRLW	LD	A,(HL)		; A => char at TXTCSR
	OR	A		; check A for zero
	RET	Z		; exit if A = 0
	PUSH	HL		; put text cursor in BC
	POP	BC
CTRLW10	INC	HL		; advance ptr
	LD	A,(HL)		; A => char at HL
	OR	A		; check A for zero
	JR	Z,CTRLW20	; go if found
	CP	CR		; check A for ENTER
	JR	Z,CTRLW20	; go if A = 13
	CALL	DELIM		; check for delimiter
	JR	NZ,CTRLW10	; loop back if not found
	INC	HL		; advance ptr
CTRLW20	OR	A		; reset carry flag
	SBC	HL,BC		; find the difference
	PUSH	HL		; BC => block length
	POP	BC
	JP	DLBLOCK		; delete the block
;
;---------------------------------------------------------
;  DNARROW:  <DOWN ARROW> routine
;	Entry:	None
;	Exit:	All registers are altered
;
DNARROW	LD	A,(ROWCOL)	; A => column number
	OR	A		; check A for zero
	JR	Z,DNARR10	; bypass if A = 0
	CALL	BLINE		; go to line start
DNARR10	LD	DE,(TXTCSR)	; DE => line start
	CALL	NLINE		; move to next line
	LD	A,D		; test DE for zero
	OR	E
	RET	Z		; exit if DE = 0
	LD	(TXTCSR),DE	; store new text cursor
	LD	A,(ROWCOL+1)	; A => row number
	CP	SCRBTM		; check for screen bottom
	JP	C,REALIGN	; exit if A < SCRBTM
	LD	HL,(LINE2)	; HL => second line start
	LD	(FIRST),HL	; store as first line
	JP	REALIGN		; realign cursor
;
;--------------------------------------------------------
;  ENTER:  <ENTER> character routine
;	Entry:	None
;
ENTER	LD	A,CR		; A => ENTER char
	JP	INSERT		; insert it at TXTCSR
;
;--------------------------------------------------------
;  FORMFD:  <CTRL><N> new page routine
;	Entry:	None
;
FORMFD	LD	A,12		; A => formfeed char
	JP	INSERT		; insert it at TXTCSR
;
;--------------------------------------------------------
;  LTARROW:  <LEFT ARROW> routine
;	Entry:	HL => text cursor
;
LTARROW	DEC	HL		; back up one char
	LD	A,(HL)		; A => char at TXTCSR - 1
	OR	A		; check A for zero
	RET	Z		; exit if A = 0
	LD	(TXTCSR),HL	; store new text cursor
	RET
;
;---------------------------------------------------------
;  RTARROW:  <RIGHT ARROW> routine
;	Entry:	HL => text cursor
;
RTARROW	LD	A,(HL)		; A => char at TXTCSR
	OR	A		; check A for zero
	RET	Z		; exit if A = 0
	INC	HL		; advance one char
	LD	(TXTCSR),HL	; store new text cursor
	RET
;
;---------------------------------------------------------
;  SHIFTDN:  <SHIFT><DOWN ARROW> routine
;	Entry:	None
;
SHIFTDN	LD	HL,(LINEBTM)	; HL => bottom line start
	LD	A,H		; check HL for zero
	OR	L
	RET	Z		; return if HL = 0
	LD	(FIRST),HL	; store new first char
	LD	(TXTCSR),HL	; store new text cursor
	RET
;
;---------------------------------------------------------
;  SHIFTUP:  <SHIFT><UP ARROW> routine
;	Entry:	None
;	Exit:	All registers are altered
;
SHIFTUP	LD	HL,(FIRST)	; HL => first display char
	LD	(TXTCSR),HL	; store as text cursor
	LD	B,SCRBTM	; B => # lines to move
SHUP10	CALL	ULINE		; move up one line
	DJNZ	SHUP10		; loop until B = 0
	LD	HL,(TXTCSR)	; HL => text cursor
	LD	(FIRST),HL	; store as first char
	RET
;
;---------------------------------------------------------
;  UPARROW:  Handle the <UP ARROW> key
;	Entry:	None
;	Exit:	All registers are altered
;
UPARROW	LD	A,(ROWCOL)	; A => column number
	OR	A		; test A for zero
	JR	Z,UPARR10	; bypass if A = 0
	CALL	BLINE		; move to line start
UPARR10	CALL	ULINE		; move up one line
	LD	A,(ROWCOL+1)	; A => row number
	OR	A		; check A for zero
	JP	NZ,REALIGN	; exit if A > 0
	LD	HL,(TXTCSR)	; HL => text cursor
	LD	(FIRST),HL	; store as new first char
	JP	REALIGN		; realign cursor
;
;  End of E4CMD/ASM
;
