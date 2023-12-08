PRINT_STRING MACRO params
                 push ax
                 mov  ah,09h
                 mov  dx,offset params
                 int  21h
                 pop  ax
ENDM

PrintStr macro string                ;輸出字串
             mov ah,09h
             mov dx,offset string
             int 21h
endm

SetCursor macro row,col        ;設定游標位置
              mov dh,row
              mov dl,col
              mov bx,00h
              mov ah,02h
              int 10h
endm

printstr13h macro str,atr,len,row,col,cursor_move        ;繪圖模式輸出字串
                mov ax,ds
                mov es,ax
                mov bp,offset str
                mov ah,13h
                mov al,cursor_move
                mov bh,00
                mov bl,atr
                mov cx,len
                mov dh,row
                mov dl,col
                int 10h
endm

.model small

.data
    screen_hight            dw 200
    screen_width            dw 320
    color                   db 0fh                                                                                                                                                                                                        ;white
    ground_color            db 06h                                                                                                                                                                                                        ;brown
    charactor_init          dw 38440d                                                                                                                                                                                                     ;320*120+40,charactor(40*20)
    charactor_color         db 04h
    charactor_position      dw 38440d
    charactor_last_position dw 50940d
    exit_                   db 0h
    score                   dw 0h
    highest_score           dw 0h
    mesg_1                  db 'ESC to exit,Space jump and start',0ah,0Dh,'$'
    mesg_2                  db 0ah,0dh,'press Space to restart the game','$'
    mesg_3                  db 'HI=','$'
    end_game_over           db 01h
        
    ;obstacle position
    obstacle_init           dw 41899d                                                                                                                                                                                                     ;320*130+300 起始點
    obstacle_position       dw 41899d,41899d,41899d
    obstacle_color          db 00h                                                                                                                                                                                                        ;black
    obstacle_number         dw 3d
    obstacle_position_index dw 0d                                                                                                                                                                                                         ;用來判斷障礙物前後距離
    x_num                   db "N:",3 dup(' '),'$'
    y_num                   db "H:",3 dup(' '),'$'
    score_now               dw 0
    score_high              dw 0
    call_score_output_time  db 0
    write_tree_part1        dw 0,1,2,3,4,5,6,7,8,9,11,12,13,14,15,16,17,18,19,320,321,322,323,324,325,326,327,328,332,333,334,335,336                                                                                                     ;33組
    write_tree_part2        dw 337,338,339,640,641,642,643,644,645,646,647,653,654,655,656,657,658,659,960,961,962,963,964,965,966,974,975,976,977,978,979,1280,1281                                                                      ;33組
    write_tree_part3        dw 1282,1283,1284,1285,1295,1296,1297,1298,1299,1600,1601,1602,1603,1604,1616,1617,1618,1619,1920,1921,1922,1923,1937,1938,1939,2240,2241,2242,2243,2257,2258,2259,2560,2561,2562,2578,2579,2880,2881,2899    ;33
    write_tree_part4        dw 3520,3521,3522,3523,3524,3525,3526,3527,3528,3529,3531,3532,3533,3534,3535,3536,3537,3538,3539,3840,3841,3842,3843,3844,3845,3846,3847,3848,3852,3853,3854,3855,3856                                       ;37
    write_tree_part5        dw 3857,3858,3859,4160,4161,4162,4163,4164,4165,4166,4167,4173,4174,4175,4176,4177,4178,4179,4480,4481,4482,4483,4484,4485,4486,4494,4495,4496,4497,4498,4499,4800,4801                                       ;37
    write_tree_part6        dw 4802,4803,4804,4805,4815,4816,4817,4818,4819,5120,5121,5122,5123,5124,5136,5137,5138,5139,5440,5441,5442,5443,5457,5458,5459,5760,5761,5762,5763,5777,5778,5779,6080,6081,6082,6098,6099,6400,6401,6419    ;35
    write_tree_part7        dw 6720,6721,6722,6723,6724,6735,6736,6737,6738,6739,7040,7041,7042,7043,7044,7055,7056,7057,7058,7059,7360,7361,7362,7363,7364,7375,7376,7377,7378,7379,7680,7681,7682,7683,7684,7695,7696,7697,7698,7699
    write_tree_part8        dw 8000,8001,8002,8003,8004,8015,8016,8017,8018,8019,8320,8321,8322,8323,8324,8335,8336,8337,8338,8339,8640,8641,8642,8643,8644,8655,8656,8657,8658,8659,8960,8961,8962,8963,8964,8975,8976,8977,8978,8979
    write_tree_part9        dw 9280,9281,9282,9283,9284,9295,9296,9297,9298,9299,9600,9601,9602,9603,9604,9615,9616,9617,9618,9619
.stack 100h


.code
    ;   ASCII_OUTPUT proto near c,arg:word
              OBSTACLE     proto near c,arg:byte


    main:     
              mov          ax,@data
              mov          ds,ax
              call         INIT_BACKGROUND
              call         score_output
    GAME_LOOP:
.if end_game_over == 01h
              PRINT_STRING mesg_2
              mov          dx,0000h
              mov          score,dx
              call         RESTART
              call         INIT_BACKGROUND
              cmp          exit_,01h
              jz           exit_program
.endif
          call   score_output
          call   RANDOM_OBSTACLE_GENERATE
          invoke OBSTACLE,obstacle_color
          mov    di,charactor_last_position
          mov    ah,obstacle_color
.if es:[di] == ah
          mov    end_game_over,01h
          jmp    GAME_LOOP
.endif
                            xor          di,di
                            xor          ah,ah


                            call         OBSTACLE_MOVE              ;這只是設定一次位移幾個,沒call的話障礙物會靜止不動，這還要搭配
                            call         DELAY
                            call         SPACE_ESC

                            cmp          exit_,01h
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
                            push         ax
                            push         di
                            push         cx
                            push         dx
                            xor          dx,dx
                            xor          cx,cx
                            xor          di,di
                            mov          di,charactor_position
                            mov          ah,charactor_color
                            mov          al,obstacle_color
    CHARACTOR_LOOP:         
.if es:[di] == al
                            mov          end_game_over,01h
.endif
          mov es:[di],ah
          inc di
          inc cx
.if cx < 20d
          jmp CHARACTOR_LOOP
.endif
                       xor  cx,cx
                       add  di,300d
                       inc  dx
                       cmp  dx,40d
                       jnz  CHARACTOR_LOOP
                       sub  di,300d
                       mov  charactor_last_position,di
                       pop  dx
                       pop  cx
                       pop  di
                       pop  ax
                       ret
WRITE_CHARACTOR endp
    ;清除舊的角色
WRITE_CHARACTOR_CL proc
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
                       pop  dx
                       pop  cx
                       pop  di
                       pop  ax
                       ret
WRITE_CHARACTOR_CL endp
    ;是否有跳躍或離開
SPACE_ESC proc
                       push ax
                       mov  ah,01h            ;掃描但不等待
                       int  16h
.if al==1bh
                       mov  exit_,01h
.elseif al==20h
                       call CHARACTOR_JUMP
.endif
                   mov  ax,0c00h                    ;clear keyboard buffer
                   int  21h
                   pop  ax
                   ret
SPACE_ESC endp

    ;from 320*160 to 320*40
CHARACTOR_JUMP proc
                   push ax
                   push di
                   mov  bx,1280d                    ;4 lines
    JUMP_LOOP_UP:  
                   call RANDOM_OBSTACLE_GENERATE
                   call WRITE_CHARACTOR_CL
                   call OBSTACLE_MOVE
                   inc  call_score_output_time
                   cmp  call_score_output_time,5    ;決定分數加的快慢
                   jne  ignore_1
                   mov  call_score_output_time,0
                   inc  score_now                   ;計分數
    ignore_1:      
                   sub  charactor_position,bx
                   call WRITE_CHARACTOR
.if end_game_over == 01h
                   jmp  exit_jump
.endif
    
                   cmp  charactor_position,(320d*40d)+40
                   call DELAY
                   jnz  JUMP_LOOP_UP

    JUMP_LOOP_DOWN:
                   call RANDOM_OBSTACLE_GENERATE
                   call WRITE_CHARACTOR_CL
                   call OBSTACLE_MOVE
                   inc  call_score_output_time
                   cmp  call_score_output_time,5            ;決定分數加的快慢
                   jne  ignore_2
                   mov  call_score_output_time,0
                   inc  score_now                           ;計分數
    ignore_2:      
                   add  charactor_position,bx
                   call WRITE_CHARACTOR
.if end_game_over == 01h
                   jmp  exit_jump
.endif
                   cmp  charactor_position,38440d
                   call DELAY
    ;call RANDOM_OBSTACLE_GENERATE
                   jnz  JUMP_LOOP_DOWN
    exit_jump:     
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
                   mov  score_now,0
                   push ax
                   mov  charactor_position,38440d
                   mov  obstacle_position[0],0d
                   mov  obstacle_position[2],0d
                   mov  obstacle_position[4],0d
                   mov  obstacle_number,0d
                   mov  obstacle_position_index,0d
                   mov  ah,00h
                   int  16h
.if al == 20h
                   mov  end_game_over,00h
.elseif al == 1bh
                   mov  exit_,01h
.endif
             mov  ax,0c00h          ;clear keyboard buffer
             int  21h
             pop  ax
             ret
RESTART endp

OBSTACLE proc near c,color_arg:byte
             push ax
             push cx
             push dx
             push di
.if obstacle_number == 0
             jmp  leave_obstacle
.endif
                        mov  cx,obstacle_number
                        mov  si,0
    obstacle_loop:      
                        push cx
                        mov  cx,0d
                        mov  dx,0d
                        mov  di,obstacle_position[si]
                        mov  ah,color_arg
    write_obstacle_loop:
                        mov  es:[di],ah
                        inc  di
                        inc  cx
.if cx < 20d
                        jmp  write_obstacle_loop
.endif
          xor cx,cx
          add di,300d
          inc dx
.if dx < 30d
          jmp write_obstacle_loop
.endif
                   call   write_tree
                   add    si,2h
                   pop    cx
                   loop   obstacle_loop
    leave_obstacle:
                   pop    di
                   pop    dx
                   pop    cx
                   pop    ax
                   ret
OBSTACLE endp

    ;移動所有障礙物每次4d
OBSTACLE_MOVE proc
                   push   ax
                   push   cx
                   push   dx
                   push   si
                   mov    cx,obstacle_number
                   mov    si,0d
                   cmp    cx,0
                   jz     leave_move
                   invoke OBSTACLE,color
.if word ptr [obstacle_position] != 0000h
                   sub    word ptr [obstacle_position],4d
.endif
.if word ptr [obstacle_position+2] != 0000h
          sub word ptr [obstacle_position+2],4d
.endif
.if word ptr [obstacle_position+4] != 0000h
          sub word ptr [obstacle_position+4],4d
.endif
                           call   OBSTACLE_BOUNDARY
                           invoke OBSTACLE,obstacle_color
    leave_move:            
                           pop    si
                           pop    dx
                           pop    ax
                           pop    ax
                           ret
OBSTACLE_MOVE endp
    ;清除碰到邊界的障礙物
CLAER_OBSTACLE proc
                           push   ax
                           push   dx
                           push   di
                           mov    di,obstacle_position[0]
                           mov    ah,color
    write_obstacle_loop_cl:
                           mov    es:[di],ah
                           inc    di
                           inc    cx
.if cx < 20d
                           jmp    write_obstacle_loop_cl
.endif
          xor cx,cx
          add di,300d
          inc dx
.if dx < 30d
          jmp write_obstacle_loop_cl
.endif
                             mov  obstacle_position[0],0d
                             call SHIFT_OBSTACLE
                             dec  word ptr [obstacle_number]
                             sub  word ptr [obstacle_position_index],2d
                             pop  di
                             pop  dx
                             pop  ax
                             ret
CLAER_OBSTACLE endp


    ;未成功
    ;用ivrine16的函式產生亂數，當亂數除41等於0時且障礙物數量(obstacle_number)不等於三時，再新增一個障礙物
RANDOM_OBSTACLE_GENERATE proc
                             push ax
                             push dx
                             push bx
                             push si
                             xor  bx,bx
.if obstacle_number == 3                                                   ;如果目前障礙物數量有三個就不用再產生障礙物
                             jmp  leave_generate
.endif
          mov ah,2ch
          int 21h                           ;CH:CL hour/min,DH:DL second:1/100second
          xor dh,dh
          add dx,70                         ;70~179
          mov si,obstacle_position_index
.if obstacle_number != 0
          mov bx,obstacle_position[si+2]
          sub bx,obstacle_position[si]
.else
         mov bx,obstacle_position[si+2]
         sub bx,obstacle_position[si]
.endif

    ;xor bx,000000000010011b

.if (dx > 130 && dx < 150 && bx > 70)|| obstacle_number==0

          mov bx,obstacle_init
          mov obstacle_position[si],bx
          inc word ptr [obstacle_number]
          add word ptr [obstacle_position_index],2d    ;每產生一個物體obstacle_position_index要多一組出來
.endif
    leave_generate:          
                             pop  si
                             pop  bx
                             pop  dx
                             pop  ax
                             ret
RANDOM_OBSTACLE_GENERATE endp
    ;將obstacle_position前移一元素
SHIFT_OBSTACLE proc
                             push ax
                             mov  ax,obstacle_position[2]
                             mov  obstacle_position[0],ax
                             mov  ax,obstacle_position[4]
                             mov  obstacle_position[2],ax
                             xor  ax,ax
                             mov  obstacle_position[4],ax
                             pop  ax
                             ret
SHIFT_OBSTACLE endp

    ;如果obstacle_position[0]的位置除以320等於0則清除該obstacle並將剩餘兩個obstacle_position前移
OBSTACLE_BOUNDARY proc
                             push ax
                             mov  ax,obstacle_position[0]
.if ax < 41604d
                             call CLAER_OBSTACLE
.endif
                      pop  ax
                      ret
OBSTACLE_BOUNDARY endp

score_output proc
                      push ax
                      push cx
                      push dx
                      push di
                      inc  call_score_output_time
                      cmp  call_score_output_time,5    ;決定分數加的快慢
                      jne  ignore
                      mov  call_score_output_time,0
                      inc  score_now
    ignore:           
                      mov  dx,score_high
.if dx <=score_now
                      mov  dx,score_now
                      mov  score_high,dx
.endif
                 mov       di,offset x_num
                 call      clear                       ;清除x_num字串的後三個字元
                 mov       di,offset y_num
                 call      clear                       ;清除y_num字串的後三個字元
    ;MUS_GET03                               ;取得滑鼠狀態及游標位置
                 mov       dx,score_high
                 push      dx                          ;dx為歷史最高分數

                 mov       ax,score_now                ;cx為滑鼠x座標
                 mov       di,offset x_num
                 call      tran                        ;x座標轉換為十進制
                 pop       ax
                 mov       di,offset y_num
                 call      tran                        ;y座標轉換為十進制
	
                 SetCursor 0,35                        ;設定游標位置
                 PrintStr  x_num
                 SetCursor 1,35                        ;設定游標位置
                 PrintStr  y_num

                 pop       di
                 pop       dx
                 pop       cx
                 pop       ax

                 ret
score_output endp

    ;清除字串的後三個字元
clear proc
                 push      ax
                 push      cx
                 push      di
                 mov       cx,3
    L1:          
                 mov       al,' '
                 mov       [di+2],al
                 inc       di
                 loop      L1
                 pop       di
                 pop       cx
                 pop       ax
                 ret
clear endp

    ;十六進制轉十進制
tran proc
                 push      ax
                 push      bx
                 push      cx
                 push      dx
                 push      di
                 mov       cx,0
    Hex2Dec:     
                 inc       cx
                 mov       bx,10
                 mov       dx,0
                 div       bx
                 push      dx
                 cmp       ax,0
                 jne       Hex2Dec
    dec2Ascll:   
                 pop       ax
                 add       al,30h
                 mov       [di+2],al
                 inc       di
                 loop      dec2Ascll
                 pop       di
                 pop       dx
                 pop       cx
                 pop       bx
                 pop       ax
                 ret
tran endp

write_tree proc
                 push      ax
                 push      cx
                 push      dx
                 push      di
                 push      bx
                 xor       di,di
                 xor       dx,dx
                 xor       cx,cx
                 xor       bx,bx
                 mov       di,obstacle_position[si]
                 push      si
                 xor       si,si
                 mov       ah,0fh
                 add       si,0
    L6:          
    ;mov       cx,1
    ;write_tree_loop:
                 mov       dx,write_tree_part1[si]
                 add       di,dx
                 mov       es:[di],ah
                 sub       di,dx
                 inc       bx
                 add       si,2
    ;loop      write_tree_loop
                 cmp       bx,302
                 jne       L6
                 pop       si
                 pop       bx
                 pop       di
                 pop       dx
                 pop       cx
                 pop       ax
                 ret
write_tree endp

end main