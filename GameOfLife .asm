;~~~~~~~~~~~~~~~~~~~~~~~~
;GameOfLife.asm
;9/6/2021

;Maya Keter 325122224
;Iftah Kotler 213141039

;Description:game of life part 2.
;in this part we program the game itself, the rules of the game and generations and use the interrupts to change generations once in a second.
;~~~~~~~~~~~~~~~~~~~~~~~

	.model small

	.stack 100h

	.data 

	ctr dw 0000h ;check if 1 second has passed
	
	;colors:
	WHITE EQU 7FDBh
	CHANGE_WHITE EQU 8FDBh ;we will use it between two generations 
	BLACK EQU 0000h
	CHANGE_BLACK EQU 0100h;we will use it between two generations
	RED EQU 0C100h

	color dw 7FDBh ;save the color of the current symbol (the cell that now is red)
	
	SEC_msg db'[','s','e','c',']'
	CLK_msg db 'S','T','1',' ','T','I','M','E',':' 
	PAUSE_msg db 'p',' ','-',' ','P','a','u','s','e'
	EXIT_msg db 'e',' ','-',' ','E','x','i','t'
	Dictionary db '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E','F' ;for PRINTHEX

	
	.code


	ISR_New_Int8 proc near uses ax es cx 

	;how many times 55 ms have passed 
	mov di,offset ctr
	mov cx, ds:[di]
	inc cx
	mov ds:[di],cx

	;check if cx is 18 which means that one second has passed
	cmp cx,18d
	jnz prev_isr
	;rules of the game

	mov cx,0 ;reset cx to 0
	mov ds:[di],cx ;put 0 in the counter

	mov ax, 0B800h 
	mov es, ax

	
	mov cx,1500d ;the game board size is 1500 cells
	xor bx,bx ;start go over the board game from the top left corner
	
	;check the changes for the next generation, alive cell that need to die we will change his color to CHANGE_WHITE
	;dead cell that need to revive we will change his color to CHANGE_BLACK
	TURN:
	
		call NUMBER_OF_NEIGHBORS
		
		;change the cell color according to the game of life rules 
		cmp es:[bx],BLACK
		jnz CELL_W
			cmp dx,3
			jz CONTTURN
			cmp dx,2
			jz CONTTURN
			mov es:[bx],CHANGE_WHITE
				
		CELL_W:
			cmp dx,3
			jnz CONTTURN
			mov es:[bx],CHANGE_BLACK
	
		CONTTURN:;move to the next cell we need to check
		
		
		PUSH cx
		mov ax,bx
		mov cx,160d 
		xor dx,dx
		div cx
		
		cmp dx,118d; check if we got to the right border of the board game, if we do go to the next line
		jnz NEXT_LINE
		add bx,40d
		NEXT_LINE:
		add bx,2d
		
		
		POP cx
		LOOP TURN
		
		mov cx,1500d
		xor bx,bx
		;in this loop we change to black all the cells we colored in CHANGE_BLACK and change to white the cells we colored in CHANGE_WHITE
		;also we print the updated board game to the screen
		NEXT_GEN:
			cmp es:[bx],CHANGE_WHITE
			jnz IF_CHANGE_BLACK
				mov es:[bx],WHITE
			IF_CHANGE_BLACK:
			cmp es:[bx],CHANGE_BLACK
			jnz NEXT_CELL
				mov es:[bx],BLACK
			
			NEXT_CELL:;move to the next cell we need to check
		
			
			PUSH cx
			;mov es:[bx],00DBh
			mov ax,bx
			
			mov cx,160d
			xor dx,dx
			div cx
			
			cmp dx,118d ; check if we got to the right border of the board game, if we do go to the next line
			jnz NEXTLINE
			add bx,40d
			NEXTLINE:
			add bx,2d
			
			
			POP cx
		loop NEXT_GEN

		
	
	; if the counter has not reached to 18 
	prev_isr:
	int 80h ;use the old interupt

	mov al,20h ;check it out
	out 20h,al ;check it out
	iret
	ISR_New_Int8 endp


	HERE: 

	mov ax, @data ;initializing
	mov ds, ax ;data segment



	cli ; block interrupts
	;moving Int8 into IVT[080h]
	mov ax,0b800h
	mov es,ax
	
	;clock start
	xor ax,ax
	mov al,00h 
 	out 70h, al
 	in al,71h
	
	PUSH ax;save start time
	
	;remove the activation of interrupt 8
	in al, 21h
	or al, 02h
	out 21h, al
	
	;paint the background in white
	xor bx,bx
	mov cx,2000d
	mov ax,WHITE;
	
	PAINT:
	mov es:[bx],ax
	add bx,2h
	LOOP PAINT
	
	;paint menu
	mov bx,120d
	mov cx,25d
	mov ax,797Ch
	
	PAINTMENU:
	mov es:[bx],ax
	add bx,160d
	loop PAINTMENU
	
	;create the symbol that indicating our position on the screen
	mov bx,1662d
	mov ax,RED
	mov es:[bx],ax
	

	BeforePollKeyPress:
	xor ax,ax

	PollKeyPress:
	IN al, 64h
	TEST al, 01
	JZ PollKeyPress
	IN al, 60h
	
	
	;if the user pressed 'a'
	cmp al,9Eh ;scancode leave a
	jnz NEXTA; if not 'a'
	mov ax,bx
	mov cx,00A0h
	xor dx,dx
	div cx
	cmp dx,0 ;check if the player has reached the limit of the screen
	jz NEXTA ;if 'a'
	mov si,offset color 
	mov cx,ds:[si]
	mov es:[bx],cx
	sub bx,2h ;the new position of the symbol 
	mov cx,es:[bx]
	mov ds:[si],cx
	mov es:[bx],RED 
	jmp BeforePollKeyPress
	
	NEXTA:
	
	
	;if the user pressed 'd'
	cmp al,0A0h ;scancode leave d
	jnz NEXTD
	mov ax,bx
	mov cx,160
	xor dx,dx
	div cx
	cmp dx,118d
	jz NEXTD
	
	mov si,offset color
	mov cx,ds:[si]
	mov es:[bx],cx
	add bx,2h
	mov cx,es:[bx]
	mov ds:[si],cx
	mov es:[bx],RED
	jmp BeforePollKeyPress

	NEXTD:	
	
	;if the user pressed 'w'
	cmp al,91h ;scancode leave w
	jnz NEXTW
	sub bx,160d
	jns DC
	add bx,160d
	JMP NEXTW
	DC:
	mov si,offset color
	mov cx,ds:[si]
	mov es:[bx+160d],cx
	mov cx,es:[bx]
	mov ds:[si],cx
	mov es:[bx],RED
	
	NEXTW:

	;if the user pressed 's'
	cmp al,9Fh ;scancode leave s
	jnz NEXTS
	mov ax,bx
	mov cx, 3840d
	xor dx,dx
	div cx
	cmp ax,1h
	jz NEXTS
	
	mov si,offset color
	mov cx,ds:[si]
	mov es:[bx],cx
	add bx,160d
	mov cx,es:[bx]
	mov ds:[si],cx
	mov es:[bx],RED
	jmp BeforePollKeyPress
	
	NEXTS:
	
	;if the user pressed 't'
	cmp al,94h ;scancode leave t
	jnz NEXTT
	mov si,offset color ;check the color of the current symbol
	mov cx,ds:[si]
	cmp cx,WHITE 
	jnz IS_BLACK  
	mov ds:[si],BLACK ;the current color is white so we will change it to black
	jmp NEXTT
	
	IS_BLACK: 
	mov ds:[si],WHITE ;the current color is black so we will change it to white
	
	NEXTT:
	;if the user pressed 'e'
	cmp al,92h ;scancode leave e
	jz END_e
	jmp BeforePollKeyPress ;if the user pressed anything but awsdet go and receive again from the user
	
	END_e:
	;the setup stage of the game is done

	;change the color of the current symbol from red to its origin value
	mov si,offset color
	mov cx,ds:[si]
	mov es:[bx],cx

	;clock end
	mov al,00h 
    	out 70h, al
    	in al,71h

	;compute total time in second:
	POP bx
	sub ax,bx
	
	;print the time of th esetup stage in seconds
	mov bx,3966d
	call PRINTHEX
	
	;'print message [sec]'
	mov dx,3974d
	mov cx,0005d
	mov di,offset SEC_msg
	call PRINT_MSG

	;print message 'ST1 TIME:'
	mov dx,3806d
	mov cx,0009h
	mov di,offset CLK_msg
	call PRINT_MSG
	
	mov dx,446d
	mov cx,0009h
	mov di,offset PAUSE_msg
	call PRINT_MSG
	
	mov dx,606d
	mov cx,0008h
	mov di,offset EXIT_msg
	call PRINT_MSG
	
	
	;start again interrupt 9
	
	in al, 21h
	and al, 0FDh
	out 21h, al
	

	mov ax,0h ; IVT is location is '0000' address of RAM
	mov es,ax


	mov ax,es:[8h*4] ;copying old ISR8 IP to free vector
	mov es:[80h*4],ax

	mov ax,es:[8h*4+2] ;copying old ISR8 CS to free vector
	mov es:[80h*4+2],ax

	;moving ISR_New_Int8 into IVT[8]

	mov ax,offset ISR_New_Int8 ;copying IP of ISR_New to IVT[8]
	mov es:[8h*4],ax

	mov ax,cs ;copying CS of our ISR_New into IVT[8]
	mov es:[8h*4+2],ax

	sti ;enable interrupts

	;wait for the user to input p for pause and e for exit
	in al, 21h
	or al, 02h
	out 21h, al

	xor cx,cx ;if 0 than the gane is runing if 1 the game is in pause mod
	
	L1:
	
	;checks if all the board is dead and exit the program, otherwise contiune to the game
	push cx
	push bx
	
	mov cx,1500d
	PUSH es
	mov bx,0b800h
	mov es,bx
	xor bx,bx
	ISALLWHITE:
		
		cmp es:[bx],WHITE
		jnz NOTALLWHITE
		PUSH cx
		mov ax,bx
		mov cx,160d 
		PUSH dx
		xor dx,dx
		div cx
		
		cmp dx,118d; check if we got to the right border of the board game, if we do go to the next line
		jnz NEXT_LINE_CHECKWHITE
		add bx,40d
		NEXT_LINE_CHECKWHITE:
		POP dx
		add bx,2d
		POP cx
	LOOP ISALLWHITE
	pop es
	pop bx
	pop cx
	jmp END_e_PART2
	
	NOTALLWHITE:
	pop es
	pop bx
	pop cx
	
	
	BeforePollKeyPress_PART2:
	xor ax,ax

	PollKeyPress_PART2:
	IN al, 64h
	TEST al, 01
	JZ PollKeyPress_PART2
	IN al, 60h

	cmp al,92h ;scancode leave e
	jz END_e_PART2

	cmp al,99h ;scancode leave p
	jnz BeforePollKeyPress_PART2

	cmp cx,1 ;the game is on pause so change now into unpause
	jz UNPAUSE

	inc cx ;the game was runing so chnge the cx into 1 (pause mode) and pause the game 

	call SWAP_IVT

	jmp BeforePollKeyPress_PART2

	UNPAUSE:
	xor cx,cx

	call SWAP_IVT


	jmp BeforePollKeyPress_PART2 ;if the user pressed anything but awsdet go and receive again from the user
		

	jmp L1

	END_e_PART2:

	cmp cx,0
	jnz EXITTOT



	mov ax,es:[80h*4] ;copying old ISR8 IP to free vector
	mov es:[8h*4],ax

	mov ax,es:[80h*4+2] ;copying old ISR8 IP to free vector
	mov es:[8h*4+2],ax

	EXITTOT: 

	in al, 21h
	and al, 0FDh
	out 21h, al

	mov ah,4ch
	int 21h

	;SWAP_IVT function change from pause to unpause mode and the opposite by swapping the interrupts in the IVT table
	SWAP_IVT proc

	mov ax,es:[80h*4] ;copying old ISR8 IP to free vector
	push ax
	mov ax,es:[80h*4+2] ;copying old ISR8 CS to free vector
	push ax

	mov ax, es:[8h*4]
	mov es:[80h*4],ax

	mov ax, es:[8h*4+2]
	mov es:[80h*4+2],ax

	POP ax
	mov es:[8h*4+2],ax

	POP ax
	mov es:[8h*4],ax

	ret
	SWAP_IVT endp

	;the function check how many neighbors the cell has. the function also take in consideration  cells that are in the boarder lines 
	NUMBER_OF_NEIGHBORS proc uses bx cx ;dx is the counter, bx is the current place
	xor dx,dx

	mov cx,8

	sub bx,162d

	CHECK_NEIGHBORS:
	cmp bx ,0 ;check if the cell is above the first line 
	JL CONTINUE
	cmp bx,4000d ;check if the cell is under the last line
	JGE CONTINUE
	PUSH cx
	PUSH dx
	mov ax,bx ;check if the cell is on the left side of the first column
	mov cx,009Fh
	xor dx,dx
	div cx
	mov ax,dx
	POP dx
	POP cx
	cmp ax,0
	JZ CONTINUE
	PUSH cx
	PUSH dx
	mov ax,bx ;check if the cell is on the menu border line
	mov cx,160
	xor dx,dx
	div cx
	mov ax,dx
	POP dx
	POP cx
	cmp dx,120d
	JZ CONTINUE
	
	cmp es:[bx],BLACK
	jz IS_BLACK_COLOR
	cmp es:[bx],CHANGE_WHITE
	jz IS_BLACK_COLOR
	jmp CONTINUE
	IS_BLACK_COLOR:
	inc dx
	
	CONTINUE:
	cmp cx,6d
	jnz CONT6
	add bx,154d
	CONT6:

	cmp cx,5
	jnz CONT5
	add bx,2
	CONT5:

	cmp cx,4
	jnz CONT4
	add bx,154d
	CONT4:


	add bx,2d


	LOOP CHECK_NEIGHBORS


	ret
	NUMBER_OF_NEIGHBORS endp
	
	;function from hw 3 that print ax register in hexa form to the screen
	PRINTHEX proc 
	
	mov di, offset Dictionary ;pointer to the dictionary
	mov dx,bx
	mov cx ,0004h	
	BUILD_NUM:
		mov bx,000Fh
		and bx,ax
		mov bx,[bx+di]
		PUSH bx
		ror ax, 1
		ror ax, 1
		ror ax, 1
		ror ax, 1
			
		LOOP BUILD_NUM
		;printing the number
		mov bx,dx
		mov cx ,0004h
		PRINT_NUM:
			POP ax
			mov ah,79h ;bacground whiter and blue letters
			mov es:[bx], ax
			add bx,2
			
		loop PRINT_NUM
		RET
	PRINTHEX endp
	
	;function we use in order to print arrays to the screen
	;di is the pointer to the array, dx the position to the screen, cx the length of the array
	PRINT_MSG proc
	PRINT_TXT:
		mov bh,0000h
		mov byte ptr al,[di]
		mov bx,dx
		mov es:[bx],ax
		inc di
		add dx,0002h
	loop PRINT_TXT

	RET
	PRINT_MSG endp
	
	end HERE