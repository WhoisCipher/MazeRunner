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

upadateToZero:
        push ax
        mov word[MenuSelection], 0
        pop ax
        ret
    ;   Scan-Code
    ;   UP      0x48
    ;   DOWN    0x50
    ;   ENTER   0x1C

kbISR_MENU:
        push bp
        mov bp, sp
        pusha
        
        in al, 0x60
        
        ; UP-Arrow
        cmp al, 0x48
        je up

        ; DOWN-Arrow
        cmp al, 0x50
        je down

        ; ENTER
        cmp al, 1C
        je enter
        jmp EOI

    enter:
        mov word[ENTER_flag], 1
        jmp EOI
        

    up: 
        dec word[MenuSelection]
        cmp word[MenuSelection], -1
        jle _call_to_updateToZero
        jmp update

        
    down:
        inc byte[MenuSelection]
        cmp word[MenuSelection], 1
        jle _call_to_updateToZero
        jmp upadte
        

    _call_to_updateToZero:
        call upadateToZero
    
    update:
        push word[MenuSelection]
        call drawMenu
    
    EOI:
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
        mov word[4*8], kbISR_GAME
        mov word[4*8+2], cs
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
        mov ds, ax
        mov word[4*8], kbISR_MENU
        mov word[4*8+2], cs
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

timeISR1:
check_key:
    mov ah, 0x00            ; AH=0 indicates key code in AL
    int 0x16                ; Read the keypress
    mov ah, 0x00            ; Clear AH

    cmp al, 0x48            ; Check for Up Arrow key scan code (0x48)
    je up_key_pressed

    cmp al, 0x50            ; Check for Down Arrow key scan code (0x50)
    je down_key_pressed

    cmp al, 0x1C            ; Check for Enter key scan code (0x1C)
    je enter_key_pressed

    jmp check_key           ; Loop back if none matched

up_key_pressed:
    mov dx, msg_up          ; Point to "Up Arrow Pressed" message
    mov word[es:0], 77
    jmp check_key           ; Loop back

down_key_pressed:
    mov dx, msg_down        ; Point to "Down Arrow Pressed" message
    mov word[es:0], 79
    jmp check_key           ; Loop back

enter_key_pressed:
    mov dx, msg_enter       ; Point to "Enter Key Pressed" message
    mov word[es:0], 78
    jmp check_key 

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
                je terminate
    
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
;   void    drawMenu()
;   void    clearScreen()
;   void    setVideoMode()
;   void    restoreTextMode()

    ; @prams 
    ;   bp+4 => Random Value to return
getRand:
        push bp
        push ax

        mov ax, [tick]
        mov [bp+4]
        
        pop ax
        pop bp
        ret

setVideoMode:
        push bp
        mov bp, sp
        pusha

        call clearScreen

        mov ah, 0
        mov al, 0x13
        int 10h
        
        mov ax, 0xa000
        mov es, ax
        mov di, 0
        
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
        
        mov ah, 0x06
        mov al, 24
        mov bh, 0x07
        mov cx, 0
        mov dh, 0x24
        mov dl, 0x79
        int 10h

        popa
        pop bp
        ret

; ///////////////////////////////////////////////////////////////////
; // Menu
; //    Basic menu with three buttons
; //        - play  - quit  - about
; //    Esthetics focused 
; ///////////////////////////////////////////////////////////////////
    ; @Prams
    ;   bp+4 => Selected Option
drawMenu:
        push bp
        mov bp, sp
        pusha
    
        mov ax, 0xA000
        mov es, ax
        
        mov ax, [bp+4]
        inc ax
        mov bx, 320
        mul bx
        mov di, ax
        mov cx, length                      ; Number of pixels
        mov al, color                       ; Color to draw
        rep stosb

        popa
        pop bp
        ret 2

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
        call setVideoMode
        call kbISR_MENU_hook
        call timerISR_hook
        
    startGame:
        cmp byte[game_running], 0
        je startGame
        
        call __init__

    terminate:
        mov ax, 4c00h
        int 21h
