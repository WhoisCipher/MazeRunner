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
MenuSelection:  dw  0
ENTER_flag:     dw  0

    ;   Scan-Code
    ;   UP      0x48
    ;   DOWN    0x50
    ;   ENTER   0x1C
kbISR_MENU:
        push bp
        mov bp, sp
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
        je enter1

        jmp eoi

    enter1:
        mov word[ENTER_flag], 1
        jmp eoi

    up: 
        push 1
        call updateMenuSelection
        jmp eoi

        
    down:
        push 0
        call updateMenuSelection

    eoi:
        mov al, 0x20
        out 0x20, al
        
        popa
        pop bp
        iret

kbISR_GAME:

kbISR_GAME_hook:
        push bp
        mov bp, sp
        pusha

        cli
        xor ax, ax
        mov ds, ax
        mov word[ds:4*9], kbISR_GAME
        mov word[ds:4*9+2], cs
        sti

        popa
        pop bp
        ret

kbISR_MENU_hook:
        push bp
        mov bp, sp
        pusha
        
        cli
        xor ax, ax
        mov es, ax
        mov word[es:4*9], kbISR_MENU
        mov [es:4*9+2], cs
        sti

        popa
        pop bp
        ret


; ////////////////////////////////////////////
; // Timer Intrupt
; // 
; // Used to make the timer Work, Each time
; // the IRQ-0 sets, the tick variable gets
; // increased and 18 ticks approx to 1 sec
; ////////////////////////////////////////////
tick:           db  0
game_running:   dw  0

timerISR:
        push bp
        mov bp, sp
        pusha
        
        cmp byte[game_running], 1
        je _inc_TICK

                cmp word[ENTER_flag], 1
                je enterPressed
                jmp _inc_TICK

            enterPressed:
                cmp word[MenuSelection], 0
                je start

                cmp word[MenuSelection], 1

            start:    
                call kbISR_GAME_hook
                mov byte[game_running], 1
                mov word[ENTER_flag], 0

    _inc_TICK:
        inc byte[tick]
        
        mov al, [tick]
        cmp al, 18
        jl done
        
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
        mov ds, ax
        mov word[4*8], timerISR
        mov [4*8+2], cs
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


; ///////////////////////////////////////////////////////////////////
; // Game Handler
; //    Initializes the Game in memory
; //    Handles GameState
; //    
; //    Key Feature:
; //    - Initializes Map
; //    - Initializes Player/Enemies
; //    - Initializes Timer
; //    - Initializes Scoring
; // 
; //    - All the game components communicate with the handler
; //    - Handler updates GameState based on the communication
; //    
; //    Game Logic:
; //    - Avoid enemies
; //    - Gain maximum collectables for higher score
; //    - Once you reach the end of the Maze:
; //            - Score is shown
; //            - The next level loads on key-stroke
; //    - If hit by the enemy: 
; //            - Game Over message shown
; //            - Same map reloads
; ///////////////////////////////////////////////////////////////////
Struct_GAMEHANDLER:

    ; Handles:
    ;   - Map
    ;   - Player
    ;   - Enemies
    ;   - Collectables

    ;   - Timer
    ;   - Score
    
    __init__:
            call _init_MAP
    reset_same_MAP:
            call _init_PLAYER
            call _init_ENEMIES
            call _init_COLLECTABLES
            call _init_TIMER
            call _init_SCORE
    
    gameLoop:
            call _check_collision_PLAYER
            call _check_collision_ENEMIES
            call _check_COLLECTABLES
            jmp gameLoop
    
    game_Over:
            call _show_SCORE
            jmp reset_same_MAP

    level_UP:
            call _show_SCORE
            jmp __init__

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
    
    _init_MAP:
            ret


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
    
    _init_ENEMIES:
            ret

    collide_ENEMIES:
            ret

    _check_collision_ENEMIES:
            ret

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

    _init_PLAYER:
            ret

    _check_collision_PLAYER:
            ; if collides with enemy
            jmp game_Over
            
            ; if collides with Collectable
            ; pram -> collision with
            call _inc_SCORE

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
    
    score:  dw  0
    
    _init_SCORE:
            mov word[score], 0
            ret

            ; @prams 
            ;   bp+4 => Score to Print
    drawScore:
            push bp
            mov bp, sp

            push ax
            push bx
            push si
            push di

            
            pop di
            pop si
            pop bx
            pop ax
            
            pop bp
            ret 2
    
    _show_SCORE:
            push bp
            mov bp, sp

            push ax
            push bx
            push cx
            push dx
            
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
            
            pop dx
            pop cx
            pop bx
            pop ax
            
            pop bp
            ret
    
        ; @prams
        ;   bp+4 => Collectables Score sent
    _inc_SCORE:
            push bp
            mov bp, sp
            push ax

            mov ax, [bp+4]
            add [score], ax
            
            pop ax
            pop bp
            ret 2

main:   
        call kbISR_MENU_hook
        call setVideoMode
        call drawMenu
    
        jmp $
