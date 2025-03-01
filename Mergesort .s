
;	0x60001000 (Sorted Answer located here)
;	; = pseudocode
;	// = comments

	AREA Mergesort, CODE, READONLY
	ENTRY

LAST_ARRAY_i EQU 9				; 10-1 = 9
ARRAY_SIZE EQU 40
	
	LDR SP, =Stack
	ADD SP, #4096

ARRAY   DCD 8, 29, 50, 81, 4, 23, 24, 30, 1, 7
Initialise

Read RN r0
Write RN r5

Left RN r1
Mid RN r2
Right RN r3
Instruction RN r4
	
	LDR Read, =ARRAY
	LDR Write, =Array_Modify
	
	MOV Left, #0                    ; Left index = 0
	MOV Right, #LAST_ARRAY_i	    ; Right index = 9
	MOV r9, #10                     
	MOV Instruction, PC             ; Currecnt instruction + 4// When reached the end skip 4 line of instruction at end of memory stack
	ADD Instruction, #16		    
	PUSH {Instruction}              ; Store to Stack
	PUSH {Left, Mid, Right}         ; Store starting Left, Mid, Right to Stack
	BL Read_Array                   ; Read_Array(ARRAY, Array_Modify, 10, 0)
	B Split
	B Exit                          ; // only Exit occur after last POP 
	
Read_Array                          ; Read_Array(Read, Write, r9, r8) //Copy unmodifiable array to a modifiable one
	LDR r12, [Read]
	STR r12, [Write]                ;    Write[j] = Read[i] 
	ADD Read, #4                    ;   i++
	ADD Write, #4                   ;   j++
	ADD r8, r8, #1                  ;   r8++
	CMP r8, r9                      ;   IF r8 _ 10
	BLT Read_Array                  ;       LESS THAN
	BX LR                           ;   ELSE: Return
	
;-------------------------------------------------------------
Split
	CMP Left, Right				    ; IF Left MORE or EQUALS Right
	POPGE {Left, Right, Mid, PC}    ; 	POP 
	
Left_Split                          
	MOV Instruction, PC             ; Currecnt instruction + 6
	ADD Instruction, #24            
	PUSH {Instruction}
	ADD R2, Left, Right             ; Calculate mid = (left + right) / 2
    LSR Mid, R2, #1                 ; Divide by 2
	PUSH {Left, Mid, Right}   	    ; PUSH left, mid, right to stack
	MOV Right, Mid				    ; Right = Mid
	B Split					        ;   Repeat
	
Right_Split
	MOV Instruction, PC
	ADD Instruction, #20            ; Currecnt instruction + 5
	PUSH {Instruction}              
	PUSH {Left, Mid, Right}         ; PUSH left, mid, right to stack
	ADD Mid, Mid, #1			    ; Mid + 1 		// because left [0-4][5-9] mid is 4, to get left of right, we need to add 1 to mid
	MOV Left, Mid				    ; Left = mid
	B Split				            ;   Repeat

;-------------------------------------------------------------
Merge
Left_Size RN r6
Right_Size RN r7

I RN r8
J RN r9

Left_CMP RN r10
Right_CMP RN r11

Left_A RN r4
Right_A RN r5
Sort_A RN r0

	LDR Left_A, =Left_Array 
	LDR Right_A, =Right_Array
	LDR Sort_A, =Array_Modify           ; Sort_Array

;Get Left and Right Array Sizes
	SUB Left_Size, Mid, Left            
	ADD Left_Size, Left_Size, #1 	    ; Left_Size = (Mid - Left) + 1
	SUB Right_Size, Right, Mid		    ; Right = Right - Mid
	
	LDR Read, =Array_Modify			    
	LDR Write, =Left_Array
	MOV r12, #4
	MUL r12, Left, r12
	ADD Read, r12                       ; Array_Modify_i = Array_Modify_i * 4   // starting index
	MOV r8, #0
	MOV r9, Left_Size                   ; r9 = left_Size
	BL Read_Array                       ; Read(Left_A, Array_Modify[Array_Modify_i], Left_Size, 0)
	
	LDR Read, =Array_Modify			
	LDR Write, =Right_Array
	MOV r12, #4
	MUL r12, Mid, r12
	ADD Read, r12
	ADD Read, #4                        ; Array_Modify_i = (Array_Modify_i * 4) + 4 // starting index
	MOV r8, #0
	MOV r9, Right_Size 
	BL Read_Array                       ; Read(Left_A, Array_Modify[Array_Modify_i], Right_Size, 0)
	
	MOV I, #0
	MOV J, #0                           ; // reset their index since used them before
	LDR Left_A, =Left_Array
	LDR Right_A, =Right_Array           ; // reload left & right array since used R5 in read array
	LDR Sort_A, =Array_Modify           ; // reload the array address
	MOV r12, #4                         
	MUL r12, Left, r12                  ; Array_Modify_i = Array_Modify_i * 4
	ADD Sort_A, r12                     ; Array_Modify[Array_Modify_i]

Compare                                 ; Compare
	CMP I, Left_Size 				    ;   IF I < Left Array Size
	BGE storeRight                      ;       storeRight
	CMPLT J, Right_Size 			    ;   IF J < Right Array Size         //if I or J is greater than or equal to their respective array size, dont need to compare anymore
	BGE storeLeft					    ;       storeLeft
	LDR Left_CMP, [Left_A] 			    ;   Left_A[i]
	LDR Right_CMP, [Right_A] 		    ;   Right_A[i]
	CMP Left_CMP, Right_CMP
	BLE Left_Compare 				    ;   IF Left_A[i] <= Right_A[i]
	BGT Right_Compare				    ;   IF Left_A[i] > Right_A[i]
	
Left_Compare                            ;   Left_Compare
	STR Left_CMP, [Sort_A] 			    ;       Store Left_A[i] to Sorted_Array
	ADD Left_A, #4 					    ;       i++
	ADD I, #1 						    ;       I++
	ADD Sort_A, #4 					    ;       Sort_A_i++
	B Compare                           ;       REPEAT

Right_Compare                           ;   Right_Compare
	STR Right_CMP, [Sort_A] 		    ;       Store Right_A[i] to Sorted_Array
	ADD Right_A, #4 				    ;       i++
	ADD J, #1 						    ;       I++
	ADD Sort_A, #4 					    ;       Sort_A_i++
	B Compare                           ;       REPEAT

storeLeft                               ;   storeLeft
	LDR Left_CMP, [Left_A] 			    ;       Left_A[i]
	STR Left_CMP, [Sort_A] 			    ;       Store Left_A[i] to Sorted_Array
	ADD Left_A, #4 					    ;       i++
	ADD I, #1 						    ;       I++
	ADD Sort_A, #4 					    ;       Sort_A_i++
	CMP I, Left_Size                    ;       IF I >= Left_Size
	BGE End_Compare                     ;           End_Compare
	B storeLeft                         ;       ELSE : storeLeft

storeRight                              ;   storeRight
	LDR Right_CMP, [Right_A] 		    ;       Right_A[i]
	STR Right_CMP, [Sort_A] 		    ;       Store Right_A[i] to Sorted_Array
	ADD Right_A, #4 				    ;       i++
	ADD J, #1 						    ;       J++
	ADD Sort_A, #4 					    ;       Sort_A_i++
	CMP J, Right_Size                   ;       IF J >= Right_Size
	BGE End_Compare                     ;       End_Compare
	B storeRight                        ;       ELSE : storeLeft

End_Compare
	POP {Left, Mid, Right, PC}          ;    Get Left, Mid, Right, Next_Instruction from Stack
	
Exit
	B Exit
	
	AREA data, DATA, READWRITE
Stack SPACE 4096 
Array_Modify SPACE ARRAY_SIZE
Left_Array SPACE ARRAY_SIZE
Right_Array SPACE ARRAY_SIZE
	
	END