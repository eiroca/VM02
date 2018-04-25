;
; HIRES COLOR
;
	LDY	#$07	; SAVE VM02, RESTORE HGR
:	LDA	$E0,Y
	STA	$40F8,Y
	LDA	$4078,Y
	STA	$E0,Y
	DEY
	BPL	:-
	LDA	$1C
	STA	$41FE
	LDA	$417E
	STA	$1C
	LDA	$1D
	STA	$41FF
	LDA	$417F
	STA	$1D
	BIT	$C081
	PLA		; SAVE RETURN ADDRESS
	STA	$A0
	PLA
	STA	$A1
	PLA
	TAX
	PLA
	PLA
	PLA
	TXA
	JSR	$F6F0	; SET COLOR
	LDA	#$40	; SET PAGE2
	STA	$E6
	LDA	$A1	; RESTORE RETURN ADDRESS
	PHA
	LDA	$A0
	PHA
	BIT	$C083
	BIT	$C083
	LDY	#$07	; SAVE HGR, RESTORE VM02
:	LDA	$E0,Y
	STA	$4078,Y
	LDA	$40F8,Y
	STA	$E0,Y
	DEY
	BPL	:-
	LDA	$1C
	STA	$417E
	LDA	$41FE
	STA	$1C
	LDA	$1D
	STA	$417F
	LDA	$41FF
	STA	$1D
	RTS
