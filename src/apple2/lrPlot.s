;
; LORES PLOT
;
	BIT	$C081	; SWAP IN ROM
	PLA
	STA	$A0
	PLA
	STA	$A1
	PLA
	STA	$A2	; VERTICAL POSITION
	PLA
	PLA
	PLA
	PLA
	TAY		; HORIZ POSITION
	PLA
	PLA
	PLA
	LDA	$A2
	JSR	$F800
	LDA	$A1
	PHA
	LDA	$A0
	PHA
;	BIT	$C083	; SWAP IN LC BANK2
;	BIT	$C083	; WRITE ENABLE
	RTS
