PRINT_STRING MACRO params
                 push ax
                 mov  ah,09h
                 mov  dx,offset params
                 int  21h
                 pop  ax
ENDM

.model small

.data
    screen_hight             dw 200
    screen_width             dw 320
    color                    db 0fh                                               ;white
    ground_color             db 06h                                               ;brown
    charactor_init           dw 38420d                                            ;320*120+40,charactor(40*20)
    charactor_color          db 04h
    charactor_position       dw 38420d
    charactor_last_position  dw ?
    exit                     db 0h
    score                    dw 0h
    highest_score            dw 0h
    mesg_1                   db 'ESC to exit,Space jump and start',0ah,0Dh,'$'
    mesg_2                   db 0ah,0dh,'press Space to restart the game','$'
    end_game_over            db 01h
    
    ;lower left corner  element0(the beging of last line minus 1),element1(the beging of last line plus a line(320)),
    ;lower right corner element2(the last position plus 1),element3(the last postion plus a line(320))
    
    test_point               dw 4 dup(0)
    ;lower_left_next dw 0000h
    ;lower_left_down dw 0000h
    ;lower_right_next dw 0000h
    ;lower_right_down dw 0000h
    confilct                 db 0h

    ;obstacle position
    obstacle_position        dw 41905d
    obstacle_position_1      dw 41905d
    obstacle_position_2      dw 41905d
    obstacle_color           db 00h                                               ;black
    call_OBSTACLE_MOVE_times dw 0
    random_system_time       dw 0
    obstacle_switch          db 1                                                 ;obstacle_switch_1~3 是亂數產生物體的開關 0代表螢幕沒有顯示該物體
    obstacle_switch_1        db 0
    obstacle_switch_2        db 0
.stack 100h

.code
    main:     
              mov          ax,@data
              mov          ds,ax
              call         INIT_BACKGROUND
    ;call         OBSTACLE
    ;call         OBSTACLE_1
    GAME_LOOP:
.if end_game_over == 01h
                
              call         PLAYER_SCORE
              PRINT_STRING mesg_2
              mov          dx,0000h
              mov          score,dx
              call         RESTART
              call         INIT_BACKGROUND
              cmp          exit,01h
              jz           exit_program
.endif
                            call         OBSTACLE_MOVE
                            push         cx
                            mov          cx,03ffh                   ;control obstacle speed
    loop_1:                 
                            call         SPACE_ESC
                            loop         loop_1
                            pop          cx

                            cmp          exit,01h
                            jnz          GAME_LOOP
    exit_program:           
                            call         INIT_SCREEN

                            mov          ax,4c00h
                            int          21h

    ;set the vedio segment 0a000h and go into mode 13h
INIT_BACKGROUND proc
                            push         ax
                            mov          ax,0a000h
                            mov          es,ax
                            mov          ax,0013h
                            int          10h
                            call         WRITE_SCREEN_BACKGROUND
                            call         WRITE_CHARACTOR
                            PRINT_STRING mesg_1
                            pop          ax
                            ret
INIT_BACKGROUND endp
    ;write the backgroud and the ground
WRITE_SCREEN_BACKGROUND PROC
                            push         ax
                            push         di
                            xor          di,di
                            mov          ah,color
    WRITE_BACKGROUND_LOOP:                                          ;background 0~320*200
                            mov          es:[di],ah
                            inc          di
                            cmp          di,320d*200d
                            jnz          WRITE_BACKGROUND_LOOP
                            xor          di,di
                            mov          di,320d*160d
                            mov          ah,ground_color
    WRITE_GROUND_LOOP:                                              ;ground 320*160~320*200
                            mov          es:[di],ah
                            inc          di
                            cmp          di,320d*200d
                            jnz          WRITE_GROUND_LOOP
                            pop          di
                            pop          ax
                            ret
WRITE_SCREEN_BACKGROUND ENDP

    ;畫角色
WRITE_CHARACTOR proc
                            call         OBSTACLE_MOVE
                            push         ax
                            push         di
                            push         cx
                            push         dx
                            xor          dx,dx
                            xor          cx,cx
                            xor          di,di
                            mov          di,charactor_position
                            mov          ah,charactor_color
    CHARACTOR_LOOP:         
                            mov          es:[di],ah
                            inc          di
                            inc          cx
.if cx < 20d
                            jmp          CHARACTOR_LOOP
.endif
          xor cx,cx
          add di,300d
          inc dx
.if dx < 40d
          jmp CHARACTOR_LOOP
.endif
                       pop  dx
                       pop  cx
                       pop  di
                       pop  ax
                       ret
WRITE_CHARACTOR endp
    ;清除舊的角色
WRITE_CHARACTOR_CL proc
                       call OBSTACLE_MOVE
                       push ax
                       push di
                       push cx
                       push dx
                       xor  dx,dx
                       xor  cx,cx
                       xor  di,di
                       mov  di,charactor_position
                       mov  ah,color
    CHARACTOR_LOOP_CL: 

                       mov  es:[di],ah
                       inc  di
                       inc  cx
.if cx < 20d
                       jmp  CHARACTOR_LOOP_CL
.endif
          xor cx,cx
          add di,300d
          inc dx
.if dx < 40d
          jmp CHARACTOR_LOOP_CL
.endif
                       mov  charactor_last_position,di
                       pop  dx
                       pop  cx
                       pop  di
                       pop  ax
                       ret
WRITE_CHARACTOR_CL endp
    ;是否有跳躍或離開
SPACE_ESC proc
    ;call OBSTACLE
    ;call OBSTACLE_MOVE
                       push ax
    ;push ax
                       mov  ah,01h
                       int  16h

                       jz   continue
                       
                       
                       mov  ah,10h
                       int  16h

              
    continue:          
.if al==1bh
                       mov  exit,01h
.elseif al==20h
                       call CHARACTOR_JUMP
.endif
                   mov  ax,0c00h                 ;clear keyboard buffer
                   int  21h
    ;pop  ax
                   pop  ax
                   ret
SPACE_ESC endp

    ;from 320*160 to 320*40
CHARACTOR_JUMP proc
                   push ax
                   push di
    ;mov ax,0013h
    ;int 10h
                   mov  bx,1280d                 ;4 lines
    JUMP_LOOP_UP:  
                   call WRITE_CHARACTOR_CL
                   sub  charactor_position,bx
                   call WRITE_CHARACTOR
                   call KEEP_TEST_POINT
                   call TEST_CONFLICT
.if confilct == 01h
                   call RESTART
.endif

                   cmp  charactor_position,(320d*40d)+20
                   call DELAY
    
                   jnz  JUMP_LOOP_UP

    JUMP_LOOP_DOWN:
                   call WRITE_CHARACTOR_CL
                   add  charactor_position,bx
                   call WRITE_CHARACTOR
                   call KEEP_TEST_POINT
                   call TEST_CONFLICT
.if confilct == 01h
                   call RESTART
.endif
                   cmp  charactor_position,38420d
                   call DELAY
    
                   jnz  JUMP_LOOP_DOWN
                   pop  di
                   pop  ax
                   ret
CHARACTOR_JUMP endp
    ;DELAY cx:dx microsecond
DELAY PROC
                   push ax
                   push dx
                   push cx
                   mov  ax,8600h
                   mov  cx,0000h
                   mov  dx,04000h
                   int  15h
                   pop  cx
                   pop  dx
                   pop  ax
                   ret
DELAY ENDP

INIT_SCREEN proc
                   push ax
                   mov  ax,03h
                   int  10h
                   pop  ax
                   ret
INIT_SCREEN endp

RESTART proc
                   push ax
                   mov  ah,00h
                   int  16h
.if al == 20h
                   mov  end_game_over,00h
.elseif al == 1bh
                   mov  exit,01h
.endif
                   pop  ax
                   ret
RESTART endp

ASCII_OUTPUT proc
                   push ax
                   push dx
                   mov  ah,02h
                   mov  dl,'H'
                   int  21h
                   mov  dl,'I'
                   int  21h
                   mov  dl,':'
                   int  21h
                   mov  dx,score
                   mov  cx,04h
    score_hex_loop:
                   push cx
                   mov  cl,04h
                   rol  dx,cl
                   pop  cx
                   push dx
                   and  dl,0fh
.if dl > 09h
                   add  dl,'7'
.else
         add dl,'0'
.endif
                     int  21h
                     pop  dx
                     loop score_hex_loop
                     mov  dl,' '
                     int  21h
                     mov  dx,highest_score
                     mov  cx,04h
    h_score_hex_loop:
                     push cx
                     mov  cl,04h
                     rol  dx,cl
                     pop  cx
                     push dx
                     and  dl,0fh
.if dl > 09h
                     add  dl,'7'
.else
         add dl,'0'
.endif
                    int  21h
                    pop  dx
                    loop h_score_hex_loop
                    pop  dx
                    pop  ax
                    ret
ASCII_OUTPUT endp

KEEP_TEST_POINT proc
                    push dx
                    push bx
                    mov  dx,charactor_last_position
                    mov  test_point[0],dx
                    sub  test_point[0],21d
                    mov  test_point[2],dx
                    add  test_point[2],320d
                    mov  test_point[4],dx
                    add  test_point[4],1d
                    mov  test_point[6],dx
                    add  test_point[6],320d
                    pop  bx
                    pop  dx
                    ret
KEEP_TEST_POINT endp

TEST_CONFLICT proc
                    push ax
                    push di
                    push cx
                    mov  cx,4d
                    mov  di,test_point[0]
                    mov  al,obstacle_color
    test_loop:      
.if es:[di] == al
                    mov  exit,01h
                    jmp  exit_test
.endif
                   add  di,2d
                   loop test_loop
    exit_test:     
                   pop  cx
                   pop  di
                   pop  ax
                   ret
TEST_CONFLICT endp

OBSTACLE proc
                   push ax
                   push bx
                   push cx
                   push dx
                   xor  di,di
                   xor  dx,dx
                   mov  di,obstacle_position
                   mov  cx,450                  ;450=15d*30d
                   mov  ah,obstacle_color

    write_obstacle:
                   inc  dl
                   mov  es:[di],ah
                   inc  di
.if dl==15d
                   add  di,320d
                   sub  di,15d
                   xor  dl,dl
.endif
                     loop write_obstacle
                     pop  ax
                     pop  bx
                     pop  cx
                     pop  dx
                     ret
OBSTACLE endp

OBSTACLE_1 proc
                     push ax
                     push bx
                     push cx
                     push dx
                     xor  di,di
                     xor  dx,dx
                     mov  di,obstacle_position_1
                     mov  cx,450                    ;450=15d*30d
                     mov  ah,obstacle_color

    write_obstacle_1:
                     inc  dl
                     mov  es:[di],ah
                     inc  di
.if dl==15d
                     add  di,320d
                     sub  di,15d
                     xor  dl,dl
.endif
                     loop write_obstacle_1
                     pop  ax
                     pop  bx
                     pop  cx
                     pop  dx
                     ret
OBSTACLE_1 endp

OBSTACLE_2 proc
                     push ax
                     push bx
                     push cx
                     push dx
                     xor  di,di
                     xor  dx,dx
                     mov  di,obstacle_position_2
                     mov  cx,450                    ;450=15d*30d
                     mov  ah,obstacle_color

    write_obstacle_2:
                     inc  dl
                     mov  es:[di],ah
                     inc  di
.if dl==15d
                     add  di,320d
                     sub  di,15d
                     xor  dl,dl
.endif
                  loop write_obstacle_2
                  pop  ax
                  pop  bx
                  pop  cx
                  pop  dx
                  ret
OBSTACLE_2 endp

OBSTACLE_MOVE proc
                  call RANDOM_OBSTACLE_GENERATE
                  push ax
                  push dx
    ;inc  call_OBSTACLE_MOVE_times
                  

                  

.if obstacle_switch==1
                  mov  obstacle_color,0fh
                  call OBSTACLE                    ;clear OBSTACLE
                  sub  obstacle_position,1         ;1 is obstacle move distance
                  mov  obstacle_color,00h
                  call OBSTACLE                    ;畫出障礙物移動過後
.endif
          mov  dx,obstacle_position
.if dx==41600d
          mov  obstacle_switch,0
          mov  obstacle_color,0fh
          call OBSTACLE                    ;clear OBSTACLE
          mov  obstacle_position,41905d
          mov  obstacle_color,00h
.endif

.if obstacle_switch_1==1
          mov  obstacle_color,0fh
          call OBSTACLE_1               ;clear OBSTACLE
          sub  obstacle_position_1,1    ;1 is obstacle move distance
          mov  obstacle_color,00h
          call OBSTACLE_1               ;畫出障礙物移動過後
.endif
          mov  dx,obstacle_position_1
.if dx==41600d
          mov  obstacle_switch_1,0
          mov  obstacle_color,0fh
          call OBSTACLE_1                    ;clear OBSTACLE
          mov  obstacle_position_1,41905d
          mov  obstacle_color,00h
.endif

.if obstacle_switch_2==1
          mov  obstacle_color,0fh
          call OBSTACLE_2               ;clear OBSTACLE
          sub  obstacle_position_2,1    ;1 is obstacle move distance
          mov  obstacle_color,00h
          call OBSTACLE_2               ;畫出障礙物移動過後
.endif
          mov  dx,obstacle_position_2
.if dx==41600d
          mov  obstacle_switch_2,0
          mov  obstacle_color,0fh
          call OBSTACLE_2                    ;clear OBSTACLE
          mov  obstacle_position_2,41905d
          mov  obstacle_color,00h
.endif
                             pop  dx
                             pop  ax
                             ret
OBSTACLE_MOVE endp









RANDOM_OBSTACLE_GENERATE proc
                             push ax
                             push bx
                             push dx
                             xor  dx,dx
                             mov  ah,2ch
                             int  21h
                             xor  dh,dh
                             mov  random_system_time,dx
                             add  random_system_time,90     ;使亂數在40~139間
.if obstacle_switch==0
                             mov  bx,obstacle_position
                             sub  bx,obstacle_position_2
                             cmp  bx,random_system_time
                             jb   L1
                             mov  obstacle_switch,1
    L1:                      
                             xor  bx,bx

.elseif obstacle_switch_1==0
                             mov  bx,obstacle_position_1
                             sub  bx,obstacle_position
                             cmp  bx,random_system_time
                             jb   L2
                             mov  obstacle_switch_1,1
    L2:                      
                             xor  bx,bx

.elseif obstacle_switch_2==0
                             mov  bx,obstacle_position_2
                             sub  bx,obstacle_position_1
                             cmp  bx,random_system_time
                             jb   L3
                             mov  obstacle_switch_2,1
    L3:                      
.endif
                             
                             pop  ax
                             pop  bx
                             pop  dx
                             ret
RANDOM_OBSTACLE_GENERATE endp









PLAYER_SCORE proc
                             push ax
                             push dx
                             mov  dx,score
.if dx >= highest_score
                             mov  highest_score,dx
.endif
                 call ASCII_OUTPUT
                 pop  dx
                 pop  ax
                 ret
PLAYER_SCORE endp

end main