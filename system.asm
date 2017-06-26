
macro SET_GPIO gpio, value {
    mov r0, gpio
    mov r1, value
    bl set_gpio
}

macro RED_LED_ON {
    SET_GPIO LED_RED, #1
}

macro RED_LED_OFF {
    SET_GPIO LED_RED, #0
}

macro GREEN_LED_ON {
    SET_GPIO LED_GREEN, #1
}

macro GREEN_LED_OFF {
    SET_GPIO LED_GREEN, #0
}

macro WAIT time {
    m32 r0, time
    bl wait
}

macro ERR RED, GREEN {
    m32 r0, RED
    m32 r1, GREEN
    bl error_state
}

; in: r0 = red blinks
;     r1 = green blinks
; never returns
error_state:
    push {r4, r5, r6, r7}
    mov r4, r0
    mov r5, r1

    err_loop_outer$:

    GREEN_LED_OFF
    FOR err_loop_red, r6, r4
        RED_LED_ON
        WAIT $40000
        RED_LED_OFF
        WAIT $40000
    FOR_END err_loop_red, r6

    WAIT $80000
    
    RED_LED_OFF
    FOR err_loop_green, r7, r5
        GREEN_LED_ON
        WAIT $40000
        GREEN_LED_OFF
        WAIT $40000
    FOR_END err_loop_green, r7

    WAIT $80000
b err_loop_outer$

; in {time to wait in microseconds}
; out {}
wait:
    ; r0 time to wait
    ; r1 time left
    ; r2 start timer
    ; r3 timer memory location
    ; r4 current time (small bits)
    ; r5 current time (big bits)

    ; TODO: Add Timer offset($3000) to rpi.inc
    m32 r3, PERIPHERAL_BASE + $3000
    push {r4, r5}
    ldrd r4,r5, [r3, #4]
    mov r2, r4
    wait_loop$:
        ldrd r4,r5, [r3, #4]
        sub r1, r4,r2
        cmp r1, r0
        bls wait_loop$
    pop {r4, r5}
    mov pc, lr
