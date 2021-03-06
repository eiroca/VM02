;*
;* JAVA CLASS STRUCTURE
;*

;*
;* CLASS STRUCTURE - 24 BYTES + CONST POOL
;*
.DEFINE	CLASSBASESZ	24	; BASE CLASS SIZE = 24 BYTES
.DEFINE	CLASSTHIS	$00	; 2 BYTES - HSTR
.DEFINE	CLASSSUPER	$02	; 1 BYTE  - CLASS INDEX
.DEFINE	CLASSLOADER	$03	; 1 BYTE  - CLASS INDEX
.DEFINE	CLASSINSTSIZE	$04	; 2 BYTES - U2
.DEFINE	CLASSACCESS	$06	; 2 BYTES - U2
.DEFINE	CLASSCONSTCNT	$08	; 2 BYTES - U2
.DEFINE	CLASSIFACECNT	$0A	; 1 BYTE  - U1
.DEFINE	CLASSFIELDCNT	$0B	; 1 BYTE  - U1
.DEFINE	CLASSMETHODCNT	$0C	; 1 BYTE  - U1
.DEFINE	CLASSVTBLCNT	$0D	; 1 BYTE  - U1
.DEFINE	CLASSIFACETBL	$0E	; 2 BYTES - HMEM
.DEFINE	CLASSFIELDTBL	$10	; 2 BYTES - HMEM
.DEFINE	CLASSMETHODTBL	$12	; 2 BYTES - HMEM
.DEFINE	CLASSVIRTBL	$14	; 2 BYTES - HMEM
.DEFINE	CLASSLOCKCNT	$16	; 2 BYTES - U2
.DEFINE	CLASSCONSTPL	$18	; CLASSCONSTCNT * CONSTPLRECSZ BYTES
;*
;* CONSTANT POOL RECORD SIZE - 5 BYTES (1 BYTE TYPE, 4 BYTES VALUE)
;*
.DEFINE	CONSTPLRECSZ	5
	.IMPORT	MUL5
.MACRO	CALC_CONSTPLRECSZ
	JSR	MUL5
.ENDMACRO
;*
;* FIELD TABLE RECORD - 9 BYTES
;*
.DEFINE	FIELDRECSZ	10
.DEFINE	FIELDACCESS	$00	; 1 BYTE  - U1
.DEFINE	FIELDNAME	$01	; 2 BYTES - HSTR
.DEFINE	FIELDDESC	$03	; 2 BYTES - HSTR
.DEFINE	FIELDTYPE	$05	; 1 BYTE  - U1
.DEFINE	FIELDINSTOFFSET	$06	; 2 BYTES - U2
.DEFINE	FIELDSTATICVAL	$06	; 4 BYTES - U4 (UNION WITH INST OFFSET)
.IMPORT	MUL10
.DEFINE	MUL_FIELDRECSZ	MUL10
;*
;* METHOD TABLE RECORD - 9 BYTES
;*
.DEFINE	METHODRECSZ	9
.DEFINE	METHODACCESS	$00	; 2 BYTES - U2
.DEFINE	METHODNAME	$02	; 2 BYTES - HSTR
.DEFINE	METHODDESC	$04	; 2 BYTES - HSTR
.DEFINE	METHODPARAMS	$06	; 1 BYTE  - U1
.DEFINE	METHODSTATICODE	$07	; 2 BYTES - HCODE FOR STATIC CODE
.DEFINE	METHODVINDEX	$07	; 2 BYTES - INDEX TO VTABLE (UNION WITH HCODE)
.IMPORT	MUL9
.DEFINE	MUL_METHODRECSZ	MUL9
