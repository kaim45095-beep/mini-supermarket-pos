section .data
    ; --- Boot & Navigation Menus ---
    boot_menu db 10, "=== Mini Supermarket POS System ===", 10, "1. Kiosk Mode (Self-Service)", 10, "2. Regular Mode (Staff Counter)", 10, "3. App Mode (Online Order)", 10, "4. Exit System", 10, "Select: ", 0
    kiosk_menu db 10, "=== KIOSK MODE ===", 10, "Welcome! Self-checkout is ready...", 10, 0
    staff_login_msg db 10, "=== STAFF LOGIN ===", 10, "Enter Staff PIN (e.g., 1234 or 4321): ", 0
    login_success db 10, "Login Successful! System unlocked.", 10, 0
    msg_member db 10, "Enter Member Code (e.g., 123456, 654321 or 0 for Guest): ", 0

    ; --- App Mode Strings ---
    msg_app_id db 10, "=== APP LOGIN ===", 10, "Enter Member Code as ID (e.g., 123456 or 654321): ", 0
    msg_app_pass db "Enter App Password (e.g., 1234): ", 0
    msg_delivery db 10, "Select Delivery Method:", 10, "1. Home Delivery", 10, "2. Pickup in Store", 10, "Select: ", 0
    msg_stores db 10, "Select Store for Pickup:", 10, "1. Seri Kembangan", 10, "2. Bukit Jalil", 10, "3. Puchong", 10, "4. Cyberjaya", 10, "5. Petaling Jaya", 10, "Select: ", 0
    msg_pay_delivery db 10, "Please pay the delivery person upon arrival.", 10, 0
    msg_pay_counter db 10, "Please pay at the store counter upon pickup.", 10, 0
    msg_order_success db 10, "Order is successful! Order ID: ORD-99824", 10, 0

    ; --- Error Messages ---
    msg_err_menu db 10, "Error: Invalid selection. Please enter a valid number.", 10, 0
    msg_err_pin db 10, "Error: Invalid PIN/Credentials. Access Denied.", 10, 0
    msg_err_mem db 10, "Error: Invalid Member Code. Try again.", 10, 0
    msg_err_qty db 10, "Error: Invalid quantity. Must be 1 or more.", 10, 0
    msg_kiosk_pin db 10, "Enter Admin PIN to Exit Kiosk: ", 0

    ; --- POS Menus & Prompts ---
    item_menu db 10, "--- CART ---", 10, "1. Fruits (RM10)", 10, "2. Fish (RM30)", 10, "3. Meat (RM20)", 10, "4. Sauce (RM5)", 10, "5. Toiletries (RM20)", 10, "6. Snacks (RM15)", 10, "7. Frozen Items (RM25)", 10, "8. Checkout", 10, "9. Cancel Cart", 10, "10. Logout/Exit", 10, "Select: ", 0
    msg_qty db "Enter Quantity: ", 0
    msg_total db 10, "Current Total: RM", 0
    msg_cancel db 10, "Cart canceled. Emptying cart...", 10, 0
    
    ; --- Points & Payment Strings ---
    msg_pts_bal db 10, "Member Points: ", 0
    msg_pts_ask db 10, "Enter POINTS to redeem (100 pts = RM1, Enter 0 to skip): ", 0
    msg_err_pts db 10, "Error: Invalid amount or insufficient points. Try again.", 10, 0
    
    msg_pay_method db 10, "Payment Method:", 10, "1. Cash", 10, "2. Card", 10, "3. QR Code", 10, "Select: ", 0
    msg_pay db 10, "Enter Cash Amount (RM): ", 0
    msg_err_pay db 10, "Error: Payment is less than total cost or invalid. Try again.", 10, 0
    msg_change db 10, "Change to return: RM", 0
    msg_exact_pay db 10, "Card/QR Payment Approved. Exact amount received.", 10, 0
    
    msg_pts_awarded db 10, "Points awarded this transaction: ", 0
    msg_pts_earned db 10, "Total Points remaining: ", 0
    msg_nl db 10, 0

    ; --- System State ---
    total_cost dd 0
    member_pts dd 0        ; Holds current session's points
    is_member dd 0         ; 0 = Guest, 1 = Member
    sys_mode dd 0          ; 1 = Kiosk, 2 = Staff, 3 = App
    delivery_mode dd 0     ; 1 = Home Delivery, 2 = Pickup
    active_mem_id dd 0     ; 1 = Member 123456, 2 = Member 654321
    
    ; --- Member Databases ---
    mem1_saved dd 500      ; Saved points for member 123456
    mem2_saved dd 150      ; Saved points for member 654321

section .bss
    input_buf resb 16
    num_buf resb 16

section .text
    global _start

_start:
    mov dword [total_cost], 0
    mov dword [is_member], 0
    mov dword [sys_mode], 0
    mov dword [delivery_mode], 0
    mov dword [active_mem_id], 0

boot_loop:
    mov esi, boot_menu
    call print_string
    call read_int

    cmp eax, 1
    jl boot_error
    cmp eax, 4
    jg boot_error

    cmp eax, 1
    je kiosk_mode
    cmp eax, 2
    je staff_mode
    cmp eax, 3
    je app_mode
    cmp eax, 4
    je exit_program

boot_error:
    mov esi, msg_err_menu
    call print_string
    jmp boot_loop

; ==========================================
; MODES & LOGIN
; ==========================================
kiosk_mode:
    mov dword [sys_mode], 1
    jmp next_customer

staff_mode:
    mov esi, staff_login_msg
    call print_string
    call read_int
    
    cmp eax, 1234
    je staff_success
    cmp eax, 4321
    je staff_success
    
    mov esi, msg_err_pin
    call print_string
    jmp staff_mode

staff_success:
    mov esi, login_success
    call print_string
    mov dword [sys_mode], 2
    jmp next_customer

app_mode:
    mov esi, msg_app_id
    call print_string
    call read_int
    
    cmp eax, 123456
    je app_user_1
    cmp eax, 654321
    je app_user_2
    jmp app_error

app_user_1:
    mov dword [active_mem_id], 1
    jmp verify_app_pass

app_user_2:
    mov dword [active_mem_id], 2
    jmp verify_app_pass

verify_app_pass:
    mov esi, msg_app_pass
    call print_string
    call read_int

    cmp eax, 1234
    jne app_error

    mov esi, login_success
    call print_string
    
    ; Initialize App Session
    mov dword [sys_mode], 3
    mov dword [is_member], 1
    mov dword [total_cost], 0
    call load_member_pts
    jmp pos_loop

app_error:
    mov esi, msg_err_pin
    call print_string
    jmp app_mode

; ==========================================
; NEXT CUSTOMER LOOP (Kiosk & Staff Only)
; ==========================================
next_customer:
    mov dword [total_cost], 0
    mov dword [is_member], 0
    mov dword [delivery_mode], 0
    mov dword [active_mem_id], 0
    
    cmp dword [sys_mode], 1
    je kiosk_welcome
    jmp ask_member

kiosk_welcome:
    mov esi, kiosk_menu
    call print_string
    jmp ask_member

ask_member:
    mov esi, msg_member
    call print_string
    call read_int
    
    cmp eax, 0
    jl mem_error           
    
    cmp eax, 0
    je set_guest
    
    cmp eax, 123456
    je set_member_1
    cmp eax, 654321
    je set_member_2

mem_error:
    mov esi, msg_err_mem
    call print_string
    jmp ask_member

set_member_1:
    mov dword [is_member], 1
    mov dword [active_mem_id], 1
    call load_member_pts
    jmp pos_loop

set_member_2:
    mov dword [is_member], 1
    mov dword [active_mem_id], 2
    call load_member_pts
    jmp pos_loop

set_guest:
    mov dword [is_member], 0
    jmp pos_loop

; --- Helper to load points ---
load_member_pts:
    cmp dword [active_mem_id], 1
    je .load1
    cmp dword [active_mem_id], 2
    je .load2
    ret
.load1:
    mov eax, [mem1_saved]
    mov [member_pts], eax
    ret
.load2:
    mov eax, [mem2_saved]
    mov [member_pts], eax
    ret

; ==========================================
; MAIN POS CART LOOP
; ==========================================
pos_loop:
    mov esi, item_menu
    call print_string
    call read_int

    cmp eax, 1
    jl cart_error
    cmp eax, 10
    jg cart_error

    cmp eax, 1
    je add_item_1
    cmp eax, 2
    je add_item_2
    cmp eax, 3
    je add_item_3
    cmp eax, 4
    je add_item_4
    cmp eax, 5
    je add_item_5
    cmp eax, 6
    je add_item_6
    cmp eax, 7
    je add_item_7
    cmp eax, 8
    je checkout
    cmp eax, 9
    je cancel_cart
    cmp eax, 10
    je logout_exit

cart_error:
    mov esi, msg_err_menu
    call print_string
    jmp pos_loop

; --- Add Items (1 to 7) ---
add_item_1: ; Fruits RM10
    call get_quantity
    imul eax, eax, 10
    add [total_cost], eax
    jmp pos_loop

add_item_2: ; Fish RM30
    call get_quantity
    imul eax, eax, 30
    add [total_cost], eax
    jmp pos_loop

add_item_3: ; Meat RM20
    call get_quantity
    imul eax, eax, 20
    add [total_cost], eax
    jmp pos_loop

add_item_4: ; Sauce RM5
    call get_quantity
    imul eax, eax, 5
    add [total_cost], eax
    jmp pos_loop

add_item_5: ; Toiletries RM20
    call get_quantity
    imul eax, eax, 20
    add [total_cost], eax
    jmp pos_loop

add_item_6: ; Snacks RM15
    call get_quantity
    imul eax, eax, 15
    add [total_cost], eax
    jmp pos_loop

add_item_7: ; Frozen Items RM25
    call get_quantity
    imul eax, eax, 25
    add [total_cost], eax
    jmp pos_loop

get_quantity:
    mov esi, msg_qty
    call print_string
    call read_int
    cmp eax, 0
    jle qty_error_handler
    ret

qty_error_handler:
    mov esi, msg_err_qty
    call print_string
    add esp, 4 
    jmp pos_loop

cancel_cart:
    mov esi, msg_cancel
    call print_string
    cmp dword [sys_mode], 3
    je app_reset_cart
    jmp next_customer

app_reset_cart:
    mov dword [total_cost], 0
    jmp pos_loop

logout_exit:
    cmp dword [sys_mode], 1
    je kiosk_exit_auth
    jmp _start 

kiosk_exit_auth:
    mov esi, msg_kiosk_pin
    call print_string
    call read_int
    cmp eax, 1234
    je _start
    cmp eax, 4321
    je _start
    mov esi, msg_err_pin
    call print_string
    jmp pos_loop

; ==========================================
; CHECKOUT & POINTS
; ==========================================
checkout:
    mov esi, msg_total
    call print_string
    mov eax, [total_cost]
    call print_int

    cmp dword [is_member], 1
    jne app_delivery_check

    ; --- Member Points Redemption ---
    mov esi, msg_pts_bal
    call print_string
    mov eax, [member_pts]
    call print_int

ask_points:
    mov esi, msg_pts_ask
    call print_string
    call read_int          
    
    cmp eax, 0
    je app_delivery_check          
    cmp eax, 0
    jl pts_error           

    cmp eax, [member_pts]
    jg pts_error           
    
    xor edx, edx
    mov ecx, 100
    div ecx                
    
    mov ebx, eax
    imul ebx, ebx, 100     

    cmp eax, [total_cost]
    jle .apply_deduction
    mov eax, [total_cost]  
    mov ebx, eax
    imul ebx, ebx, 100     

.apply_deduction:
    sub [member_pts], ebx
    sub [total_cost], eax

    mov esi, msg_total
    call print_string
    mov eax, [total_cost]
    call print_int
    jmp app_delivery_check

pts_error:
    mov esi, msg_err_pts
    call print_string
    jmp ask_points

; ==========================================
; APP MODE LOGISTICS & PAYMENT
; ==========================================
app_delivery_check:
    cmp dword [sys_mode], 3
    jne ask_method

process_app_delivery:
    mov esi, msg_delivery
    call print_string
    call read_int
    
    mov dword [delivery_mode], eax
    cmp eax, 1
    je ask_method
    cmp eax, 2
    je select_store
    
    mov esi, msg_err_menu
    call print_string
    jmp process_app_delivery

select_store:
    mov esi, msg_stores
    call print_string
    call read_int
    
    cmp eax, 1
    jl store_error
    cmp eax, 5
    jg store_error
    jmp ask_method

store_error:
    mov esi, msg_err_menu
    call print_string
    jmp select_store

; --- Payment Method Selection ---
ask_method:
    mov esi, msg_pay_method
    call print_string
    call read_int

    cmp eax, 1
    je ask_payment_cash
    cmp eax, 2
    je payment_card_qr
    cmp eax, 3
    je payment_card_qr
    
    mov esi, msg_err_menu
    call print_string
    jmp ask_method

; --- Payment Processing (Card/QR) ---
payment_card_qr:
    mov esi, msg_exact_pay
    call print_string
    jmp check_member_reward

; --- Payment Processing (Cash) ---
ask_payment_cash:
    cmp dword [sys_mode], 3
    je app_cash_handler

    mov esi, msg_pay
    call print_string
    call read_int
    
    cmp eax, [total_cost]
    jl pay_error           

    mov ebx, eax
    sub ebx, [total_cost]  
    
    mov esi, msg_change
    call print_string
    mov eax, ebx
    call print_int
    jmp check_member_reward

pay_error:
    mov esi, msg_err_pay
    call print_string
    jmp ask_payment_cash

app_cash_handler:
    cmp dword [delivery_mode], 1
    je app_cash_home
    mov esi, msg_pay_counter
    call print_string
    jmp check_member_reward

app_cash_home:
    mov esi, msg_pay_delivery
    call print_string
    jmp check_member_reward

; ==========================================
; REWARDS & FINALIZE
; ==========================================
check_member_reward:
    cmp dword [is_member], 1
    jne end_transaction

reward_points:
    mov eax, [total_cost]
    xor edx, edx
    mov ecx, 5
    div ecx                
    imul eax, eax, 50      
    add [member_pts], eax  

    mov esi, msg_pts_awarded
    call print_string
    call print_int         

    mov esi, msg_pts_earned
    call print_string
    mov eax, [member_pts]
    call print_int
    
    ; Save updated points back to specific member account
    call save_member_pts

end_transaction:
    mov esi, msg_nl
    call print_string
    
    cmp dword [sys_mode], 3
    je finalize_order
    jmp next_customer 

finalize_order:
    mov esi, msg_order_success
    call print_string
    jmp _start

; --- Helper to save points ---
save_member_pts:
    mov eax, [member_pts]
    cmp dword [active_mem_id], 1
    je .save1
    cmp dword [active_mem_id], 2
    je .save2
    ret
.save1:
    mov [mem1_saved], eax
    ret
.save2:
    mov [mem2_saved], eax
    ret

; ==========================================
; EXIT ROUTINE
; ==========================================
exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80

; ==========================================
; SUBROUTINES (I/O)
; ==========================================
print_string:
    pusha
    mov eax, esi
    xor ecx, ecx
.len_loop:
    cmp byte [eax], 0
    je .len_done
    inc eax
    inc ecx
    jmp .len_loop
.len_done:
    mov edx, ecx
    mov ecx, esi
    mov eax, 4
    mov ebx, 1
    int 0x80
    popa
    ret

read_int:
    push ebx
    push ecx
    push edx
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buf
    mov edx, 16
    int 0x80
    
    xor eax, eax
    xor ebx, ebx
    mov esi, input_buf
    mov ecx, 0             

.parse_loop:
    mov bl, [esi]
    cmp bl, 10
    je .done_check
    cmp bl, '0'
    jl .invalid_input
    cmp bl, '9'
    jg .invalid_input
    
    mov ecx, 1             
    sub bl, '0'
    imul eax, eax, 10
    add eax, ebx
    inc esi
    jmp .parse_loop

.done_check:
    cmp ecx, 0             
    je .invalid_input
    jmp .exit_read

.invalid_input:
    mov eax, -1            

.exit_read:
    pop edx
    pop ecx
    pop ebx
    ret

print_int:
    pusha
    mov ecx, 10
    mov edi, num_buf + 15
    mov byte [edi], 0
    mov ebx, 0

    test eax, eax
    jnz .convert_loop
    dec edi
    mov byte [edi], '0'
    inc ebx
    jmp .print
.convert_loop:
    xor edx, edx
    div ecx
    add dl, '0'
    dec edi
    mov [edi], dl
    inc ebx
    test eax, eax
    jnz .convert_loop
.print:
    mov eax, 4
    mov ecx, edi
    mov edx, ebx
    mov ebx, 1
    int 0x80
    popa
    ret