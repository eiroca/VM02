;
; LORES COLOR HLINE
;
	BIT	$C081
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
	STA	$2C	; HORIZ POSITION RIGHT
	PLA
	PLA
	PLA
	PLA
	TAY		; HORIZ POSITION LEFT
	PLA
	PLA
	PLA
	LDA	$A2
	JSR	$F819
	LDA	$A1
	PHA
	LDA	$A0
	PHA
	BIT	$C083
	BIT	$C083
	RTS
