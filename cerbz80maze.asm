	org	$0202
	jp	main

; printstr	- HL pointer to 0-terminated string
; gotoxy	- A = Y coord, BC = X coord, DE pointer in video mem
; hline		- A = char to use, B = length of line
; vline		- A = char to use, B = height of line
; drawbox	- A = char to use, B = width, C = height
; fillbox	- A = char to use, B = width, C = height
; clearscr	- A = char to fill screen with
; waitforkey	- Uses A

VIDEOSTART	= $F800
MAILFLAG	= $0200
MAILBOX		= $0201

macro goxy xcord, ycord
	ld	BC, {xcord}
	ld	A, {ycord}
	call	gotoxy
mend

; Characters used in Cerberus Z80 Maze
BACKGROUND	= $20
SOLID		= $A0
PATH		= $08
CURSOR		= $00

SCREENWIDTH	= 40
SCREENHEIGHT	= 30
NUMLEVELS	= 57

Level	defb	0
Mwidth	defb	0
Mheight	defb	0
Mazesx	defb	0
Mazesy	defb	0
Cursorx	defb	0
Cursory	defb	0
Fields	defb	0

main:
	call	welcomescreen
	ld	A, 1			; Level number in A
	ld	(Level), A

.newlevel:
	call	gamescreen
	ld	A, (Level)
	call	updatelevel
	ld	A, (Level)
	call	findmaze		; HL points to start of maze
	call	getmazevals		; HL now points to actual maze data
	call	drawmaze

.loop:	call	getdirection
	call	domove
	ld	A, (Fields)
	cp	0
	jr	NZ, .loop

	ld	A, (Level)
	inc	A
	cp	NUMLEVELS+1
	jr	Z, .startover
	ld	(Level), A
	jr	.newlevel
.startover:
	ld	A, 1
	ld	(Level), A
	jr	.newlevel
	ret

;******************************************************************************
;******************************************************************************
;******************************************************************************
delay:
	push	BC
	ld	B, 50
.outloop:
	ld	C, 0
.inloop:
	dec	C
	jr	NZ, .inloop
	dec	B
	jr	NZ, .outloop
	pop	BC
	ret


;******************************************************************************
;******************************************************************************
;******************************************************************************
domove:
	push	HL
	ld	B, 0
	ld	A, (CursorX)
	ld	C, A
	ld	A, (CursorY)
	call	gotoxy
	ld	A, (Fields)
	ld	B, A
	pop	IX
	jp	(IX)

moveup:
	call	delay
	ld	A, E
	sub	SCREENWIDTH
	ld	E, A
	jr	NC, .skipd
	dec	D
.skipd:
	ld	A, (DE)
	cp	SOLID
	ret	Z
	cp	PATH
	jr	Z, .skipdec
	dec	B
	ld	A, B
	ld	(Fields), A
.skipdec:
	ld	A, (CursorY)
	dec	A
	ld	(CursorY), A
	ld	A, CURSOR
	ld	(DE), A
	ld	A, PATH
	ld	(HL), A
	ld	A, L
	sub	SCREENWIDTH
	ld	L, A
	jr	NC, moveup
	dec	H
	jr	moveup

movedown:
	call	delay
	ld	A, E
	add	A, SCREENWIDTH
	ld	E, A
	jr	NC, .skipd
	inc	D
.skipd:
	ld	A, (DE)
	cp	SOLID
	ret	Z
	cp	PATH
	jr	Z, .skipdec
	dec	B
	ld	A, B
	ld	(Fields), A
.skipdec:
	ld	A, (CursorY)
	inc	A
	ld	(CursorY), A
	ld	A, CURSOR
	ld	(DE), A
	ld	A, PATH
	ld	(HL), A
	ld	A, L
	add	A, SCREENWIDTH
	ld	L, A
	jr	NC, movedown
	inc	H
	jr	movedown

moveleft:
	call	delay
	dec	DE
	ld	A, (DE)
	cp	SOLID
	ret	Z
	cp	PATH
	jr	Z, .skipdec
	dec	B
	ld	A, B
	ld	(Fields), A
.skipdec:
	ld	A, (CursorX)
	dec	A
	ld	(CursorX), A
	ld	A, CURSOR
	ld	(DE), A
	ld	A, PATH
	ld	(HL), A
	dec	HL
	jr	moveleft

moveright:
	call	delay
	inc	DE
	ld	A, (DE)
	cp	SOLID
	ret	Z
	cp	PATH
	jr	Z, .skipdec
	dec	B
	ld	A, B
	ld	(Fields), A
.skipdec:
	ld	A, (CursorX)
	inc	A
	ld	(CursorX), A
	ld	A, CURSOR
	ld	(DE), A
	ld	A, PATH
	ld	(HL), A
	inc	HL
	jr	moveright

;******************************************************************************
;******************************************************************************
;******************************************************************************
getdirection:
	call	waitforkey
	ld	A, (MAILBOX)
	ld	B, A
	ld	A, 0
	ld	(MAILFLAG), A
	ld	A, B
	ld	HL, moveup
	cp	'w'
	ret	Z
	cp	'W'
	ret	Z
	cp	'i'
	ret	Z
	cp	'I'
	ret	Z

	ld	HL, movedown
	cp	's'
	ret	Z
	cp	'S'
	ret	Z
	cp	'k'
	ret	Z
	cp	'K'
	ret	Z

	ld	HL, moveleft
	cp	'a'
	ret	Z
	cp	'A'
	ret	Z
	cp	'j'
	ret	Z
	cp	'J'
	ret	Z

	ld	HL, moveright
	cp	'd'
	ret	Z
	cp	'D'
	ret	Z
	cp	'l'
	ret	Z
	cp	'L'
	ret	Z
	jp	getdirection

;******************************************************************************
; Update the Level printed in the top right corner of the screen
;******************************************************************************
; INPUTS:	A - Level number
; USES:		BC, DE
;******************************************************************************
updatelevel:
	GOXY 37,0
	ld	A, (Level)
	ld	C, 0
.hloop:	sub	100
	jr	C, .writehundreds
	inc	C
	jr	.hloop
.writehundreds:
	add	100
	ld	B, A
	ld	A, C
	add	'0'
	ld	(DE), A
	inc	DE
	ld	C, 0
	ld	A, B
.tloop:	sub	10
	jr	C, .writetens
	inc	C
	jr	.tloop
.writetens:
	add	10
	ld	B, A
	ld	A, C
	add	'0'
	ld	(DE), A
	inc	DE
	ld	A, B
	add	'0'
	ld	(DE), A
	ret

;******************************************************************************
; Draws the maze pointed to by HL to the screen and places the cursor.
; A call to getmazevals is needed before this function is called
;******************************************************************************
; INPUTS:	HL - Pointer to beginning of maze data
;******************************************************************************
drawmaze:
	push	HL
	ld	A, (Mazesx)
	ld	B, 0			; BC = Mazesx
	ld	C, A
	ld	A, (Mazesy)		; A = Mazesy
	call	gotoxy			; DE pointer to coords in video memory
	pop	IX			; IX pointer to maze data
	ld	A, (Mheight)
	ld	B, A			; B = Height of maze
	ld	C, 0			; C = number of fields in maze
	ld	A, (Mwidth)
	ld	H, A			; H = Mwidth
.newline:
	ld	L, 8			; L = number of bits in a byte
	ld	A, (IX+0)		; A = 1 byte of maze data
.loop:	sla	A			; shift a bit of data into carryflag
	push	AF			; Save A as it is used for writing to screen
	ld	A, BACKGROUND
	inc	C
	jr	NC, .doprint		; If the bit shifted was a 1, we are not
	ld	A, SOLID		; writing a BACKGROUND char and we are not
	dec	C			; Incrementing Fields register
.doprint:
	ld	(DE), A			; Write to screen
	pop	AF
	inc	DE			; Point to next char on screen
	dec	H			; Decrement Maze width
	jr	nz, .continueline	; Continue on same line if not 0
	; do stuff to DE
	dec	B			; Decrement maze height
	jr	Z, .placecursor		; If we have done all of maze, place the cursor
	push	BC			; Save maze height register
	ld	A, (Mwidth)		; calculate bytes to add to pointer to go to
	ld	H, A			; next line on screen
	ld	A, SCREENWIDTH
	sub	H
	ld	B, 0			; Store the calculated value in BC
	ld	C, A
	push	DE			; Cannot do ADD DE,BC so move value in DE to IY
	pop	IY
	add	IY, BC
	push	IY
	pop	DE			; DE now points to next line on screen
	inc	IX			; Point to next byte in maze data
	pop	BC			; Restore maze height register
	jr	.newline
.continueline:
	dec	L			; decrement bit counter
	jr	nz, .loop		; if not zero, we can continue
	ld	L, 8			; Reset bit counter
	inc	IX			; Move to next byte in maze data
	ld	A, (IX+0)
	jr	.loop
.placecursor:
	ld	A, C			; Save the number of free fields in maze
	dec	A			; the cursor overwrites a free field
	ld	(Fields), A
	ld	A, (Cursorx)		; BC = CursorX
	ld	B, 0
	ld	C, A
	ld	A, (Cursory)		; A = CursorY
	call	gotoxy
	ld	A, CURSOR
	ld	(DE), A
	ret

;******************************************************************************
; Find/Calculate needed values for current maze and store it in global variables
;******************************************************************************
; INPUTS:	HL - Points to start of current maze
; OUTPUS:	HL - Points to the actual maze data
;		Global variables contain current maze information
;******************************************************************************
getmazevals:
	push	HL
	pop	IX
	ld	A, (IX+1)		; Get maze width
	ld	(Mwidth), A		; Save it for later
	srl	A			; divide it by 2 (half it)
	ld	B, A
	ld	A, SCREENWIDTH/2	; Load .A with half of screen width
	sub	B			; Subtract half of the maze width
	ld	(Mazesx), A		; to get Maze start X coordinate

	ld	A, (IX+2)		; Get maze height
	ld	(Mheight), A		; Save it for later
	srl	A			; divide it by 2 (half it)
	ld	B, A
	ld	A, SCREENHEIGHT/2	; Load .A with half of screen height
	sub	B			; Subtract half of the maze height
	ld	(Mazesy), A		; to get Maze start Y coordinate

	ld	A, (IX+3)		; Load and save cursor starting X
	ld	B, A
	ld	A, (Mazesx)
	add	A, B
	ld	(Cursorx), A
	ld	A, (IX+4)		; Load and save cursor starting Y
	ld	B, A
	ld	A, (Mazesy)
	add	A, B
	ld	(Cursory), A
	ld	BC, 5
	add	HL, BC
	ret

;******************************************************************************
; Seek through the mazes until the maze number given in .A is reached
;******************************************************************************
; INPUTS:	A - Maze number / Level
; OUTPUTS:	HL - Points to the chosen maze
;******************************************************************************
findmaze:
	ld	B, 0			; BC is used to jump to next maze
	ld	HL, mazes		; Point to beginning of mazes
.loop:	dec	A			; Count down to 0 to find the right maze
	ret	Z
	ld	C, (HL)			; Load size of maze into (B)C
	add	HL, BC			; Add maze size to pointer to point to
	jr	.loop			; next maze
	; This could potentially continue past the mazes.

;******************************************************************************
; Clear screen, write header and usage
;******************************************************************************
gamescreen:
	ld	A, $A0
	call	clearscr

	ld	DE, VIDEOSTART		; Write header on top line
	ld	HL, .topl
	call	printstr
	ld	DE, VIDEOSTART+(40*29)	; Write usage on bottom line
	ld	HL, .botl
	jp	printstr

.topl	defb "            Cerberus Z80 Maze   Lvl: 000",0
.botl	defb "           Move = WASD or IJKL          ",0

;******************************************************************************
; Clear screen, draw a pretty startup screen and wait for a keypress
;******************************************************************************
welcomescreen:
STARTPOS=2
	ld	A, BACKGROUND
	call	clearscr

	goxy 11, STARTPOS-1
	ld	HL, .TITLE
	call	printstr

	goxy 7, startpos+2
	ld	HL, .CERB1
	call	printstr
	goxy 7, startpos+3
	ld	HL, .CERB2
	call	printstr
	goxy 7, startpos+4
	ld	HL, .CERB3
	call	printstr
	goxy 7, startpos+5
	ld	HL, .CERB4
	call	printstr
	goxy 7, startpos+6
	ld	HL, .CERB5
	call	printstr
	goxy 7, startpos+7
	ld	HL, .CERB6
	call	printstr
	goxy 7, startpos+8
	ld	HL, .CERB7
	call	printstr
	goxy 7, startpos+9
	ld	HL, .CERB8
	call	printstr
	goxy 7, startpos+10
	ld	HL, .CERB9
	call	printstr
	goxy 7, startpos+11
	ld	HL, .CERB10
	call	printstr
	goxy 7, startpos+12
	ld	HL, .CERB11
	call	printstr
	goxy 7, startpos+13
	ld	HL, .CERB12
	call	printstr
	goxy 7, startpos+14
	ld	HL, .CERB13
	call	printstr
	goxy 7, startpos+15
	ld	HL, .CERB14
	call	printstr
	goxy 7, startpos+16
	ld	HL, .CERB15
	call	printstr
	goxy 7, startpos+17
	ld	HL, .CERB16
	call	printstr
	goxy 7, startpos+18
	ld	HL, .CERB17
	call	printstr
	goxy 7, startpos+19
	ld	HL, .CERB18
	call	printstr
	goxy 7, startpos+20
	ld	HL, .CERB19
	call	printstr
	goxy 7, startpos+21
	ld	HL, .CERB20
	call	printstr
	goxy 7, startpos+22
	ld	HL, .CERB21
	call	printstr
	goxy 7, startpos+23
	ld	HL, .CERB22
	call	printstr

	goxy 6, 29
	ld	HL, .DEV
	call	printstr

	call	waitforkey
	ld	A, 0
	ld	(MAILFLAG), A
	ret

.TITLE:	defb	"Cerberus Z80 Maze",0
.CERB1	defb	"      ",$A0,$A0,"         ",$A0,$A0,0
.CERB2	defb	"      ",$A0,$A0,$A0,"       ",$A0,$A0,$A0,0
.CERB3	defb	"      ",$A0," ",$A0,"       ",$A0," ",$A0,0
.CERB4	defb	"      ",$A0," ",$A0,"       ",$A0," ",$A0,0
.CERB5	defb	"      ",$A0,$A0,$A0,$A0,"     ",$A0,$A0,$A0,$A0,0
.CERB6	defb	"     ",$A0,"    ",$A0,$A0," ",$A0,$A0,"    ",$A0,0
.CERB7	defb	"    ",$A0,$A0," ",$A0,$A0,"  ",$A0," ",$A0,"  ",$A0,$A0," ",$A0,$A0,0
.CERB8	defb	"   ",$A0,$A0,"  ",$A0,$A0,$A0,"  ",$A0,"  ",$A0,$A0,$A0,"  ",$A0,$A0,0
.CERB9	defb	"  ",$A0,$A0,"   ",$A0," ",$A0,"  ",$A0,"  ",$A0," ",$A0,"   ",$A0,$A0,0
.CERB10	defb	$A0,$A0,$A0,"    ",$A0," ",$A0,"  ",$A0,"  ",$A0," ",$A0,"    ",$A0,$A0,$A0,0
.CERB11	defb	$A0,"      ",$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,"      ",$A0,0
.CERB12	defb	$A0,$A0,"     ",$A0,"         ",$A0,"     ",$A0,$A0,0
.CERB13	defb	" ",$A0,$A0,"    ",$A0,"         ",$A0,"    ",$A0,$A0,0
.CERB14	defb	"  ",$A0,$A0,$A0,$A0,$A0,$A0,"  ",$A0,"   ",$A0,"  ",$A0,$A0,$A0,$A0,$A0,$A0,0
.CERB15	defb	"       ",$A0,"   ",$A0," ",$A0,"   ",$A0,0
.CERB16	defb	"       ",$A0,"         ",$A0,0
.CERB17	defb	"        ",$A0,"       ",$A0,0
.CERB18	defb	"         ",$A0,"     ",$A0,0
.CERB19	defb	"         ",$A0," ",$A0,$A0,$A0," ",$A0,0
.CERB20	defb	"         ",$A0,"  ",$A0,"  ",$A0,0
.CERB21	defb	"         ",$A0,"  ",$A0,"  ",$A0,0
.CERB22	defb	"          ",$A0,$A0,$A0,$A0,$A0,0
/*
.CERB1	defb	"      **         **",0
.CERB2	defb	"      ***       ***",0
.CERB3	defb	"      * *       * *",0
.CERB4	defb	"      * *       * *",0
.CERB5	defb	"      ****     ****",0
.CERB6	defb	"     *    ** **    *",0
.CERB7	defb	"    ** **  * *  ** **",0
.CERB8	defb	"   **  ***  *  ***  **",0
.CERB9	defb	"  **   * *  *  * *   **",0
.CERB10	defb	"***    * *  *  * *    ***",0
.CERB11	defb	"*      ***********      *",0
.CERB12	defb	"**     *         *     **",0
.CERB13	defb	" **    *         *    **",0
.CERB14	defb	"  ******  *   *  ******",0
.CERB15	defb	"       *   * *   *",0
.CERB16	defb	"       *         *",0
.CERB17	defb	"        *       *",0
.CERB18	defb	"         *     *",0
.CERB19	defb	"         * *** *",0
.CERB20	defb	"         *  *  *",0
.CERB21	defb	"         *  *  *",0
.CERB22	defb	"          *****",0*/
.DEV	defb	"Developed by: Jimmy Dansbo",0

;******************************************************************************
; Busy loop to check the MailFlag for a keypress
;******************************************************************************
; USES:		A
;******************************************************************************
waitforkey:
	ld	A, (MAILFLAG)
	cp	1
	jr	NZ, waitforkey
	ret

;******************************************************************************
; Fill the screen with chars in A
;******************************************************************************
; INPUTS:	A = character to use
; USES:		BC, DE, HL
;******************************************************************************
clearscr:
	ld	HL, VIDEOSTART
	ld	DE, VIDEOSTART
	ld	BC, 1200
.loop:	ld	(HL), A
	ldi
	jp	PE, .loop
	ret

;******************************************************************************
; Create a filled box
;******************************************************************************
; INPUTS:	A = character to use
;		B = width of box
;		C = height of box
; USES:		HL
;******************************************************************************
fillbox:
	ld	HL, DE			; Load screenptr to HL
.loop	push	BC			; Save dimensions
	call	hline
	POP	BC			; Restore dimensions
	ld	DE, 40			; Go to next line
	add	HL, DE
	ld	DE, HL
	dec	C			; Continue while hight>0
	jr	NZ, .loop
	ret

;******************************************************************************
; Draw the outline of a box
;******************************************************************************
; INPUTS:	A = character to use
;		B = width of box
;		C = height of box
;******************************************************************************
drawbox:
	push	DE			; Save screenptr
	push	BC			; Save dimensions
	call	hline			; Draw top horizontal line
	dec	DE			; Move screenptr 1 char back
	ld	B, C			; Load B with height of box
	call	vline			; Draw right vertical line
	pop	DE			; Restore dimensions, but swap the
	ld	B, E			; values so we can start by drawing
	ld	C, D			; the vertical line
	dec	B			; Height is decremented as bottom left
					; corner will be printed by hline
	pop	HL			; Restore screenptr
	ld	DE, 40			; Use DE to add 40 to HL on each pass
.loop:	ld	(HL), A			; Print character
	add	HL, DE			; Move to next line
	djnz	.loop
	ld	DE, HL			; Move screenptr to DE
	ld	B, C			; Load B with width of box
	jp	hline			; Draw bottom horizontal line


;******************************************************************************
; Print a vertical line
;******************************************************************************
; INPUTS:	A = character to use
;		B = height of line
; USES:		HL
;******************************************************************************
vline:
	ld	HL, DE			; Use HL as pointer to video mem
	ld	DE, 40			; Use DE to add 40 on each pass
.loop	ld	(HL), A			; Write char
	add	HL, DE			; Go to next line
	djnz	.loop			; DEC B and loop if not 0
	ld	DE, HL			; Save current screenptr in DE
	ret

;******************************************************************************
; Print a horizontal line
;******************************************************************************
; INPUTS:	A = character to use
;		B = Length of line
;******************************************************************************
hline:
	ld	(DE), A
	inc	DE
	djnz	hline
	ret

;******************************************************************************
; Print a 0-terminated string pointed to by HL
;******************************************************************************
; INPUTS:	HL = Pointer to 0-terminated string
; USES:		A, BC, DE
;******************************************************************************
printstr:
	ld	A, (HL)			; Return if current character is
	cp	0			; 0 = end of string
	ret	Z
	ldi				; Print char to screen and inc ptrs
	jr	printstr

;******************************************************************************
; Set DE to point to video memory address that corresponds to X and Y
; coordinates assigned as in C and A registers respectively
;******************************************************************************
; INPUTS:	A = Y coordinate
;		BC = X coordinate
; OUTPUTS:	DE = Video memory address
; USES:		HL
;******************************************************************************
gotoxy:
	ld	HL, VIDEOSTART		; Start of video memory
	add	HL, BC			; Add X coordinate
	cp	0			; Return if Y coordinate = 0
	jr	Z, .end
	ld	DE, 40			; DE used to add 40 Y number of times
	ld	B, A			; Move Y coord to B for use with djnz
.yloop:	add	HL, DE			; Add 40*Y
	djnz	.yloop
.end:	ld	DE, HL			; Save video memory position in DE
	ret

	; Level 1
mazes	defb	25,10,10	;size,width,Height
	defb	00,01		;start coordinates (zero based)
	defb	%00000000,%00111111
	defb	%00000000,%01111111
	defb	%10000000,%01111111
	defb	%10000000,%11111111
	defb	%11000000,%11111111
	defb	%11000001,%11111111
	defb	%11100001,%11111111
	defb	%11100011,%11111111
	defb	%11110011,%11111111
	defb	%11110111,%11111111

	; Level 2
	defb	15,8,10
	defb	0,9
	defb	%00000000
	defb	%01111010
	defb	%01100010
	defb	%01000000
	defb	%01000011
	defb	%01000000
	defb	%01000010
	defb	%01000110
	defb	%01101110
	defb	%00000000

	; Level 3
	defb	14,7,9
	defb	0,8
	defb	%00000001
	defb	%01111101
	defb	%00000001
	defb	%01111111
	defb	%00000001
	defb	%11111101
	defb	%00000001
	defb	%01111101
	defb	%00000001

	; Level 4
	defb	12,7,7
	defb	0,6
	defb	%00000011
	defb	%01111001
	defb	%01000001
	defb	%01011001
	defb	%01000001
	defb	%01111101
	defb	%00000001

	; Level 5
	defb	12,7,7
	defb	0,6
	defb	%00000001
	defb	%01111101
	defb	%01111101
	defb	%00000001
	defb	%01010101
	defb	%01010101
	defb	%00010001

	; Level 6
	defb	25,10,10	;size,width,height
	defb	0,9		;start coordinates (zero based)
	defb	%00000000,%01111111
	defb	%01000000,%00111111
	defb	%01011111,%10111111
	defb	%01010000,%10111111
	defb	%01010010,%10111111
	defb	%01010010,%10111111
	defb	%01011110,%10111111
	defb	%01000000,%10111111
	defb	%01111111,%10111111
	defb	%00000000,%00111111

	; Level 7
	defb	15,7,10
	defb	0,8
	defb	%10000011
	defb	%00111001
	defb	%00000001
	defb	%00010001
	defb	%01010101
	defb	%01010101
	defb	%01000101
	defb	%01111101
	defb	%00010001
	defb	%10000011

	; Level 8
	defb	23,10,9
	defb	0,8
	defb	%11000000,%01111111
	defb	%11011111,%00111111
	defb	%00000001,%00111111
	defb	%01010000,%00111111
	defb	%01010111,%11111111
	defb	%01000000,%01111111
	defb	%01100000,%01111111
	defb	%01111111,%01111111
	defb	%00000000,%01111111

	; Level 9
	defb	31,13,13
	defb	0,12
	defb	%11110000,%00000111
	defb	%00000011,%11110111
	defb	%01110010,%00000111
	defb	%00000000,%00100111
	defb	%11110011,%11100111
	defb	%00000010,%01100111
	defb	%01111010,%01100111
	defb	%01111010,%01100111
	defb	%01111010,%01100111
	defb	%00011000,%01100111
	defb	%11011111,%01100111
	defb	%00010000,%01100111
	defb	%00010000,%01100111

	; Level 10
	defb	27,11,11
	defb	0,10
	defb	%00000000,%11111111
	defb	%01110000,%00111111
	defb	%01100000,%00011111
	defb	%00001110,%01011111
	defb	%01001000,%01011111
	defb	%01011010,%11011111
	defb	%01011010,%11011111
	defb	%01011010,%11011111
	defb	%00000010,%11011111
	defb	%00000010,%01011111
	defb	%00111111,%00011111

	; Level 11
	defb	27,11,11
	defb	0,10
	defb	%00011100,%00011111
	defb	%01000100,%00011111
	defb	%01000000,%01111111
	defb	%01000011,%00111111
	defb	%01100000,%00111111
	defb	%01000010,%00011111
	defb	%01000010,%00011111
	defb	%01101011,%10011111
	defb	%01100010,%00111111
	defb	%01101110,%11111111
	defb	%01100000,%11111111

	; Level 12
	defb	31,13,13
	defb	0,11
	defb	%10000000,%11100111
	defb	%00111110,%01100111
	defb	%00111110,%01100111
	defb	%00111110,%01100111
	defb	%00000110,%01100111
	defb	%01110111,%00000111
	defb	%00000001,%11110111
	defb	%01111000,%00010111
	defb	%00111001,%11010111
	defb	%00111001,%11010111
	defb	%00111000,%01000111
	defb	%00111101,%01011111
	defb	%10000001,%00000111

	; Level 13
	defb	31,13,13
	defb	0,11
	defb	%10000111,%00111111
	defb	%00110001,%00001111
	defb	%00110101,%00001111
	defb	%00000001,%00000111
	defb	%00010111,%00000111
	defb	%01110111,%00000111
	defb	%00000000,%00000111
	defb	%11110110,%00000111
	defb	%00000110,%00011111
	defb	%01101110,%00011111
	defb	%00100000,%01111111
	defb	%00111110,%11111111
	defb	%10000000,%11111111

	; Level 14
	defb	41,13,18
	defb	0,14
	defb	%00000010,%01111111
	defb	%01011010,%01111111
	defb	%01000010,%00011111
	defb	%01011110,%01011111
	defb	%01000000,%00001111
	defb	%01000110,%01001111
	defb	%01111110,%00000111
	defb	%00000000,%00000111
	defb	%11111111,%01000111
	defb	%11000001,%00000111
	defb	%10000001,%11000111
	defb	%10111101,%11110111
	defb	%10000101,%11110111
	defb	%10110100,%00000111
	defb	%00110111,%11110111
	defb	%00000100,%00000111
	defb	%01111100,%00000111
	defb	%00000001,%11111111

	; Level 15
	defb	25,10,10
	defb	0,9
	defb	%00000001,%11111111
	defb	%01111100,%01111111
	defb	%01000001,%01111111
	defb	%01011111,%01111111
	defb	%01010000,%00111111
	defb	%00000000,%00111111
	defb	%11010110,%00111111
	defb	%00000000,%00111111
	defb	%01010110,%00111111
	defb	%00010000,%01111111

	; Level 16
	defb	31,9,13
	defb	0,12
	defb	%10000001,%11111111
	defb	%10101101,%11111111
	defb	%10100000,%01111111
	defb	%10101111,%01111111
	defb	%10000000,%01111111
	defb	%11101111,%11111111
	defb	%10001100,%01111111
	defb	%00111101,%01111111
	defb	%01110000,%01111111
	defb	%01110101,%11111111
	defb	%00000000,%01111111
	defb	%01110101,%01111111
	defb	%00000100,%01111111

	; Level 17
	defb	25,10,10
	defb	1,8
	defb	%10001000,%01111111
	defb	%00000000,%00111111
	defb	%00001010,%10111111
	defb	%00000000,%00111111
	defb	%00000010,%00111111
	defb	%01000000,%01111111
	defb	%00000000,%00111111
	defb	%00100000,%00111111
	defb	%10000000,%11111111
	defb	%11100001,%11111111

	; Level 18
	defb	27,11,11
	defb	0,10
	defb	%00000011,%10011111
	defb	%01101011,%00011111
	defb	%00000001,%00011111
	defb	%11101001,%00011111
	defb	%00001001,%00011111
	defb	%01001001,%00011111
	defb	%01011001,%11011111
	defb	%01010000,%01011111
	defb	%01110101,%01011111
	defb	%00000001,%01011111
	defb	%00000111,%00011111

	; Level 19
	defb	31,13,13
	defb	0,12
	defb	%10011111,%11110111
	defb	%10000111,%11000111
	defb	%10000111,%00000111
	defb	%10000001,%00000111
	defb	%10000001,%00000111
	defb	%10000011,%00000111
	defb	%00000000,%00000111
	defb	%00000010,%00000111
	defb	%00000010,%00000111
	defb	%00000010,%00000111
	defb	%00000010,%00000111
	defb	%00001111,%10000111
	defb	%00111111,%11100111

	; Level 20
	defb	31,13,13
	defb	0,0
	defb	%00000000,%00000111
	defb	%11110111,%11110111
	defb	%11100000,%01110111
	defb	%11000000,%00110111
	defb	%10000000,%10110111
	defb	%10100000,%00010111
	defb	%10110101,%10010111
	defb	%10000101,%10010111
	defb	%10001101,%00110111
	defb	%11101101,%01110111
	defb	%11100000,%00000111
	defb	%11100000,%00111111
	defb	%11111100,%01111111

	; Level 21
	defb	29,12,12
	defb	0,11
	defb	%11110001,%00001111
	defb	%11110101,%01111111
	defb	%11110101,%01111111
	defb	%11000001,%00001111
	defb	%11010011,%01101111
	defb	%11011000,%01101111
	defb	%11011111,%01101111
	defb	%00010000,%00001111
	defb	%01010110,%11111111
	defb	%01000000,%11111111
	defb	%01110111,%11111111
	defb	%00000111,%11111111

	; Level 22
	defb	31,13,13
	defb	0,12
	defb	%00111111,%00001111
	defb	%00001111,%01100111
	defb	%00001111,%01110111
	defb	%10101000,%01110111
	defb	%10101000,%00000111
	defb	%10100011,%10110111
	defb	%10111011,%10110111
	defb	%00100010,%00110111
	defb	%00101110,%11110111
	defb	%00001110,%00010111
	defb	%00111111,%11010111
	defb	%00000000,%01010111
	defb	%00000000,%01000111

	; Level 23
	defb	29,13,12
	defb	0,10
	defb	%11111001,%10000111
	defb	%00000000,%10000111
	defb	%01111010,%11110111
	defb	%00001010,%11000111
	defb	%11101010,%00000111
	defb	%00001011,%11011111
	defb	%01111011,%11011111
	defb	%00110011,%11011111
	defb	%10110000,%01000111
	defb	%00010111,%01010111
	defb	%00010100,%00010111
	defb	%11000100,%01000111

	; Level 24
	defb	33,14,14
	defb	0,12
	defb	%10001000,%11001111
	defb	%00001000,%00000011
	defb	%00101010,%11001011
	defb	%00101010,%11001011
	defb	%00000000,%00000011
	defb	%00001110,%11001011
	defb	%10000110,%11001011
	defb	%10010000,%00001011
	defb	%00010000,%00000011
	defb	%00000100,%11100011
	defb	%00011100,%00000011
	defb	%00000001,%11010011
	defb	%01000000,%00000111
	defb	%11111001,%11000111

	; Level 25
	defb	31,13,13
	defb	0,11
	defb	%01000000,%00000111
	defb	%01011110,%00000111
	defb	%00000010,%11111111
	defb	%01111010,%11111111
	defb	%00011010,%00001111
	defb	%11011011,%00000111
	defb	%00000001,%11110111
	defb	%01000001,%11110111
	defb	%01111100,%01110111
	defb	%01111101,%01110111
	defb	%01111101,%01110111
	defb	%00000101,%00000111
	defb	%10000000,%00001111

	; Level 26
	defb	44,18,13
	defb	0,8
	defb	%00000000,%11111100,%00111111
	defb	%01111110,%11000000,%10111111
	defb	%00000010,%10010110,%10111111
	defb	%01010010,%10010110,%10111111
	defb	%01010010,%10010000,%10111111
	defb	%00010110,%10011111,%10111111
	defb	%11110110,%10000010,%00111111
	defb	%00000000,%11111010,%01111111
	defb	%00000000,%00111010,%01111111
	defb	%11010100,%10111010,%01111111
	defb	%11000000,%00011010,%01111111
	defb	%11110000,%00011010,%01111111
	defb	%11111100,%00000000,%01111111

	; Level 27
	defb	31,14,13
	defb	0,11
	defb	%00000000,%00001111
	defb	%01000111,%11101111
	defb	%00000000,%11100011
	defb	%11000110,%11100011
	defb	%11000110,%11111011
	defb	%11000000,%00111011
	defb	%11100000,%00011011
	defb	%11100000,%00011011
	defb	%11110000,%00011011
	defb	%11110111,%10111011
	defb	%00000000,%00000011
	defb	%00000000,%00111111
	defb	%11000000,%00111111

	; Level 28
	defb	33,13,14
	defb	0,13
	defb	%11111111,%00010111
	defb	%11111111,%01010111
	defb	%11111100,%01010111
	defb	%11110001,%10000111
	defb	%11110101,%10111111
	defb	%10000101,%10111111
	defb	%10000000,%00000111
	defb	%10100000,%01111111
	defb	%10101011,%01000111
	defb	%10100011,%00010111
	defb	%00010000,%00010111
	defb	%01000000,%00010111
	defb	%01010110,%00100111
	defb	%00000000,%10001111

	; Level 29
	defb	31,13,13
	defb	0,12
	defb	%10000100,%01111111
	defb	%00000101,%00000111
	defb	%00111101,%01000111
	defb	%00000001,%01011111
	defb	%10101101,%01000111
	defb	%00100001,%01010111
	defb	%00111111,%01010111
	defb	%00000000,%00010111
	defb	%01000000,%00010111
	defb	%01011111,%11110111
	defb	%01000000,%00000111
	defb	%01111010,%11110111
	defb	%00000010,%00000111

	; Level 30
	defb	44,18,13
	defb	0,12
	defb	%10000000,%00001111,%11111111
	defb	%10010110,%00000011,%11111111
	defb	%10010110,%00000000,%11111111
	defb	%10010111,%01001010,%11111111
	defb	%10010111,%00000000,%00111111
	defb	%10010111,%11000000,%00111111
	defb	%00010000,%01011011,%11111111
	defb	%01111110,%01011010,%00111111
	defb	%01000010,%01010010,%10111111
	defb	%01011010,%01010010,%10111111
	defb	%01011010,%01010000,%00111111
	defb	%01000000,%11011111,%10111111
	defb	%00001111,%11000000,%00111111

	; Level 31
	defb	21,10,8
	defb	0,6
	defb	%10011110,%00111111
	defb	%00011100,%00111111
	defb	%00001101,%00111111
	defb	%00000000,%00111111
	defb	%01000000,%00111111
	defb	%01100000,%00111111
	defb	%00000000,%01111111
	defb	%10000000,%00111111

	; Level 32
	defb	41,13,18
	defb	0,13
	defb	%00111100,%11001111
	defb	%00110000,%11001111
	defb	%00110000,%00001111
	defb	%00110000,%10001111
	defb	%00000000,%00001111
	defb	%00010000,%10001111
	defb	%00010000,%10001111
	defb	%00010000,%10001111
	defb	%00010000,%10001111
	defb	%00010000,%10001111
	defb	%00000000,%00000111
	defb	%00000000,%00000111
	defb	%00010001,%10000111
	defb	%00000001,%10000111
	defb	%10010001,%11100111
	defb	%10010001,%11100111
	defb	%10000001,%11111111
	defb	%10011001,%11111111

	; Level 33
	defb	33,15,14
	defb	0,12
	defb	%11000111,%11000111
	defb	%10000101,%11000111
	defb	%10000000,%10000011
	defb	%00000000,%10000011
	defb	%00000000,%01100011
	defb	%00010100,%00100111
	defb	%00000110,%00100011
	defb	%10000000,%00000001
	defb	%01110110,%00100001
	defb	%00000000,%00100001
	defb	%11110101,%00000011
	defb	%00000000,%00000111
	defb	%00000000,%00011111
	defb	%11110001,%00111111

	; Level 34
	defb	33,14,14
	defb	0,8
	defb	%11000000,%00000111
	defb	%00000011,%10110111
	defb	%00100000,%00000011
	defb	%00001000,%00000011
	defb	%10101001,%10110111
	defb	%10101001,%10110111
	defb	%10100000,%00000011
	defb	%00000001,%10110011
	defb	%00011001,%10000011
	defb	%10010000,%10111111
	defb	%10010110,%00000011
	defb	%10000000,%00110011
	defb	%11000000,%00000011
	defb	%10000011,%00000111

	; Level 35
	defb	31,13,13
	defb	0,10
	defb	%11111000,%00000111
	defb	%10001011,%01110111
	defb	%10101001,%00000111
	defb	%10101101,%01011111
	defb	%10100000,%00011111
	defb	%10100110,%01011111
	defb	%00111110,%01000111
	defb	%00001110,%01010111
	defb	%00000110,%01000111
	defb	%00000000,%11110111
	defb	%00000010,%00000111
	defb	%10010010,%11011111
	defb	%11111110,%00011111

	; Level 36
	defb	29,13,12
	defb	0,10
	defb	%11111000,%00000111
	defb	%10000000,%00010111
	defb	%10111011,%11110111
	defb	%10100000,%00010111
	defb	%10101111,%11010111
	defb	%10000000,%00000111
	defb	%00100000,%01000111
	defb	%01111011,%01011111
	defb	%01100000,%00000111
	defb	%01101000,%01010111
	defb	%00101111,%11010111
	defb	%10000000,%00000111

	; Level 37
	defb	59,18,18
	defb	0,15
	defb	%10000000,%00111001,%11111111
	defb	%10000000,%00011001,%11111111
	defb	%10100000,%00010001,%00111111
	defb	%10100111,%11110000,%00111111
	defb	%10100100,%00000000,%00111111
	defb	%00100100,%11111000,%00111111
	defb	%00100000,%00000000,%00111111
	defb	%01100100,%00010000,%00111111
	defb	%01000110,%10010000,%01111111
	defb	%01000000,%11111000,%01111111
	defb	%01000011,%10011000,%01111111
	defb	%00000011,%00011000,%01111111
	defb	%01100011,%00001000,%01111111
	defb	%00111111,%01101000,%01111111
	defb	%00100000,%00001000,%01111111
	defb	%00101101,%00101110,%01111111
	defb	%10000000,%00000110,%01111111
	defb	%11111100,%00100111,%11111111

	; Level 38
	defb	59,18,18
	defb	0,17
	defb	%00000011,%11100111,%00111111
	defb	%01111001,%10000111,%00111111
	defb	%00001100,%00001100,%00111111
	defb	%00000100,%10101100,%00111111
	defb	%10100100,%10000000,%00111111
	defb	%10111111,%10100100,%00111111
	defb	%10000010,%00000000,%00111111
	defb	%11111000,%10100100,%01111111
	defb	%11000000,%10100100,%01111111
	defb	%11011100,%10100100,%01111111
	defb	%11000100,%10100100,%01111111
	defb	%10000100,%10100100,%01111111
	defb	%00011100,%10100100,%01111111
	defb	%00011100,%10100100,%01111111
	defb	%00000000,%00000000,%01111111
	defb	%00111100,%00000110,%01111111
	defb	%00111100,%11100110,%01111111
	defb	%00111111,%11111111,%11111111

	; Level 39
	defb	37,16,16
	defb	0,11
	defb	%00111100,%00000000
	defb	%00001101,%10000000
	defb	%00000000,%10000001
	defb	%01001110,%11000001
	defb	%01011110,%11010111
	defb	%01000010,%11010001
	defb	%01111010,%00010001
	defb	%00000000,%01011101
	defb	%11111011,%01010000
	defb	%00000011,%01010000
	defb	%01111011,%01010001
	defb	%00001010,%01011001
	defb	%10000000,%00000001
	defb	%11101110,%01011001
	defb	%11100000,%00000001
	defb	%11100000,%10011001

	; Level 40
	defb	37,16,16
	defb	0,15
	defb	%00000111,%00010001
	defb	%00110111,%01010100
	defb	%10000100,%00010100
	defb	%10111101,%01110100
	defb	%00110000,%01110100
	defb	%01110101,%01110100
	defb	%01110000,%01000100
	defb	%00011101,%11011110
	defb	%00011100,%00000000
	defb	%10000111,%11011100
	defb	%10100111,%11011100
	defb	%10101111,%11000100
	defb	%00000000,%00000100
	defb	%00101111,%11101100
	defb	%00100000,%00001100
	defb	%00111111,%11111100

	; Level 41
	defb	33,14,14
	defb	0,12
	defb	%00011000,%01000111
	defb	%01001011,%01010111
	defb	%01100000,%00000011
	defb	%01111011,%01011011
	defb	%00000000,%01011011
	defb	%11111011,%11000011
	defb	%00001000,%01111111
	defb	%00000000,%01001111
	defb	%11101001,%11001111
	defb	%11101000,%00000111
	defb	%11101001,%01010111
	defb	%00000000,%01010111
	defb	%00001001,%11010111
	defb	%11111001,%11000111

	; Level 42
	defb	33,14,14
	defb	0,13
	defb	%00000001,%00000011
	defb	%01111101,%01111011
	defb	%00001001,%00001011
	defb	%11100011,%00001011
	defb	%00000111,%00111011
	defb	%01111100,%00001011
	defb	%01110000,%00101011
	defb	%01000101,%00101011
	defb	%01010101,%00101011
	defb	%01010101,%11101011
	defb	%01010101,%00000011
	defb	%01000000,%00001011
	defb	%01110101,%01011011
	defb	%00000100,%01000011

	; Level 43
	defb	33,14,14
	defb	0,13
	defb	%10000100,%00100011
	defb	%00000101,%10101011
	defb	%01110001,%00000011
	defb	%00011111,%00111011
	defb	%11011110,%00111011
	defb	%00000000,%01100011
	defb	%01011110,%01000111
	defb	%00000010,%01010111
	defb	%11011010,%00000011
	defb	%11000011,%01010011
	defb	%11111000,%00000011
	defb	%00001001,%01011011
	defb	%00000000,%01000011
	defb	%00000001,%11111111

	; Level 44
	defb	31,13,13
	defb	0,11
	defb	%10000000,%00000111
	defb	%00111111,%11110111
	defb	%00000000,%11110111
	defb	%11111010,%10000111
	defb	%11100010,%10111111
	defb	%11101010,%10000111
	defb	%10000000,%00010111
	defb	%00101110,%11010111
	defb	%00100000,%11010111
	defb	%00100100,%10010111
	defb	%01111100,%10010111
	defb	%00000100,%10000111
	defb	%10000001,%10001111

	; Level 45
	defb	33,14,14
	defb	0,13
	defb	%00011000,%01000011
	defb	%00010001,%01001011
	defb	%01110001,%01001011
	defb	%00000111,%01001011
	defb	%01111100,%00001011
	defb	%01111001,%01011011
	defb	%01000001,%00000011
	defb	%01011011,%10111111
	defb	%00000000,%00001111
	defb	%01001011,%10101111
	defb	%01111010,%00000011
	defb	%00001010,%00001011
	defb	%00101011,%10111011
	defb	%00100011,%10000011

	; Level 46
	defb	41,13,18
	defb	0,11
	defb	%11111100,%00000111
	defb	%00000001,%11110111
	defb	%00000001,%00000111
	defb	%01111111,%01100111
	defb	%00000001,%01101111
	defb	%01111101,%00001111
	defb	%01111101,%11101111
	defb	%00011100,%00001111
	defb	%00000100,%00011111
	defb	%00010111,%11111111
	defb	%00000000,%00000111
	defb	%00000011,%11110111
	defb	%10010011,%00010111
	defb	%10000000,%00010111
	defb	%11010011,%11010111
	defb	%11000010,%00010111
	defb	%11110010,%11010111
	defb	%11110010,%00000111

	; Level 47
	defb	31,13,13
	defb	0,9
	defb	%11000100,%11001111
	defb	%10010100,%01000111
	defb	%10100101,%01010111
	defb	%00001100,%00000111
	defb	%00111111,%01011111
	defb	%00000000,%00000111
	defb	%11111111,%01010111
	defb	%11100001,%01010111
	defb	%00000000,%01010111
	defb	%00000111,%11010111
	defb	%11100100,%00000111
	defb	%11100001,%11011111
	defb	%11111100,%00011111

	; Level 48
	defb	31,13,13
	defb	0,11
	defb	%11100000,%00111111
	defb	%00100111,%10011111
	defb	%00000100,%11011111
	defb	%00111100,%01000111
	defb	%00001101,%01010111
	defb	%00101101,%01010111
	defb	%00100001,%01010111
	defb	%01111111,%01010111
	defb	%00000000,%00000111
	defb	%11111111,%01011111
	defb	%00000000,%00000111
	defb	%00111111,%01010111
	defb	%10000000,%01000111

	; Level 49
	defb	37,16,16
	defb	0,14
	defb	%00000000,%00000000
	defb	%00000000,%00000010
	defb	%11111111,%10111110
	defb	%11111100,%10000010
	defb	%11000000,%11111010
	defb	%00011101,%10000000
	defb	%00011101,%00001011
	defb	%00011101,%00111011
	defb	%00000101,%00111001
	defb	%00010000,%01111100
	defb	%00010001,%01000000
	defb	%00010001,%01011111
	defb	%00110000,%00000000
	defb	%00110001,%01011110
	defb	%00110001,%01000000
	defb	%11110011,%00000001

	; Level 50
	defb	44,18,13
	defb	0,7
	defb	%00001000,%00010000,%00111111
	defb	%01101011,%11010111,%10111111
	defb	%01101011,%00000111,%10111111
	defb	%00000010,%00011111,%10111111
	defb	%01111010,%01100000,%00111111
	defb	%01000000,%01101011,%11111111
	defb	%01011010,%11101011,%11111111
	defb	%00000010,%11101011,%11111111
	defb	%11011110,%11101011,%11111111
	defb	%11011110,%11101000,%00111111
	defb	%11011110,%00000011,%10111111
	defb	%11011110,%11111111,%10111111
	defb	%11000000,%00000000,%00111111

	; Level 51
	defb	35,13,15
	defb	0,11
	defb	%10000000,%00000111
	defb	%10111011,%11110111
	defb	%00000000,%00110111
	defb	%00110000,%00000111
	defb	%00101010,%10111111
	defb	%00100000,%00011111
	defb	%00101010,%10011111
	defb	%00100010,%00000111
	defb	%00000000,%10010111
	defb	%01000010,%10010111
	defb	%01010000,%00000111
	defb	%00000011,%10010111
	defb	%11011000,%10010111
	defb	%11011110,%11110111
	defb	%11000000,%00000111

	; Level 52
	defb	31,13,13
	defb	0,8
	defb	%10001000,%00000111
	defb	%00000000,%11110111
	defb	%00101110,%00010111
	defb	%00100010,%01010111
	defb	%00101010,%01010111
	defb	%11101010,%01000111
	defb	%00000010,%01011111
	defb	%01111110,%01000111
	defb	%00000000,%01010111
	defb	%10111110,%01010111
	defb	%10000000,%01010111
	defb	%10010111,%11010111
	defb	%10010000,%00000111

	; Level 53
	defb	35,14,15
	defb	0,11
	defb	%11000101,%00011111
	defb	%00000000,%00001111
	defb	%00000101,%00101111
	defb	%00100001,%10000111
	defb	%10000011,%11010111
	defb	%11100110,%00000011
	defb	%11100010,%11000011
	defb	%00101010,%00111111
	defb	%00000010,%01000111
	defb	%00100011,%00000111
	defb	%01000100,%01110111
	defb	%00010001,%00000111
	defb	%11111000,%01011111
	defb	%11111001,%10011111
	defb	%11111100,%00111111

	; Level 54
	defb	41,13,18
	defb	0,17
	defb	%00000100,%00000111
	defb	%01110101,%11110111
	defb	%01110001,%11110111
	defb	%01010110,%00000111
	defb	%01010110,%10111111
	defb	%01000000,%10111111
	defb	%01011110,%10111111
	defb	%01010000,%00000111
	defb	%01010110,%10110111
	defb	%00000000,%00010111
	defb	%11110110,%10010111
	defb	%00110110,%10000111
	defb	%00010110,%11011111
	defb	%01010110,%00000111
	defb	%01000001,%11010111
	defb	%01110101,%11010111
	defb	%01110100,%00000111
	defb	%00000111,%11111111

	; Level 55
	defb	44,18,13
	defb	0,11
	defb	%11100011,%11000000,%00111111
	defb	%11101011,%10010111,%10111111
	defb	%10000011,%00000000,%00111111
	defb	%10101110,%00110101,%10111111
	defb	%00001110,%10100000,%10111111
	defb	%00000010,%10100100,%10111111
	defb	%00011010,%10100100,%10111111
	defb	%00011010,%10100100,%10111111
	defb	%00000000,%00000000,%10111111
	defb	%01011010,%10100101,%10111111
	defb	%01011000,%10110101,%10111111
	defb	%00011110,%00000000,%00111111
	defb	%10000000,%10000001,%11111111

	; Level 56
	defb	35,14,15
	defb	0,10
	defb	%11110001,%11111111
	defb	%11100000,%10001111
	defb	%11000000,%00000011
	defb	%11000000,%00000011
	defb	%10001101,%11000011
	defb	%00000000,%01001111
	defb	%00000000,%00111111
	defb	%10010000,%00001111
	defb	%00000101,%00000111
	defb	%00010101,%10001111
	defb	%00000000,%00000011
	defb	%10010100,%10000011
	defb	%10010100,%00000011
	defb	%10010100,%00000111
	defb	%10010010,%00011111

	; Level 57
	defb	21,15,8
	defb	0,0
	defb	%00001111,%11100001
	defb	%10000111,%11000011
	defb	%11000011,%10000111
	defb	%11100000,%00011111
	defb	%11110000,%00001111
	defb	%11000011,%10000111
	defb	%10000111,%11000011
	defb	%00001111,%11100001
