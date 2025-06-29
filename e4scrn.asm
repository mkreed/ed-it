;==========================================
;  Screen Output Module for Model 4 ED-IT
;	copyright (c) 1991 by Mark Reed
;	all rights reserved
;==========================================
;
;---------------------------------------------------------
;  BLANK:  Blank bottom screen line
;	Entry:	None
;	Exit:	None
;
BLANK	RPUSH	BC,DE,HL
	LD	H,SCRBTM	; H => bottom row
	LD	L,0		; L => column zero
	LD	B,3		; B => function code 3
	@@VDCTL			; set cursor pos'n
	LD	C,30		; clear to end of line
	CALL	DSP
	RPOP	HL,DE,BC
	RET
;
;---------------------------------------------------------
;  DOTAB:  Expand a tab
;	Entry:	B => cursor column
;	Exit:	B <= new cursor column
;		C is altered
;
DOTAB	PUSH	AF
	LD	A,(TABINT)	; A => tab interval
	LD	C,A		; put it in C
	XOR	A		; A => zero
DOTAB10	ADD	A,C		; add tab interval
	CP	B		; compare A with B
	JR	C,DOTAB10	; loop back if A < B
	JR	Z,DOTAB10	; loop back if A = B
	LD	C,A		; C => next tab stop
	LD	(HL),' '	; display a space
DOTAB20	INC	HL		; advance ptr
	INC	B		; advance counter
	LD	A,(LINLEN)	; A => max line length
	CP	B		; compare A with B
	JR	Z,DOTAB99	; exit loop if A = B
	LD	A,C		; A => next tab stop
	CP	B		; compare A with B
	JR	Z,DOTAB99	; exit loop if A = B
	LD	(HL),128	; display a blank
	JR	DOTAB20		; loop back
DOTAB99	POP	AF
	RET
;
;---------------------------------------------------------
;  DSP:  Display one byte
;	Entry:	C => byte to display
;	Exit:	A is altered
;
DSP	PUSH	DE
	@@DSP			; display the byte
	POP	DE
	RET
;
;---------------------------------------------------------
;  DSPBUFF:  Display VBUFF$
;	Entry:	None
;	Exit:	None
;
DSPBUFF	RPUSH	BC,DE,HL
	LD	HL,VBUFF$	; HL => screen buffer
	LD	B,5		; B  => function code 5
	@@VDCTL			; buffer to video
	RPOP	HL,DE,BC
	RET
;
;---------------------------------------------------------
;  DSPLY:  Display message on bottom line
;	Entry:	HL => message
;	Exit:	A is altered
;
DSPLY	PUSH	DE
	@@DSPLY			; display message
	POP	DE
	RET
;
;---------------------------------------------------------
;  FMTLINE:  Format one line
;	Entry:	DE => current text line start
;		HL => current screen line start
;	Exit:	DE <= next text line start
;		HL <= next screen line start
;
FMTLINE	RPUSH	AF,BC
	LD	B,0		; initialize counter
	LD	A,D		; check DE for zero
	OR	E
	JR	Z,FMTLN90	; go if DE = 0
FMTLN10	LD	A,(LINLEN)	; A => max line length
	CP	B		; compare A with B
	JR	Z,FMTLN80	; exit loop if A = B
	LD	A,(DE)		; A => text char
	INC	DE		; advance ptr
FMTLN12	CP	' '		; check A for ctrl char
	JR	C,FMTLN20	; go if A < 32
	CP	128		; check A for blank
	JR	NZ,FMTLN15	; go if A <> 128
	LD	A,' '		; replace blank with space
FMTLN15	LD	(HL),A		; display char
	INC	HL		; advance ptr
	INC	B		; advance counter
	JR	FMTLN10		; loop back
FMTLN20	CP	CR		; check A for ENTER
	JR	NZ,FMTLN25	; go if A <> 13
	LD	A,(ENTCHAR)	; A => ENTER char
	LD	(HL),A		; display it
	INC	HL		; advance ptr
	INC	B		; advance counter
	JR	FMTLN90		; exit loop
FMTLN25	CP	9		; check A for tab
	JR	NZ,FMTLN30	; go if A <> 9
	CALL	DOTAB		; expand the tab
	JR	FMTLN10		; loop back
FMTLN30	CP	1		; check A for block start
	JR	NZ,FMTLN35	; go if A <> 1
	LD	A,183		; replace with bracket
	JR	FMTLN15		; display it
FMTLN35	CP	2		; check A for block end
	JR	NZ,FMTLN40	; go if A <> 2
	LD	A,187		; replace with bracket
	JR	FMTLN15		; display it
FMTLN40	CP	3		; check A for cursor char
	JR	NZ,FMTLN45	; go if A <> 3
	LD	(SCRCSR),HL	; store screen cursor
	LD	A,(CSRCHAR)	; A => char under cursor
	JR	FMTLN12		; loop back
FMTLN45	CP	12		; check A for form-feed
	JR	NZ,FMTLN50	; go if A <> 12
	LD	(HL),A		; display form-feed
	INC	HL		; advance ptr
	INC	B		; advance counter
	JR	FMTLN90		; exit loop
FMTLN50	OR	A		; check A for end of file
	JR	NZ,FMTLN15	; go if A <> 0
	LD	DE,0		; DE => end of file
	LD	(HL),' '	; display a space
	INC	HL		; advance ptr
	INC	B		; advance counter
	JR	FMTLN90		; exit loop
FMTLN80	CALL	WRAP		; word-wrap if necessary
FMTLN90	LD	A,SCRWID	; A => screen width
	CP	B		; compare A with B
	JR	Z,FMTLN99	; go if A = B
	LD	(HL),128	; display a blank
	INC	HL		; advance ptr
	INC	B		; advance counter
	JR	FMTLN90		; loop back
FMTLN99	RPOP	BC,AF
	RET
;
;---------------------------------------------------------
;  FORMAT:  Format and display page
;	Entry:	None
;	Exit:	A is altered
;
FORMAT	RPUSH	BC,DE,HL
	LD	A,2		; set maximum number of
	LD	(PASSNUM),A	;   passes
FM10	LD	HL,(TXTCSR)	; HL => text cursor
	LD	DE,(FIRST)	; DE => first display char
	CALL	CMPARE		; compare HL with DE
	JR	NC,FM20		; bypass if no adjustment
	PUSH	HL		; save text cursor
	CALL	BLINE		; go to line start
	LD	HL,(TXTCSR)	; HL => temp text cursor
	LD	(FIRST),HL	; store as first char
	POP	HL		; retrieve old text cursor
	LD	(TXTCSR),HL	; store it
FM20	LD	HL,(TXTCSR)	; HL => text cursor
	LD	A,(HL)		; A  => char at HL
	LD	(CSRCHAR),A	; store as cursor char
	LD	(HL),ETX	; stuff ETX to mark pos'n
	LD	HL,VBUFF$	; HL => screen buffer
	LD	DE,(FIRST)	; DE => text buffer
	CALL	FMTLINE		; format line 1
	LD	(LINE2),DE	; store start of line 2
	LD	B,SCRBTM-1	; B => 22 screen lines
FM30	CALL	FMTLINE		; format next line
	DJNZ	FM30		; loop back until B = 0
	LD	(LINEBTM),DE	; store start of btm line
	CALL	FMTLINE		; format last line
	LD	HL,(TXTCSR)	; HL => text cursor
	LD	A,(CSRCHAR)	; A  => char under cursor
	LD	(HL),A		; replace char in memory
	LD	(LAST),DE	; save last display char
	LD	A,D		; check DE for zero
	OR	E
	JR	Z,FM99		; go if DE = 0
	DEC	DE		; adjust ptr
	LD	(LAST),DE	; save adjusted ptr
	CALL	CMPARE		; compare HL with DE
	JR	C,FM99		; go if HL < DE
	JR	Z,FM99		; go if HL = DE
	LD	HL,(LINE2)	; HL => start of line 2
	LD	(FIRST),HL	; store it as first char
	LD	A,(PASSNUM)	; A => pass number
	DEC	A		; decrease it
	LD	(PASSNUM),A	; store new one
	JR	NZ,FM20		; loop back if A > 0
	LD	HL,(TXTCSR)	; HL => text cursor
	PUSH	HL		; save it
	CALL	BLINE		; move to line start
	LD	B,SCRBTM/2	; B => 12 screen lines
FM40	CALL	ULINE		; move up one line
	DJNZ	FM40		; loop back until B = 0
	LD	HL,(TXTCSR)	; HL => new text cursor
	LD	(FIRST),HL	; store as first char
	POP	HL		; retrieve old text cursor
	LD	(TXTCSR),HL	; store it
	JR	FM20		; loop back, format screen
FM99	CALL	DSPBUFF		; display VBUFF$
	RPOP	HL,DE,BC
	RET
;
;---------------------------------------------------------
;  WRAP:  Word-wrap at end of line
;	Entry:	B  => cursor column
;		DE => text line temporary cursor
;		HL => screen line temporary cursor
;	Exit:	B, DE, and HL are updated
;
WRAP	NOP			; disable with "RET"
	PUSH	AF
	LD	A,B		; store old values for
	LD	(WRAP40+1),A	;   later retrieval if
	LD	(WRAP50+1),DE	;   no wrapping point is
	LD	(WRAP60+1),HL	;   found
WRAP10	XOR	A		; A => zero
	CP	B		; compare A with B
	JR	Z,WRAP40	; go if A = B
	DEC	DE		; back up ptrs
WRAP20	DEC	HL
	DEC	B		; back up counter
	LD	A,(HL)		; A => screen char
	CP	128		; check A for blank
	JR	Z,WRAP20	; loop back if A = 128
	CP	' '		; check A for space
	JR	Z,WRAP30	; go if A = 32
	CP	'-'		; check A for hyphen
	JR	NZ,WRAP10	; loop back if A <> 45
WRAP30	INC	B		; advance counter
	INC	DE		; advance ptrs
	INC	HL
	JR	WRAP99		; exit routine
WRAP40	LD	B,$-$		; retrieve old values
WRAP50	LD	DE,$-$
WRAP60	LD	HL,$-$
WRAP99	POP	AF
	RET
;
;  End of E4SCRN/ASM
;
