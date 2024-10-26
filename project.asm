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


kbISR_GAME_hook:

kbISR_MENU_hook:

timeISR_hook:
        

; ----** GlobalFunctions **----
;   void drawMenu()
;   int getRand()


; ///////////////////////////////////////////////////////////////////
; // Menu
; //    Basic menu with three buttons
; //        - play  - quit  - about
; //    Esthetics focused 
; ///////////////////////////////////////////////////////////////////
drawMenu:



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

    ; Private
    ;   - Map
    ;   - Player
    ;   - Enemies
    ;   - Collectables

    ;   - Timer
    ;   - Score
    
    __init__:
            call kbISR_GAME_hook
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
            call _check_SCORE
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

    collide_ENEMIES:
        
    _check_collision_ENEMIES:


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
            
    _check_collision_PLAYER:
            ; if collides with enemy
            jmp game_Over
            
            ; if collides with Collectable
            ; pram -> collision with
            call _inc_SCORE

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
