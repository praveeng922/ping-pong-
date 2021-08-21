assume cs:code_seg, ds:data_seg, ss:stack_seg

stack_seg segment stack
	db 200 dup(?)
	top db 	?
stack_seg ends

data_seg segment

	win_msg			db			10, 13, 9, 9, 9, "       Congratulations. You win!", 10,13,"$"
	over_msg		db			10, 13, 9, 9, 9, 9, "    Game over...", 10,13,"$"
	exit_msg		db			10, 13, 9, 9, 9, 9, " Game was exited...", 10,13,"$"
	score_msg		db			10, 13, 9, 9, 9, 9, "  Your score is ", "$"
	racket  		dw			185 												
	d_x				dw			1  													
	d_y				dw			1   												
	ball_x  		dw			0 													
	ball_y  		dw			0   												
	color   		db			31 													
	score 			dw			0 													
	time			dw 			10000												

data_seg 						ends

code_seg segment


start:

	mov 			ax, seg top 													
	mov 			ss,	ax
	mov 			sp, offset top
	
	mov 			ax, seg data_seg 												
	mov 			ds,ax
	
	call 			graphics_mode													
	call 			ball_init														
	call 			racket_init														
	
	main:
		call 			sleep														
		call 			processing													
		
		event:
			call 			move_ball												
			call 			clear 													
			call 			racket_init 											
			call 			ball_init												
			jmp 			main
	
	sleep: 																			
		mov 			cx, 0 														
		mov 			dx, word ptr ds:[time] 										
		mov 			ah, 86h
		int 			15h
	
	clear: 																			
		xor 			cx, cx 														
		mov 			dx, 63999 													
		xor 			bx, bx 														
		mov 			ah, 06h 
		mov 			al, 00
		int 			10h

		ret
		
	graphics_mode: 																	
		mov 			ax, 13h
		int 			10h
		mov 			ax, 0a000h
		mov 			es, ax
		ret
	
	text_mode: 																		
		mov 			ax, 03h
		int 			10h
		ret
	
	processing: 																	
		xor 			ax, ax
		mov 			ah, 01h 													
		int 			16h
		jz 				event 														
		mov 			ah, 00h 													
		int 			16h
		cmp 			ah, 4bh 													
		je 				left_arrow
		cmp 			ah, 4dh 													
		je 				right_arrow
		cmp 			ah, 01h 													
		je 				exit_pass
		jmp 			event
	
	left_arrow: 																	
		mov 			ax, word ptr ds:[racket]
		sub 			ax, 15 														
		cmp 			ax, 50 														
		jg 				left_wall 													
		mov 			word ptr ds:[racket], 50
		jmp 			event
		
		left_wall:
			mov 			word ptr ds:[racket],ax
			jmp 			event
	
	right_arrow: 																	
		mov 			ax, word ptr ds:[racket]
		add				ax, 15 														
		cmp 			ax, 320 													
		jl 				right_wall 													
		mov 			word ptr ds:[racket], 320
		jmp 			event
		
		right_wall:
			mov 			word ptr ds:[racket], ax
			jmp 			event
	
	losers_pass:
		jmp 			losers_gate

	exit_pass:
		jmp				exit_gate
	
	move_ball: 																	
		
		mov 			ax, word ptr ds:[ball_x] 									
		add 			ax, word ptr ds:[d_x]
		mov 			word ptr ds:[ball_x], ax
		
		mov 			bx, word ptr ds:[ball_y] 									
		add 			bx, word ptr ds:[d_y]
		mov 			word ptr ds:[ball_y], bx
		
		mov 			cx, word ptr ds:[racket] 									
		
		cmp 			ax, 0 														
		jg 				not_left_edge
		mov 			word ptr ds:[d_x], 1 										
		jmp 			top_bottom
		
		not_left_edge:
			cmp 			ax, 315 												
			jl 				top_bottom
			mov 			word ptr ds:[d_x], -1 									
		
		top_bottom:
			cmp 			bx, 0 													
			jg 				not_top_edge
			mov 			word ptr ds:[d_y], 1 									
			ret
			
		not_top_edge:
			cmp 			bx, 195 												
			jg 				losers_pass 											
			cmp 			bx, 188 												
			jl 				hit
			add 			cx, 5
			cmp 			ax, cx 													
			jg 				hit
			sub 			cx, 60
			cmp 			ax, cx 													
			jl 				hit
			cmp 			bx, 188 												
			je 				central_sector
			add 			cx, 25	
			cmp 			ax, cx 													
			jl 				left_sector
			mov 			word ptr ds:[d_x], 1 									
			ret
		
		left_sector:
			mov 			word ptr ds:[d_x], -1 									
			ret
		
		central_sector:																
			mov 			word ptr ds:[d_y], -1 									
			inc 			word ptr ds:[score]
			
			cmp 			byte ptr ds:[score], 20 								
			je 				winners_gate 											

			mov 			cx, 400 												
			inc_time:
				dec 			word ptr ds:[time]
				loop 			inc_time

			ret
		
		hit:
			ret
	
	racket_init: 																	
		mov 			al,byte ptr ds:[color]
		mov 			ax, 193
		mov 			cx,	320
		mul 			cx
		mov 			di, ax
		mov 			al, byte ptr ds:[color]
		add 			di, word ptr ds:[racket] 									
		mov 			cx, 4
		
		lines1:
			add 			di, 270
			push 			cx
			mov 			cx, 50
			call 			create_line
			pop 			cx
			loop 			lines1
		ret
	
	ball_init: 																		
		mov 			ax, word ptr ds:[ball_y]
		mov 			cx, 320
		mul 			cx
		mov 			di, ax
		sub 			di, 315
		mov 			al, byte ptr ds:[color]										
		add 			di, word ptr ds:[ball_x] 
		mov 			cx, 5
		
		lines2:
			add 			di, 315
			push 			cx
			mov 			cx, 5
			call 			create_line
			pop 			cx
			loop 			lines2
		ret
	
	create_line: 
		mov 			byte ptr es:[di], al
		inc 			di
		loop 			create_line
		ret
	
	winners_gate: 																		
		call 			text_mode
		
		mov 			dx, offset win_msg
		mov 			ah, 09
		int 			21h

		mov 			dx, offset score_msg
		mov 			ah, 09
		int 			21h

		jmp	 			print_score

	exit_gate: 																			
		call 			text_mode

		mov 			dx, offset exit_msg
		mov 			ah, 09
		int 			21h

		mov 			dx, offset score_msg
		mov 			ah, 09
		int 			21h

		jmp 			print_score
	
	losers_gate: 																		
		call 			text_mode
		
		mov 			dx, offset over_msg
		mov 			ah, 09
		int 			21h

		mov 			dx, offset score_msg
		mov 			ah, 09
		int 			21h

		jmp 			print_score
	
	
	print_score: 																		

		mov 			bx, word ptr ds:[score]
		k1:
			mov 		ax, bx
	        mov 		bx, 0
	        mov 		dx, 000ah
	        mov 		cx, 0000 														
		k2:
			div			dl     
	        mov 		bl, ah
	        push 		bx
	        mov 		ah, 0
	        inc 		cx					    										
	        cmp 		ax, 0
	        jne 		k2    															
	        mov 		ah, 02
		k3:
			pop 		dx
	        add 		dl, 30h
	        int 		21h
	        loop 		k3

	exit_cmd: 																			

		mov 		ah, 4ch
		xor 		al, al
		int 		21h
	
code_seg 			ends
end 				start
