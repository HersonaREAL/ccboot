;先读取软盘0面0道1扇区的复制引导程序的程序，然后跳到7e00h执行引导程序
;7c00h-7dffh这段空间留作操作系统的引导程序使用

assume cs:code
code segment


CCguide:
    call install_int9
guide_loop:
    ;不引导就一直在这里循环
    call show_option
    call input_option
    jmp guide_loop

;---------------------数据以及函数地址---------------------------
fun0str: db 'Welcome to CC guide!',0
fun1str: db '    1.reset pc',0
fun2str: db '    2.start OS',0
fun3str: db '    3.show clock',0
fun4str: db '    4.set clock',0
timestr db 'ye/mo/da ho:mi:se'
fun3PS  db 'F1:change color              ESC:exit',0
fun4PS1  db 'Please input in the format "ye/mo/da ho:mi:se"',0
fun4PS2  db 'ESC:exit               ENTER:confirm',0
CMOSport db 9,8,7,4,2,0 ;对应年月日时分秒
change_time db 64 dup(0)
stack_top dw 0
funcstr  dw fun0str+7e00h,fun1str+7e00h,fun2str+7e00h,fun3str+7e00h,fun4str+7e00h

functable dw fun1_resetpc+7e00h,fun2_startOS+7e00h,fun3_showclock+7e00h,fun4_setclock+7e00h
;--------------------------------------------------------------


;-----------------------基本函数--------------------------------
show_option:
    push ax
    push cx
    push dx
    push ds
    push si
    push di

    call clean_screen
    mov cx,5
    mov dh,10 ;11 row
    mov dl,30 ;30 col
    mov ax,0  ;set ds
    mov ds,ax 
    mov di,0  ;指向选项字符串的地址
 showloop:
    mov si,funcstr[di+7e00h]
    push cx
    mov cl,7
    call show_str
    inc dh
    add di,2
    pop cx
    loop showloop
 show_ret:
    pop di
    pop si
    pop ds
    pop dx
    pop cx
    pop ax
    ret
input_option:
    push ax
    push bx

    mov ah,0
    int 16h
    ;判断输入合法性
    cmp al,'1'
    jb input_ret
    cmp al,'4'
    ja input_ret
    ;算出函数地址表位置
    mov ah,0
    sub al,'1' 
    add ax,ax
    mov bx,ax
    call word ptr functable[bx+7e00h]
input_ret:
    pop bx
    pop ax
    ret
;-------------------------基本函数结束------------------------------






;------------------------选项函数-------------------------------
;共有四个，分别对应四个功能
fun1_resetpc:
    mov ax,0ffffh
    push ax
    mov ax,0
    push ax
    retf





fun2_startOS:
    mov ax,0
	mov es,ax
    mov bx,7c00h ;操作系统引导程序放在7c00h
	mov al,1
	mov ch,0
	mov cl,1
	mov dl,80h  ;C盘参数要为80h
	mov ah,2
	int 13h
 
	mov ax,0
	push ax
	mov ax,7c00h
	push ax
	retf





fun3_showclock:
    push ax
    push cx
    push dx
    push ds
    push es
    push si
    push di

    call clean_screen
    ;输出提示
    mov dh,14 ;14 row
    mov dl,20 ;20 col
    mov cl,7  ;white
    mov ax,0
    mov ds,ax
    mov si,offset fun3PS+7e00h
    call show_str

    mov ax,0
    mov es,ax

    cli
    mov word ptr es:[9*4],204h ;更改中断向量表
    mov word ptr es:[9*4+2],0
    sti    

    mov ax,0b800h
    mov es,ax
 die_loop:
    mov di,0 ;指向cmos端口，已存储在最开始的的数据段
    mov si,0 ;指向字符串位置
    mov cx,6 ;读取年月日时分秒一共六次
 clock_loop:
    mov al,CMOSport[di+7e00h]
    out 70h,al
    in al,71h

    ;把读到的数据处理成ASCII码
    mov ah,al
    push cx
    mov cl,4
    shr ah,cl
    and al,00001111b
    add ah,30h
    add al,30h
    pop cx

    ;读到的数据移动到数据段位置
    mov timestr[si+7e00h],ah
    mov timestr[si+1+7e00h],al
    add si,3;中间有空格或者冒号，所以要+3
    inc di  ;指向下一个CMOS端口
    loop clock_loop
    
    ;展示
    mov cx,17
    mov si,0 ;指向字符串位置
    mov di,0 ;指向显存写入位置
 clock_show:
    mov al,timestr[si+7e00h]
    mov es:[160*12+30*2+di],al
    inc si
    add di,2
    loop clock_show
    jmp die_loop

 fun3_showclock_ret:
    mov ax,0
    mov es,ax

    cli
    push es:[200h] ;恢复原来的int9
    pop es:[9*4]
    push es:[202h]
    pop es:[9*4+2]
    sti

    pop di
    pop si
    pop es
    pop ds
    pop dx
    pop cx
    pop ax
    ret

fun4_setclock:
    push ax
    push cx
    push dx
    push ds
    push es
    push si
    push di
   
    call clean_screen
    call clean_charstack

    ;输出提示
    mov dh,14 ;14 row
    mov dl,15 ;15 col
    mov cl,2  ;green
    mov ax,0
    mov ds,ax
    mov si,offset fun4PS1+7e00h
    call show_str
    mov dh,17
    mov dl,22
    mov si,offset fun4PS2+7e00h
    call show_str

    mov di,0 ;指向cmos端口，已存储在最开始的的数据段
    mov si,0 ;指向字符串位置
    mov cx,6 ;读取年月日时分秒一共六次
 fun4_loop:
    mov al,CMOSport[di+7e00h]
    out 70h,al
    in al,71h

    ;把读到的数据处理成ASCII码
    mov ah,al
    push cx
    mov cl,4
    shr ah,cl
    and al,00001111b
    add ah,30h
    add al,30h
    pop cx

    ;读到的数据移动到数据段位置
    mov timestr[si+7e00h],ah
    mov timestr[si+1+7e00h],al
    add si,3;中间有空格或者冒号，所以要+3
    inc di  ;指向下一个CMOS端口
    loop fun4_loop
    
    ;展示
    mov cx,17
    mov si,0 ;指向字符串位置
    mov di,0 ;指向显存写入位置
 fun4_show:
    mov al,timestr[si+7e00h]
    mov es:[160*12+30*2+di],al
    inc si
    add di,2
    loop fun4_show

 input_time:
    mov ax,0
    mov ds,ax
    mov si,offset change_time+7e00h
    mov dh,13 ;18row
    mov dl,30 ;30col
    call getstr
    cmp ah,01h
    je fun4_ret
    call set_clock

 fun4_ret:
    pop di
    pop si
    pop es
    pop ds
    pop dx
    pop cx
    pop ax
    ret
;------------------------选项函数结束-----------------------------





;-----------------------杂七杂八的函数----------------------------
show_str:
;dh=row,dl=col,cl=color,ds:si=str_addr
    push ax
    push bx
    push cx
    push dx
    push si
    push di


    mov ax,0b800h
    mov es,ax

    mov bx,0
    push cx
    mov ch,0
    mov cl,dh
 row:
    add bx,0a0h
    loop row
    pop cx
    mov ah,cl ;color
    mov dh,0
    add dx,dx ;col
    mov di,dx
 show:
    mov al,[si]
    cmp al,0
    je showEnd
    mov es:[bx+di],ax
    inc si
    add di,2
    jmp short show
  showEnd:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


clean_screen:
   ;清屏
    push bx
    push cx
    push es
    mov bx,0b800h
    mov es,bx
    mov bx,0
    mov cx,2000
 clean_loop:
    mov byte ptr es:[bx],' '
    mov byte ptr es:[bx+1],7
    add bx,2
    loop clean_loop
    pop es
    pop cx
    pop bx
    ret

clean_charstack:
   ;清除输入缓存
   push ax
   push cx
   push ds
   push si

   mov ax,0
   mov ds,ax
   mov si,offset change_time+7e00h
   mov cx,64
 clean_charstack_loop:
   mov byte ptr [si],0
   inc si
   loop clean_charstack_loop
   mov word ptr stack_top[7e00h],0

   pop si
   pop ds
   pop cx
   pop ax
   ret


charstack:
   ;操作字符栈
    jmp short charstart
charfunc_table dw charpush+7e00h,charpop+7e00h,charshow+7e00h

 charstart:
    push bx
    push dx
    push di
    push es

    cmp ah,2 
    ja sret
    mov bl,ah
    mov bh,0
    add bx,bx
    jmp word ptr charfunc_table[bx+7e00h]

 charpush:
    mov bx,stack_top[7e00h]
    mov [si][bx],al
    inc stack_top[7e00h]
    jmp sret
 charpop:
    cmp stack_top[7e00h],0
    je sret
    dec stack_top[7e00h]
    mov bx,stack_top[7e00h]
    mov al,[si][bx]
    jmp sret
 charshow:
    mov bx,0b800h
    mov es,bx
    mov al,160
    mov ah,0
    mul dh
    mov di,ax
    add dl,dl
    mov dh,0
    add di,dx

    mov bx,0
 charshows:
    cmp bx,stack_top[7e00h]
    jne noempty
    mov byte ptr es:[di],' '
    jmp sret
 noempty:
    mov al,[si][bx]
    mov es:[di],al
    mov byte ptr es:[di+2],' '
    inc bx
    add di,2
    jmp charshows
 sret:
    pop es
    pop di
    pop dx
    pop bx
    ret


getstr:
   ;读取并显示字符串
    push ax
 getstrs:
    mov ah,0
    int 16h
    cmp ah,01h
    je esc_ret

    cmp al,20h
    jb nochar

    mov ah,0
    call charstack
    mov ah,2
    call charstack
    jmp getstrs
 nochar:
    cmp ah,0eh
    je backspace
    cmp ah,1ch
    je enter
    jmp getstrs
 backspace:
    mov ah,1
    call charstack
    mov ah,2
    call charstack
    jmp getstrs
 enter:
    mov al,0
    mov ah,0
    call charstack
    mov ah,2
    call charstack
    pop ax
    ret
  esc_ret:
   pop ax
   mov ah,01h
   ret

set_clock:
   ;根据字符栈设置时钟
   push ax
   push cx
   push ds
   push di
   push si

   mov di,0 ;指向COMOS端口
   mov ax,0
   mov ds,ax
   mov si,offset change_time+7e00h
   mov di,0
   mov cx,6
 set_clock_loop:
   mov ah,[si] ;取出十位数
   mov al,[si+1];取出个位数
   sub ah,30h  ;减去30h得到BCD码
   sub al,30h
   push cx
   mov cl,4
   shl ah,cl  ;十位数左移4位加到al上
   add al,ah
   pop cx

   push ax
   mov al,CMOSport[di+7e00h] ;送入CMOS
   out 70h,al
   pop ax
   out 71h,al

   inc di
   add si,3 
   loop set_clock_loop

   pop si
   pop di
   pop ds
   pop cx
   pop ax
   ret


install_int9:
   ;中断安装
    push ax
    push cx
    push ds
    push es
    push si
    push di

    mov ax,0
    mov ds,ax
    mov es,ax
    mov si,offset int9+7e00h
    mov di,204h
    mov cx,offset int9end-offset int9
    cld
    rep movsb

    cli
    push es:[9*4] ;保存原来的int9到200h
    pop es:[200h]
    push es:[9*4+2]
    pop es:[202h]
    sti

    pop di
    pop si
    pop es
    pop ds
    pop cx
    pop ax
    ret


int9:
    push ax
    push bx
    push cx
    push es

    in al,60h
    
    pushf
    call dword ptr cs:[200h]

    push ax
 clean_keyboradbuff:  
 ;清除键盘缓冲区,ah=1判断缓冲区是否为空 
    mov ah,1
    int 16h
    jz judge_keyborad
    mov ah,0
    int 16h  
    jmp short clean_keyboradbuff
 
 judge_keyborad:
    pop ax
    
    cmp al,01h
    je esc_
    cmp al,3bh
    je f1
    jmp int9ret

  esc_:
    push bp
    mov bp,sp
    ;因为push了es,cx,bx,ax还有bp，所以定位到ip需要+10
    mov [bp+10],offset fun3_showclock_ret+7e00h ;set ip
    pop bp
    jmp int9ret
  f1:
    mov ax,0b800h
    mov es,ax
    mov bx,1
    mov cx,2000
 f1_s:
    inc byte ptr es:[bx]
    add bx,2
    loop f1_s
int9ret:
    pop es
    pop cx
    pop bx
    pop ax
    iret
int9end:nop

;----------------------到此整个程序结束-----------------------------






;---------------------复制引导程序到内存----------------------
copy_CCguide:
    ;复制裸机程序
	mov bx,7e00h
 
	mov al,3
	mov ch,0
	mov cl,2
	mov dh,0
	mov dl,0
 
	mov ah,2
	int 13h
 
	mov ax,0
	push ax
	mov ax,7e00h
	push ax
	retf




;-------------------安装------------------------
start:
mov ax,cs
	mov es,ax
	mov bx,offset CCguide
 
	mov al,3
	mov ch,0
	mov cl,2
	mov dh,0
	mov dl,0
 
	mov ah,3
	int 13h
 
	mov bx,offset copy_CCguide
 
	mov al,1
	mov ch,0
	mov cl,1
	mov dl,0
	mov dh,0
	mov ah,3
	int 13h
 
	mov ax,4c00h
	int 21h

code ends
end start