; Set up the screen
	lea eax, home_text ; Print all the instructions
	out 0xEC, eax
	mov eax, 0x0300FF
	out 0xE6, eax
	mov ax, 0x1300 ; Move the cursor to 0,19
	out 0xEA, ax
	mov eax, 0x0901ff ; Row 1's text color's R component
	out 0xE6, eax
	mov eax, 0x0A0199 ; Row 1's text color's G component
	out 0xE6, eax
	mov eax, 0x0B0133 ; Row 1's text color's B component
	out 0xE6, eax
	mov eax, 0x0600cc
	out 0xE6, eax
	mov eax, 0x0700ff 
	out 0xE6, eax
	mov eax, 0x0800aa 
	out 0xE6, eax
	mov eax, 0x0601cc
	out 0xE6, eax
	mov eax, 0x0701ff 
	out 0xE6, eax
	mov eax, 0x0801aa 
	out 0xE6, eax
	mov eax, 0x0602cc
	out 0xE6, eax
	mov eax, 0x0702ff 
	out 0xE6, eax
	mov eax, 0x0802aa 
	out 0xE6, eax
	mov al, 4 ; Update the entire screen at once
	call PRINT_FOOTER
	out 0xE8, al
	; Wait for the user to choose:
	; 1 = Admin login
	; 2 = Guest login
WAIT_FOR_BUTTON:
	hlt
	in ax, 0xE0
	cmp ax, 0x0001 ; Button 1 released
	je ADMIN_LOGIN
	cmp ax, 0x0002
	je GUEST_LOGIN 
	jmp WAIT_FOR_BUTTON


SHUT_DOWN:
	; Sending any byte other than 0 to port 255 finishes the execution
	mov al, 1
	out 255, al

PRINT_FOOTER:
    mov ax, 0x1300 ; Move the cursor to 0,19
	out 0xEA, ax
	lea eax, footer_text ; Print the footer
	out 0xEC, eax
	mov eax, 0x0300FF
	out 0xE6, eax
    mov eax, 0x061344 ; Row 19's background color's R component
	out 0xE6, eax
	mov eax, 0x0713AA ; Row 19's background color's G component
	out 0xE6, eax
	mov eax, 0x0813FF ; Row 19's background color's B component
	out 0xE6, eax
	mov eax, 0x091300 ; Row 19's text color's R component
	out 0xE6, eax
	mov eax, 0x0A1300 ; Row 19's text color's G component
	out 0xE6, eax
	mov eax, 0x0B1300 ; Row 19's text color's B component
	out 0xE6, eax
    mov al, 4 ; Update the entire screen at once
	out 0xE8, al
    ret
	

INT_GEN:
	iret
INT_KEY:
	;int 3
	xor eax, eax
	xor ecx, ecx
	in ax, 0xE0
	mov cx, ax
	iret
	
GUEST_LOGIN:
    jmp WAIT_FOR_BUTTON ; Prevent granting admin privileges for guest login


ADMIN_LOGIN:
	mov al, 2 ; clear screen memory
	out 0xE8, al
	; This block generates a pseudo-random number
    in eax, 0x00 ; Use the current system time as the seed for the random numbers
	mov ecx, 1103515245
	imul ecx
	add eax, 111
    mov edi, eax
	
	; Add line to screen
	mov ax, 0x0a00 ; Move the cursor to 0,19
	out 0xEA, ax
    lea ebx, login_num_print
	add ebx, 28
	mov ecx, 10
	xor edx, edx
	mov eax, edi
    div ecx
	add dx, 48
    mov [ebx], dx
    xor edx, edx
    div ecx
	add dx, 48
    mov [ebx + 2], dx
    xor edx, edx
    div ecx
	add dx, 48
    mov [ebx + 4], dx
    xor dx, dx
	lea eax, login_num_print
	out 0xEC, eax
	mov eax, 0x0300FF
	out 0xE6, eax
	
	call PRINT_FOOTER
	mov ax, 0x0000
	out 0xEA, ax
    lea eax, admin_login_header ; Print header
	out 0xEC, eax
    mov eax, 0x0300FF
	out 0xE6, eax
    mov al, 4 ; Update the entire screen at once
	out 0xE8, al
    
    ; Calculate the digit sum
    call CALCULATE_DIGIT_SUM ; Call the CALCULATE_DIGIT_SUM subroutine

	; Check if the value in EBX is >= 10
	cmp ebx, 10         ; Compare the value in EBX with 10
	jl skip_digit_sum   ; Jump if the value in EBX is less than 10

	; Sum the digits of EBX
	mov eax, ebx        ; Move the value of EBX to EAX
	call CALCULATE_DIGIT_SUM_DOUBLE ; Call the CALCULATE_DIGIT_SUM_DOUBLE subroutine
	jmp WAIT_FOR_INPUT ; Jump to WAIT_FOR_INPUT

skip_digit_sum:

    jmp WAIT_FOR_INPUT ; Jump to WAIT_FOR_INPUT

WAIT_FOR_INPUT:

    ; Wait for user input
    hlt                  ; Halt processor until an interrupt is received
    in ax, 0xE0          ; Read input from the user

    ; Compare input with calculated digit sum
    call COMPARE_WITH_INPUT ; Call the COMPARE_WITH_INPUT subroutine

    jmp SHUT_DOWN        ; Jump to SHUT_DOWN

COMPARE_WITH_INPUT:
    cmp al, bl            ; Compare the input with the calculated digit sum
    jne PASS_FAIL         ; Jump to PASS_FAIL if not equal
    
    jmp PRINT_OK_MESSAGE	 ; Jump to PRINT_OK_MESSAGE if equal
	jmp SHUT_DOWN          ; Jump to SHUT_DOWN otherwise

CALCULATE_DIGIT_SUM:
    xor ebx, ebx          ; Clear EBX register to store the digit sum
    xor edx, edx          ; Clear EDX register before division
    mov ecx, 10           ; Set divisor for decimal digits
	mov eax, edi          ; Move the login number to EAX
    div ecx               ; Divide EAX by 10
    add bl, dl            ; Add the remainder to the digit sum in BL
    xor edx, edx          ; Clear EDX for the next division
    div ecx               ; Divide EAX by 10
    add bl, dl            ; Add the remainder to the digit sum in BL
    xor edx, edx          ; Clear EDX for the next division
    div ecx               ; Divide EAX by 10
    add bl, dl            ; Add the remainder to the digit sum in BL
    ret                   ; Return from the subroutine

CALCULATE_DIGIT_SUM_DOUBLE:
    xor ebx, ebx          ; Clear EBX register to store the digit sum
    xor edx, edx          ; Clear EDX register before division
    mov ecx, 10           ; Set divisor for decimal digits
    div ecx               ; Divide EAX by 10
    add bl, dl            ; Add the remainder to the digit sum in BL
    xor edx, edx          ; Clear EDX for the next division
    div ecx               ; Divide EAX by 10
    add bl, dl            ; Add the remainder to the digit sum in BL
    ret                   ; Return from the subroutine 
PASS_FAIL:
    mov al, 2 ; clear screen memory
	out 0xE8, al
	mov ax, 0x0707
	out 0xEA, ax
	lea eax, login_error_msg
	out 0xEC, eax
	mov eax, 0x0300FF
	out 0xE6, eax
    xor esi, esi
    mov ebx, 0x0600ff
    mov ecx, 0x070000
    mov edx, 0x080000
COLOR_LOOP_F:
    mov eax, ebx
	out 0xE6, eax
	mov eax, ecx
	out 0xE6, eax
	mov eax, edx
	out 0xE6, eax
    add ebx, 0x100
    add ecx, 0x100
    add edx, 0x100
    inc esi
    cmp esi, 19
    jle COLOR_LOOP_F
    
    mov al, 4 ; Update the entire screen at once
	out 0xE8, al
    
    int 3
	jmp SHUT_DOWN

PRINT_OK_MESSAGE:
	mov al, 2 ; clear screen memory
	out 0xE8, al
	mov ax, 0x0707
	out 0xEA, ax
	lea eax, login_success_msg
	out 0xEC, eax
	mov eax, 0x0300FF
	out 0xE6, eax
    xor esi, esi
    mov ebx, 0x060000
    mov ecx, 0x0700cc
    mov edx, 0x080000
COLOR_LOOP:
    mov eax, ebx
	out 0xE6, eax
	mov eax, ecx
	out 0xE6, eax
	mov eax, edx
	out 0xE6, eax
    add ebx, 0x100
    add ecx, 0x100
    add edx, 0x100
    inc esi
    cmp esi, 19
    jle COLOR_LOOP
    
    mov al, 4 ; Update the entire screen at once
	out 0xE8, al
    int 3
	jmp SHUT_DOWN
