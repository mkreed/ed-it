;=========================================
;  Menu Command Module for Model 4 ED-IT
;	copyright (c) 1995 by Mark Reed
;	all rights reserved
;=========================================
;
;---------------------------------------------------------
;  ASMSET, BASSET, CCCSET:  Set programming modes
;	Entry:	None
;	Exit:	AF is altered
;
ASMSET	LD	A,';'		; A => semi-colon
	LD	(UCF20+1),A	; stuff comment marker
	LD	A,27H		; A => single quote
	LD	(UCF40+1),A	; stuff quote markers
	LD	(UCF55+1),A
	XOR	A		; A => "NOP" instruction
	LD	(UCFILE),A	; enable UCFILE routine
	LD	A,8		; A => tab interval of 8
	PUSH	HL
	LD	HL,ASMEXT$	; HL => "ASM" extension
	JR	PGMSET		; set programming mode
BASSET	LD	A,27H		; A => single quote
	LD	(UCF20+1),A	; stuff comment marker
	LD	A,'"'		; A => double quote
	LD	(UCF40+1),A	; stuff quote markers
	LD	(UCF55+1),A
	XOR	A		; A => "NOP" instruction
	LD	(UCFILE),A	; enable UCFILE routine
	LD	A,4		; A => tab interval of 4
	PUSH	HL
	LD	HL,BASEXT$	; HL => "BAS" extension
	JR	PGMSET
CCCSET	LD	A,0C9H		; A => "RET" instruction
	LD	(UCFILE),A	; disable UCFILE routine
	LD	A,4		; A => tab interval of 4
	PUSH	HL
	LD	HL,CCCEXT$	; HL => "CCC" extension
PGMSET	LD	(TABINT),A	; stuff tab interval
	XOR	A		; A => "NOP" instruction
	LD	(ASM26),A	; enable ASM26 routine
	LD	(DOEXT),A	; enable DOEXT routine
	LD	A,0C9H		; A => "RET" instruction
	LD	(WRAP),A	; disable wordwrap
	RPUSH	BC,DE
	LD	DE,FEXT$	; DE => destination
	LD	BC,3		; BC => block length
	LDIR			; move "ASM" to FEXT$
	RPOP	DE,BC,HL
	RET
;
;---------------------------------------------------------
;  AUTO:  Automatic find/change
;	Entry:	None
;
AUTO	CALL	REPLACE		; do the first find/change
	@@CKBRKC		; clear BREAK bit
AUTO10	CALL	RFIND		; find the next one
	CALL	RRPLC		; replace the next one
	@@CKBRKC		; check for BREAK
	RET	NZ		; exit if BREAK
	JR	AUTO10		; loop back
;
;---------------------------------------------------------
;  BBLOCK:  Begin block
;	Entry:	None
;	Exit:	A is altered
;
BBLOCK	LD	A,1		; block start marker
	JP	INSERT		; insert it into memory
;
;---------------------------------------------------------
;  BMENU:  Display and handle block menu
;	Entry:	None
;
BMENU	LD	HL,BLOCK$	; HL => display string
	LD	DE,BDISP$	; dispatch table
	JP	DOMENU

;---------------------------------------------------------
;  CBLOCK:  Copy block to cursor position
;	Entry:	None
;	Exit:	A is altered
;
CBLOCK	RPUSH	BC,DE,HL
	CALL	FBLOCK		; HL => block start
	JP	NZ,BLKERR	; exit if no block found
	LD	DE,(TXTCSR)	; DE => text cursor
	CALL	CMPARE		; compare HL with DE
	JP	Z,CPYERR	; go if HL = DE
	JR	NC,CB10		; bypass if HL > DE
	ADD	HL,BC		; HL => block end + 1
	CALL	CMPARE		; compare HL with DE
	JP	Z,CPYERR	; go if HL = DE
	JP	NC,CPYERR	; go if HL > DE
CB10	CALL	IBLOCK		; insert BC chars
	CALL	FBLOCK		; find block again
	LD	DE,(TXTCSR)	; DE => destination
	LDIR			; transfer the block
	RPOP	HL,DE,BC
	RET
;
;---------------------------------------------------------
;  DMBLOCK:  Delete block menu entry
;	Entry:	None
;
DMBLOCK	CALL	FBLOCK		; find the block
	JP	NZ,BLKERR	; go if no block found
	DEC	HL		; HL => block start marker
	INC	BC		; adjust block length to
	INC	BC		;   delete block markers
	LD	(TXTCSR),HL	; move to block start
	JP	DLBLOCK		; delete the block
;
;---------------------------------------------------------
;  DMBQURY:  Ask if block should be deleted
;	Entry:	None
;
DMBQURY	LD	HL,SURE$	; "Are you sure?"
	CALL	QUERY		; get yes/no answer
	RET	NZ		; abort if No
	JP	DMBLOCK		; go delete block
;
;---------------------------------------------------------
;  DOMENU:  Display and handle menus
;	Entry:	DE => menu dispatch table
;		HL => menu display string
;
DOMENU	CALL	BLANK		; blank menu line
	CALL	DSPLY		; display menu string
	CALL	GETKEY		; wait for a keystroke
	EX	DE,HL		; HL => dispatch table
	JP	DSPATCH		; interpret keystroke
;
;---------------------------------------------------------
;  DOS:  Enter and execute a DOS command
;	Entry:	None
;
DOS	LD	A,(FREEMEM+1)	; A => MSB of free memory
	CP	20H		; check for 8K or more
	JP	C,MEMERR	; abort if less than 8K
	@@FLAGS$		; IY => flags table
	BIT	0,(IY+'C'-'A')	; check HIGH$ bit
	JP	NZ,CMDERR	; abort if HIGH$ is frozen
	LD	HL,DOSMSG$	; HL => "DOS command:"
	LD	DE,DOSCMD$	; DE => DOS command buffer
	LD	B,SCRWID-14	; B  => max input length
	CALL	GETSTR		; get string input
	LD	A,B		; A => # chars entered
	OR	A		; check A for zero
	RET	Z		; exit if nothing typed
	LD	DE,INBUF$	; DE => DOS input buffer
DOS10	LD	A,(HL)		; A  => char from DOS cmd
	CP	ETX		; check A for ETX
	JR	Z,DOS20		; go if A = 3
	LD	(DE),A		; transfer char
	INC	DE		; advance ptrs
	INC	HL
	JR	DOS10		; loop back
DOS20	LD	A,CR		; change ETX to CR
	LD	(DE),A		; store in DOS buffer
	@@CLS			; clear screen
	LD	HL,INBUF$	; HL => DOS input buffer
	@@DSPLY			; display the command
	LD	H,(IY+26)	; point to @ABORT SVC
	LD	L,21*2		;   entry
	LD	E,(HL)		; E => LSB of @ABORT
	INC	HL
	LD	D,(HL)		; D => MSB of @ABORT
	LD	(DOS30+1),DE	; stuff into program
	LD	(DOS50+1),DE	; store for later
	EX	DE,HL		; HL => source
	LD	DE,OLDAB$	; DE => destination
	LD	BC,6		; BC => length
	LDIR			; copy from @ABORT/@EXIT
	LD	HL,0		; HL => 0 (get LOW$/HIGH$)
	LD	B,H		; B  => 0 (get HIGH$)
	@@HIGH$			; return HIGH$ in HL
	LD	(OLDHI),HL	; stuff HIGH$ into header
	EX	DE,HL		; DE => destination
	LD	HL,STUB2-1	; HL => source
	LD	BC,STUB2-STUB1	; BC => length
	LDDR			; move stub to himem
	EX	DE,HL		; HL => new HIGH$ value
	INC	HL		; advance to stub start
	LD	(STUBADR+1),HL	; stuff into program
	PUSH	HL		; put HL in IX
	POP	IX
	LD	HL,(TXTEND)	; HL => text end
	PUSH	HL		; save it
	LD	DE,HEADER	; DE => start of program
	OR	A		; reset carry flag
	SBC	HL,DE		; find difference
	INC	HL		; adjust it
	LD	(IX+7),L	; stuff into stub
	LD	(IX+8),H
	PUSH	HL		; BC => LDDR length
	POP	BC
	POP	HL		; HL => text end (source)
	PUSH	IX		; DE => high memory
	POP	DE		;   (destination)
	DEC	DE
	LDDR			; transfer to high memory
	EX	DE,HL		; HL => temp HIGH$ value
	@@HIGH$			; set it (B = 0 from LDDR)
	JP	NZ,CMDERR	; abort if error
	INC	HL		; HL => module start
	LD	(IX+1),L	; stuff into stub
	LD	(IX+2),H
	SET	0,(IY+'C'-'A')	; freeze HIGH$
	LD	HL,NEWAB$	; HL => source
DOS30	LD	DE,$-$		; DE => destination
	LD	BC,6		; BC => length
	LDIR			; copy to @ABORT/@EXIT
	LD	HL,INBUF$	; HL => DOS command buffer
	@@CMNDI			; invoke command
;
DOS40	LD	HL,OLDAB$	; HL => source
DOS50	LD	DE,$-$		; DE => destination
	LD	BC,6		; BC => length
	LDIR			; copy to @ABORT/@EXIT
	@@FLAGS$		; IY => system flags
	RES	0,(IY+'C'-'A')	; un-freeze HIGH$
	LD	HL,(OLDHI)	; HL => old HIGH$ address
	LD	B,0		; B  => 0 (set HIGH$)
	@@HIGH$
	LD	HL,CONT$	; "Press a key..."
	CALL	DSPLY		; display message
	CALL	GETKEY		; wait for keystroke
	JP	EDIT		; rejoin the program
;
OLDAB$	DC	6,0		; space for 6 lomem bytes
;
NEWAB$	DB	0,0,0		; temporary replacement
STUBADR	JP	$-$		;   for @ABORT/@EXIT
;
STUB1	LD	HL,$-$		; HL => source
	LD	DE,HEADER	; DE => destination
	LD	BC,$-$		; BC => length
	LDIR			; move back from himem
	JP	DOS40		; rejoin the program
STUB2	EQU	$		; end of stub + 1
;
;---------------------------------------------------------
;  EBLOCK:  End block
;	Entry:	None
;	Exit:	A is altered
;
EBLOCK	LD	A,2		; block end marker
	JP	INSERT		; insert it into memory
;
;---------------------------------------------------------
;  FIND:  Find string menu entry
;	Entry:	None
;
FIND	LD	HL,FNDMSG$	; HL => "Find string:"
	LD	DE,FIND$	; DE => find input buffer
	LD	B,SCRWID-14	; B  => max input length
	CALL	GETSTR		; get string input
	LD	A,B		; A => # chars entered
	OR	A		; check for zero
	RET	Z		; exit if nothing typed
	LD	(FIND$-1),A	; else store input length
	XOR	A		; reset replace flag
	LD	(RFLAG),A
	JP	RFIND		; find the string
;
;---------------------------------------------------------
;  FMENU:  Display and handle file menu
;	Entry:	None
;
FMENU	LD	HL,FILE$	; HL => display string
	LD	DE,FDISP$	; DE => dispatch table
	JP	DOMENU
;
;---------------------------------------------------------
;  GOLINE:  Go to a specific line number
;	Entry:	None
;
GOLINE	LD	HL,GOLINE$	; HL => "Go to line..."
	LD	DE,SCRAP$	; DE => input buffer
	LD	B,4		; B  => max input length
	LD	A,ETX		; clear input buffer
	LD	(DE),A
	CALL	GETSTR		; get string input
	LD	A,B		; A => # chars entered
	OR	A		; check for zero
	RET	Z		; exit if A = 0
	@@DECHEX		; BC => decimal value
	LD	A,B		; check BC for zero
	OR	C
	RET	Z		; exit if BC = 0
	LD	DE,TEXT$	; DE => start of text
	LD	(TXTCSR),DE	; store as new text cursor
GOLIN10	DEC	BC		; adjust counter
	LD	A,B		; check BC for zero
	OR	C
	JR	Z,GOLIN20	; go if BC = 0
	CALL	NLINE		; DE => start of next line
	LD	A,D		; check DE for zero
	OR	E
	JR	NZ,GOLIN10	; loop back if DE > 0
	LD	DE,(TXTEND)	; DE => text end
GOLIN20	LD	(TXTCSR),DE	; store new text cursor
	RET
;
;---------------------------------------------------------
;  INFO:  Display program information
;	Entry:	None
;
INFO	LD	HL,(TXTEND)	; HL => end of text
	LD	DE,TEXT$	; DE => start of text
	PUSH	DE		; save it
	OR	A		; reset carry flag
	SBC	HL,DE		; find difference
	INC	HL		; adjust it
	LD	DE,IMSG1$	; DE => 1st info msg
	@@HEXDEC		; convert to decimal
	LD	HL,(FREEMEM)	; HL => free memory
	LD	DE,IMSG2$	; DE => 2nd info msg
	@@HEXDEC		; convert to decimal
	LD	HL,(HIMEM)	; HL => HIGH$ value
	POP	DE		; DE => start of text
	OR	A		; reset carry flag
	SBC	HL,DE		; find difference
	INC	HL		; adjust it
	LD	DE,IMSG3$	; DE => 3rd info msg
	@@HEXDEC		; convert to decimal
	CALL	BLANK		; blank menu line
	LD	HL,FNAME$	; HL => filename buffer
	LD	A,(HL)		; A  => char at HL
	CP	ETX		; check for end marker
	JR	NZ,INF10	; go if filename
	LD	HL,UNTTL$	; HL => "(Untitled)"
INF10	CALL	DSPLY		; display message
	LD	HL,IMSG0$	; HL => info msg
	CALL	DSPLY		; display it
	LD	A,(MODFLAG)	; A  => mod flag
	OR	A		; check A for zero
	JR	Z,INF20		; go if mod flag is off
	LD	C,'*'		; else display asterisk
	@@DSP
INF20	JP	GETKEY		; wait for a key
;
;---------------------------------------------------------
;  LENSET:  Set line length
;	Entry:	None
;
LENSET	LD	HL,LINLEN$	; HL => prompt
	LD	A,(LINLEN)	; A  => current length
	CALL	GETNUM		; get numeric input
	CP	20		; check lower range
	RET	C		; exit if A < 20
	CP	SCRWID+1	; check upper range
	RET	NC		; exit if A > SCRWID
	LD	(LINLEN),A	; store it
	LD	HL,(TXTCSR)	; HL => text cursor
	PUSH	HL		; save it
	LD	HL,(FIRST)	; HL => first char
	LD	(TXTCSR),HL	; store as text cursor
	CALL	BLINE		; go to line start
	LD	HL,(TXTCSR)	; HL => new first char
	LD	(FIRST),HL	; store it
	POP	HL		; HL => old text cursor
	LD	(TXTCSR),HL	; store it
	RET
;
;---------------------------------------------------------
;  MARSET:  Set margins and page lengths for print-outs
;	Entry:	None
;
MARSET	LD	HL,LEFT$	; HL => prompt
	LD	A,(LMARGIN)	; A  => current margin
	CALL	GETNUM		; get numeric input
	LD	(LMARGIN),A	; store new value
	LD	HL,TOP$		; HL => prompt
	LD	A,(TMARGIN)	; A  => current margin
	CALL	GETNUM		; get numeric input
	LD	(TMARGIN),A	; store new value
	LD	HL,LINE$	; HL => prompt
	LD	A,(MAXLNS)	; A  => current maximum
	CALL	GETNUM		; get numeric input
	LD	(MAXLNS),A	; store new value
	LD	HL,PAGE$	; HL => prompt
	LD	A,(PAGELEN)	; A  => current length
	CALL	GETNUM		; get numeric input
	LD	(PAGELEN),A	; store new value
	RET
;
;---------------------------------------------------------
;  MBLOCK:  Move block to cursor position
;	Entry:	None
;
MBLOCK	CALL	CBLOCK		; copy block
	LD	A,3		; A => marker character
	CALL	INSERT		; insert it
	CALL	FBLOCK		; find block
	DEC	HL		; point to start marker
	INC	BC		; adjust byte counter
	INC	BC
	LD	(TXTCSR),HL	; move to block start
	CALL	DLBLOCK		; delete block
	LD	HL,TEXT$	; HL => text start
	LD	A,3		; look for marker
	CP	(HL)		; check first char
	JR	Z,MBLCK10	; go if found
	CALL	FCHAR		; look for marker again
MBLCK10	LD	(TXTCSR),HL	; store new text cursor
	LD	BC,1		; delete one char
	JP	DLBLOCK		; do it
;
;---------------------------------------------------------
;  MDMENU:  Set file mode
;	Entry:	None
;
MDMENU	LD	HL,MODE$	; HL => display string
	LD	DE,MDDISP$	; DE => dispatch table
	JP	DOMENU
;
;---------------------------------------------------------
;  NEWFILE:  Erase file in memory
;	Entry:	None
;	Exit:	All registers are altered
;
NEWFILE	LD	HL,SURE$	; "Are you sure (Y/N)?"
	CALL	QUERY		; get yes/no answer
	CALL	Z,SETUP		; set up file if Yes
	RET
;
;---------------------------------------------------------
;  NUMSET:  Set starting page number for print-outs
;	Entry:	None
;
NUMSET	LD	HL,NUM1$	; HL => prompt
	LD	A,(PAGE1)	; A  => current value
	CALL	GETNUM		; get numeric input
	LD	(PAGE1),A	; store new value
	RET
;
;---------------------------------------------------------
;  OMENU:  Display and handle other menu
;	Entry:	None
;
OMENU	LD	HL,OTHER$	; HL => display string
	LD	DE,ODISP$	; DE => dispatch table
	JP	DOMENU
;
;---------------------------------------------------------
;  OTHSET:  Set other print-out variables
;	Entry:	None
;
OTHSET	LD	HL,SINGLE$	; HL => question
	CALL	QUERY		; get yes/no answer
	JR	NZ,OTH10	; bypass if no
	XOR	A		; A => "NOP" instruction
	JR	OTH20		; bypass next "LD A"
OTH10	LD	A,0C9H		; A => "RET" instruction
OTH20	LD	(PFORM99),A	; enable/disable line-feed
	LD	HL,ADDLF$	; HL => question
	CALL	QUERY		; get yes/no answer
	JR	NZ,OTH30	; bypass if no
	XOR	A		; A => "NOP" instruction
	JR	OTH40		; bypass next "LD A"
OTH30	LD	A,0C9H		; A => "RET" instruction
OTH40	LD	(PCR10),A	; enable/disable pausing
	LD	HL,ZERO$	; HL => question
	CALL	QUERY		; get yes/no answer
	JR	NZ,OTH50	; bypass if no
	XOR	A		; A => "NOP" instruction
	JR	OTH60		; bypass next "LD A"
OTH50	LD	A,0C9H		; A => "RET" instruction
OTH60	LD	(PZERO),A	; enable/disable slashes
	RET
;
;---------------------------------------------------------
;  PMENU:  Display and handle print menu
;	Entry:	None
;
PMENU	LD	HL,PRINT$	; HL => display string
	LD	DE,PDISP$	; DE => dispatch table
	JP	DOMENU
;
;---------------------------------------------------------
;  QUIT:  End the program
;	Entry:	None
;	Exit:	None
;
QUIT	LD	HL,TEXT$	; HL => start of text
	LD	A,(HL)		; A  => first text char
	OR	A		; check for ending zero
	JP	Z,EXIT		; exit if no text
	LD	A,(MODFLAG)	; check mod flag for zero
	OR	A
	JR	Z,QUIT10	; go if mod flag = 0
	LD	HL,MOD$		; "File has changed..."
	DB	0DDH
QUIT10	LD	HL,UNMOD$	; "File is unchanged..."
	CALL	QUERY		; get yes/no answer
	CALL	Z,SFILE		; save file if Yes
	JP	EXIT		; and exit
;
;---------------------------------------------------------
;  REPLACE:  Replace string in memory
;	Entry:	None
;	Exit:	None
;
REPLACE	CALL	FIND		; find the string first
	RPUSH	AF,DE,HL
	LD	HL,RPLMSG$	; HL => "Replace string:"
	LD	DE,RPLC$	; DE => replace buffer
	LD	B,SCRWID-14	; B  => max input length
	CALL	GETSTR		; get string input
	LD	A,B		; A => # chars entered
	LD	(RPLC$-1),A	; store input length
	LD	A,1		; set replace flag
	LD	(RFLAG),A
	CALL	RRPLC		; replace the string
RPL99	RPOP	HL,DE,AF
	RET
;
;---------------------------------------------------------
;  RPTLAST:  Repeat last find/change
;	Entry:	None
;	Exit:	A is altered
;
RPTLAST	CALL	RFIND		; find next occurrence
	LD	A,(RFLAG)	; A => replace flag
	OR	A		; check A for zero
	CALL	NZ,RRPLC	; replace next if A <> 0
	RET
;
;---------------------------------------------------------
;  SMBLOCK:  Save block menu entry
;	Entry:	None
;
SMBLOCK	CALL	FBLOCK		; find the block
	JP	NZ,BLKERR	; abort if no block found
	JP	SBLOCK		; save the block
;
;---------------------------------------------------------
;  SMENU:  Display and handle search menu
;	Entry:	None
;
SMENU	LD	HL,SEARCH$	; HL => display string
	LD	DE,SDISP$	; DE => dispatch table
	JP	DOMENU
;
;---------------------------------------------------------
;  TABSET:  Set tab interval
;	Entry:	None
;
TABSET	LD	HL,TABINT$	; HL => prompt
	LD	A,(TABINT)	; A  => current interval
	CALL	GETNUM		; get numeric input
	CP	2		; check lower range
	RET	C		; exit if A < 2
	CP	20+1		; check upper range
	RET	NC		; exit if A > 20
	LD	(TABINT),A	; store it
	RET
;
;---------------------------------------------------------
;  TTLSET:  Set header and footer
;	Entry:	None
;
TTLSET	LD	HL,HDRMSG$	; HL => "Header:"
	LD	DE,HEADER$	; DE => input buffer
	LD	B,SCRWID-9	; B  => max input length
	CALL	GETSTR		; get string input
	LD	A,B		; A  => input length
	LD	(HEADER$-1),A	; store it
	LD	HL,FTRMSG$	; HL => "Footer:"
	LD	DE,FOOTER$	; DE => input buffer
	LD	B,SCRWID-9	; B  => max input length
	CALL	GETSTR		; get string input
	LD	A,B		; A  => input length
	LD	(FOOTER$-1),A	; store it
	RET
;
;---------------------------------------------------------
;  TXTSET:  Set "TXT" mode
;	Entry:	None
;
TXTSET	LD	A,0C9H		; A => "RET" instruction
	LD	(ASM26),A	; disable ASM26 routine
	LD	(DOEXT),A	; disable DOEXT routine
	LD	(UCFILE),A	; disable UCFILE routine
	XOR	A		; A => "NOP" instruction
	LD	(WRAP),A	; enable wordwrap
	LD	A,8		; set tab interval of 8
	LD	(TABINT),A
	LD	A,' '		; A => space
	LD	(FEXT$),A	; store 3 spaces as file
	LD	(FEXT$+1),A	;   extension
	LD	(FEXT$+2),A
	RET
;
;---------------------------------------------------------
;  UBLOCK:  Unmark any blocks
;	Entry:	None
;	Exit:	None
;
UBLOCK	RPUSH	AF,BC,HL
	CALL	FBLOCK		; HL => block start
	JR	NZ,UB99		; exit if no block found
	DEC	HL		; point to start marker
	PUSH	HL		; save for later
	ADD	HL,BC		; point to end marker
	INC	HL
	LD	(TXTCSR),HL	; store as text cursor
	LD	BC,1		; delete one char
	CALL	DLBLOCK		; do it
	POP	HL		; retrieve block start
	LD	(TXTCSR),HL	; store as text cursor
	LD	BC,1		; delete one char
	CALL	DLBLOCK		; do it
UB99	RPOP	HL,BC,AF
	RET
;
;  End of E4MENU/ASM
;
