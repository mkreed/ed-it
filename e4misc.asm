;=============================================
;  Miscellaneous Functions for Model 4 ED-IT
;	copyright (c) 1995 by Mark Reed
;	all rights reserved
;=============================================
;
;---------------------------------------------------------
;  BACKUP:  Back up to previous ENTER + 1
;	Entry:	None
;	Exit:	A is altered
;
BACKUP	RPUSH	BC,DE,HL
	LD	HL,(TXTCSR)	; HL => text cursor
	DEC	HL		; back up
	LD	A,(HL)		; get character
	OR	A		; check for leading zero
	JR	Z,BACK99	; exit if A = 0
	DEC	HL		; back up
	LD	A,(HL)		; get character
	OR	A		; check for leading zero
	JR	Z,BACK99	; exit if A = 0
	PUSH	HL		; save ptr
	LD	BC,TEXT$	; BC => text start
	OR	A		; reset carry flag
	SBC	HL,BC		; HL => difference
	INC	HL		; adjust it
	PUSH	HL		; put it in BC
	POP	BC
	POP	HL		; retrieve ptr
	LD	A,CR		; search for ENTER
	CPDR			; search backwards
	JR	NZ,BACK99	; go if no ENTER found
	INC	HL		; adjust ptr
BACK99	INC	HL
	LD	(TXTCSR),HL	; store as text cursor
	RPOP	HL,DE,BC
	RET
;
;---------------------------------------------------------
;  BLINE:  Move to the beginning of the line
;	Entry:	None
;	Exit:	A is altered
;
BLINE	RPUSH	DE,HL
	LD	HL,(TXTCSR)	; HL => text cursor
	LD	A,(HL)		; A  => char at HL
	OR	A		; check for ending zero
	JR	NZ,BLINE10	; bypass if not found
	DEC	HL		; else adjust cursor
	LD	A,(HL)		; A  => char at HL
	CP	CR		; test for ENTER
	JR	NZ,BLINE10	; go if not found
	INC	HL		; else adjust cursor
	LD	(TXTCSR),HL	; store it
	JR	BLINE99		; and exit
BLINE10	INC	HL		; adjust text cursor
	PUSH	HL		; save it for later
	CALL	BACKUP		; back up to last ENTER
	LD	DE,(TXTCSR)	; DE => last ENTER + 1
BLINE20	POP	HL		; retrieve old text cursor
	CALL	CMPARE		; compare HL and DE
	JR	C,BLINE99	; go if HL < DE
	JR	Z,BLINE99	; go if HL = DE
	PUSH	HL		; save old text cursor
	LD	(TXTCSR),DE	; save new text cursor
	CALL	NLINE		; DE => start of next line
	LD	A,D		; test DE for zero
	OR	E
	JR	NZ,BLINE20	; loop back if DE <> 0
	POP	HL		; discard old text cursor
BLINE99	RPOP	HL,DE
	RET
;
;---------------------------------------------------------
;  CCHAR:  Enter control character
;	Entry:	None
;	Exit:	A contains control character
;
CCHAR	RPUSH	BC,DE
	LD	A,3		; specify 3 passes
	LD	(CCHAR40+1),A	; stuff into program
	LD	C,0		; initialize with zero
CCHAR10	LD	A,C		; A => current value
	SLA	A		; multiply by 2
	LD	C,A		; store it
	SLA	A		; multiply by 4
	SLA	A		; multiply by 8
	ADD	A,C		; multiply by 10
	LD	C,A		; store value
CCHAR20	CALL	GETKEY		; A => keystroke
	CP	128		; check for BREAK
	JR	NZ,CCHAR30	; go if not BREAK
	XOR	A		; else zero char
	JR	CCHAR99		; exit routine
CCHAR30	CP	'0'		; check lower limit
	JR	C,CCHAR20	; go if A < "0"
	CP	'9'+1		; check upper limit
	JR	NC,CCHAR20	; go if A > "9"
	SUB	'0'		; convert to binary
	ADD	A,C		; merge with value
	LD	C,A		; store value
CCHAR40	LD	A,$-$		; A => pass number
	DEC	A		; decrease by one
	LD	(CCHAR40+1),A	; store new pass number
	JR	NZ,CCHAR10	; loop back if A > 0
	LD	A,C		; A => final value
	CP	ETX+1		; check A for 1 to 3
	JR	NC,CCHAR99	; go if A > ETX
	XOR	A		; zero A
CCHAR99	RPOP	DE,BC
	RET
;
;---------------------------------------------------------
;  CMPARE:  Compare HL and DE
;	Entry:	None
;	Exit:	Z and C flags set accordingly
;
CMPARE	PUSH	HL
	OR	A		; reset carry flag
	SBC	HL,DE		; find difference
	POP	HL
	RET
;
;---------------------------------------------------------
;  CPYDEC:  Copy decimal value into buffer as ASCII
;	Entry:	A  => decimal value
;		HL => buffer
;	Exit:	A is altered
;
CPYDEC	RPUSH	BC,DE,HL
	LD	E,A		; E => dividend
	LD	C,100		; C => divisor
	@@DIV8			; divide E by C
	OR	A		; check A for zero
	JR	Z,CPYD10	; bypass if A = 0
	ADD	A,'0'		; convert product to ASCII
	LD	(HL),A		; store it
	INC	HL		; advance ptr
CPYD10	LD	C,10		; C => divisor
	@@DIV8			; divide remainder by C
	OR	A		; check A for zero
	JR	Z,CPYD20	; bypass if A = 0
	ADD	A,'0'		; convert product to ASCII
	LD	(HL),A		; store it
	INC	HL		; advance ptr
CPYD20	LD	A,E		; A => remainder value
	ADD	A,'0'		; convert to ASCII
	LD	(HL),A		; store it
	INC	HL		; advance ptr
	LD	(HL),ETX	; terminate entry
	RPOP	HL,DE,BC
	RET
;
;---------------------------------------------------------
;  DLBLOCK:  Delete a block
;	Entry:	BC => number of bytes to delete
;	Exit:	A is altered
;		BC <= zero
;
DLBLOCK	RPUSH	DE,HL
	LD	HL,(TXTCSR)	; HL => text cursor
	PUSH	HL		; save it
	LD	DE,0		; initialize delete count
DB10	LD	A,(HL)		; A  => char at HL
	OR	A		; test for ending zero
	JR	Z,DB20		; go if found
	INC	HL		; advance cursor
	DEC	BC		; decrease counter
	INC	DE		; increase delete count
	LD	A,B		; test for BC = zero
	OR	C
	JR	NZ,DB10		; loop back
DB20	LD	(DB30+1),DE	; stuff delete count
	EX	DE,HL		; DE => source ptr
	LD	HL,(TXTEND)	; HL => text end
	OR	A		; reset carry flag
	SBC	HL,DE		; find the difference
	INC	HL		; adjust it for LDIR
	PUSH	HL		; put the difference in BC
	POP	BC
	EX	DE,HL		; HL => source ptr
	POP	DE		; DE => destination ptr
	LDIR			; delete the characters
	LD	A,1		; turn on mod flag
	LD	(MODFLAG),A
DB30	LD	DE,$-$		; DE => delete count
	LD	HL,(TXTEND)	; HL => old text end
	OR	A		; reset carry flag
	SBC	HL,DE		; HL => new text end
	LD	(TXTEND),HL	; store it
	LD	HL,(FREEMEM)	; HL => free memory
	ADD	HL,DE		; add delete count
	LD	(FREEMEM),HL	; store new free memory
	RPOP	HL,DE
	RET
;
;---------------------------------------------------------
;  DELIM:  Checks character as a delimiter
;	Entry:	A => character to check
;	Exit:	Z flag set if character was delimiter
;		Z flag reset otherwise
;
DELIM	CP	' '		; check for space
	RET	Z		; return if found
	CP	'-'		; check for hyphen
	RET	Z		; return if found
	CP	9		; check for tab
	RET	Z		; return if found
	CP	','		; check for comma
	RET	Z		; return if found
	CP	CR		; check for ENTER
	RET			; return w/flags set
;
;---------------------------------------------------------
;  DSPATCH:  Dispatch program to appropriate subroutine
;	Entry:	A  => keystroke
;		HL => dispatch table
;	Exit:	A and DE are altered
;		HL <= text cursor
;
DSPATCH	CALL	UCASE		; convert to uppercase
	LD	E,A		; save keystroke
DSPAT10	LD	A,(HL)		; A => key to compare
	INC	HL		; advance ptr
	OR	A		; test for zero
	RET	Z		; return if found
	CP	E		; compare to keystroke
	JR	Z,DSPAT20	; go if same
	INC	HL		; advance past address
	INC	HL
	JR	DSPAT10		; loop back
DSPAT20	LD	E,(HL)		; E => address LSB
	INC	HL		; advance ptr
	LD	D,(HL)		; D => address MSB
	PUSH	DE		; put address on stack
	LD	HL,(TXTCSR)	; HL => text cursor
	RET			; jump to address
;
;---------------------------------------------------------
;  ELINE:  Move to the end of the line
;	Entry:	None
;	Exit:	None
;
ELINE	PUSH	DE
	CALL	BLINE		; go to beginning of line
	LD	DE,(TXTCSR)	; DE => text cursor
	CALL	NLINE		; move to next line start
	LD	A,D		; check DE for zero
	OR	E
	JR	NZ,ELINE10	; bypass if DE = 0
	LD	DE,(TXTEND)	; DE => text end
	INC	DE		; adjust for next "DEC DE"
ELINE10	DEC	DE		; back up to previous line
	LD	(TXTCSR),DE	; store new text cursor
	POP	DE
	RET
;
;---------------------------------------------------------
;  FBLOCK:  Find block start and length
;	Entry:	None
;	Exit:	A is altered
;		Z flag set if block found, reset if not
;		BC <= block length
;		HL <= block start (block marker + 1)
;
FBLOCK	PUSH	DE
	LD	HL,TEXT$	; HL => start of text
	LD	A,1		; A  => block start marker
	CP	(HL)		; check first char
	JR	Z,FB10		; bypass if found
	CALL	FCHAR		; look for it
	JR	NZ,FB99		; exit if not found
FB10	INC	HL		; advance ptr
	PUSH	HL		; DE => block start
	POP	DE
	LD	A,2		; A  => block end marker
	CP	(HL)		; check first char
	JR	Z,FB20		; bypass if found
	CALL	FCHAR		; look for it
	JR	NZ,FB99		; exit if not found
FB20	OR	A		; reset carry flag
	SBC	HL,DE		; HL => block length
	PUSH	HL		; BC => block length
	POP	BC
	EX	DE,HL		; HL => block start
	CP	A		; set Z flag
FB99	POP	DE
	RET
;
;---------------------------------------------------------
;  FCHAR:  Find a character
;	Entry:	A  => character to find
;		HL => position to start looking
;	Exit:	Z flag set if found, reset if not found
;		HL <= position of character
;
FCHAR	PUSH	BC
	CALL	UCASE		; make char uppercase
	LD	C,A		; C  => char to find
	LD	A,(HL)		; A  => char at HL
FC10	OR	A		; check for ending zero
	JR	Z,FC20		; go if found
	INC	HL		; else advance ptr
	LD	A,(HL)		; A  => char at HL
	CALL	UCASE		; make it uppercase
	CP	C		; check for find char
	JR	Z,FC99		; return if found
	JR	FC10		; loop back if not found
FC20	OR	1		; reset Z flag
FC99	POP	BC
	RET
;
;---------------------------------------------------------
;  GETNUM:  Get numeric input
;	Entry:	A  => default value
;		HL => prompt to display
;	Exit:	A  <= input value
;		BC and HL are altered
;
GETNUM	PUSH	AF		; save default value
	CALL	BLANK		; blank menu line
	CALL	DSPLY		; display message
	LD	HL,PROMPT$	; HL => " :"
	CALL	DSPLY		; display prompt
	LD	HL,SCRAP$	; HL => scratch buffer
	POP	AF		; retrieve default value
	CALL	CPYDEC		; install the default
	LD	B,2		; B  => max of 2 chars
	CALL	KEYIN		; input a string
	LD	A,B		; A => # chars entered
	OR	A		; check for zero
	JP	Z,EDIT		; abort if A = 0
	@@DECHEX		; BC => decimal value
	LD	A,C		; A  => input value
	RET
;
;---------------------------------------------------------
;  GETSTR:  Get string input
;	Entry:	B  => maximum input length
;		DE => input buffer
;		HL => prompt
;	Exit:	A and DE are altered
;		B  <= actual input length
;		HL <= input buffer
;
GETSTR	CALL	BLANK		; blank menu line
	CALL	DSPLY		; display message
	LD	HL,PROMPT$	; HL => ": "
	CALL	DSPLY		; display prompt
	EX	DE,HL		; HL => input buffer
	JP	KEYIN		; get input
;
;---------------------------------------------------------
;  IBLOCK:  Insert a block
;	Entry:	BC => length of block
;	Exit:	None
;
IBLOCK	RPUSH	AF,BC,DE,HL
	LD	HL,(FREEMEM)	; HL => free memory
	OR	A		; reset carry flag
	SBC	HL,BC		; adjust free memory
	JP	C,MEMERR	; go if no free memory
	LD	(FREEMEM),HL	; store new FREEMEM value
IB10	PUSH	BC		; save block length
	LD	DE,(TXTCSR)	; DE => text cursor
	LD	HL,(TXTEND)	; HL => text end
	PUSH	HL		; save it
	OR	A		; reset carry flag
	SBC	HL,DE		; find the difference
	INC	HL		; adjust for subtraction
	PUSH	BC		; DE => block length
	POP	DE
	PUSH	HL		; BC => LDDR length
	POP	BC
	POP	HL		; HL => source
	PUSH	HL		; save it again
	ADD	HL,DE		; find destination
	EX	DE,HL		; DE => destination
	POP	HL		; retrieve source
	LDDR			; insert block
	LD	HL,(TXTCSR)	; HL => text cursor
	POP	BC		; BC => block length
	PUSH	BC		; save it again
IB20	LD	(HL),' '	; stuff a space
	INC	HL		; advance cursor
	DEC	BC		; decrease counter
	LD	A,B		; test counter for zero
	OR	C
	JR	NZ,IB20		; go if not zero
	LD	A,1		; turn on mod flag
	LD	(MODFLAG),A
	LD	HL,(TXTEND)	; HL => old text end
	POP	BC		; BC => block length
	ADD	HL,BC		; HL => new text end
	LD	(TXTEND),HL	; store it
IB99	RPOP	HL,DE,BC,AF
	RET
;
;---------------------------------------------------------
;  INSERT:  Insert character in text buffer
;	Entry:	A => character to insert
;	Exit:	A is altered
;
INSERT	RPUSH	BC,HL
	LD	BC,1		; insert one char in the
	CALL	IBLOCK		;   text buffer
	LD	HL,(TXTCSR)	; HL => text cursor
	LD	(HL),A		; store the char
	INC	HL		; advance ptr
	LD	(TXTCSR),HL	; store new text cursor
	RPOP	HL,BC
	RET
;
;---------------------------------------------------------
;  INSTAB:  Insert a tab character
;	Entry:	None
;	Exit:	A <= tab character (ASCII 9)
;
INSTAB	LD	A,9		; A => tab char
	JP	INSERT		; insert it
;
;---------------------------------------------------------
;  NLINE:  Move to start of next line
;	Entry:	DE => start of current line
;	Exit:	A is altered
;		DE <= start of next line
;
NLINE	PUSH	HL
	LD	HL,SCRAP$	; HL => scrap buffer
	CALL	FMTLINE		; format one line
	POP	HL
	RET
;
;---------------------------------------------------------
;  OTYPE:  Overtype character in text buffer
;	Entry:	A => character to overtype
;
OTYPE	PUSH	AF		; save character
	LD	HL,(TXTCSR)	; HL => text cursor
	LD	A,(HL)		; A  => char in buffer
	OR	A		; check for ending zero
	JR	Z,OTYPE10	; go if A = 0
	CP	CR		; check for ENTER
	JR	Z,OTYPE10	; go if A = 13
	CP	9		; check for tab
	JR	Z,OTYPE10	; go if A = 9
	POP	AF		; retrieve character
	LD	(HL),A		; stuff char into buffer
	INC	HL		; advance text cursor
	LD	(TXTCSR),HL	; store new value
	LD	(MODFLAG),A	; turn on mod flag
	RET
OTYPE10	POP	AF		; retrieve character
	JP	INSERT		; insert it
;
;---------------------------------------------------------
;  PUTCHAR:  Put character in A into text buffer
;	Entry:	A => character to put
;	Exit:	None
;
PUTCHAR	PUSH	AF		; save character
	LD	A,(INSFLAG)	; check insert flag
	OR	A		; test it for zero
	JR	Z,PC20		; go if overtype mode
	DEC	A		; test it for one
	JR	Z,PC10		; go if line insert mode
	POP	AF		; retrieve character
	JP	INSERT		; insert it
PC10	PUSH	HL
	LD	HL,(TXTCSR)	; HL => text cursor
	LD	A,(HL)		; A  => char at cursor
	POP	HL
	CP	' '		; check for space
	JR	Z,PC20		; go if char is space
	PUSH	BC
	LD	A,(LINLEN)	; A => line length
	LD	C,A		; put it in BC
	LD	B,0
	CALL	IBLOCK		; insert spaces
	POP	BC
PC20	POP	AF		; retrieve character
	JP	OTYPE		; overtype it
;
;---------------------------------------------------------
;  QUERY:  Get Yes/No answer
;	Entry:	HL => question
;	Exit:	A and HL are altered
;		Z flag set if "Yes," reset if "No"
;
QUERY	PUSH	DE
	CALL	BLANK		; blank menu line
	CALL	DSPLY		; display question
	LD	HL,QMSG$	; HL => "(Y/N)?"
	CALL	DSPLY		; display prompt
QUERY10	CALL	GETKEY		; A => keystroke
	CP	128		; check for BREAK
	JP	Z,EDIT		; abort if found
	CALL	UCASE		; convert to uppercase
	CP	'Y'		; check for Yes
	JR	Z,QUERY99	; exit if found
	CP	'N'		; check for No
	JR	NZ,QUERY10	; loop back if not found
	OR	A		; reset Z flag
QUERY99	POP	DE
	RET
;
;---------------------------------------------------------
;  REALIGN:  Realign cursor after line movement
;	Entry:	None
;	Exit:	None
;
REALIGN	RPUSH	AF,BC,DE,HL
	LD	A,(ROWCOL)	; A => column number
	OR	A		; check A for zero
	JR	Z,REAL99	; exit if A = 0
	LD	B,A		; B  => column number
	LD	C,SCRWID	; C  => screen width
	LD	DE,(TXTCSR)	; DE => text cursor
	LD	HL,VBUFF$	; HL => scratch buffer
	CALL	FMTLINE		; format one line
	LD	A,D		; check DE for zero
	OR	E
	JR	NZ,REAL10	; go if DE <> 0
	LD	DE,(TXTEND)	; DE => text end
	INC	DE		; adjust for "DEC DE"
REAL10	DEC	DE		; back up ptrs
REAL20	DEC	HL
	DEC	C		; back up counter
	LD	A,(HL)		; A => screen char
	CP	128		; check A for blank
	JR	Z,REAL20	; loop back if A = 128
	LD	A,B		; A => old column number
	CP	C		; compare A with C
	JR	C,REAL10	; loop back if A < C
	LD	(TXTCSR),DE	; store new text cursor
REAL99	RPOP	HL,DE,BC,AF
	RET
;
;---------------------------------------------------------
;  RFIND:  Repeat last find
;	Entry:	None
;	Exit:	A is altered
;
RFIND	RPUSH	DE,HL
	LD	A,(FIND$-1)	; A => length of FIND$
	OR	A		; check for zero
	JR	Z,RF99		; go if no string entered
	CALL	BLANK		; blank menu line
	LD	HL,FNDING$	; "Finding..."
	CALL	DSPLY		; display message
	LD	HL,(TXTCSR)	; HL => text cursor
RF10	LD	DE,FIND$	; DE => entered string
	LD	A,(DE)		; first entered char
	CALL	FCHAR		; find it
	JP	NZ,FNDERR	; go if nothing found
RF20	INC	DE		; advance ptrs
	INC	HL
	LD	A,(DE)		; A => char at DE
	CP	ETX		; check for ETX
	JR	Z,RF30		; go if string is over
	CP	(HL)		; else compare with (HL)
	JR	Z,RF20		; loop back if they match
	CALL	UCASE		; else make it uppercase
	CP	(HL)		; and compare it again
	JR	Z,RF20		; loop back if they match
	DEC	HL		; ** adjust for INC HL **
	JR	RF10		; try again if no match
RF30	LD	A,(FIND$-1)	; A => length of FIND$
	LD	E,A		; put length in DE
	LD	D,0
	OR	A		; reset carry flag
	SBC	HL,DE		; HL => start of match
	LD	(TXTCSR),HL	; store new text cursor
RF99	RPOP	HL,DE
	RET
;
;---------------------------------------------------------
;  RRPLC:  Repeat last replace
;	Entry:	None
;	Exit:	A is altered
;
RRPLC	RPUSH	DE,HL
	CALL	BLANK		; blank menu line
	LD	HL,RPLING$	; "Replacing..."
	CALL	DSPLY		; display message
	LD	A,(FIND$-1)	; BC => length of FIND$
	LD	C,A
	LD	B,0
	CALL	DLBLOCK		; delete FIND$
	LD	A,(RPLC$-1)	; A => length of RPLC$
	OR	A		; check A for zero
	JR	Z,RR99		; go if no RPLC$
	LD	C,A		; BC => length of RPLC$
	LD	B,0
	PUSH	BC		; save it
	CALL	IBLOCK		; insert some spaces
	POP	BC		; retrieve length
	LD	HL,RPLC$	; HL => source
	LD	DE,(TXTCSR)	; DE => destination
	LDIR			; transfer RPLC$ to memory
	DEC	DE		; decrease ptr
	LD	(TXTCSR),DE	; store new text cursor
RR99	RPOP	HL,DE
	RET
;
;---------------------------------------------------------
;  TOGINS:  Toggle insert mode
;	Entry:	None
;	Exit:	A is altered
;
TOGINS	PUSH	BC
	LD	A,(INSFLAG)	; A => insert flag
	INC	A		; increment it
	CP	3		; have we gone too far?
	JR	C,TG10		; no, not yet
	XOR	A		; else reset to zero
TG10	LD	(INSFLAG),A	; replace flag
	JR	Z,TG30		; go if overtype mode
	DEC	A		; check for line insert
	JR	Z,TG20		; go if line insert
	LD	BC,088FH	; change cursor to block
	JR	TG40
TG20	LD	BC,088CH	; change cursor to half
	JR	TG40		;   block
TG30	LD	BC,085FH	; change cursor to line
TG40	@@VDCTL
	POP	BC
	RET
;
;---------------------------------------------------------
;  UCASE:  Convert character to uppercase
;	Entry:	A => character to convert
;	Exit:	A <= converted character
;
UCASE	CP	'a'		; check for lowercase char
	RET	C		; return if not
	CP	'z'+1		; check for lowercase char
	RET	NC		; return if not
	SUB	32		; convert to uppercase
	RET
;
;---------------------------------------------------------
;  ULINE:  Up one line
;	Entry:	None
;	Exit:	A is altered
;
ULINE	RPUSH	DE,HL
	LD	HL,(TXTCSR)	; HL => text cursor
	PUSH	HL		; save it for later
	CALL	BACKUP		; back up to last ENTER
	LD	DE,(TXTCSR)	; DE => last ENTER + 1
ULINE10	POP	HL		; retrieve old text cursor
	CALL	CMPARE		; compare HL and DE
	JR	C,ULINE20	; go if HL < DE
	JR	Z,ULINE20	; go if HL = DE
	PUSH	HL		; save old text cursor
	LD	(TXTCSR),DE	; save new text cursor
	CALL	NLINE		; DE => start of next line
	LD	A,D		; check DE for zero
	OR	E
	JR	NZ,ULINE10	; loop back if DE > 0
	POP	HL		; discard old text cursor
ULINE20	RPOP	HL,DE
	RET
;
;  End of E4MISC/ASM
;
