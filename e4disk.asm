;==============================================
;  Disk Input/Output Module for Model 4 ED-IT
;	copyright (c) 1991 by Mark Reed
;	all rights reserved
;==============================================
;
;---------------------------------------------------------
;  ASM26:  Add ASCII 26 to end of /ASM files
;	Entry:	None
;	Exit:	A is altered
;
ASM26	RET			; disable ASM26
	LD	A,(MODFLAG)	; A => modification flag
	PUSH	AF		; save it
	PUSH	HL
	LD	HL,(FREEMEM)	; HL => free memory
	LD	A,H		; check HL for zero
	OR	L
	JR	Z,ASM26Z	; return if HL = 0
	LD	HL,(TXTEND)	; HL => text end
	DEC	HL		; decrease ptr
	LD	A,(HL)		; A  => char at HL
	CP	26		; check for ASCII 26
	JR	Z,ASM26Z	; return if A = 26
	INC	HL		; advance ptr
	PUSH	HL		; save it
	LD	HL,(TXTCSR)	; HL => text cursor
	EX	(SP),HL		; HL => text end
	LD	(TXTCSR),HL	; store as text cursor
	LD	A,26		; insert ASCII 26
	CALL	INSERT
	POP	HL		; HL => text cursor
	LD	(TXTCSR),HL	; store it
ASM26Z	POP	HL
	POP	AF		; retrieve mod flag
	LD	(MODFLAG),A	; store it
	RET
;
;---------------------------------------------------------
;  DOEXT:  Add extension to file (if desired)
;	Entry:	DE => FCB
;	Exit:	A is altered
;
DOEXT	RET			; disable DOEXT
	PUSH	HL
	LD	HL,FEXT$	; HL => default extension
	@@FEXT			; add it to file
	PUSH	DE
	LD	H,D		; HL => FCB
	LD	L,E		; DE => FCB
DOEXT10	LD	A,(HL)		; A  => char in filename
	INC	HL		; advance pointer
	CP	' '		; is it a space?
	JR	Z,DOEXT10	; yes -- ignore it
	LD	(DE),A		; else store it
	JR	C,DOEXT20	; exit if A < 32
	INC	DE		; advance ptr
	JR	DOEXT10		; loop back
DOEXT20	RPOP	DE,HL
	RET
;
;---------------------------------------------------------
;  LBLOCK:  Load block from disk
;	Entry:	None
;	Exit:	A is altered
;
LBLOCK	PUSH	HL
	LD	HL,(TXTCSR)	; HL => text cursor
	PUSH	HL		; save it
	CALL	LBNAME		; get block file name
	CALL	LOAD		; load file
	POP	HL		; retrieve text cursor
	LD	(TXTCSR),HL	; store it again
	POP	HL
	RET
;
;---------------------------------------------------------
;  LBNAME:  Get name of block to load, then open it
;	Entry:	None
;	Exit:	A is altered
;		DE <= FCB
;
LBNAME	RPUSH	BC,HL
	LD	HL,LBNAME$	; HL => "Load block:"
	LD	DE,BNAME$	; DE => input buffer
	LD	B,21		; B  => max input length
	CALL	GETSTR		; get string input
	LD	A,B		; A => # chars entered
	OR	A		; check A for zero
	JP	Z,EDIT		; go if nothing entered
	CALL	LOPEN		; open file
	RPOP	HL,BC
	RET
;
;---------------------------------------------------------
;  LFILE:  Load new file from disk
;	Entry:	None
;	Exit:	A is altered
;
LFILE	RPUSH	BC,DE,HL
	LD	A,(MODFLAG)	; A => mod flag
	OR	A		; check A for zero
	JR	Z,LFL10		; go if A = 0
	LD	HL,MOD$		; "File has changed..."
	CALL	QUERY		; get yes/no answer
	CALL	Z,SFILE		; save file if yes
LFL10	CALL	LFNAME		; enter load filename
	CALL	SETUP		; set up new file
	LD	BC,(FCB+6)	; BC => DEC/drive #
	LD	DE,FNAME$	; DE => filename buffer
	@@FNAME			; get "filename/ext:d"
	CALL	LOAD		; load file
	LD	HL,TEXT$	; HL => start of text
	LD	(TXTCSR),HL	; store as text cursor
	XOR	A		; turn off mod flag
	LD	(MODFLAG),A
	RPOP	HL,DE,BC
	RET
;
;---------------------------------------------------------
;  LFNAME:  Get name of file to load, then open it
;	Entry:	None
;	Exit:	A is altered
;		DE <= FCB
;
LFNAME	RPUSH	BC,HL
	LD	HL,LFNAME$	; HL => "Load file:"
	LD	DE,FNAME$	; DE => input buffer
	LD	B,21		; B  => max input length
	CALL	GETSTR		; get string input
	LD	A,B		; A => # chars entered
	OR	A		; check A for zero
	JP	Z,EDIT		; go if nothing entered
	CALL	LOPEN		; open file
	RPOP	HL,BC
	RET
;
;---------------------------------------------------------
;  LOAD:  Load file into memory
;	Entry:	HL => name of file to load
;	Exit:	A is altered
;
LOAD	RPUSH	BC,DE
	LD	DE,FCB		; DE => FCB
	LD	BC,(FCB+12)	; BC => ending record #
	LD	A,B		; check BC for zero
	OR	C
	JR	Z,LD99		; exit if BC = 0
LD10	DEC	BC		; decrease ERN counter
	LD	A,B		; check BC for zero
	OR	C
	JR	Z,LD20		; go if BC = 0
	PUSH	BC		; save ERN counter
	LD	BC,256		; insert 256 bytes
	CALL	IBLOCK
	LD	HL,(TXTCSR)	; HL => text cursor
	LD	(FCB+3),HL	; store as file buffer
	POP	BC		; retrieve ERN counter
	@@READ			; read sector
	JP	NZ,DOSERR	; abort if DOS error
	INC	H		; add 256 to HL
	LD	(TXTCSR),HL	; store new text cursor
	JR	LD10		; loop back
LD20	LD	HL,IOBUF$	; HL => I/O buffer
	LD	(FCB+3),HL	; store as file buffer
	LD	A,(FCB+8)	; A => ERN byte offset
	LD	C,A		; put it in BC
	LD	B,0
	OR	A		; check A for zero
	JR	NZ,LD30		; go if A <> 0
	LD	B,1		; else put 256 in BC
LD30	@@READ			; read last sector
	JP	NZ,DOSERR	; abort if DOS error
	PUSH	BC		; save offset counter
	CALL	IBLOCK		; insert some bytes
	POP	BC		; retrieve offset counter
	PUSH	DE		; save FCB
	LD	DE,(TXTCSR)	; DE => text cursor
	LD	HL,IOBUF$	; HL => I/O buffer
	LDIR			; transfer some bytes
	POP	DE		; retrieve FCB
LD99	@@CLOSE			; close file
	RPOP	DE,BC
	JP	RMVJUNK		; fall into RMVJUNK
;
;---------------------------------------------------------
;  LOPEN:  Open file for loading
;	Entry:	HL => filename
;	Exit:	A is altered
;		DE <= FCB of open file
;
LOPEN	RPUSH	BC,HL
	LD	DE,FCB		; DE => file control block
	@@FSPEC			; parse filename
	LD	A,19		; assume bad filename
	JP	NZ,DOSERR	; exit if DOS filename
	CALL	DOEXT		; add file extension
	PUSH	DE		; save FCB
	CALL	BLANK		; blank menu line
	LD	HL,LDING$	; "Loading..."
	CALL	DSPLY		; display message
	@@FLAGS$		; IY => system flags
	SET	0,(IY+'S'-'A')	; set FORCE TO READ flag
	POP	DE		; retrieve FCB
	LD	B,0		; B  => LRL of 256
	@@OPEN			; open file
	JR	Z,LOPEN99	; exit if no error
	LD	HL,FNAME$	; HL => filename buffer
	LD	(HL),ETX	; get rid of filename
	PUSH	DE		; save FCB again
	LD	HL,CREATE$	; "Create new file?"
	CALL	QUERY		; get yes/no answer
	JP	NZ,EDIT		; abort if no
	POP	DE		; DE => FCB
	LD	B,0		; B  => LRL of 256
	@@INIT			; create new file
	JP	NZ,DOSERR	; abort if DOS error
LOPEN99	RPOP	HL,BC
	RET
;
;---------------------------------------------------------
;  RMVJUNK:  Remove ASCII 1, 2, 3, and 26 from file
;	Entry:	None
;	Exit:	A is altered
;
RMVJUNK	RPUSH	DE,HL
	LD	DE,TEXT$-1	; DE => text start - 1
	LD	A,1		; remove ASCII zero before
	LD	(DE),A		;   text start
	LD	HL,(TXTEND)	; HL => text end
RMV10	DEC	HL		; back up
	LD	A,(HL)		; A => text character
	OR	A		; loop if ASCII zero
	JR	Z,RMV10
	CP	26		; loop if ASCII 26
	JR	Z,RMV10
	INC	HL		; HL => new text end
	XOR	A		; A  => ASCII zero
	LD	(HL),A		; stuff at text end
	LD	(DE),A		; stuff before text start
	LD	(TXTEND),HL	; store text end ptr
;
;  The carry flag was already reset with "XOR A" above
;
	INC	DE		; DE => text start
	SBC	HL,DE		; HL => text length
	EX	DE,HL		; swap start & length
RMV20	LD	A,D		; exit if DE = zero
	OR	E
	JR	Z,RMV99
	LD	A,(HL)		; A => text character
	CP	3+1		; go if not ASCII zero,
	JR	NC,RMV30	;   1, 2, or 3
	LD	(HL),252	; store question mark box
	LD	A,3
	LD	(FNAME$),A
RMV30	INC	HL		; advance ptr
	DEC	DE		; decrease counter
	JR	RMV20		; loop back
RMV99	POP	HL
	POP	DE
	RET
;
;---------------------------------------------------------
;  SAVE:  Save to disk file
;	Entry:	BC => # bytes to save
;		HL => position to start saving
;	Exit:	A is altered
;
SAVE	CALL	UCFILE		; uppercase file
	RPUSH	BC,DE,HL
	LD	A,B		; check BC for zero
	OR	C
	JR	Z,SV20		; exit if BC = 0
	LD	DE,FCB		; DE => FCB
	DEC	BC		; adjust counter
	INC	B		; increase by 1 page
	INC	C		; restore counter
SV10	LD	(FCB+3),HL	; store ptr as disk buffer
	@@WRITE			; write sector
	JR	NZ,SV30		; go if disk error
	INC	H		; advance ptr by 1 page
	DEC	B		; decrease ctr by 1 page
	JR	NZ,SV10		; loop back if B > 0
SV20	LD	A,C		; A => ERN byte offset
	LD	(FCB+8),A	; store it in FCB
	@@CLOSE			; close file
	JR	SV99		; exit routine
SV30	PUSH	AF		; save error code
	@@CLOSE			; close file
	POP	AF		; restore error code
	JP	DOSERR		; abort for DOS error
SV99	RPOP	HL,DE,BC
	RET
;
;---------------------------------------------------------
;  SBLOCK:  Save block to disk
;	Entry:	None
;	Exit:	A is altered
;
SBLOCK	RPUSH	BC,DE,HL
	CALL	FBLOCK		; find block
	JP	NZ,BLKERR	; abort if no block
	CALL	SBNAME		; get block file name
	CALL	SAVE		; save block
	RPOP	HL,DE,BC
	RET
;
;---------------------------------------------------------
;  SBNAME:  Get name of block to save, then open it
;	Entry:	None
;	Exit:	A is altered
;		DE <= FCB
;
SBNAME	RPUSH	BC,HL
	LD	HL,SBNAME$	; HL => "Save block:"
	LD	DE,BNAME$	; DE => input buffer
	LD	B,21		; B  => max input length
	CALL	GETSTR		; get string input
	LD	A,B		; A => # chars entered
	OR	A		; check A for zero
	JP	Z,EDIT		; go if nothing entered
	CALL	SOPEN		; open file
	RPOP	HL,BC
	RET
;
;---------------------------------------------------------
;  SFILE:  Save entire file to disk
;	Entry:	None
;	Exit:	A is altered
;
SFILE	RPUSH	BC,DE,HL
	CALL	ASM26		; add ASCII 26 to /ASM
	LD	HL,(TXTEND)	; HL => end of text
	LD	BC,TEXT$	; BC => start of text
	OR	A		; reset carry flag
	SBC	HL,BC		; find difference
	RPUSH	HL,BC		; save start, length
	CALL	SFNAME		; get save file name
	LD	BC,(FCB+6)	; BC => DEC/drive #
	LD	DE,FNAME$	; DE => filename buffer
	@@FNAME			; get "filename/ext:d"
	RPOP	HL,BC		; retrieve length, start
	CALL	SAVE		; save block
	CALL	RMVJUNK		; remove junk from file
	XOR	A		; turn off mod flag
	LD	(MODFLAG),A
	RPOP	HL,DE,BC
	RET
;
;---------------------------------------------------------
;  SFNAME:  Get name of file to save, then open it
;	Entry:	None
;	Exit:	A is altered
;		DE <= FCB
;
SFNAME	RPUSH	BC,HL
	LD	HL,SFNAME$	; HL => "Save file:"
	LD	DE,FNAME$	; DE => input buffer
	LD	B,21		; B  => max input length
	CALL	GETSTR		; get string input
	LD	A,B		; A => # chars entered
	OR	A		; check A for zero
	JP	Z,EDIT		; go if nothing entered
	CALL	SOPEN		; open file
	RPOP	HL,BC
	RET
;
;---------------------------------------------------------
;  SOPEN:  Open file for saving
;	Entry:	HL => filename
;	Exit:	A is altered
;		DE <= FCB of open file
;
SOPEN	RPUSH	BC,HL
	LD	DE,FCB		; DE => file control block
	@@FSPEC			; parse filename
	LD	A,19		; assume bad filename
	JP	NZ,DOSERR	; exit if DOS error
	CALL	DOEXT		; add file extension
	PUSH	DE		; save FCB
	CALL	BLANK		; blank menu line
	LD	HL,SVING$	; "Saving..."
	CALL	DSPLY		; display message
	POP	DE		; retrieve FCB
	LD	B,0		; B  => LRL of 256
	@@INIT			; open new file
	JP	NZ,DOSERR	; abort if DOS error
	RPOP	HL,BC
	RET
;
;---------------------------------------------------------
;  UCFILE:  Uppercase an /ASM or /BAS file
;	Entry:	None
;	Exit:	A is altered
;
UCFILE	RET			; disable UCFILE
	PUSH	HL
	LD	HL,TEXT$-1	; HL => text start
UCF10	INC	HL		; advance ptr
	LD	A,(HL)		; A => char at HL
	OR	A		; check for ending zero
	JR	Z,UCF99		; exit if found
UCF20	CP	';'		; check for semi-colon
	JR	NZ,UCF40	; go if not found
UCF30	INC	HL		; advance ptr
	LD	A,(HL)		; A  => char at HL
	OR	A		; check for ending zero
	JR	Z,UCF99		; exit if found
	CP	CR		; check for ENTER
	JR	Z,UCF10		; loop way back if found
	JR	UCF30		; loop back if not found
UCF40	CP	27H		; check for single quote
	JR	NZ,UCF60	; go if not found
UCF50	INC	HL		; advance ptr
	LD	A,(HL)		; A  => char at HL
	OR	A		; check for ending zero
	JR	Z,UCF99		; exit if found
UCF55	CP	27H		; check for single quote
	JR	Z,UCF10		; loop way back if found
	CP	CR		; check for ENTER
	JR	Z,UCF10		; loop way back if found
	JR	UCF50		; loop back if not found
UCF60	CP	'a'		; check for lowercase
	JR	C,UCF10		; loop back if not found
	CP	'z'+1		; check for lowercase
	JR	NC,UCF10	; loop back if not found
	SUB	32		; convert to uppercase
	LD	(HL),A		; store new value
	JR	UCF10		; loop back
UCF99	POP	HL
	RET
;
;  End of E4DISK/ASM
;
