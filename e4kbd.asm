;===========================================
;  Keyboard Input Module for Model 4 ED-IT
;	copyright (c) 1991 by Mark Reed
;	all rights reserved
;===========================================
;
;---------------------------------------------------------
;  GETKEY:  Get keystroke
;	Entry:	None
;	Exit:	A <= keystroke
;
GETKEY	PUSH	DE
GTKY10	@@KBD			; get keystroke if any
	OR	A		; check for keystroke
	JR	Z,GTKY10	; loop back if no key
	POP	DE
	RET
;
;---------------------------------------------------------
;  KEY:  Get a keystroke
;	Entry:	None
;	Exit:	A <= keystroke
;
KEY	RPUSH	BC,DE,HL
	LD	HL,(SCRCSR)	; HL => screen cursor
	LD	DE,VBUFF$	; DE => screen buffer
	OR	A		; reset carry flag
	SBC	HL,DE		; find the difference
	LD	C,80		; divide difference by 80
	@@DIV16
	LD	H,L		; H => row number
	LD	L,A		; L => column number
	LD	(ROWCOL),HL	; store them for later
	LD	B,3		; B => function code 3
	@@VDCTL			; set cursor pos'n
	LD	C,14		; turn on cursor
	CALL	DSP
	CALL	GETKEY		; wait for a keystroke
	RPOP	HL,DE,BC
	RET
;
;---------------------------------------------------------
;  KEYIN:  Improved KEYIN handler
;	Entry:	B  => maximum number of input characters
;		HL => input buffer
;	Exit:	A and C are altered
;		B  <= number of characters entered
;		HL <= unchanged
;
KEYIN	PUSH	DE
	LD	(IBUFF$),HL	; store input buffer
	LD	(KCSR),HL	; store KEYIN cursor
	LD	A,B		; store max char value
	LD	(KMAX),A
	LD	B,4		; B  => function code 4
	@@VDCTL			; HL => cursor pos'n
	LD	(KDSP+1),HL	; store it for later
	CALL	KSRIGHT		; go to extreme right
KYIN10	CALL	KDSP		; display the line
	CALL	GETKEY		; wait for a key
	CP	128		; check for BREAK
	JP	Z,EDIT		; abort if BREAK pressed
	JR	NC,KYIN20	; go if A > 128
	CP	' '		; check for control char
	JR	C,KYIN20	; go if found
	CALL	KPUT		; handle input char
	JR	KYIN10		; loop back
KYIN20	CP	CR		; check for ENTER
	JR	Z,KYIN99	; go if found
	LD	HL,KDISP$	; HL => dispatch table
	CALL	DSPATCH		; go to proper routine
	JR	KYIN10		; loop back
KYIN99	PUSH	AF		; save flags
	CALL	KGETLEN		; B  => # chars entered
	LD	HL,(IBUFF$)	; HL => input buffer
	POP	AF		; retrieve flags
	POP	DE
	RET
;
;---------------------------------------------------------
;  Insert control character
;
KCCHAR	CALL	CCHAR		; A => control char
	JP	KPUT		; insert/overstrike it
;
;---------------------------------------------------------
;  Delete one character backwards
;
KDLBACK	CALL	KGETCSR		; A => KEYIN cursor offset
	LD	A,B
	OR	A		; check A for zero
	RET	Z		; return if A = 0
	DEC	HL		; decrease ptr
	LD	(KCSR),HL	; store new KEYIN cursor
				; fall into KDEL
;
;---------------------------------------------------------
;  Delete one character
;
KDEL	CALL	KGETCSR		; HL => KEYIN cursor
	PUSH	HL		; put KEYIN cursor in DE
	POP	DE
	INC	DE		; advance ptr
	LD	A,(HL)		; A  => char at HL
	CP	ETX		; check for ETX
	RET	Z		; return if found
KDEL10	LD	A,(DE)		; A => next char
	LD	(HL),A		; make it current char
	INC	DE		; advance ptrs
	INC	HL
	CP	ETX		; check for ETX
	JR	NZ,KDEL10	; loop back if not found
	RET
;
;---------------------------------------------------------
;  Display input line
;
KDSP	LD	HL,$-$		; HL => cursor pos'n
	PUSH	HL		; save it twice
	PUSH	HL
	LD	C,15		; turn cursor off
	CALL	DSP
	LD	B,3		; B  => function code 3
	@@VDCTL			; set cursor pos'n
	LD	HL,(IBUFF$)	; HL => input buffer
KDSP10	LD	A,(HL)		; A  => char at HL
	CP	ETX		; check for end of line
	JR	Z,KDSP30	; go if found
KDSP20	LD	C,A		; C => char to display
	INC	HL		; advance ptr
	EX	(SP),HL		; HL => cursor pos'n
	LD	B,2		; B  => function code 2
	@@VDCTL			; display char
	INC	HL		; advance cursor pos'n
	EX	(SP),HL		; HL => input buffer
	JR	KDSP10		; loop back
KDSP30	POP	HL		; retrieve end pos'n
	LD	B,3		; B => function code 3
	@@VDCTL			; set new cursor pos'n
	LD	C,30		; clear to end of line
	CALL	DSP
	POP	HL		; retrieve start pos'n
	LD	B,3		; B => function code 3
	@@VDCTL			; set cursor pos'n
	CALL	KGETCSR		; B => cursor offset
	JR	Z,KDSP50	; bypass if B = 0
KDSP40	LD	C,25		; move forward on screen
	CALL	DSP
	DJNZ	KDSP40		; loop until B = 0
KDSP50	LD	C,14		; turn cursor on
	CALL	DSP
	RET
;
;---------------------------------------------------------
;  Get cursor offset in B
;
KGETCSR	LD	HL,(KCSR)	; HL => KEYIN cursor
	PUSH	HL		; save it
	LD	DE,(IBUFF$)	; DE => input buffer
	OR	A		; reset carry flag
	SBC	HL,DE		; find difference
	LD	B,L		; put it in B
	POP	HL
	RET
;
;---------------------------------------------------------
;  Get string length in B
;
KGETLEN	LD	HL,(KCSR)	; HL => KEYIN cursor
	PUSH	HL		; save it
	CALL	KSRIGHT		; HL => extreme right
	LD	DE,(IBUFF$)	; DE => extreme left
	OR	A		; reset carry flag
	SBC	HL,DE		; find difference
	LD	B,L		; B  => string length
	POP	HL		; retrieve KEYIN cursor
	LD	(KCSR),HL	; store it
	RET
;
;---------------------------------------------------------
;  Insert one space (if there's room)
;
KINS	LD	A,' '		; insert a space
KINS10	LD	B,(HL)		; B => char at HL
	LD	(HL),A		; stuff previous char
	INC	HL		; advance ptr
	CP	ETX		; check for final ETX
	JP	Z,KGETCSR	; go if A = ETX
	LD	A,B		; A => previous char
	JR	KINS10		; loop back
;
;---------------------------------------------------------
;  Insert or overtype a character
;
KPUT	LD	(KPUT30+1),A	; store char for later
	CALL	KGETCSR		; HL => KEYIN cursor
	LD	A,(INSFLAG)	; A  => insert flag
	OR	A		; check A for zero
	JR	Z,KPUT20	; go if A = 0
KPUT10	CALL	KGETLEN		; B => string length
	LD	A,(KMAX)	; A => maximum length
	CP	B		; compare them
	JR	Z,KPUT99	; go if A = B
	CALL	KINS		; else insert space
KPUT20	LD	A,(HL)		; A => char at HL
	CP	ETX		; check for ETX
	JR	Z,KPUT10	; loop back if A = ETX
KPUT30	LD	(HL),$-$	; store char in buffer
	INC	HL		; else advance ptr
	LD	(KCSR),HL	; store it
KPUT99	RET
;
;---------------------------------------------------------
;  LEFT ARROW
;
KLEFT	CALL	KGETCSR		; B => cursor offset
	RET	Z		; return if offset = 0
	DEC	HL		; else back up cursor
	LD	(KCSR),HL	; store it
	RET
;
;---------------------------------------------------------
;  RIGHT ARROW
;
KRIGHT	LD	HL,(KCSR)	; HL => KEYIN cursor
KRT10	LD	A,(HL)		; A  => char at HL
	CP	ETX		; check for ETX
	RET	Z		; return if found
	INC	HL		; else advance ptr
	LD	(KCSR),HL	; store new cursor
	RET
;
;---------------------------------------------------------
;  SHIFT CLEAR
;
KSCLEAR	CALL	KSLEFT		; move to extreme left
	LD	(HL),ETX	; put ETX in first pos'n
	RET
;
;---------------------------------------------------------
;  SHIFT LEFT
;
KSLEFT	CALL	KGETCSR		; B => cursor offset
	RET	Z		; return if offset = 0
KSL10	CALL	KLEFT		; move left
	DJNZ	KSL10		; loop until B = 0
	RET
;
;---------------------------------------------------------
;  SHIFT RIGHT
;
KSRIGHT	LD	HL,(KCSR)	; HL => KEYIN cursor
KSR10	LD	A,(HL)		; A  => char at HL
	CP	ETX		; check for ETX
	JR	Z,KSR99		; go if found
	INC	HL		; else advance ptr
	JR	KSR10		; loop back
KSR99	LD	(KCSR),HL	; store KEYIN cursor
	RET
;
;---------------------------------------------------------
;  Insert a tab
;
KTAB	LD	A,(INSFLAG)	; A => insert flag
	OR	A		; check A for zero
	JR	NZ,KTAB10	; go if insert mode
	CALL	KGETLEN		; B => string length
	LD	A,(KMAX)	; A => maximum length
	CP	B		; compare them
	RET	Z		; return if A = B
	CALL	KINS		; insert one space
KTAB10	LD	A,9		; overtype one tab
	JR	KPUT
;
;  End of E4KBD/ASM
;
