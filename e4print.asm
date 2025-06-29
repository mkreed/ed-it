;========================================
;  Print Module for Model 4 ED-IT
;	copyright (c) 1991 by Mark Reed
;	all rights reserved
;========================================
;
;---------------------------------------------------------
;  PCR:  Print a carriage return
;	Entry:	None
;	Exit:	A is altered
;
PCR	LD	A,(LINES)	; A => lines printed
	INC	A		; add one more
	LD	(LINES),A	; store new value
	LD	A,CR		; A => carriage return
	CALL	PRT		; print it
PCR10	RET			; disable ADDLF
	LD	A,LF		; A => line-feed
	JP	PRT		; print it, return
;
;---------------------------------------------------------
;  PFOOTER:  Print a footer
;	Entry:	None
;	Exit:	A is altered
;
PFOOTER	LD	A,(LINES)	; A => lines printed
PFOOT10	CP	$-$		; compare with max value
	JR	NC,PFOOT20	; bypass if at page bottom
	CALL	PCR		; print carriage return
	JR	PFOOTER		; loop back
PFOOT20	LD	A,(FOOTER$-1)	; A => footer length
	OR	A		; check A for zero
	RET	Z		; return if A = 0
	CALL	PCR		; print carriage return
	CALL	PLEFT		; print left margin
	PUSH	HL
	LD	HL,FOOTER$	; HL => footer string
	CALL	PRSTR		; print it
	POP	HL
	RET
;
;---------------------------------------------------------
;  PFORM:  Feed paper to top of next form
;	Entry:	None
;	Exit:	A is altered
;
PFORM	CALL	PFOOTER		; print footer (if any)
	LD	A,(PAGENUM)	; A => page number
	INC	A		; add one to it
	LD	(PAGENUM),A	; store new value
	PUSH	BC
	LD	A,(PAGELEN)	; A => page length
	LD	B,A		; put it in B
PFORM10	LD	A,(LINES)	; A => lines printed
	CP	B		; compare A with B
	JR	NC,PFORM20	; exit if A >= B
	CALL	PCR		; print carriage return
	JR	PFORM10		; loop back
PFORM20	POP	BC
PFORM99	RET			; disable single sheets
	CALL	BLANK		; blank menu line
	LD	HL,CONT$	; HL => "Press a key..."
	CALL	DSPLY		; display the message
	JP	GETKEY		; wait for keystroke
;
;---------------------------------------------------------
;  PLEFT:  Print a left margin
;	Entry:	None
;	Exit:	A is altered
;
PLEFT	LD	A,(LMARGIN)	; A => left margin
	OR	A		; check A for zero
	RET	Z		; return if A = 0
	PUSH	BC
	LD	B,A		; put left margin in B
PLFT10	LD	A,' '		; print a space
	CALL	PRT
	DJNZ	PLFT10		; loop back until B = 0
	POP	BC
	RET
;
;---------------------------------------------------------
;  PRFILE:  Print the file in memory
;	Entry:	None
;
PRFILE	LD	DE,TEXT$	; DE => start of text
	LD	A,(DE)		; A  => first char of text
	OR	A		; check A for zero
	JP	Z,EDIT		; abort if no text
	LD	A,(ENTCHAR)	; A => ENTER char
	LD	(PRF40+1),A	; stuff into program
	LD	(PTRIM40+1),A
	LD	A,(PAGE1)	; A => 1st page number
	LD	(PAGENUM),A	; make it current number
	LD	A,(MAXLNS)	; A => max lines to print
	LD	B,A		; put it in B
	LD	A,(TMARGIN)	; A => top margin value
	ADD	A,B		; add them
	LD	(PRF70+1),A	; stuff into program
	LD	(PFOOT10+1),A
	@@CKBRKC		; clear BREAK bit
PRF10	CALL	BLANK		; blank menu line
	LD	HL,PRTNG$	; HL => "Printing..."
	CALL	DSPLY		; display the message
	CALL	PTOP		; print top margin
PRF20	LD	A,D		; check DE for zero
	OR	E
	JR	NZ,PRF25	; bypass if DE > 0
	CALL	PFORM		; feed form to next page
	JP	EDIT		; exit routine
PRF25	CALL	PLEFT		; print left margin
	LD	HL,SCRAP$	; HL => scratch buffer
	PUSH	HL		; save it
	CALL	FMTLINE		; format one line
	CALL	PTRIM		; trim trailing blanks
	POP	HL		; retrieve buffer ptr
	LD	A,(LINLEN)	; A => line length
	LD	B,A		; put it in B
PRF30	LD	A,(HL)		; A => char from buffer
	INC	HL		; advance ptr
	CP	12		; check A for form-feed
	JR	Z,PRF80		; loop way back if A = 12
PRF40	CP	$-$		; check A for ENTER char
	JR	Z,PRF60		; go if A = ENTER
	CP	128		; check A for blank
	JR	NZ,PRF50	; bypass if A <> 128
	LD	A,' '		; replace blank with space
PRF50	CALL	PRT		; print it
	DJNZ	PRF30		; loop back until B = 0
PRF60	CALL	PCR		; print carriage return
	LD	A,(LINES)	; A => lines printed
PRF70	CP	$-$		; check A for max value
	JR	C,PRF20		; loop back if A < maximum
PRF80	CALL	PFORM		; feed form to next page
	JR	PRF10		; loop way back
;
;---------------------------------------------------------
;  PRSTR:  Print string
;	Entry:	HL => string
;	Exit:	A and HL are altered
;
PRSTR	LD	A,(HL)		; A => char from string
	INC	HL		; advance ptr
	CP	ETX		; check A for string end
	JP	Z,PCR		; exit if A = ETX
	CP	'#'		; check A for number sign
	JR	NZ,PRSTR30	; bypass if A <> '#'
	PUSH	HL
	LD	HL,SCRAP$	; HL => scratch buffer
	LD	A,(PAGENUM)	; A  => page number
	CALL	CPYDEC		; convert to decimal ASCII
PRSTR10	LD	A,(HL)		; A  => char from page #
	INC	HL		; advance ptr
	CP	ETX		; check A for ETX
	JR	Z,PRSTR20	; bypass if A = ETX
	CALL	PRT		; print character
	JR	PRSTR10		; loop back
PRSTR20	POP	HL
	JR	PRSTR
PRSTR30	CALL	PRT		; print character
	JR	PRSTR		; loop back
;
;---------------------------------------------------------
;  PRT:  Print character
;	Entry:	A => character
;	Exit:	A is altered
;
PRT	RPUSH	BC,DE
	LD	C,A		; C => char to print
	@@CKBRKC		; check for BREAK key
	JP	NZ,EDIT		; abort if BREAK pressed
	@@PRT			; print it
	JP	NZ,DOSERR	; abort if DOS error
	LD	A,C		; A => printed char
	CP	'0'		; check for zero
	CALL	Z,PZERO		; slash it if desired
	RPOP	DE,BC
	RET
;
;---------------------------------------------------------
;  PTOP:  Print top margin
;	Entry:	None
;	Exit:	A is altered
;
PTOP	XOR	A		; A => zero
	LD	(LINES),A	; zero lines printed
	LD	A,(TMARGIN)	; A => top margin
	OR	A		; check A for zero
	JR	Z,PTOP20	; bypass if A = 0
	PUSH	BC
	LD	B,A		; put top margin in B
PTOP10	CALL	PCR		; print carriage return
	DJNZ	PTOP10		; loop back until B = 0
	POP	BC
PTOP20	LD	A,(HEADER$-1)	; A => length of header
	OR	A		; check A for zero
	RET	Z		; return if A = 0
	CALL	PLEFT		; print a left margin
	PUSH	HL
	LD	HL,HEADER$	; HL => header string
	CALL	PRSTR		; print it
	POP	HL
	JP	PCR		; print carriage return
;
;---------------------------------------------------------
;  PTRIM:  Trim trailing blanks on line
;	Entry:	HL => end of line + 1
;	Exit:	A, BC, and HL are altered
;
PTRIM	LD	B,SCRWID	; initialize loop counter
PTRIM10	DEC	HL		; back up ptr
	LD	A,(HL)		; A => char from line
	CP	' '		; check A for space
	JR	Z,PTRIM20	; go if A = 32
	CP	128		; check A for blank
	JR	NZ,PTRIM30	; go if A <> 128
PTRIM20	DJNZ	PTRIM10		; loop back until B = 0
PTRIM30	LD	A,B		; A => loop counter
	CP	SCRWID		; see if line was full
	RET	Z		; exit if it was
	INC	HL		; advance ptr
PTRIM40	LD	(HL),$-$	; stuff an ENTER char
	RET
;
;---------------------------------------------------------
;  PZERO:  Backspace and slash zero
;	Entry:	None
;	Exit:	A, BC, and DE are altered
;
PZERO	RET			; disable PZERO
	LD	C,8		; C => backspace
	@@PRT			; print it
	LD	C,0		; C => null
	@@PRT			; print it
	LD	C,'/'		; C => slash
	@@PRT			; print it
	RET
;
;	End of E4PRINT/ASM
;
