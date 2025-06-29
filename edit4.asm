;========================================
;  ED-IT for the Model 4, version 1.2
;	copyright (c) 1995 by Mark Reed
;	all rights reserved
;========================================
;
	TITLE	'<EDIT4>'
	COM	'<(c) 1995 by Mark Reed>'
;
*GET SVCMAC
;
SCRBTM	EQU	23		; bottom screen line
SCRWID	EQU	80		; screen width
VLEN	EQU	1920		; length of VBUFF$
INBUF$	EQU	0420H		; DOS input buffer
;
	ORG	2600H
;
	DS	256		; allow 1 page of stack
;
;---------------------------------------------------------
;  Standard memory header
;
HEADER	JR	HEADER		; null "JR" instruction
OLDHI	DW	$-$		; old HIGH$ value
	DB	4,'EDIT'	; length of name, name
;
;---------------------------------------------------------
;  Main dispatch table
;
DISP$	DB	8		; LEFT ARROW
	DW	LTARROW
	DB	9		; RIGHT ARROW
	DW	RTARROW
	DB	11		; UP ARROW
	DW	UPARROW
	DB	10		; DOWN ARROW
	DW	DNARROW
	DB	24		; SHIFT LEFT ARROW
	DW	BLINE
	DB	25		; SHIFT RIGHT ARROW
	DW	ELINE
	DB	139		; CLEAR UP ARROW
	DW	CLEARUP
	DB	138		; CLEAR DOWN ARROW
	DW	CLEARDN
	DB	27		; SHIFT UP ARROW
	DW	SHIFTUP
	DB	26		; SHIFT DOWN ARROW
	DW	SHIFTDN
	DB	137		; CLEAR RIGHT ARROW
	DW	CLEARRT
	DB	1		; CTRL A
	DW	TOGINS
	DB	4		; CTRL D
	DW	CTRLD
	DB	23		; CTRL W
	DW	CTRLW
	DB	12		; CTRL L
	DW	CTRLL
	DB	19		; CTRL S
	DW	CTRLS
	DB	136		; CLEAR LEFT ARROW
	DW	CLEARLT
	DB	18		; CTRL R
	DW	RPTLAST
	DB	3		; CTRL C
	DW	CTRLC
	DB	2		; CTRL B
	DW	CTRLB
	DB	6		; CTRL F
	DW	CTRLF
	DB	14		; CTRL N
	DW	FORMFD
	DB	CR		; ENTER
	DW	ENTER
	DB	128		; BREAK
	DW	BREAK
	DB	129		; F1
	DW	CLEARRT
	DB	130		; F2
	DW	CTRLD
	DB	131		; F3
	DW	TOGINS
	DB	145		; SHIFT F1
	DW	BBLOCK
	DB	146		; SHIFT F2
	DW	EBLOCK
	DB	147		; SHIFT F3
	DW	DMBQURY
	DB	189		; CLEAR SHIFT =
	DW	QUIT
	DB	0		; end of table
	DC	15,0		; allow for 5 more entries
;
;---------------------------------------------------------
;  KEYIN Dispatch Table
;
KDISP$	DB	8		; LEFT ARROW
	DW	KLEFT
	DB	9		; RIGHT ARROW
	DW	KRIGHT
	DB	24		; SHIFT LEFT ARROW
	DW	KSLEFT
	DB	25		; SHIFT RIGHT ARROW
	DW	KSRIGHT
	DB	137		; CLEAR RIGHT ARROW
	DW	KTAB
	DB	1		; CTRL A
	DW	TOGINS
	DB	4		; CTRL D
	DW	KDEL
	DB	12		; CTRL L
	DW	KSCLEAR
	DB	31		; SHIFT CLEAR
	DW	KSCLEAR
	DB	136		; CLEAR LEFT ARROW
	DW	KDLBACK
	DB	3		; CONTROL C
	DW	KCCHAR
	DB	129		; F1
	DW	KTAB
	DB	130		; F2
	DW	KDEL
	DB	131		; F3
	DW	TOGINS
	DB	0		; end of table
;
;---------------------------------------------------------
;  Main menu dispatch table
;
MDISP$	DB	'F'		; File
	DW	FMENU
	DB	'B'		; Block
	DW	BMENU
	DB	'S'		; Search
	DW	SMENU
	DB	'P'		; Print
	DW	PMENU
	DB	'O'		; Other
	DW	OMENU
	DB	'Q'		; Quit
	DW	QUIT
	DB	0		; end of table
;
;---------------------------------------------------------
;  File menu dispatch table
;
FDISP$	DB	'L'		; Load
	DW	LFILE
	DB	'S'		; Save
	DW	SFILE
	DB	'N'		; New
	DW	NEWFILE
	DB	0		; end of table
;
;---------------------------------------------------------
;  Block menu dispatch table
;
BDISP$	DB	'B'		; Begin
	DW	BBLOCK
	DB	'E'		; End
	DW	EBLOCK
	DB	'D'		; Delete
	DW	DMBQURY
	DB	'M'		; Move
	DW	MBLOCK
	DB	'C'		; Copy
	DW	CBLOCK
	DB	'L'		; Load
	DW	LBLOCK
	DB	'S'		; Save
	DW	SMBLOCK
	DB	'U'		; Unmark
	DW	UBLOCK
	DB	0		; end of table
;
;---------------------------------------------------------
;  Search menu dispatch table
;
SDISP$	DB	'F'		; Find
	DW	FIND
	DB	'C'		; Change
	DW	REPLACE
	DB	'R'		; Repeat
	DW	RPTLAST
	DB	'A'		; Automatic
	DW	AUTO
	DB	'L'		; Line
	DW	GOLINE
	DB	0		; end of table
;
;---------------------------------------------------------
;  Print menu dispatch table
;
PDISP$	DB	'P'		; Print
	DW	PRFILE
	DB	'M'		; Margins
	DW	MARSET
	DB	'T'		; Titles
	DW	TTLSET
	DB	'N'		; Number
	DW	NUMSET
	DB	'O'		; Other
	DW	OTHSET
	DB	0		; end of table
;
;---------------------------------------------------------
;  Other menu dispatch table
;
ODISP$	DB	'T'		; Tab
	DW	TABSET
	DB	'L'		; Length
	DW	LENSET
	DB	'I'		; Info
	DW	INFO
	DB	'M'		; Mode
	DW	MDMENU
	DB	'D'		; DOS
	DW	DOS
	DB	0		; end of table
;
;---------------------------------------------------------
;  Mode menu dispatch table
;
MDDISP$	DB	'A'		; ASM
	DW	ASMSET
	DB	'B'		; BAS
	DW	BASSET
	DB	'C'		; CCC
	DW	CCCSET
	DB	'T'		; TXT
	DW	TXTSET
	DB	0		; end of table
;
;---------------------------------------------------------
;  Initialize
;
START	LD	SP,HEADER	; set up new stack
	LD	BC,8<8+'_'	; set cursor to underline
	@@VDCTL
	LD	(EXIT+1),A	; stuff old cursor char
	LD	C,28		; turn off reverse video
	CALL	DSP
	CALL	CMDTAIL		; handle command tail
	JR	EDIT		; bypass error routines
;
;---------------------------------------------------------
;  External error routine
;
PRMERR	LD	HL,44		; "Parameter error"
	LD	C,L		; display message and
	@@ERROR			;   exit to LS-DOS
;
;---------------------------------------------------------
;  Internal error routines
;
BLKERR	LD	HL,BLKERR$	; "Block not marked!"
	DB	0DDH
CMDERR	LD	HL,CMDERR$	; "Can't execute DOS cmd!"
	DB	0DDH
CPYERR	LD	HL,CPYERR$	; "Copy error!"
	DB	0DDH
FNDERR	LD	HL,FNDERR$	; "String not found!"
	DB	0DDH
MEMERR	LD	HL,MEMERR$	; "Out of memory!"
ALLERR	CALL	FORMAT		; format display screen
	CALL	BLANK		; blank bottom screen line
	CALL	DSPLY		; display message
	LD	HL,ERR$		; display exclamation
	CALL	DSPLY		;   mark, turn off cursor
	CALL	GETKEY		; wait for keystroke
;
;---------------------------------------------------------
;  Edit file
;
EDIT	LD	SP,HEADER	; reload stack
EDIT10	CALL	FORMAT		; display screen
	CALL	KEY		; A => keystroke
	CP	' '		; check A for ctrl char
	JR	C,EDIT20	; go if A < 32
	CP	128		; check A for ctrl char
	JR	NC,EDIT20	; go if A >= 128
	CALL	PUTCHAR		; insert/overtype char
	JR	EDIT10		; loop back
EDIT20	LD	HL,DISP$	; HL => dispatch table
	CALL	DSPATCH		; interpret keystroke
	JR	EDIT10		; loop back
;
;---------------------------------------------------------
;  Handle DOS errors
;
DOSERR	OR	10000000B	; display and return
	LD	C,A		; C  => error code
	@@FLAGS$		; IY => system flags
	SET	7,(IY+'C'-'A')	; put message in buffer
	LD	DE,SCRAP$	; DE => scratch buffer
	@@ERROR			; post error message
	PUSH	DE		; save ptr
DERR10	LD	A,(DE)		; A => char at DE
	CP	CR		; check A for ENTER
	JR	Z,DERR20	; go if A = 13
	INC	DE		; advance ptr
	JR	DERR10		; loop back
DERR20	DEC	DE		; back up over space
	LD	A,ETX		; A => ETX
	LD	(DE),A		; replace space with it
	POP	HL		; HL => scratch buffer
	JR	ALLERR		; display, etc.
;
;---------------------------------------------------------
;  Exit to DOS
;
EXIT	LD	BC,8<8+'_'	; set cursor to underline
	@@VDCTL
	@@CLS			; clear screen
	@@CKBRKC		; clear BREAK bit
	LD	HL,0		; signal no error
	@@EXIT			; exit to DOS
;
;---------------------------------------------------------
;  CMDTAIL:  Handle command tail
;	Entry:	HL => command tail
;	Exit:	All registers are altered
;
CMDTAIL	LD	C,15		; turn cursor off
	CALL	DSP
	CALL	DSPBUFF		; display title screen
	PUSH	HL		; save command tail
CT10	LD	A,(HL)		; A => char at HL
	CP	'('		; check for parameters
	JR	Z,CT20		; go if found
	CP	' '		; check for control char
	JR	C,APARM		; bypass if found
	INC	HL		; else advance ptr
	JR	CT10		; and loop back
CT20	LD	DE,PARM$	; DE => parameter table
	@@PARAM			; parse any parameters
	JP	NZ,PRMERR	; go if error
APARM	LD	DE,0		; default ASM=NO
	LD	A,D		; check ASM parameter
	OR	E
	CALL	NZ,ASMSET	; set ASM mode if ASM=YES
BPARM	LD	DE,0		; default BAS=NO
	LD	A,D		; check BAS parameter
	OR	E
	CALL	NZ,BASSET	; set BAS mode if BAS=YES
CPARM	LD	DE,0		; default CCC=NO
	LD	A,D		; check CCC parameter
	OR	E
	CALL	NZ,CCCSET	; set CCC mode if CCC=YES
EPARM	LD	DE,132		; default ENTER=132
	LD	A,E		; A => ENTER char
	LD	(ENTCHAR),A	; store it
	LD	A,(ERSP)	; A => ENTER response byte
	AND	STR		; check for string entry
	JR	Z,LPARM		; go if not string entry
	LD	A,(DE)		; A => ENTER char
	LD	(ENTCHAR),A	; store it
LPARM	LD	DE,SCRWID	; default LEN=SCRWID
	LD	A,E		; A => line length
	CP	20		; check lower limit
	JR	C,TPARM		; go if A < 20
	CP	SCRWID+1	; check upper limit
	JR	NC,TPARM	; go if A > SCRWID
	LD	(LINLEN),A	; store it
TPARM	LD	DE,1		; invalid default
	LD	A,E		; A => tab interval
	CP	2		; check lower limit
	JR	C,CT30		; go if A < 2
	CP	20+1		; check upper limit
	JR	NC,CT30		; go if A > 20
	LD	(TABINT),A	; store it
CT30	POP	HL		; retrieve command tail
	LD	A,(HL)		; A => char at HL
	CP	'*'		; check for asterisk
	JR	Z,CT40		; go if found
	PUSH	AF		; save char
	CALL	SETUP		; set up environment
	POP	AF		; retrieve char
	CP	'('		; check for parameters
	JR	Z,CT40		; go if found
	CP	' '		; check for control char
	JR	C,CT40		; go if found
	LD	DE,FNAME$	; DE => filename buffer
	PUSH	DE		; save ptr
CT35	LD	A,(HL)		; A  => char of filename
	LD	(DE),A		; store it in buffer
	INC	DE		; advance ptrs
	INC	HL
	CP	' '		; check for control char
	JR	NC,CT35		; loop back if A > 31
	POP	HL		; HL => filename buffer
	CALL	LOPEN		; open file if possible
	LD	BC,(FCB+6)	; BC => DEC/drive #
	LD	DE,FNAME$	; DE => filename buffer
	@@FNAME			; get "filename/ext:d"
	CALL	LOAD		; load file if possible
	LD	HL,TEXT$	; HL => start of text
	LD	(TXTCSR),HL	; restore text cursor
	XOR	A		; turn mod flag off
	LD	(MODFLAG),A
	RET
CT40	CALL	GETKEY		; wait for keystroke
	RET
;
;---------------------------------------------------------
;  SETUP:  Set up editing environment
;	Entry:	None
;	Exit:	A, BC, and DE are altered
;
SETUP	PUSH	HL
	LD	HL,0		; get HIGH$ in HL
	LD	B,H
	@@HIGH$
	LD	(HIMEM),HL	; store for later
	LD	DE,TEXT$	; DE => text buffer
	OR	A		; reset carry flag
	SBC	HL,DE		; find difference
	LD	(FREEMEM),HL	; store for later
	LD	HL,TEXT$	; HL => text buffer
	LD	(TXTCSR),HL	; store as text cursor
	LD	(FIRST),HL	;   and first display char
	LD	(TXTEND),HL	;   and end of text marker
	XOR	A		; A => zero
	LD	(HL),A		; mark end of buffer
	LD	(MODFLAG),A	; turn off mod flag
	INC	A
	INC	A		; A => 2
	LD	(INSFLAG),A	; turn insert on
	CALL	TOGINS		; then turn it off again
	LD	A,ETX		; A => 3
	LD	(FNAME$),A	; erase filename
	POP	HL
	RET
;
*GET E4CMD			; command module
*GET E4DISK			; disk input/output module
*GET E4KBD			; keyboard input module
*GET E4MENU			; menu command module
*GET E4MISC			; miscellaneous functions
*GET E4PRINT			; print module
*GET E4SCRN			; screen output module
;
;---------------------------------------------------------
;  Messages
;
DOSMSG$	DB	'DOS command',ETX
FNDMSG$	DB	'Find string',ETX
RPLMSG$	DB	'Replace string',ETX
LBNAME$	DB	'Load block',ETX
LFNAME$	DB	'Load file',ETX
SBNAME$	DB	'Save block',ETX
SFNAME$	DB	'Save file',ETX
TABINT$	DB	'Tab interval (2-20)',ETX
LINLEN$	DB	'Line length (20-80)',ETX
GOLINE$	DB	'Go to line number',ETX
LEFT$	DB	'Left margin',ETX
LINE$	DB	'Number of printed lines',ETX
PAGE$	DB	'Page length',ETX
TOP$	DB	'Top margin',ETX
ADDLF$	DB	'Add line-feeds',ETX
ZERO$	DB	'Print slashed zeroes',ETX
HDRMSG$	DB	'Header',ETX
FTRMSG$	DB	'Footer',ETX
NUM1$	DB	'Starting page number',ETX
PROMPT$	DB	': ',14,ETX
;
CREATE$	DB	'File doesn''t exist; create it',ETX
MOD$	DB	'File has changed; save it',ETX
UNMOD$	DB	'File is unchanged; save it anyway',ETX
SURE$	DB	'Are you sure',ETX
SINGLE$	DB	'Pause after each page',ETX
;
QMSG$	DB	' (Y/N)? ',14,ETX
;
IMSG0$	DB	'    Memory in use: '
IMSG1$	DB	'00000  Free memory: '
IMSG2$	DB	'00000  Total: '
IMSG3$	DB	'00000  '
FEXT$	DB	'    ',ETX
;
EDIT$	DB	'EDIT',ETX
;
CONT$	DB	'Press a key... ',14,ETX
FNDING$	DB	'Finding... ',ETX
LDING$	DB	'Loading... ',ETX
PRTNG$	DB	'Printing... ',ETX
RPLING$	DB	'Replacing... ',ETX
SVING$	DB	'Saving... ',ETX
;
BLKERR$	DB	'Block not marked',ETX
CMDERR$	DB	'Can''t execute DOS command',ETX
CPYERR$	DB	'Can''t copy block',ETX
FNDERR$	DB	'String not found',ETX
MEMERR$	DB	'Out of memory',ETX
;
ERR$	DB	'!',15,ETX
;
UNTTL$	DB	'(Untitled)',ETX
;
;---------------------------------------------------------
;  Menu texts
;
MAIN$	DB	'File  Block  Search  Print  Other  '
	DB	'Quit',15,ETX
;
FILE$	DB	'Load  Save  New',ETX
;
BLOCK$	DB	'Begin  End  Delete  Move  Copy  Load  '
	DB	'Save  Unmark',ETX
;
SEARCH$	DB	'Find  Change  Automatic  Repeat  Line'
	DB	ETX
;
PRINT$	DB	'Print  Margins  Titles  Number  '
	DB	'Other',ETX
;
OTHER$	DB	'Tab  Length  Info  Mode  DOS',ETX
;
MODE$	DB	'Assembly  BASIC  C  Text',ETX
;
;---------------------------------------------------------
;  Data area
;
TXTEND	DS	2		; end of text
SCRCSR	DS	2		; screen cursor
HIMEM	DS	2		; high memory ptr
FREEMEM	DS	2		; amount of free memory
KCSR	DS	2		; KEYIN cursor
IBUFF$	DS	2		; KEYIN input buffer
LDPTR1	DS	2		; last delimiter pointers
LDPTR2	DS	2
LINE2	DS	2		; start of screen line 2
LINEBTM	DS	2		; start of bottom line
;
TXTCSR	DW	TEXT$		; text cursor
FIRST	DW	TEXT$		; first display char
LAST	DW	$-$		; last display char
ROWCOL	DW	0		; screen column, row
TABINT	DB	8		; tab interval
RFLAG	DB	0		; replace flag
MAXLNS	DB	54		; max lines per page
PAGELEN	DB	66		; printed page length
LMARGIN	DB	10		; left margin
TMARGIN	DB	0		; top margin
PAGE1	DB	1		; 1st page number
;
INSFLAG	DS	1		; insert/overtype flag
MODFLAG	DS	1		; modification flag
ENTCHAR	DS	1		; ENTER character
LINLEN	DS	1		; line length
KMAX	DS	1		; KEYIN max char value
LDCNTR	DS	1		; last delimiter counter
PASSNUM	DS	1		; format screen pass #
CSRCHAR	DS	1		; char under cursor
LINES	DS	1		; lines already printed
PAGENUM	DS	1		; current page number
;
	DB	0		; length of find string
FIND$	DC	SCRWID-13,ETX	; find string
	DB	0		; length of replace string
RPLC$	DC	SCRWID-13,ETX	; replace string
	DB	0		; length of header string
HEADER$	DC	SCRWID-8,ETX	; header string
	DB	0		; length of footer string
FOOTER$	DC	SCRWID-8,ETX	; footer string
;
DOSCMD$	DC	SCRWID-13,ETX	; DOS command string
;
BNAME$	DB	'EDIT/BLK',ETX
	DS	13
;
FNAME$	DS	22		; filename storage
;
ASMEXT$	DB	'ASM'		; file extensions
BASEXT$	DB	'BAS'
CCCEXT$	DB	'C  '
;
FCB	DS	32		; file control block
IOBUF$	DS	256		; I/O buffer
;
	DC	100,0		; patch area
;
SCRAP$	DS	SCRWID		; scrap buffer
;
;---------------------------------------------------------
;  Parameter table
;
PARM$	DB	128		; start of table
;
	DB	SW.OR.ABR.OR.3
	DB	'ASM'
ARSP	DB	SW
	DW	APARM+1
;
	DB	SW.OR.ABR.OR.3
	DB	'BAS'
BRSP	DB	SW
	DW	BPARM+1
;
	DB	SW.OR.ABR.OR.3
	DB	'CCC'
CRSP	DB	SW
	DW	CPARM+1
;
	DB	VAL.OR.ABR.OR.5
	DB	'ENTER'
ERSP	DB	VAL
	DW	EPARM+1
;
	DB	VAL.OR.ABR.OR.3
	DB	'LEN'
LRSP	DB	VAL
	DW	LPARM+1
;
	DB	VAL.OR.ABR.OR.3
	DB	'TAB'
TRSP	DB	VAL
	DW	TPARM+1
;
	DB	0		; end of table
;
;---------------------------------------------------------
;  Title screen
;
VBUFF$	EQU	$		; screen buffer
;
*LIST OFF
	DB	'                                   Versi'
	DB	'on 1.2                                  '
	DB	'                 °°°°°°°°°°°°°°°°°°°°°°°'
	DB	'°°°°°°°°°°°°°°°°°°°°°°°                 '
	DB	'                ‚ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
	DB	'ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ                 '
	DB	'                   °°°°°°°°   °°°°°°°   '
	DB	'       °°  °°°°°°°°                   '
	DB	'                   ¿¿¿  ª¿¿¯¿•  '
	DB	'       ¿¿•  ¿¿Ÿ…                   '
	DB	'                   ¿¿¿       ª¿¿    ¿•  '
	DB	'       ¿¿•     ¿¿•                      '
	DB	'                   ¿¿¿°°°   ª¿¿    ¿•  '
	DB	'°°°°  ¿¿•     ¿¿•                      '
	DB	'                   ¿¿¿ƒƒƒ   ª¿¿    ¿•  '
	DB	'ƒƒƒƒ  ¿¿•     ¿¿•                      '
	DB	'                   ¿¿¿       ª¿¿    ¿•  '
	DB	'       ¿¿•     ¿¿•                      '
	DB	'                   ¿¿¿¼¼¼¼¼  ª¿¿¼¼¼¾¿•  '
	DB	'       ¿¿•     ¿¿•                      '
	DB	'                   ƒƒƒƒƒƒƒƒ  ‚ƒƒƒƒƒƒƒ   '
	DB	'       ƒƒ     ƒƒ                      '
	DB	'                 °°°°°°°°°°°°°°°°°°°°°°°'
	DB	'°°°°°°°°°°°°°°°°°°°°°°°                 '
	DB	'                ‚ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
	DB	'ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ                 '
	DB	'                  F O R   T H E   T R S '
	DB	'- 8 0   M O D E L   4                   '
	DB	'                ¨¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼'
	DB	'¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼¼                 '
	DB	'                                        '
	DB	'                                        '
	DB	'           copyright (c) 1995 by Mark Al'
	DB	'len Reed, all rights reserved           '
	DB	'                                        '
	DB	'                                        '
	DB	'                                 distrib'
	DB	'uted by:                                '
	DB	'                                COMPUTER'
	DB	' NEWS 80                                '
	DB	'                                 P.O. Bo'
	DB	'x 50127                                 '
	DB	'                             Casper, WY '
	DB	' 82605-0127                             '
	DB	'                                        '
	DB	'                                        '
	DB	'                          >>> Press a ke'
	DB	'y to begin <<<                          '
*LIST ON
;
	DB	0		; mark buffer start
TEXT$	EQU	$		; text buffer
;
	END	START
