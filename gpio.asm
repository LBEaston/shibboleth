LED_RED = $23
LED_GREEN = $2F

; in  {gpio_pin_number, pin_val}
; out {}
set_gpio:
    cmp r0, #53
    movhi pc, lr

    push {lr}
    mov r2, r0 ; move pin_number to r2
    m32 r0, PERIPHERAL_BASE + GPIO_BASE

    lsr r3, r2, #5 ; pin_bank = pin_number/32
    lsl r3, #2 ; pin_bank *= 4

    add r0, r3

    ; calc bit to set
    and r2, #31 ; pin %= 32
    mov r3, #1
    lsl r3, r2

    ; if val=0 turn off, else turn on
    teq r1, #0
    streq r3, [r0, #40]
    strne r3, [r0, #28]

    pop {pc}

; in  {gpio_pin_number, pin_function}
; out {}
set_gpio_function:
    cmp   r0, #53
    movhi pc, lr

    push  {lr}
    mov   r2, r0
    m32 r0, PERIPHERAL_BASE + GPIO_BASE

    function_loop$:
        cmp r2, #9
        subhi r2, #10
        addhi r0, #4
        bhi function_loop$

    add r2, r2, lsl #1
    lsl r1, r2

    mov r3, #7 ; set mask to b111
    lsl r3, r2 ; shift mask to pin pos
    mvn r3, r3 ; flip mask

    ldr r2, [r0] ; load old function
    and r2, r3   ; mask out old function
    orr r1, r2   ; combine old and new functions

    str r1, [r0] ; store function
    ; mov pc, lr
    pop {pc} ; return

GPIO_0  =        $1 ; GPIO Pin 0: 0
GPIO_1  =        $2 ; GPIO Pin 0: 1
GPIO_2  =        $4 ; GPIO Pin 0: 2
GPIO_3  =        $8 ; GPIO Pin 0: 3
GPIO_4  =       $10 ; GPIO Pin 0: 4
GPIO_5  =       $20 ; GPIO Pin 0: 5
GPIO_6  =       $40 ; GPIO Pin 0: 6
GPIO_7  =       $80 ; GPIO Pin 0: 7
GPIO_8  =      $100 ; GPIO Pin 0: 8
GPIO_9  =      $200 ; GPIO Pin 0: 9
GPIO_10 =      $400 ; GPIO Pin 0: 10
GPIO_11 =      $800 ; GPIO Pin 0: 11
GPIO_12 =     $1000 ; GPIO Pin 0: 12
GPIO_13 =     $2000 ; GPIO Pin 0: 13
GPIO_14 =     $4000 ; GPIO Pin 0: 14
GPIO_15 =     $8000 ; GPIO Pin 0: 15
GPIO_16 =    $10000 ; GPIO Pin 0: 16
GPIO_17 =    $20000 ; GPIO Pin 0: 17
GPIO_18 =    $40000 ; GPIO Pin 0: 18
GPIO_19 =    $80000 ; GPIO Pin 0: 19
GPIO_20 =   $100000 ; GPIO Pin 0: 20
GPIO_21 =   $200000 ; GPIO Pin 0: 21
GPIO_22 =   $400000 ; GPIO Pin 0: 22
GPIO_23 =   $800000 ; GPIO Pin 0: 23
GPIO_24 =  $1000000 ; GPIO Pin 0: 24
GPIO_25 =  $2000000 ; GPIO Pin 0: 25
GPIO_26 =  $4000000 ; GPIO Pin 0: 26
GPIO_27 =  $8000000 ; GPIO Pin 0: 27
GPIO_28 = $10000000 ; GPIO Pin 0: 28
GPIO_29 = $20000000 ; GPIO Pin 0: 29
GPIO_30 = $40000000 ; GPIO Pin 0: 30
GPIO_31 = $80000000 ; GPIO Pin 0: 31
