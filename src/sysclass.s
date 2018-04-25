;*
;* JAVA SYSTEM CLASSES FOR 6502
;*
	.INCLUDE	"global.inc"
	.INCLUDE	"class.inc"
	.IMPORT	CROUT,COUT,PRSTR,KBWAIT,PRHSTR,PRHSTRLN,PRBYTE
	.IMPORT	HMEM_ALLOC,HMEM_ALLOC_FIXED,HMEM_FREE,HMEM_LOCK,HMEM_UNLOCK
	.IMPORT	HMEM_PTR,HMEM_REF_INC,HMEM_REF_DEC
	.IMPORT	HSTR_HASH,STR_HASH,HSTRPL_ADD,HSTRPL_DEL
	.IMPORT	HCLASS_NAME,HCLASS_HNDL,HCLASS_ADD,HCLASS_INDEX,CLASS_STRING
	.IMPORT	CLASS_METHODPTR,CLASS_VIRTCODE,CLASS_LOCKMETHOD,CLASS_UNLOCKMETHOD
	.IMPORT	MEMSRC,MEMDST,MEMCLR,MEMCPY
	.IMPORT	CLASS_MATCH_NAME,CLASS_MATCH_DESC,RESOLVE_METHOD,CLASS_METHODPTR
	.IMPORT	THREAD_WAIT_HOBJL,THREAD_WAIT_HOBJH,THREAD_WAITQ
	.IMPORT	ASYNC_VIRTUAL
	.IMPORT	STRINGCLASS_INIT
	.IMPORT	LOADCLASS_MEM
	.IMPORT	HFINALNAMESTR,HVOIDDESCSTR
	.EXPORT	SYSCLASS_INIT,INIT_END
	.EXPORT	UNREF_OBJECT,SYS_CALL

	.SEGMENT "INIT"
SYSCLASS_INIT:	LDA	#<NATIVE_CALL
	STA	LINK_VMCALL
	LDA	#>NATIVE_CALL
	STA	LINK_VMCALL+1
	LDA	#<OBJECT_CLASS_DATA
	LDX	#>OBJECT_CLASS_DATA
	JSR	LOADCLASS_MEM
.IFDEF	DEBUG
	CPY	#CL_OBJ
	BEQ	:+
	PERR	"OBJECT CLASS NOT 1!"
:
.ENDIF
	LDA	#<ARRAY_CLASS_DATA
	LDX	#>ARRAY_CLASS_DATA
	JSR	LOADCLASS_MEM
.IFDEF	DEBUG
	CPY	#CL_ARRAY
	BEQ	:+
	PERR	"ARRAY CLASS NOT 2!"
:
.ENDIF
	JMP	STRINGCLASS_INIT
;*
;* MIRROR CLASS FILE STRUCTURE FOR SYSTEM CLASSES
;*
OBJECT_CLASS_DATA:
	.INCLUDE	"object.clasm"
ARRAY_CLASS_DATA:
	.INCLUDE	"array.clasm"
INIT_END	:=	*

	.CODE
;*
;* SYSCLASS OBJECT HELPER ROUTINES
;*
;*
;* UNREFERENCE AN OBJECT INSTANCE
;* ENTRY: STACK = INSTANCE REF
;*
UNREF_OBJECT:	TSX
	LDA	$0103,X
	TAY
	LDA	$0104,X
	BEQ	OBJUNREFDONE		; SKIP NULL REF
	TAX
	TYA
	JSR	HMEM_REF_DEC
	CMP	#$00		; IF REF COUNT NOT ZERO, DONE
	BNE	OBJUNREFDONE
	CPX	#$00
	BEQ	OBJDEL
OBJUNREFDONE:	TSX			; REMOVE OBJECT REF FROM STACK
	LDA	$0101,X
	STA	$0105,X
	LDA	$0102,X
	STA	$0106,X
	INX
	INX
	INX
	INX
	TXS
	RTS
OBJDEL:	TSX
	LDA	$0105,X
	CMP	#CL_STR+1		; IS IT A BASIC SYSCLASS?
	BCC	:+
	JMP	FINALIZE		; NO, FINALIZE
:	CMP	#CL_STR		; IS IT A STRING?
	BNE	CHKARRAY		; NO, CHECK FOR ARRAY
.IFDEF	DEBUG_FINALIZE
	PSTRLN	"DELETING STRING"
	TSX
.ENDIF
	LDA	$0103,X
	TAY
	LDA	$0104,X
	TAX
	TYA
	JSR	HSTRPL_DEL		; DEL STRPL CONST
	JMP	OBJUNREFDONE
CHKARRAY:	CMP	#CL_ARRAY
	BNE	OBJFREE
.IFDEF	DEBUG_FINALIZE
	PSTR	"DELETING ARRAY TYPE:"
	TSX
	LDA	$0106,X
	JSR	PRBYTE
	JSR	CROUT
	TSX
.ENDIF
	LDA	$0106,X
	CMP	#T_REF|$10		; CHECK ARRAY TYPE
	BNE	:+
	JMP	UNREFARRAYREFS		; UNREF ARRAY OF REFS
:	BCC	OBJFREE		; IF BASIC ARRAY, JUST DELETE
	SBC	#$10		; DECREMENT ARRAY DIMENSION
	STA	$0106,X
	JMP	UNREFARRAYARRAY
OBJFREE:	TSX
	LDA	$0103,X
	TAY
	LDA	$0104,X
	TAX
	TYA
	JSR	HMEM_FREE		; DELETE INSTANCE
	JMP	OBJUNREFDONE
FINALIZE:	TSX
	LDA	$0103,X
	TAY
	LDA	$0104,X
	TAX
	TYA
	JSR	HMEM_REF_INC		; NEEDED FOR FINALIZE()
.IFDEF	DEBUG_FINALIZE
	PSTR	"FINALIZING OBJECT OF CLASS: "
	TSX
	LDY	$0106,X
	JSR	CLASS_STRING
	JSR	PRHSTR
	JSR	CROUT
;	JSR	KBWAIT
.ENDIF
	LDA	HFINALNAMESTR		; LOOK FOR FINALIZE()
	LDX	HFINALNAMESTR+1
	JSR	CLASS_MATCH_NAME
	LDA	HVOIDDESCSTR
	LDX	HVOIDDESCSTR+1
	JSR	CLASS_MATCH_DESC
	TSX	
	LDA	$0106,X		; PUSH *THIS*
	PHA
	LDA	$0105,X
	PHA
	TAY			; SAVE CLASS
	LDA	$0104,X
	PHA
	LDA	$0103,X
	PHA
	JSR	RESOLVE_METHOD		; CALL FINALIZE()
	JSR	ASYNC_VIRTUAL
	BCC	:+		; NO EXCEPTION ENCOUNTERED
	JSR	OBJFREE		; FREE EXCEPTION OBJECT
;
; GET CLASS AND ITERATE THROUGH METHODS LOOKING FOR REFERENCE FIELDS TO UNREF
;
:	TSX			; INIT STACK LOCALS
	LDA	$0105,X
	PHA
	LDA	$0103,X
	TAY
	LDA	$0104,X
	TAX
	TYA
	JSR	HMEM_LOCK		; LOCK OBJ INSTANCE
	PHA
	TXA
	PHA
UNREFCLASS:	LDA	#$00
	PHA
;
; STACK HAS:
;	CURRENT CLASS INDEX = $0104,X
;	POINTER TO INSTANCE = $0102,X (HI) $0103,X (LO)
;	CURRENT FIELD INDEX = $0101,X
;
UNREFFLDS:	TSX
	LDY	$0104,X		; RETRIEVE ICLASS
	JSR	HCLASS_INDEX		; GET HCLASS
	JSR	HMEM_PTR		; GET CLASS PTR
	STA	CCLASSPTR
	STX	CCLASSPTR+1
	LDY	#CLASSFIELDTBL+1
	LDA	(CCLASSPTR),Y
	BNE	:+
	JMP	UNREFSUPRCLS		; NO FIELDS FOR THIS CLASS, CHECK SUPER
:	DEY
	TAX
	LDA	(CCLASSPTR),Y
	JSR	HMEM_PTR
	STA	CCTBLPTR
	STX	CCTBLPTR+1
	LDY	#CLASSFIELDCNT
	PLA			; CHECK FOR MAX FIELD INDEX
	CMP	(CCLASSPTR),Y
	PHA
	BEQ	UNREFSUPRCLS		; UNREF SUBCLASS FIELDS
	LDX	#$00		; GET POINTER TO FIELD DEF
	JSR	MUL_FIELDRECSZ		; FIELD RECORD SIZE
	CLC
	ADC	CCTBLPTR
	STA	TMPTR
	TXA
	ADC	CCTBLPTR+1
	STA	TMPTR+1
	LDY	#FIELDACCESS
	LDA	(TMPTR),Y
	AND	#$08		; CHECK FOR STATIC FIELD
	BNE	UNREFNXTFLD
	LDY	#FIELDTYPE
	LDA	(TMPTR),Y
	CMP	#T_REF|$80		; CHECK FOR REFERENCE TYPE
	BNE	UNREFNXTFLD
	TSX
	INY			; LDY #FIELDINSTOFFSET GET FIELD INSTANCE OFFSET
	LDA	(TMPTR),Y
	INY
	CLC
	ADC	$0103,X
	STA	FINPTR
	LDA	(TMPTR),Y
	ADC	$0102,X
	STA	FINPTR+1
.IFDEF	DEBUG_FINALIZE
	LDY	#FIELDNAME
	LDA	(TMPTR),Y
	INY
	PHA
	LDA	(TMPTR),Y
	PHA
	PSTR	"UNREF FIELD: "
	PLA
	TAX
	PLA
	JSR	PRHSTR
	JSR	CROUT
	JSR	KBWAIT
.ENDIF
	LDY	#$03
	LDA	(FINPTR),Y		; UNREF OBJECT FIELD
	DEY
	PHA
	LDA	(FINPTR),Y
	DEY
	PHA
	LDA	(FINPTR),Y
	DEY
	PHA
	LDA	(FINPTR),Y
	PHA
	JSR	UNREF_OBJECT
UNREFNXTFLD:	PLA			; INC FIELD INDEX
	CLC
	ADC	#$01
	PHA
;	BEQ	UNREFSUPRCLS
	JMP	UNREFFLDS
;
; UNREF SUPER CLASS FIELDS
;
UNREFSUPRCLS:	PLA			; POP FIELD COUNT
	TSX
	LDY	$0103,X		; RETRIEVE ICLASS
	JSR	HCLASS_INDEX		; GET HCLASS
	JSR	HMEM_PTR
	STA	CCLASSPTR
	STX	CCLASSPTR+1
	LDY	#CLASSSUPER		; GET SUPERCLASS
	LDA	(CCLASSPTR),Y
	BEQ	UNREFFLDDONE
	TSX
	STA	$0103,X
	JMP	UNREFCLASS
UNREFFLDDONE:	PLA			; POP STACK LOCALS
	PLA
	PLA
.IFDEF	DEBUG
	TSX
	LDA	$0103,X
	TAY
	LDA	$0104,X
	TAX
	TYA
	JSR	HMEM_REF_DEC		; NEEDED FOR FINALIZE()
.ENDIF
	JMP	OBJFREE
UNREFARRAYREFS:
.IFDEF	DEBUG_FINALIZE
	PSTRLN	"UNREFING ARRAY REFERENCES"
	TSX
.ENDIF
	LDA	$0103,X		; RETRIEVE ARRAY POINTER
	TAY
	LDA	$0104,X
	TAX
	TYA
	JSR	HMEM_PTR
	STA	TMPTR
	STX	TMPTR+1
	LDY	#$01
	LDA	(TMPTR),Y
	DEY
	STA	FINPTR+1
	TAX
	LDA	(TMPTR),Y
	STA	FINPTR
	BNE	:+
	CPX	#$00
	BEQ	ARRAYDONE		; ALL ARRAY ELEMENTS UNREFERENCED
:	SEC			; DEC INDEX
	SBC	#$01
	BCS	:+
	DEX
:	STA	(TMPTR),Y		; UPDATE INDEX OF NEXT ELEMENT
	INY
	TXA
	STA	(TMPTR),Y
	LDA	FINPTR
	ASL
	ROL	FINPTR+1
	ASL
	ROL	FINPTR+1
	SEC			; ADJUST FOR LENGTH VALUE = 2 BYTES
	SBC	#$02
	BCS	:+
	DEC	FINPTR+1
:	CLC
	ADC	TMPTR
	STA	FINPTR
	LDA	FINPTR+1
	ADC	TMPTR+1
	STA	FINPTR+1
	LDY	#$03
	LDA	(FINPTR),Y		; UNREF ARRAY ELEMENT
	DEY
	PHA
	LDA	(FINPTR),Y
	DEY
	PHA
	LDA	(FINPTR),Y
	DEY
	PHA
	LDA	(FINPTR),Y
	PHA
	JSR	UNREF_OBJECT
	TSX
	JMP	UNREFARRAYREFS
ARRAYDONE:	JMP	OBJFREE
UNREFARRAYARRAY:
.IFDEF	DEBUG_FINALIZE
	PSTRLN	"UNREFING ARRAY ARRAYS"
	TSX
.ENDIF
	LDA	$0103,X		; RETRIEVE ARRAY POINTER
	TAY
	LDA	$0104,X
	TAX
	TYA
	JSR	HMEM_PTR
	STA	TMPTR
	STX	TMPTR+1
	LDY	#$01
	LDA	(TMPTR),Y
	DEY
	STA	FINPTR+1
	TAX
	LDA	(TMPTR),Y
	STA	FINPTR
	BNE	:+
	CPX	#$00
	BEQ	ARRAYDONE		; ALL ARRAY ARRAYS UNREFERENCED
:	SEC			; DEC INDEX
	SBC	#$01
	BCS	:+
	DEX
:	STA	(TMPTR),Y		; UPDATE INDEX OF NEXT ARRAY
	INY
	TXA
	STA	(TMPTR),Y
	LDA	FINPTR
	ASL
	ROL	FINPTR+1
	CLC
	ADC	TMPTR
	STA	FINPTR
	LDA	FINPTR+1
	ADC	TMPTR+1
	STA	FINPTR+1
	TSX
	LDA	$0106,X		; RETRIEVE ARRAY TYPE
	PHA
	LDA	#CL_ARRAY
	PHA
	LDY	#$01
	LDA	(FINPTR),Y		; UNREF ARRAY ELEMENT
	DEY
	PHA
	LDA	(FINPTR),Y
	PHA
	JSR	UNREF_OBJECT
	TSX
	JMP	UNREFARRAYARRAY
;*
;* NATIVE CALL INTO VM OR ROM CODE FROM VM02.CALL()
;*
NATIVE_CALL:	PLA		; PULL RETURN ADDRESS
	STA	$A4
	PLA
	STA	$A5
	PLA		; PULL CALL ADDRESS
	STA	$A6
	PLA
	STA	$A7
	TSX
	LDA	$A4	; PUSH RETURN ADDRESS (OVERWRITE HIWORD OF CALL ADDRESS)
	STA	$0101,X
	LDA	$A5
	STA	$0102,X
	LDA	$0103,X	; GET REG VALS
	STA	$A8	; BUT LEAVE ON STACK FOR RETUN VALS
	LDA	$0104,X
	STA	$A9
	LDA	$0105,X
	STA	$AA
	LDA	$A7
	BEQ	:+
	JSR	ROMCALL
	JMP	CALLRET
:	LDX	$A6	; PATCH INDIRECT JUMP
SYS_CALL:	STX	VMCALL+7
	JSR	VMCALL
CALLRET:	PHP
	STA	$A8
	STX	$A9
	PLA
	TSX
	STA	$0106,X	; PUT RETURN REG VALS BACK ON STACK
	TYA
	STA	$0105,X
	LDA	$A9
	STA	$0104,X
	LDA	$A8
	STA	$0103,X
	RTS	
VMCALL:	LDA	$A8
	LDX	$A9
	LDY	$AA
	JMP	($0300)	
ROMCALL:	BIT	$C081	; SELECT ROM
	LDA	$A8
	LDX	$A9
	LDY	$AA
	JMP	($A6)
