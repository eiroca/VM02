;*
;* MOUSE DEVICE DRIVER
;*
MOUSE_INIT:	ORA	#$C0
	STA	XREGMOUSE1+1
	STA	XREGMOUSE2+1
	ASL
	ASL
	ASL
	ASL
	STA	YREGMOUSE1+1
	STA	YREGMOUSE2+1
	LDA	#$00
	PHA			; DISABLE ALL MOUSE INTS
	LDX	#$12		; FW INDEX FOR SETMOUSE
	BNE	CALLMOUSEFW
MOUSE_DRIVER:
MOUSE_DRVR_SZ:	.WORD	MOUSE_DRVR_END - MOUSE_DRVR_START
MOUSE_READ_OFS:	.WORD	MOUSE_READ     - MOUSE_DRVR_START
MOUSE_WRITE_OFS: .WORD	MOUSE_WRITE    - MOUSE_DRVR_START
MOUSE_CTRL_OFS:	.WORD	MOUSE_CTRL     - MOUSE_DRVR_START
MOUSE_IRQ_OFS:	.WORD	MOUSE_IRQ      - MOUSE_DRVR_START
MOUSE_DRVR_START:
MOUSE_READ:
MOUSE_WRITE:	SEC
	RTS
MOUSE_X:	.WORD	$0000
MOUSE_Y:	.WORD	$0000
MOUSE_STATUS:	.BYTE	$00
MOUSE_CTRL:	PHA
	TYA
	AND	#$F8		; MASK OFF SLOT #
	CMP	#MOUSECTL_CALLFW
	BNE	:+
CALLMOUSEFW:	STX	OPADDR
XREGMOUSE2:	LDX	#$C4
	STX	OPADDR+1
	LDY	#$00
	LDA	(OPADDR),Y		; GET ENTRYPOINT OFFSET
	STA	OPADDR
YREGMOUSE2:	LDY	#$40
	PLA
	SEI
	JMP	(OPADDR)		; CALL FIXED UP FUNCTION POINTER
:	CMP	#MOUSECTL_READMOUSE	; COPY MOUSE STATUS/POSITION INTO EASILY ACCESSIBLE MEMORY
	BNE	:+
	PLA
	TYA
	AND	#$07
	TAX			; SAVE MOUSE PARAMETERS
	ASL
	TAY
	LDA	LINK_DEVREAD,Y
	STA	TMPTR
	LDA	LINK_DEVREAD+1,Y
	STA	TMPTR+1
	SEI
	LDY	#$02
	LDA	$0478,X
	STA	(TMPTR),Y
	PHA
	INY
	LDA	$0578,X
	STA	(TMPTR),Y
	INY
	LDA	$04F8,X
	STA	(TMPTR),Y
	PHA
	INY
	LDA	$05F8,X
	STA	(TMPTR),Y
	INY
	LDA	$0778,X
	STA	(TMPTR),Y
	STA	TMP
	PLA
	TAY
	PLA
	TAX
	LDA	TMP
	RTS
:	CMP	#MOUSECTL_CLAMPX
	BEQ	:+
	CMP	#MOUSECTL_CLAMPY
	BNE	:++
:	PLA
	STA	$04F8
	STX	$05F8
	LDA	#$00
	STA	$0478
	STA	$0578
	TYA
	LSR
	LSR
	LSR
	AND	#$01
	PHA
	LDX	#$17		; FW INDEX FOR CLAMPMOUSE
	BNE	CALLMOUSEFW
SETMOUSE:	PHA
	LDX	#$12		; FW INDEX FOR SETMOUSE
	BNE	CALLMOUSEFW
:	PLA
	TYA
	AND	#$F8		; MASK OFF SLOT #
	CMP	#IOCTL_OPEN
	BNE	:+
	LDA	#<THREAD_YIELD		; REMOVE SOFTWARE TIMER
	STA	LINK_YIELD
	LDA	#>THREAD_YIELD
	STA	LINK_YIELD+1
	LDA	#$0F		; TURN MOUSE INTS ON
	BNE	SETMOUSE
:	CMP	#IOCTL_CLOSE
	BNE	:+
	LDA	#$08		; TURN MOUSE OFF
	BNE	SETMOUSE
:	CMP	#IOCTL_DEACTIVATE
	BNE	:+
	LDA	#MOUSECTL_NOIRQ
:	CMP	#MOUSECTL_NOIRQ		; UNINSTALL IRQ HANDLER
	BNE	:+
	SEI
	LDA	#<SW_TIMER		; RE-INSTALL SW TIMER
	STA	LINK_YIELD
	LDA	#>SW_TIMER
	STA	LINK_YIELD+1
	BNE	SETMOUSE
:	CMP	#IOCTL_ID
	BEQ	:+
	SEC
	RTS
:	LDA	#$20		; MOUSE ID
	CLC
	RTS
;
; VBLANK TIMER AND MOUSE IRQ
;
MOUSE_IRQ:	STA	TMP
SERVEMOUSE:	JSR	$C400
	BCS	VBLEXIT		; NOT MOUSE INT
	LDY	TMP		; CHECK MOUSE INT CAUSE
	LDA	$0778,Y
	PHA
	AND	#$08		; WAS IT VLB?
	BEQ	MOUSEEXIT		; NOPE, MOVE OR BUTTON
VBLTIC:	LDX	#$00
	LDA	#$11		; 17 MSEC (2/3 OF THE TIME)
	DEC	TIMERADJUST
	BNE	:+
	LDA	#$02
	STA	TIMERADJUST
	LDA	#$10		; 16 MSEC (1/3 OF THE TIME)
:	JSR	SYSTEM_TIC
MOUSEEXIT:	PLA
	AND	#$86		; MOUSE MOVE OR BUTTON ACTIVE
	BEQ	VBLEXIT
XREGMOUSE1:	LDX	#$C4
YREGMOUSE1:	LDY	#$40
READMOUSE:	JSR	$C400		; IIGS REQUIRES THIS HAPPEN IN IRQ
	CLC
	RTS
VBLEXIT:	SEC
	RTS
MOUSE_DRVR_END	EQU	*
