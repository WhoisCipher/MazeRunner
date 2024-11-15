; //////////////////////
; // MAZE RUNNER
; //
; // Developed by:
; //    - Moiz
; //    - Abdullah
; //
; // INT 10h - BIOS VGA modes
; // INT 9h  - Keyboard Intrupt
; // INT 8h  - Timer Intrupt
; //////////////////////

[org 0100h]
                    jmp main


; /////////////////////////////////////////
; // Keyboard Intrupt
; //
; // Input detection, 2 variations:
; // - Menu
; //    => Up/Down Arrow Keys (Change 
; //       selections)
; //    => Enter Key (Run Function Based
; //       of current selections)
; // - Game
; //    => Movement of Player  (WASD)
; //    => SuperMan Mode       (SpaceBar)
; //    => Pause Game          (Esc)
; /////////////////////////////////////////
orgKBISR_offest: dw 0
orgKBISR_segment: dw 0
MenuSelection:  dw  0
ENTER_flag:     dw  0

    ;   Scan-Code
    ;   UP      0x48
    ;   DOWN    0x50
    ;   ENTER   0x1C
kbISR_MENU:
        pusha

        in al, 0x60
        mov ah, al

        ; up-arrow
        cmp ah, 0x50
        je up

        ; down-arrow
        cmp ah, 0x48
        je down

        ; enter
        cmp ah, 0x1c
        je entr

        jmp EOI

    entr:
        cmp word[MenuSelection], 1
        je ExitGame
        call clearScreen
        call _init_MAP
        call drawScoreText
        push 0
        call drawScore
        call drawLivesText
        call drawLives
        call kbISR_GAME_hook
        jmp EOI

    up: 
        mov word[MenuSelection], 1
        push 1
        call updateMenuSelection
        jmp EOI
    
    ExitGame:
        call restoreTextMode
        mov ax, 0xb800
        mov es, ax
        mov ax, 0x720
        mov cx, 2000
        mov di, 0
        rep stosw
        call restoreISR
        mov ax, 4c00h
        int 21h
        
    down:
        mov word[MenuSelection], 0
        push 0
        call updateMenuSelection

    EOI:
        mov al, 0x20
        out 0x20, al
        
        popa
        iret

kbISR_GAME:
        pusha

        mov ax, 0xa000
        mov es, ax

        
        mov cx, 50
        mov di, 0
        mov al, 5
        rep stosb

        in al, 0x60
        mov ah, al
        
        ;W
        cmp ah, 0x11
        je moveFwd
        
        ;A
        cmp ah, 0x1E
        je moveLeft

        ;S
        cmp ah, 0x1F
        je moveDown

        ;D
        cmp ah, 0x20
        je moveRight

        jmp EOI2
    
    moveFwd:
        call player_UP
        jmp EOI2

    moveDown:
        call player_DOWN
        jmp EOI2

    moveRight:
        call player_RIGHT
        jmp EOI2

    moveLeft:
        call player_LEFT
        jmp EOI2

    EOI2:
        mov al, 0x20
        out 0x20, al

        popa
        iret

kbISR_GAME_hook:
        pusha

        cli
        xor ax, ax
        mov es, ax
        
        mov word[es:4*9], kbISR_GAME
        mov word[es:4*9+2], cs
        sti

        popa
        ret

kbISR_MENU_hook:
        push bp
        mov bp, sp
        pusha
        
        cli
        xor ax, ax
        mov es, ax
        
        mov ax, [es:4*9]          
        mov [orgKBISR_offest], ax
        mov ax, [es:4*9+2]
        mov [orgKBISR_segment], ax
     
        mov word[es:4*9], kbISR_MENU
        mov [es:4*9+2], cs
        sti

        popa
        pop bp
        ret

kbISR_REST_MENU:
        pusha
        
        mov cx, 15000
        mov al, 4
        mov di, 10*320
        rep stosb
        in al, 0x60

        ;R pressed
        cmp al, 0x13
        je newGame

        ; Q pressed
        cmp al, 0x15
    
    newGame:
        call clearScreen
        call _init_MAP
        call drawScoreText
        push 0
        call drawScore
        call drawLivesText
        call drawLives
        call kbISR_GAME_hook
        jmp EOI3

    quit:
        call restoreTextMode
        mov ax, 0xb800
        mov es, ax
        mov ax, 0x720
        mov cx, 2000
        mov di, 0
        rep stosw
        call restoreISR
        mov ax, 4c00h
        int 21h

    EOI3:
        mov al, 0x20
        out 0x20, al

        popa
        iret

kbISR_REST_MENU_hook:
        push bp
        mov bp, sp
        pusha
        
        cli
        xor ax, ax
        mov es, ax
        
        mov word[es:4*9], kbISR_REST_MENU
        mov [es:4*9+2], cs
        sti

        popa
        pop bp
        ret


restoreISR:
        pusha
        
        cli
        xor ax, ax
        mov es, ax

        mov ax, [orgKBISR_offest]
        mov [es:4*9], ax
        mov ax, [orgKBISR_segment]
        mov [es:4*9+2], ax
        sti

        popa
        ret

; ////////////////////////////////////////////
; // Timer Intrupt
; // 
; // Used to make the timer Work, Each time
; // the IRQ-0 sets, the tick variable gets
; // increased and 18 ticks approx to 1 sec
; ////////////////////////////////////////////
tick:           db  0

timerISR:
        push bp
        mov bp, sp
        pusha
        

    _inc_TICK:
        inc byte[tick]
        
        mov al, [tick]
        cmp al, 18
        jl done
        call drawTimer
        mov byte[tick], 0
        inc byte[tick]

    done:
        mov al, 0x20
        out 0x20, al

        popa
        pop bp
        iret
        

timerISR_hook:
        push bp
        push ax
        push ds
        mov bp, sp

        cli
        xor ax, ax
        mov es, ax
        mov word[es:4*8], timerISR
        mov [es:4*8+2], cs
        sti
        
        pop ax
        pop ds
        pop bp
        ret

; ----** GlobalFunctions **----
;
;   int     getRand()           ; return random value between 1-18
;   
;   void    clearScreen()
;   void    setVideoMode()
;   void    restoreTextMode()
;
;   void    drawMenu()
;   void    drawQuit()
;   void    drawPlay()
;   void    drawHorizontalLine(int offset, int width)
;   void    drawVerticalLine(int offset, int height)
;   void    drawButtons()
;   void    drawMenuMaze()
;   void    drawHeroText()
    ; @prams 
    ;   bp+4 => Random Value to return
getRand:
        push bp
        push ax

        mov ax, [tick]
        mov [bp+4], ax
        
        pop ax
        pop bp
        ret

setVideoMode:
        push bp
        mov bp, sp
        pusha

        mov ah, 0
        mov al, 0x13
        int 10h
        
        call clearScreen

        popa
        pop bp
        ret

restoreTextMode:
        push bp
        mov bp, sp
        pusha
        
        mov ah, 0
        mov al, 0x03
        int 10h

        popa
        pop bp
        ret

clearScreen:
        push bp
        mov bp, sp
        pusha
        
        mov dx, 0x03c8
        mov al, 1
        out dx, al

        mov dx, 0x03c9
        mov al, 47
        out dx, al
        mov al, 50
        out dx, al
        mov al, 42
        out dx, al

        mov ax, 0xA000
        mov es, ax
        xor di, di
        mov al,1
        mov cx, 320*200
        rep stosb

        popa
        pop bp
        ret

; ///////////////////////////////////////////////////////////////////
; // Menu
; //    Basic menu with two buttons
; //        - play  - quit
; //    Esthetics focused 
; ///////////////////////////////////////////////////////////////////
drawMenu:
        push bp
        mov bp, sp
        pusha
        
;       --ColorPallet--
    ;Grey
        mov dx, 0x03c8
        mov al, 7
        out dx, al

        mov dx, 0x03c9
        mov al, 40
        out dx, al
        mov al, 40
        out dx, al
        mov al, 40
        out dx, al

    ;heart
        mov dx, 0x03c8
        mov al, 6
        out dx, al

        mov dx, 0x03c9
        mov al, 44
        out dx, al
        mov al, 3
        out dx, al
        mov al, 15
        out dx, al
        
        
    ;blue
        mov dx, 0x03c8
        mov al, 2
        out dx, al

        mov dx, 0x03c9
        mov al, 3
        out dx, al
        mov al, 9
        out dx, al
        mov al, 20
        out dx, al

    ;cyan
        mov dx, 0x03c8
        mov al, 3
        out dx, al

        mov dx, 0x03c9
        mov al, 7
        out dx, al
        mov al, 32
        out dx, al
        mov al, 35
        out dx, al
    
    ;red
        mov dx, 0x03c8
        mov al, 4
        out dx, al

        mov dx, 0x03c9
        mov al, 62
        out dx, al
        mov al, 18
        out dx, al
        mov al, 17
        out dx, al
        
        call drawButtons
        call drawMenuMaze
        call drawHeroText
        push 0
        call updateMenuSelection

        popa
        pop bp
        ret

;FONT DATA

M:
    db  11000011b
    db  11100111b
    db  11111111b
    db  11011011b
    db  11000011b
    db  11000011b
    db  11000011b
    db  00000000b

A:
    db  00111100b
    db  01100110b
    db  01100110b
    db  01111110b
    db  01100110b
    db  01100110b
    db  01100110b
    db  00000000b

Z:
    db  11111111b
    db  00000110b
    db  00001100b
    db  00011000b
    db  00110000b
    db  01100000b
    db  11111111b
    db  00000000b

E:
    db  11111110b
    db  11000000b
    db  11000000b
    db  11111100b
    db  11000000b
    db  11000000b
    db  11111110b
    db  00000000b
L:
    db  11000000b
    db  11000000b
    db  11000000b
    db  11000000b
    db  11000000b
    db  11000000b
    db  11111110b
    db  00000000b 

V:
    db  11000011b
    db  11000011b
    db  11000011b
    db  11000011b
    db  01100110b
    db  00111100b
    db  00011000b
    db  00000000b


R:
    db  11111100b
    db  11000110b
    db  11000110b
    db  11111100b
    db  11011000b
    db  11001100b
    db  11000110b
    db  00000000b

U:
    db  11000011b
    db  11000011b
    db  11000011b
    db  11000011b
    db  11000011b
    db  11000011b
    db  01111110b
    db  00000000b

N:
    db  11000011b
    db  11100011b
    db  11110011b
    db  11011011b
    db  11001111b
    db  11000111b
    db  11000011b
    db  00000000b

O:
    db  00111100b
    db  01100110b
    db  11000011b
    db  11000011b
    db  11000011b
    db  01100110b
    db  00111100b
    db  00000000b

S:
    db  00111100b
    db  01100110b
    db  01100000b
    db  00111100b
    db  00000110b
    db  01100110b
    db  00111100b
    db  00000000b

C:
    db  00111100b
    db  01100110b
    db  11000000b
    db  11000000b
    db  11000000b
    db  01100110b
    db  00111100b
    db  00000000b

I:
    db  00111100b
    db  00011000b
    db  00011000b
    db  00011000b
    db  00011000b
    db  00011000b
    db  00111100b
    db  00000000b



drawHeroText:
        pusha
        
        mov cx, 116      ; X position
        mov dx, 51       ; Y position
        mov bl, 2      ; Color
        mov si, M
        call drawAlphabet

        add cx, 9
        mov si, A
        call drawAlphabet

        add cx, 9
        mov si, Z
        call drawAlphabet
    
        add cx, 10
        mov si, E
        call drawAlphabet

        add cx, 9
        mov si, R
        call drawAlphabet

        add cx, 9      
        mov si, U
        call drawAlphabet

        add cx, 10     
        mov si, N
        call drawAlphabet

        add cx, 10
        mov si, N
        call    drawAlphabet

        add cx, 9      
        mov si, E
        call drawAlphabet

        add cx, 9
        mov si, R
        call drawAlphabet

        mov cx, 115      ; X position
        mov dx, 50       ; Y position
        mov bl, 4      ; Color
        mov si, M
        call drawAlphabet

        add cx, 9
        mov si, A
        call drawAlphabet

        add cx, 9
        mov si, Z
        call drawAlphabet
    
        add cx, 10
        mov si, E
        call drawAlphabet

        add cx, 9
        mov si, R
        call drawAlphabet

        add cx, 9      
        mov si, U
        call drawAlphabet

        add cx, 10     
        mov si, N
        call drawAlphabet

        add cx, 10     
        mov si, N
        call    drawAlphabet

        add cx, 10     
        mov si, E
        call drawAlphabet

        add cx, 9
        mov si, R
        call drawAlphabet

       
        popa
        ret
 
drawAlphabet:
        pusha
    
        mov di, 8
    row_loop:
        mov al, [si]
        push cx
        mov ah, 8
    
    pixel_loop:
        test al, 10000000b
        jz skip_pixel
    
        push ax
        mov ah, 0Ch
        mov al, bl
        mov bh, 0
        int 10h
        pop ax
    
    skip_pixel:
        inc cx
        shl al, 1
        dec ah
        jnz pixel_loop
    
        pop cx
        inc dx
        inc si
        dec di
        jnz row_loop
        
        popa
        ret

drawTextHorizontal:
        push bp
        mov bp, sp
        pusha

        mov al, 4
        mov di, [bp+4]
        mov cx, 2
    TextHorizontalLoop:
        push cx
        push di
        mov cx, [bp+6]
        rep stosb
        pop di
        pop cx
        add di, 320
        loop TextHorizontalLoop

        popa    
        pop bp
        ret 4

drawTextVertical:
        push bp
        mov bp, sp
        pusha

        mov al, 4
        mov di, [bp+4]
        mov cx, [bp+6]

    TextVerticalLoop:
        push cx
        push di
        mov cx, 2
        rep stosb
        pop di
        pop cx
        add di, 320
        loop TextVerticalLoop

        popa    
        pop bp
        ret 4


currentS:   db  0

    ; @Prams
    ; bp+4 => selection
updateMenuSelection:
        push bp
        mov bp, sp
        pusha
        
        mov al, 4
        mov dx, [currentS]

        cmp dx, [bp+4]
        je exit
        
        mov di, (100*320)+135+5
        cmp word[bp+4], 1
        je quitUnderline
        
        push di
        mov cx, 40
        rep stosb
        
        pop di
        add di, (30*320)
        mov ax, 1
        mov cx, 40
        rep stosb
        jmp exit

    quitUnderline:
        push di
        mov al, 1
        mov cx, 40
        rep stosb
        
        pop di
        mov al, 4
        add di, (30*320)
        mov cx, 40
        rep stosb
        
    exit:
        popa
        pop bp
        ret 2

drawButtons:
        pusha
        mov di, 135+(80*320)
    
    ; button 1
        push 50
        push di
        call drawHorizontalLine

        sub di, 3
        add di, 3*320
        push 20
        push di
        call drawVerticalLine
        push di

        add di, 53
        push 20
        push di
        call drawVerticalLine

        pop di
        add di, (20*320)
        add di, 3
        push 50
        push di
        call drawHorizontalLine

        call drawPlay

    ; button 2
        add di, 7*320
        push 50
        push di
        call drawHorizontalLine

        sub di, 3
        add di, 3*320
        push 20
        push di
        call drawVerticalLine
        push di
    
        add di, 53
        push 20
        push di
        call drawVerticalLine

        pop di
        add di, (20*320)
        add di, 3
        push 50
        push di
        call drawHorizontalLine
        
        call drawQuit

    ;highlights

        
        push di
        mov al, 3
        sub di, 320
        mov cx, 50
        rep stosb
        pop di
        push di
        sub di, 320
        mov cx, 50
        rep stosb
        
        pop di
        sub di, 30*320
        push di
        sub di, 320
        mov cx, 50
        rep stosb
        pop di
        sub di, 320
        mov cx, 50
        rep stosb
        
        popa
        ret


drawMenuMaze:
        pusha

        ;Maze decore
        mov di, (60*320)+90
        
        push 80
        push di
        call drawVerticalLine
        
        push 138
        push di
        call drawHorizontalLine
        
        push di

    ; Right Side
        add di, 138
        push 80
        push di
        call drawVerticalLine

        add di, (80*320)
        sub di, 34
        push 37
        push di
        call drawHorizontalLine
        
        sub di, 6*320
        push 30
        push di
        call drawHorizontalLine

        sub di, (24*320)
        add di, 27
        push 26
        push di
        call drawVerticalLine
        
        sub di, 20
        push 20
        push di
        call drawHorizontalLine
        
        sub di, (10*320)
        push 13
        push di
        call drawVerticalLine

        sub di, (15*320)
        add di, 20
        push 20
        push di
        call drawVerticalLine

        add di, (18*320)
        sub di, 14
        push 17
        push di
        call drawHorizontalLine
        
        sub di, (6*320)
        sub di, 6
        push 17
        push di
        call drawHorizontalLine

        sub di, (6*320)+7
        push 28
        push di
        call drawHorizontalLine

        push 26
        push di
        call drawVerticalLine

        add di, (25*320)
        push 24
        push di
        call drawHorizontalLine

        add di, 9
        push 14
        push di
        call drawVerticalLine
        
        add di, 13
        push 14
        push di
        call drawVerticalLine

        sub di, 13
        add di, (13*320)
        push 16
        push di
        call drawHorizontalLine

        sub di, 9
        push 7
        push di
        call drawHorizontalLine

        sub di, (9*320)
        push 7
        push di
        call drawHorizontalLine
        
        add di, 4
        push 9
        push di
        call drawVerticalLine
        
        sub di, (29*320)
        sub di, (6*320)

        sub di, 4
        push 22
        push di
        call drawHorizontalLine

        add di, 21
        sub di, (13*320)
        push 16
        push di
        call drawVerticalLine

        sub di, 112
        push 112
        push di
        call drawHorizontalLine
        
        sub di, 1
        push 14
        push di
        call drawVerticalLine

        add di, 12*320
        push 24
        push di
        call drawHorizontalLine
        
        pop di
        
    ;Left Side Maze
    
        add di, (80*320)
        push 120
        push di
        call drawHorizontalLine

        sub di, (6*320)
        add di, 6
        push 30
        push di
        call drawHorizontalLine
    
        sub di, (26*320)
        push 26
        push di
        call drawVerticalLine
        
        push 20
        push di
        call drawHorizontalLine

        add di, 20
        sub di, (10*320)
        push 13
        push di
        call drawVerticalLine
        
        sub di, (15*320)
        sub di, 20
        push 20
        push di
        call drawVerticalLine
        
        add di, (18*320)
        push 17
        push di
        call drawHorizontalLine
        
        sub di, (6*320)
        add di, 6
        push 17
        push di
        call drawHorizontalLine

        sub di, (6*320)+6
        push 28
        push di
        call drawHorizontalLine

        add di, 27
        push 26
        push di
        call drawVerticalLine

        add di, (25*320)-22
        push 25
        push di
        call drawHorizontalLine

        push 16
        push di
        call drawVerticalLine
        
        add di, 13
        push 16
        push di
        call drawVerticalLine
        
        sub di, 13
        add di, (14*320)
        push 16
        push di
        call drawHorizontalLine

        add di, 18
        push 7
        push di
        call drawHorizontalLine

        sub di, (9*320)
        push 7
        push di
        call drawHorizontalLine

        push 9
        push di
        call drawVerticalLine

        mov di, (66*320)+96
        push 128
        push di
        call drawHorizontalLine

        push 30
        push di
        call drawVerticalLine

        add di, 125
        push 20
        push di
        call drawVerticalLine

        popa
        ret


drawPlay:
        pusha
        

    ;P
        mov di, (85*320)+143
        push 8
        push di
        call drawTextHorizontal
		
		push 13
		push di
		call drawTextVertical
		 
		add di, 6
		push 5
        push di
        call drawTextVertical
		
        add di, (5*320)
		sub di, 6
		push 8
		push di
		call drawTextHorizontal
		 
	;L
        mov di, (85*320)+152
        push 13
        push di
        call drawTextVertical

        add di, (11*320)
        push 7
        push di
        call drawTextHorizontal

    ;A
        mov di, (85*320)+160
        push 8
        push di
        call drawTextHorizontal

        push 13
        push di
        call drawTextVertical
        
        push di
        add di, (5*320)
        push 8
        push di
        call drawTextHorizontal
        
        pop di
        add di, 6
        push 13
        push di
        call drawTextVertical

    ;Y
        mov di, (85*320)+169
        push 7
        push di
        call drawTextVertical
        
        push di
        add di, (5*320)
        push 7
        push di
        call drawTextHorizontal

        pop di
        add di, 6
        push 7
        push di
        call drawTextVertical
    
        add di, (5*320)-3
        push 8
        push di
        call drawTextVertical
		
        popa
        ret

drawQuit:
        pusha

	;Q
        mov di, (115*320)+144
        push 8
        push di
        call drawTextHorizontal
		
        push 11
        push di
		call drawTextVertical

        add di, 8
        push 11
        push di
		call drawTextVertical
		
    	add di, (11*320)
        sub di, 8
        push 10
        push di
        call drawTextHorizontal
		
        sub di, 320
		add di, 5
        push 4
        push di
		call drawTextVertical
		
    ;U
        mov di, (115* 320)+155
        push 11
        push di
        call drawTextVertical

        add di, (11*320)
        push 8
        push di
        call drawTextHorizontal

        add di, 6
        sub di, (11*320)
        push 11
        push di
        call drawTextVertical

    ;I
        mov di, (115*320)+164
        push 13
        push di
        call drawTextVertical
    ;T
        mov di, (115*320)+167
        push 8
        push di
        call drawTextHorizontal

        add di, 3
        push 13
        push di
        call drawTextVertical

        popa
        ret

    ;@Prams
    ;bp+4 => offset
    ;bp+6 => height
drawVerticalLine:
        push bp
        mov bp, sp
        pusha

        mov al, 2
        mov di, [bp+4]
        mov cx, [bp+6]

    verticallineloop:
        push cx
        push di
        mov cx, 3
        rep stosb
        pop di
        pop cx
        add di, 320
        loop verticallineloop

        popa    
        pop bp
        ret 4
    
        ;@prams
        ; bp+4 => offset
        ; bp+6 => width
drawHorizontalLine:
        push bp
        mov bp, sp
        pusha

        mov al, 2
        mov di, [bp+4]
        mov cx, 3

    horizontallineloop:
        push cx
        push di
        mov cx, [bp+6]
        rep stosb
        pop di
        pop cx
        add di, 320
        loop horizontallineloop

        popa    
        pop bp
        ret 4

drawResetMENU:
        pusha
        popa
        ret

Reset:
        pusha
        call drawResetMENU
        call kbISR_REST_MENU_hook
        popa
        ret

; ///////////////////////////////////////////////////////////////////
; //    Map Structure
; //    Initializing the map in the memory
; //    
; //    Key Features:
; //    - The map generation is procedural rather than static
; //    - Map resets once the Maze is solved
; //    - Gets called once the game is initialized
; ///////////////////////////////////////////////////////////////////
Struct_MAP:

currentMAP:
    db 0
    
MAP1:
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    db 1,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1,0,1
    db 1,1,0,1,0,1,1,1,1,0,1,0,1,0,1,1,0,0,0,1
    db 1,0,0,0,1,0,0,0,1,0,0,0,0,1,0,1,1,1,0,1
    db 1,0,1,0,1,1,0,1,0,1,0,1,1,1,0,0,0,0,1,1
    db 1,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1
    db 1,1,1,1,1,4,1,1,1,0,1,1,0,1,0,1,0,1,1,1
    db 1,0,0,0,1,0,1,0,0,1,0,1,0,0,0,0,1,0,0,1
    db 1,0,1,0,0,0,1,0,0,0,0,0,0,1,0,1,1,0,1,1
    db 1,1,1,0,1,1,1,0,0,1,1,0,1,1,0,1,0,0,0,1
    db 1,0,1,0,0,0,0,3,0,1,0,1,0,0,0,0,1,0,1,1
    db 1,0,1,1,0,1,1,1,0,1,0,0,0,1,1,1,1,1,0,1
    db 1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,1
    db 1,1,0,0,0,0,1,1,1,1,1,1,1,0,1,0,1,0,0,1
    db 1,0,0,1,0,0,1,0,0,0,1,0,0,0,1,1,1,0,0,1
    db 1,0,0,1,3,3,3,1,1,3,1,0,0,1,0,1,0,1,1,1
    db 1,0,0,1,3,3,3,3,3,3,1,1,0,4,0,0,1,0,0,1
    db 1,1,1,1,1,3,3,3,1,0,0,0,4,4,0,0,0,0,1,1
    db 1,0,0,0,0,0,0,0,1,1,1,1,0,4,0,0,0,0,2,1
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1


    _init_MAP:
            pusha
            mov di, (20*320)+30
            mov si, MAP1
            mov cx, 20

    rows:
            push cx           ; Save current row counter
            mov cx, 20         ; Set the column counter to 7

        cols: 
            lodsb             ; Load byte at [si] into AL and increment SI
            cmp al, 4
            je enemyDrawer
            cmp al, 3
            je collectableDrawer
            cmp al, 2
            je playerDrawer
            cmp al, 1         ; Compare AL with 1
            je wall           ; Jump to 'wall' if AL == 1
            jmp floor         ; Otherwise, jump to 'floor'
        
        enemyDrawer:
            mov [enemyPos], di
            push di
            call drawEnemies
            jmp next_pixel

        collectableDrawer:
            mov [collectablePos], di
            push di
            call drawCollectable
            jmp next_pixel

        playerDrawer:
            mov [playerPos], di
            push di
            call drawPlayer
            jmp next_pixel

        wall:
            push di
            call drawTile
            jmp next_pixel

        floor:

        next_pixel:
            add di, 8
            loop cols           ; Decrement CX and loop back if not zero

            add di, 8*320-8*20
            pop cx              ; Restore the row counter
            loop rows           ; Decrement CX and loop back if not zero
            

            popa
            ret

    drawTile:
            push bp
            mov bp, sp
            pusha
    
            mov di, [bp+4]
            mov cx, 8

        wallLoop:
            push cx
            push di

            mov cx, 8 
            mov al, 2
            cld
            rep stosb

            pop di
            pop cx
            add di, 320
            loop wallLoop
            
    
            popa
            pop bp
            ret 2

; ///////////////////////////////////////////////////////////////////
; //    Enemies Structure
; //    Initializing the Enemies on the map
; //
; //    Key Features:
; //    - Moves Randomly on the Maze
; //    - Detects Collision with the walls
; //    - Provides Damage to the Player
; ///////////////////////////////////////////////////////////////////
Struct_ENEMIES:

enemyPos:   dw 0
enemy_SPRITE:
    db 1,1,1,1,1,1,1,1
    db 1,1,0,0,0,0,0,1
    db 1,0,0,0,0,0,0,1
    db 1,0,0,1,0,1,0,1
    db 1,0,0,0,0,0,0,1
    db 1,0,0,1,0,1,0,1
    db 1,0,0,1,0,1,0,1
    db 1,1,1,1,1,1,1,1

    
    clearEnemy:
            push bp
            mov bp, sp
            pusha

            mov di, [bp+4]
            mov cx, 8
        clearEnemyLoop:
            push cx
            push di
            
            mov cx, 8
            mov al ,1
            rep stosb
            
            pop di
            pop cx
            add di, 320
            loop clearEnemyLoop

            popa
            pop bp
            ret 2

    drawEnemies:
            push bp
            mov bp, sp
            pusha
            
            mov di, [bp+4]
            mov si, enemy_SPRITE
            mov cx, 8

    rows_ENEMY:
            push cx
            mov cx, 8

        cols_ENEMY: 
            lodsb
            cmp al, 0
            je fill3
            jmp noFill3

        fill3:
            mov byte[es:di], 4
            jmp next_pixle

        noFill3:

        next_pixle:
            inc di
            loop cols_ENEMY

            add di, 320-8
            pop cx
            loop rows_ENEMY

            popa
            pop bp
            ret 2

; ///////////////////////////////////////////////////////////////////
; //    Player Structure
; //    Initializing the Player on the map
; //
; //    Key Features:
; //    - Player Spawned Randomly on the tile furthest Away
; //    - Collision detection with the walls, Enemies and collectables
; //    - Respondes to the handler incase a collision is detected.
; ///////////////////////////////////////////////////////////////////
Struct_PLAYER:

playerPos: dw 0

player_SPRITE:
    db 1,1,1,1,1,1,1,1
    db 1,1,1,0,0,1,1,1
    db 1,1,0,0,0,0,1,1
    db 1,0,0,0,0,0,0,1
    db 1,0,0,0,0,0,0,1
    db 1,1,0,0,0,0,1,1
    db 1,1,1,0,0,1,1,1
    db 1,1,1,1,1,1,1,1
    
    clearPlayer:
            push bp
            mov bp, sp
            pusha

            mov di, [bp+4]
            mov cx, 8
        clearLoop:
            push cx
            push di
            
            mov cx, 8
            mov al ,1
            rep stosb
            
            pop di
            pop cx
            add di, 320
            loop clearLoop

            popa
            pop bp
            ret 2

        ;@Prams
        ; bp+4 => position
    drawPlayer:
            push bp
            mov bp, sp
            pusha
            
            mov di, [bp+4]
            mov si, player_SPRITE
            mov cx, 8

    rows_PLAYER:
            push cx
            mov cx, 8

        cols_PLAYER: 
            lodsb
            cmp al, 0
            je fill           
            jmp noFill

        fill:
            mov byte[es:di], 5
            jmp next_pixl

        noFill:

        next_pixl:
            inc di
            loop cols_PLAYER

            add di, 320-8
            pop cx
            loop rows_PLAYER

            popa
            pop bp
            ret 2
    
    
    player_UP:
            pusha
            mov di, [playerPos]
            mov si, [playerPos]
            sub si, 320

            cmp byte[es:si], 2
            je wallHitUp
            
            add si, 5
            sub si, 5*320
            
            cmp byte[es:si], 4
            je enemyHitUP

            cmp byte[es:si], 3
            je collectableHitUP
            
            jmp ValidUP

        collectableHitUP:
            call _inc_SCORE
        
        ValidUP:
            sub di, 8*320
            
            push word[playerPos]
            call clearPlayer

            mov word[playerPos], di

            push word[playerPos]
            call drawPlayer
            jmp wallHitUp

        enemyHitUP:
            sub di, 8*320
            push di
            call clearEnemy
            call _dec_LIFE
            cmp word[lives], 0
            je GAMEOVER1
            jmp wallHitUp

        GAMEOVER1:
            call Reset

        wallHitUp:
            popa
            ret

    player_DOWN:
            pusha

            mov di, [playerPos]
            add di, 8*320
            mov si, di
            add si, 2*320

            cmp byte[es:si], 2
            je wallHitDown
            
            add si, 5
            cmp byte[es:si], 4
            je enemyHitDOWN

            cmp byte[es:si], 3
            je collectableHitDown
            
            jmp ValidDOWN
            
        collectableHitDown:
            call _inc_SCORE

        ValidDOWN:
            push word[playerPos]
            call clearPlayer

            mov word[playerPos], di

            push word[playerPos]
            call drawPlayer
            jmp wallHitDown

        enemyHitDOWN:
            push di
            call clearEnemy
            call _dec_LIFE
            cmp word[lives], 0
            je GAMEOVER2
            jmp wallHitUp

        GAMEOVER2:
            call Reset

        wallHitDown:
            popa
            ret

    player_LEFT:
            pusha

            mov di, [playerPos]
            mov si, [playerPos]
            sub si, 1

            cmp byte[es:si], 2
            je wallHitLeft
            
            sub si, 4
            add si, 320
            
            cmp byte[es:si], 4
            je enemyHitLEFT

            cmp byte[es:si], 3
            je collectableHitLeft
            
            jmp ValidLEFT

        collectableHitLeft:
            call _inc_SCORE

        ValidLEFT:
            sub di, 8
            push word[playerPos]
            call clearPlayer

            mov word[playerPos], di

            push word[playerPos]
            call drawPlayer
            jmp wallHitLeft

        enemyHitLEFT:
            sub di, 8
            push di
            call clearEnemy
            call _dec_LIFE
            cmp word[lives], 0
            je GAMEOVER3
            jmp wallHitUp

        GAMEOVER3:
            call Reset

        wallHitLeft:
            popa
            ret

    player_RIGHT:
            pusha

            mov di, [playerPos]
            add di, 8
            mov si, di
            add si, 2

            cmp byte[es:si], 2
            je wallHitRight
            
            add si, 320
            
            cmp byte[es:si], 4
            je enemyHitRIGHT

            cmp byte[es:si], 3
            je collectableHitRight
            
            jmp ValidRIGHT

        collectableHitRight:
            call _inc_SCORE
        
        ValidRIGHT:
            push word[playerPos]
            call clearPlayer

            mov word[playerPos], di

            push word[playerPos]
            call drawPlayer
            jmp wallHitRight

        enemyHitRIGHT:
            push di
            call clearEnemy
            call _dec_LIFE
            cmp word[lives], 0
            je GAMEOVER4
            jmp wallHitUp

        GAMEOVER4:
            call Reset

        wallHitRight:
            popa
            ret

; ///////////////////////////////////////////////////////////////////
; //    Collectables Structure
; //    Initializing Collectables on the map
; //    
; //    Key Features:
; //    - More than one initializations per map
; //    - Each collectable adds to the score of the player
; //    - Remove once collides with player
; ///////////////////////////////////////////////////////////////////
Struct_COLLECTABLES:
    

collectablePos: dw  0

collectable_SPRITE:
    db 1,1,1,1,1,1,1,1
    db 1,1,0,0,0,0,1,1
    db 1,0,0,0,0,0,0,1
    db 0,0,0,0,0,0,0,0
    db 1,0,0,0,0,0,0,1
    db 1,1,0,0,0,0,1,1
    db 1,1,1,0,0,1,1,1
    db 1,1,1,1,1,1,1,1
            
        ; @prams
        ; bp+4 => position
    drawCollectable:
            push bp
            mov bp, sp
            pusha
            
            mov di, [bp+4]
            mov si, collectable_SPRITE
            mov cx, 8

    rows_COLLECT:
            push cx
            mov cx, 8

        cols_COLLECT: 
            lodsb
            cmp al, 0
            je fill1
            jmp noFill1

        fill1:
            mov byte[es:di], 3
            jmp next_pix

        noFill1:

        next_pix:
            inc di
            loop cols_COLLECT

            add di, 320-8
            pop cx
            loop rows_COLLECT

            popa
            pop bp
            ret 2
    
    _init_COLLECTABLES:
            ret

    _check_COLLECTABLES:
            ret

; ///////////////////////////////////////////////////////////////////
; //    Timer Structure    
; //    Handles the Clock, Shown on the screen
; //
; //    Key Features:
; //    - The timer resets on each map
; //    - Timer based scoring in the scoring system
; ///////////////////////////////////////////////////////////////////
Struct_TIMER:
    
    time:   dw  0

    _init_TIMER:
            mov word[time], 0
            ret
            
    ;   Gets called from timer INTERUPT hook
    ;   for increment in the time variable
    ;   every second.
    _inc_TIMER:
            inc word[time]
            ret

    drawTimer:
            

; ///////////////////////////////////////////////////////////////////
; //    Score Structure
; //    Handles the scoring for the MAZE
; //
; //    Key Features:
; //    - The map generation is procedural rather than static
; //    - Map resets once the Maze is solved
; //    - Gets called once the game is initialized
; //    - The player gets -1 after 50 seconds
; ///////////////////////////////////////////////////////////////////
Struct_SCORE:

; 0
ZERO:
    db  00111100b
    db  01100110b
    db  01101110b
    db  01110110b
    db  01100110b
    db  01100110b
    db  00111100b
    db  00000000b

; 1
ONE:
    db  00011000b
    db  00111000b
    db  00011000b
    db  00011000b
    db  00011000b
    db  00011000b
    db  01111110b
    db  00000000b

; 2
TWO:
    db  00111100b
    db  01100110b
    db  00000110b
    db  00001100b
    db  00110000b
    db  01100000b
    db  01111110b
    db  00000000b

; 3
THREE:
    db  00111100b
    db  01100110b
    db  00000110b
    db  00111100b
    db  00000110b
    db  01100110b
    db  00111100b
    db  00000000b

; 4
FOUR:
    db  00001100b
    db  00011100b
    db  00111100b
    db  01101100b
    db  01111110b
    db  00001100b
    db  00001100b
    db  00000000b

; 5
FIVE:
    db  01111110b
    db  01100000b
    db  01111100b
    db  00000110b
    db  00000110b
    db  01100110b
    db  00111100b
    db  00000000b

; 6
SIX:
    db  00111100b
    db  01100000b
    db  01111100b
    db  01100110b
    db  01100110b
    db  01100110b
    db  00111100b
    db  00000000b

; 7
SEVEN:
    db  01111110b
    db  01100110b
    db  00000110b
    db  00001100b
    db  00011000b
    db  00011000b
    db  00011000b
    db  00000000b

; 8
EIGHT:
    db  00111100b
    db  01100110b
    db  01100110b
    db  00111100b
    db  01100110b
    db  01100110b
    db  00111100b
    db  00000000b

; 9
NINE:
    db  00111100b
    db  01100110b
    db  01100110b
    db  00111110b
    db  00000110b
    db  01100110b
    db  00111100b
    db  00000000b

; HEART
HEART:
    db  01100110b
    db  11111111b
    db  11111111b
    db  01111110b
    db  00111100b
    db  00011000b
    db  00010000b
    db  00000000b
    

    score:      dw  0
    lives:      dw  3

    _init_SCORE:
            mov word[score], 0
            ret

    drawLives:
        pusha

        mov si, HEART

        cmp word[lives], 3
        je draw3L
        
        cmp word[lives], 2
        je draw2L

        cmp word[lives], 1
        je draw1L

        cmp word[lives], 0
        je draw0L
        
    draw3L:
        mov cx, 230+9*3
        mov dx, 100
        mov bl, 6
        call drawAlphabet

        sub cx, 9
        call drawAlphabet

        sub cx, 9
        call drawAlphabet
        
        jmp exitDrawL
        
    draw2L:
        mov cx, 230+9*3
        mov dx, 100
        mov bl, 7
        call drawAlphabet

        sub cx, 9
        mov bl, 6
        call drawAlphabet

        sub cx, 9
        call drawAlphabet
        
        jmp exitDrawL

    draw1L:
        mov cx, 230+9*3
        mov dx, 100
        mov bl, 7
        call drawAlphabet

        sub cx, 9
        call drawAlphabet

        sub cx, 9
        mov bl, 6
        call drawAlphabet
        
        jmp exitDrawL

    draw0L:
        mov cx, 230+9*3
        mov dx, 100
        mov bl, 7
        call drawAlphabet

        sub cx, 9
        call drawAlphabet

        sub cx, 9
        call drawAlphabet
        
    exitDrawL:
        popa
        ret
    
    _dec_LIFE:
        dec word[lives]
        call drawLives
        ret

    _inc_life:
        inc word[lives]
        ret
    
    drawLivesText:
            pusha
            
            mov ax, 0xA000
            mov es, ax

            mov cx, 232         ; X position
            mov dx, 90          ; Y position
            mov bl, 4           ; Color
            mov si, L
            call drawAlphabet

            add cx, 7
            mov si, I
            call drawAlphabet

            add cx, 9
            mov si, V
            call drawAlphabet

            add cx, 9
            mov si, E
            call drawAlphabet

            add cx, 8
            mov si, S
            call drawAlphabet

            popa
            ret

    drawScoreText:
            pusha
            
            mov ax, 0xA000
            mov es, ax

            mov cx, 230         ; X position
            mov dx, 50          ; Y position
            mov bl, 4           ; Color
            mov si, S
            call drawAlphabet

            add cx, 9
            mov si, C
            call drawAlphabet

            add cx, 9
            mov si, O
            call drawAlphabet

            add cx, 9
            mov si, R
            call drawAlphabet

            add cx, 9
            mov si, E
            call drawAlphabet

            popa
            ret


            ; @prams 
            ;   bp+4 => Score to Print
    drawScore:
            push bp
            mov bp, sp
            pusha
        
            mov ax, 0xA000
            mov es, ax
            
            mov di, 230+(59*320)
            mov cx, 8
        clearScore:
            push di
            push cx
            
            mov cx, 9*3
            mov al, 1
            rep stosb
            
            pop cx
            pop di
            add di, 320
            loop clearScore

            mov ax, [bp+4]

            mov bx, 10
            xor dx, dx
            div bx
            mov si, ZERO
            shl dx, 3
            add si, dx

            mov cx, 230+3*9
            mov dx, 60
            mov bl, 2
            call drawAlphabet
            
            mov bx, 10
            xor dx, dx
            div bx
            mov si, ZERO
            shl dx, 3
            add si, dx
            mov dx, 60
            sub cx, 9
            mov bl, 2
            call drawAlphabet

            mov bx, 10
            xor dx, dx
            div bx
            shl dx, 3
            mov si, ZERO
            add si, dx
            mov dx, 60
            sub cx, 9
            mov bl, 2
            call drawAlphabet
            
            popa
            pop bp
            ret 2


    _show_SCORE:
            push bp
            mov bp, sp
            pusha
            
            mov cx, [score]
            cmp cx, 0
            jz noSub

            mov ax, [time]
            mov bx, 50
            div bx
            
            cmp cx, ax
            js noSub

            sub cx, ax
            mov [score], cx
            
        noSub:
            push cx
            call drawScore
            
            popa
            pop bp
            ret
    
    _inc_SCORE:
            pusha
            
            add word[score], 10
            push word[score]
            cmp word[lives], 3
            je done1
            
            xor dx, dx
            mov ax, [score]
            mov bx, 30
            div bx
            cmp dx, 0
            je increaseLife
            jmp done1

        increaseLife:
            call _inc_life
            call drawLives

        done1:
            call drawScore
            popa
            ret 

main:   
        call kbISR_MENU_hook
        call setVideoMode
        call drawMenu
    stuck:
        jmp $
