format binary as 'img'

SCREEN_X = 512
SCREEN_Y = 512
BITS_PER_PIXEL = 32

org $8000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   NO INTRUCTIONS ABOVE THIS LINE!!!   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mov sp, $8000
b main

MAIL_TAGS   =    $8 ; Mailbox Channel 8: Tags (ARM to VC)
MAIL_READ   =    $0 ; Mailbox Read Register
MAIL_WRITE  =   $20 ; Mailbox Write Register
MAIL_BASE   = $B880 ; Mailbox Base Address

PERIPHERAL_BASE =  $3F000000 ; Peripheral Base Address
GPIO_BASE       =  $200000 ; GPIO Base Address
GPIO_FSEL0_OUT  =  $1 ; GPIO Function Select: GPIO Pin X0 Is An Output
GPIO_FSEL1_OUT  =  $8 ; GPIO Function Select: GPIO Pin X1 Is An Output
GPIO_GPFSEL1    =  $4 ; GPIO Function Select 1
GPIO_GPSET0     =  $1C ; GPIO Pin Output Set 0
GPIO_GPCLR0     =  $28 ; GPIO Pin Output Clear 0
GPIO_GPLEV0     =  $34 ; GPIO Pin Level 0


Set_Physical_Display  = $00048003 ; Frame Buffer: Set Physical (Display) Width/Height (Response: Width In Pixels, Height In Pixels)
Set_Virtual_Buffer    = $00048004 ; Frame Buffer: Set Virtual (Buffer) Width/Height (Response: Width In Pixels, Height In Pixels)
Set_Depth             = $00048005 ; Frame Buffer: Set Depth (Response: Bits Per Pixel)
Set_Virtual_Offset    = $00048009 ; Frame Buffer: Set Virtual Offset (Response: X In Pixels, Y In Pixels)
Set_Palette           = $0004800B ; Frame Buffer: Set Palette (Response: RGBA Palette Values (Index 0 To 255))
Allocate_Buffer       = $00040001 ; Frame Buffer: Allocate Buffer (Response: Frame Buffer Base Address In Bytes, Frame Buffer Size In Bytes)

include 'macros.inc'
;include 'rpi.inc'
include 'framebuffer.asm'
include 'gpio.asm'
include 'system.asm'
include 'rand.asm'
include 'sin.asm'

macro wait_busy amount {
    local .wait_loop_local
    m32 r12, amount
    .wait_loop_local:
        subs r12, #1
        bne .wait_loop_local
}

JOY_R      = 0000000000010000b
JOY_L      = 0000000000100000b
JOY_X      = 0000000001000000b
JOY_A      = 0000000010000000b
JOY_RIGHT  = 0000000100000000b
JOY_LEFT   = 0000001000000000b
JOY_DOWN   = 0000010000000000b
JOY_UP     = 0000100000000000b
JOY_START  = 0001000000000000b
JOY_SELECT = 0010000000000000b
JOY_Y      = 0100000000000000b
JOY_B      = 1000000000000000b

INPUT:
    dw 0

main:
; Set GPIO 10 & 11 (Clock & Latch) Function To Output
m32 r0,PERIPHERAL_BASE + GPIO_BASE
mov r1,GPIO_FSEL0_OUT + GPIO_FSEL1_OUT
str r1,[r0,GPIO_GPFSEL1]

bl init_framebuffer
mov r8, r0

; Enable output to LEDs
mov r0, LED_RED
mov r1, GPIO_FSEL0_OUT
bl set_gpio_function

mov r0, LED_GREEN
mov r1, GPIO_FSEL0_OUT
bl set_gpio_function

mov r0, LED_GREEN
mov r1, #1
bl set_gpio

mov r6, $FF
mov r7, $FF

; Setup asteroids
m32 r2, ASTEROIDS
mov r1, #256
str r1, [r2, #0] ; x
mov r1, #256
str r1, [r2, #4] ; y
mov r1, #12000
str r1, [r2, #8] ; z

mov r1, #8000
str r1, [r2, #48] ; z
mov r1, #6000
str r1, [r2, #88] ; z
mov r1, #10000
str r1, [r2, #128] ; z

bl setup_stars

loop:
;;; Update Input
;;; Input is a (lightly) modified version of Peter Lemon's bare metal raspberry pi project
m32 r0,PERIPHERAL_BASE + GPIO_BASE 

mov r1,GPIO_11
str r1,[r0,GPIO_GPSET0] ; Set (Latch) HIGH
wait_busy 32
str r1,[r0,GPIO_GPCLR0] ; Set (Latch) LOW
wait_busy 32

mov r1,0  ; R1 = Input Data
mov r2,15 ; R2 = Input Data Count

LoopInputData:
ldr r3,[r0,GPIO_GPLEV0] ; Get (Data)
tst r3,GPIO_4
moveq r3,1 ; (Data) LOW
orreq r1,r3,lsl r2

mov r3,GPIO_10
str r3,[r0,GPIO_GPSET0]; Set (Clock) HIGH
wait_busy 32
str r3,[r0,GPIO_GPCLR0]; Set (Clock) LOW
wait_busy 32

subs r2,1
bge LoopInputData ; Loop 16bit Data
m32 r0, INPUT
str r1, [r0]
;;; End Update input

mov r3, #0    ; moved this frame flag
push {r6, r7} ; popped in clear line
tst r1, JOY_RIGHT
addne r6, #10
movne r3, #1
tst r1, JOY_LEFT
subne r6, #10
movne r3, #1

tst r1, JOY_DOWN
addne r7, #10
movne r3, #1
tst r1, JOY_UP
subne r7, #10
movne r3, #1
push {r3} ; moved this frame saved for later

tst r1, JOY_Y
beq skip_bullet_check$
    push{r4, r5, r9, r10}
    m32 r4, SCREEN_X
    m32 r5, SCREEN_Y
    lsr r4, #1
    lsr r5, #1
    m32 r9, ASTEROIDS

    mov r0, #1
    push{r0}
    mov r0, #0
    push{r0}
    push{r0}
    push{r0}

    detect_collide_one_asteroid$:
    ldr r0, [r9, #0] ; x mesh center
    lsl r0, #8       ; * 128 focal distance
    ldr r1, [r9, #8]
    bl div           ; x/z
    add r0, r4       ; + screenwidth/2
    push{r0}

    ldr r0, [r9, #4] ; y mesh center
    lsl r0, #8       ; * 128 focal distance
    ldr r1, [r9, #8]
    bl div           ; y/z
    add r0, r5       ; + screenheight/2
    push{r0}

    mov r0, r6
    mov r1, r7
    pop{r3}
    pop{r2}
    ; debug draw line
    ; push{r0, r1, r2, r3, r4}
    ; m32 r4, Plot_Line_Data
    ; str r0, [r4, #0]
    ; str r1, [r4, #4]
    ; str r2, [r4, #8]
    ; str r3, [r4, #12]
    ; mov r0, r8
    ; bl plot_line
    ; pop {r0, r1, r2, r3, r4}
    bl distance_squared
    push{r0}

    ldr r0, [r9, #12] ; w
    lsl r0, #8        ; * 128 focal distance
    ldr r1, [r9, #8]
    bl div            ; w/z
    mul r0, r0
    pop {r1}
    cmp r0, r1

    blt no_collision$

    ; clear old asteroid
    m32 r2, DRAW_COLOR
    mov r1, $0
    str r1, [r2]
    mov r0, r8
    bl draw_asteroids

    ; halve the asteroid's width
    ldr r0, [r9, #12]
    lsr r0, #1
    str r0, [r9, #12]
    cmp r0, $70
    bgt no_collision$ ; don't re-randomize if it still has HP

    ; re-randomize the asteroid
    bl rand
    mov r1, r0
    lsr r1, #1
    str r1, [r9, #0] ; x
    bl rand
    mov r1, r0
    lsr r1, #1
    str r1, [r9, #4] ; y
    mov r1, #8000
    str r1, [r9, #8] ; z
    mov r1, ASTEROID_START_WIDTH
    str r1, [r9, #12] ; z
    ;rand rot
    bl rand
    and r0, $10
    sub r0, $8
    str r0, [r9, #20]
    bl rand
    and r0, $10
    sub r0, $8
    str r0, [r9, #28]
    bl rand
    and r0, $10
    sub r0, $8
    str r0, [r9, #36]

    no_collision$:
    add r9, #40
    pop{r0}
    cmp r0, #0
    beq detect_collide_one_asteroid$

    pop {r4, r5, r9, r10}

skip_bullet_check$:

m32 r0, DRAW_COLOR
m32 r1, $FF0000
str r1, [r0]

mov r0, r8      ; framebuffer

; clear asteroids
m32 r2, DRAW_COLOR
mov r1, #0
str r1, [r2]
bl draw_asteroids

; update asteroids
m32 r2, ASTEROIDS
mov r3, #1
push{r3}
mov r3, #0
push{r3}
push{r3}
push{r3}

update_one_asteroid$:
; update rotation
ldr r1, [r2, #16]
ldr r3, [r2, #20]
add r1, r3
cmp r3, #0
bgt positive_rotation1$
cmp r1, #0
addlt r1, #360
b store_asteroid_rotation1$
positive_rotation1$:
cmp r1, #360
subge r1, #360
store_asteroid_rotation1$:
str r1, [r2, #16]

ldr r1, [r2, #24]
ldr r3, [r2, #28]
add r1, r3
cmp r3, #0
bgt positive_rotation2$
cmp r1, #0
addlt r1, #360
b store_asteroid_rotation2$
positive_rotation2$:
cmp r1, #360
subge r1, #360
store_asteroid_rotation2$:
str r1, [r2, #24]

ldr r1, [r2, #32]
ldr r3, [r2, #36]
add r1, r3
cmp r3, #0
bgt positive_rotation3$
cmp r1, #0
addlt r1, #360
b store_asteroid_rotation3$
positive_rotation3$:
cmp r1, #360
subge r1, #360
store_asteroid_rotation3$:
str r1, [r2, #32]

; move forwards
ldr r1, [r2, #8]
sub r1, #32
str r1, [r2, #8]
cmp r1, #512

bgt no_death$

m32 r2, DRAW_COLOR
mov r1, $FF
str r1, [r2]
bl draw_asteroids

death_loop$:
bl update_stars
m32 r2, DRAW_COLOR
m32 r1, $ffffff
str r1, [r2]
mov r0, r8
bl draw_stars
b death_loop$

push{r0}

no_death$:

add r2, #40
pop {r3}
cmp r3, #0
beq update_one_asteroid$

;draw asteroids
m32 r2, DRAW_COLOR
mov r1, $00FF00
str r1, [r2]
bl draw_asteroids

m32 r2, DRAW_COLOR
mov r1, $0
str r1, [r2]
mov r0, r8
bl draw_stars

bl update_stars

m32 r2, DRAW_COLOR
m32 r1, $ffffff
str r1, [r2]
mov r0, r8
bl draw_stars

pop {r3}
pop {r4, r5}
cmp r3, #0
beq skip_clear_crosshair$ ; Don't clear lines if we haven't moved
push{r6, r7}
mov r6, r4
mov r7, r5
; Clear over old line
m32 r0, DRAW_COLOR
mov r1, #0
str r1, [r0]
bl draw_cross_hair
pop {r6, r7}

skip_clear_crosshair$:
; Draw crosshair
m32 r2, DRAW_COLOR
m32 r1, $ffffff
str r1, [r2]
mov r0, r8
bl draw_cross_hair

skip_drawing_lines$:

; bl draw_bullet

mov r0, $8000
;bl wait

b loop;;;;;;;;;;;;;;;;;;;;;;; END MAIN LOOP

draw_cross_hair:
    push{lr}
    m32 r0, Plot_Line_Data
    sub r1, r6, #32
    str r1, [r0, #0] ; x1
    sub r1, r7, #32
    str r1, [r0, #4] ; y1
    sub r1, r6, #16
    str r1, [r0, #8] ; x2
    sub r1, r7, #16
    str r1, [r0, #12]; y2
    mov r0, r8
    bl plot_line

    m32 r0, Plot_Line_Data
    add r1, r6, #32
    str r1, [r0, #0] ; x1
    sub r1, r7, #32
    str r1, [r0, #4] ; y1
    add r1, r6, #16
    str r1, [r0, #8] ; x2
    sub r1, r7, #16
    str r1, [r0, #12]; y2
    mov r0, r8
    bl plot_line

    m32 r0, Plot_Line_Data
    sub r1, r6, #32
    str r1, [r0, #0] ; x1
    add r1, r7, #32
    str r1, [r0, #4] ; y1
    sub r1, r6, #16
    str r1, [r0, #8] ; x2
    add r1, r7, #16
    str r1, [r0, #12]; y2
    mov r0, r8
    bl plot_line

    m32 r0, Plot_Line_Data
    add r1, r6, #32
    str r1, [r0, #0] ; x1
    add r1, r7, #32
    str r1, [r0, #4] ; y1
    add r1, r6, #16
    str r1, [r0, #8] ; x2
    add r1, r7, #16
    str r1, [r0, #12]; y2
    mov r0, r8
    bl plot_line

    pop {pc}

POINT_BOX_COLLISION_DATA:
    ;  0, 4, 8,12,16
    ; px py bx by bw
    dw 0, 0, 0, 0, 0
point_box_collision:
    push{lr, r4, r5, r6, r7, r8, r9}
    mov r0, #0
    m32 r4, POINT_BOX_COLLISION_DATA
    ldr r5, [r4, #0 ] ; px
    ldr r6, [r4, #4 ] ; py
    ldr r7, [r4, #8 ] ; bx
    ldr r8, [r4, #12] ; by
    ldr r9, [r4, #16] ; bw
    lsr r9, #1

    sub r7, r9
    cmp r5, r7 ; px < bx-w
    blt point_box_return$
    add r7, r9
    add r7, r9
    cmp r5, r7 ; px > bx+w
    bgt point_box_return$

    sub r8, r9
    cmp r6, r8 ; py < by-w
    blt point_box_return$
    add r8, r9
    add r8, r9
    cmp r6, r8 ; py > by+w
    bgt point_box_return$

    mov r0, #1
point_box_return$:
    pop {pc, r4, r5, r6, r7, r8, r9}

;(x1,y1,x2,y2)->(distance_squared)
distance_squared:
    sub r0, r2
    sub r1, r3
    mul r0, r0
    mul r1, r1
    add r0, r1
    bx lr

ASTEROID_START_WIDTH = $1F0
TEMP: dw 0
ASTEROIDS:
    ;  0  4  8   12  16   20 24  28 32  36
    ;  x, y, z,   w, rx, drx ry dry rz drz
    dw 0, 0, 0, ASTEROID_START_WIDTH,  0,   4, 0,  6, 0, -8
    dw 0, 0, 0, ASTEROID_START_WIDTH,  0,   4, 0,  6, 0, -8
    dw 0, 0, 0, ASTEROID_START_WIDTH,  0,   4, 0,  6, 0, -8
    dw 0, 0, 0, ASTEROID_START_WIDTH,  0,   4, 0,  6, 0, -8
draw_asteroids:
    push{lr, r4, r5, r6, r7, r8, r9, r10, r11, r12}

    mov r4, #1
    push{r4}
    mov r4, #0
    push{r4}
    push{r4}
    push{r4}

    ; halfwidth = z/2
    m32 r11, ASTEROIDS  ; r11 = asteroid data

    m32 r4, SCREEN_X
    lsr r4, #1         ; r4 = half screen width
    m32 r9, SCREEN_Y
    lsr r9, #1

    m32 r8, Plot_Quad_Data ; r8 = Plot_Quad_Data

    draw_one_asteroid$:
    ldr r10,[r11, #8 ]  ; r10 = zdepth
    ; change draw color based on distance
    ; push{r0, r1, r2}
    ; m32 r5, DRAW_COLOR
    ; ldr r6, [r5]
    ; mov r0, $FF0000
    ; mov r1, r10
    ; bl div
    ; lsr r0, #7
    ; cmp r6, #0
    ; and r6, $FF00
    ; addne r6, r0
    ; str r6, [r5]
    ; pop {r0, r1, r2}

    ldr r5, [r11, #12]
    lsr r5, #1          ; r5 = halfwidth

    ldr r6, [r11, #0]   ; r6, r7 = x, y
    ldr r7, [r11, #4]

    mov r12, #0
    draw_ast_quad$:
    push{r0, r1, r2}

    push{r5}
    push{r5}
    push{r5}
    push{r5}
    cmp r12, #0
    negne r5

    ; vert 0
    rsb r0, r5, #0
    mov r1, r0
    pop{r2}
    ldr r3, [r11, #32]
    bl rotx
    ldr r3, [r11, #24]
    bl roty
    ldr r3, [r11, #16]
    bl rotz

    push{r1, r2}
    ;project x to screen
    add r0, r6       ; + x mesh center
    lsl r0, #8       ; * 128 focal distance
    add r1, r2, r10  ; + zdepth
    bl div           ; x/z
    add r0, r4       ; + screenwidth/2
    str r0, [r8, #0] ; store final x

    pop {r1, r2}
    ;project y to screen
    mov r0, r1
    add r0, r7
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r9
    str r0, [r8, #4] ; store final y

    ; vert 1
    mov r0, r5
    rsb r1, r5, #0
    pop{r2}
    ldr r3, [r11, #32]
    bl rotx
    ldr r3, [r11, #24]
    bl roty
    ldr r3, [r11, #16]
    bl rotz

    push{r1, r2}
    ;project x to screen
    add r0, r6
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r4
    str r0, [r8, #8] ; store final x

    pop {r1, r2}
    ;project y to screen
    mov r0, r1
    add r0, r7
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r9
    str r0, [r8, #12] ; store final y

    ; vert 2
    mov r0, r5
    mov r1, r0
    pop{r2}
    ldr r3, [r11, #32]
    bl rotx
    ldr r3, [r11, #24]
    bl roty
    ldr r3, [r11, #16]
    bl rotz

    push{r1, r2}
    ;project x to screen
    add r0, r6
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r4
    str r0, [r8, #16] ; store final x

    pop {r1, r2}
    ;project y to screen
    mov r0, r1
    add r0, r7
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r9
    str r0, [r8, #20] ; store final y

    ; vert 3
    rsb r0, r5, #0
    mov r1, r5
    pop{r2}
    ldr r3, [r11, #32]
    bl rotx
    ldr r3, [r11, #24]
    bl roty
    ldr r3, [r11, #16]
    bl rotz

    push{r1, r2}
    ;project x to screen
    add r0, r6
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r4
    str r0, [r8, #24] ; store final x

    pop {r1, r2}
    ;project y to screen
    mov r0, r1
    add r0, r7
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r9
    str r0, [r8, #28] ; store final y

    pop {r0, r1, r2}
    bl plot_quad
    cmp r12, #0
    mov r12, #1
    neg r5
    beq draw_ast_quad$

    mov r12, #0
    draw_ast_quad2$:
    push{r0, r1, r2}

    push{r5}
    neg r5
    push{r5}
    push{r5}
    neg r5
    push{r5}

    ; vert 0
    rsb r0, r5, #0
    mov r1, r0
    pop{r2}
    ldr r3, [r11, #32]
    bl rotx
    ldr r3, [r11, #24]
    bl roty
    ldr r3, [r11, #16]
    bl rotz

    push{r1, r2}
    ;project x to screen
    add r0, r6
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r4
    str r0, [r8, #0] ; store final x

    pop {r1, r2}
    ;project y to screen
    mov r0, r1
    add r0, r7
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r9
    str r0, [r8, #4] ; store final y

    ; vert 1
    rsb r0, r5, #0
    mov r1, r0
    pop{r2}
    ldr r3, [r11, #32]
    bl rotx
    ldr r3, [r11, #24]
    bl roty
    ldr r3, [r11, #16]
    bl rotz

    push{r1, r2}
    ;project x to screen
    add r0, r6
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r4
    str r0, [r8, #8] ; store final x

    pop {r1, r2}
    ;project y to screen
    mov r0, r1
    add r0, r7
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r9
    str r0, [r8, #12] ; store final y

    ; vert 2
    rsb r0, r5, #0
    mov r1, r5
    pop{r2}
    ldr r3, [r11, #32]
    bl rotx
    ldr r3, [r11, #24]
    bl roty
    ldr r3, [r11, #16]
    bl rotz

    push{r1, r2}
    ;project x to screen
    add r0, r6
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r4
    str r0, [r8, #16] ; store final x

    pop {r1, r2}
    ;project y to screen
    mov r0, r1
    add r0, r7
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r9
    str r0, [r8, #20] ; store final y

    ; vert 3
    rsb r0, r5, #0
    mov r1, r5
    pop{r2}
    ldr r3, [r11, #32]
    bl rotx
    ldr r3, [r11, #24]
    bl roty
    ldr r3, [r11, #16]
    bl rotz

    push{r1, r2}
    ;project x to screen
    add r0, r6
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r4
    str r0, [r8, #24] ; store final x

    pop {r1, r2}
    ;project y to screen
    mov r0, r1
    add r0, r7
    lsl r0, #8
    add r1, r2, r10
    bl div
    add r0, r9
    str r0, [r8, #28] ; store final y

    pop {r0, r1, r2}
    bl plot_quad
    cmp r12, #0
    mov r12, #1
    neg r5
    beq draw_ast_quad2$

    ; advance to next asteroid
    add r11, #40
    pop{r12}
    cmp r12, #0
    beq draw_one_asteroid$

    pop {pc, r4, r5, r6, r7, r8, r9, r10, r11, r12}

Draw_Bullet_Data:
    dw 0
draw_bullet:
    push{lr, r4, r5}
    m32 r4, Draw_Bullet_Data
    ldr r4, [r4]
    cmp r4, #0
    beq return_from_draw_bullet$
    
    m32 r4, Plot_Quad_Data

    ; vert 0
    mov r5, #5
    str r5, [r4, #0]
    mov r5, #64
    str r5, [r4, #4]

    ; vert 1
    mov r5, #64
    str r5, [r4, #8]
    mov r5, #32
    str r5, [r4, #12]

    ; vert 2
    mov r5, #64
    str r5, [r4, #16]
    mov r5, #128
    str r5, [r4, #20]

    ; vert 3
    mov r5, #5
    str r5, [r4, #24]
    mov r5, #128
    str r5, [r4, #28]

    bl plot_quad

return_from_draw_bullet$:
    pop {pc, r4, r5}

; in {r0: framebuffer
;     r1: color}
clear_screen:
mov r4, r0
mov r1, SCREEN_Y
mov r2, r1
draw_row$:
    mov r0, SCREEN_X
    draw_pixel$:
        rept 64 {
            str r2, [r4]
            add r4, #4
        }
        sub r0, $40
        teq r0, #0
        bne draw_pixel$
    sub r1, #1
    teq r1, #0
    bne draw_row$
    bx lr

DRAW_COLOR:
    dw 0
; (const fb, x, y, const SCREEN_X)
plot:
    cmp r1, 0
    bxlt lr
    cmp r1, r3
    bxge lr

    cmp r2, 0
    bxlt lr
    push{r4}
        m32 r4, SCREEN_Y
        cmp r2, r4
    pop {r4}
    bxge lr

    mul r2, r3
    add r1, r2
    lsl r1, #2
    add r1, r0
    m32 r2, DRAW_COLOR
    ldr r2, [r2]
    str r2, [r1]
    bx lr

Plot_Quad_Data:
    dw 0, 0, 0, 0
    dw 0, 0, 0, 0

plot_quad:
    push {lr, r4, r5}
    
    m32 r4, Plot_Line_Data
    m32 r5, Plot_Quad_Data

    ldr r1, [r5, #0]
    str r1, [r4, #0] ; x1
    ldr r1, [r5, #4]
    str r1, [r4, #4] ; y1
    ldr r1, [r5, #8]
    str r1, [r4, #8] ; x2
    ldr r1, [r5, #12]
    str r1, [r4, #12]; y2
    bl plot_line

    ldr r1, [r5, #8]
    str r1, [r4, #0] ; x1
    ldr r1, [r5, #12]
    str r1, [r4, #4] ; y1
    ldr r1, [r5, #16]
    str r1, [r4, #8] ; x2
    ldr r1, [r5, #20]
    str r1, [r4, #12]; y2
    bl plot_line

    ldr r1, [r5, #16]
    str r1, [r4, #0] ; x1
    ldr r1, [r5, #20]
    str r1, [r4, #4] ; y1
    ldr r1, [r5, #24]
    str r1, [r4, #8] ; x2
    ldr r1, [r5, #28]
    str r1, [r4, #12]; y2
    bl plot_line

    ldr r1, [r5, #24]
    str r1, [r4, #0] ; x1
    ldr r1, [r5, #28]
    str r1, [r4, #4] ; y1
    ldr r1, [r5, #0]
    str r1, [r4, #8] ; x2
    ldr r1, [r5, #4]
    str r1, [r4, #12]; y2
    bl plot_line

    pop  {pc, r4, r5}

; X0, Y0, X1, Y1
Plot_Line_Data:
    dw 0, 0, 0, 0
; plot line using Bresenham's line algorithm
; (frame_buffer) -> ()
plot_line:
    push{lr, r4, r5, r6, r7, r8, r9, r10, r11, r12}
    mov r1, Plot_Line_Data
    ldr r4, [r1, #0] ; x0
    ldr r5, [r1, #4] ; y0
    ldr r6, [r1, #8] ; x1
    ldr r7, [r1, #12]; y1

    ; int dx = abs(x1-x0), sx = x0<x1 ? 1 : -1;
    rsb r8, r4, r6   ; r8 = x1-x0
    cmp r8, #0       ; r8 = abs(x1 - x0)
    rsblt r8, r8, #0 ; r8 = dx

    cmp r4, r6 ; x0<x1 ?
    bge plot_line_1$
    mov r9, #1
    b plot_line_2$
plot_line_1$:
    mov r9, #0       ; r9 = sx
plot_line_2$:

    ; int dy = abs(y1-y0), sy = y0<y1 ? 1 : -1; 
    rsb r10, r5, r7    ; r10 = y1-y0
    cmp r10, #0        ; r10 = abs(y1 - y0)
    rsblt r10, r10, #0 ; r10 = dy

    cmp r5, r7         ; y0<y1 ?
    bge plot_line_3$
    mov r11, #1
    b plot_line_4$
plot_line_3$:
    mov r11, #0        ; r11 = sy
plot_line_4$:

    ; int err = (dx>dy ? dx : -dy)/2, e2;
    cmp r8, r10
    bgt plot_line_5$
    rsb r12, r10, #0     ; r12 = -dy
    b plot_line_6$

plot_line_5$:
    mov r12, r8          ; r12 = dx
plot_line_6$:
    push {r0}
    mov r0, r12, lsr #31 ; r12 = (dd)/2
    add r12, r0, r12
    mov r12, r12, asr #1
    pop {r0}             ; r12 = err

    mov r3, SCREEN_X
    ;for(;;){
plot_line_loop$:
    ;   setPixel(x0,y0);
        mov r1, r4
        mov r2, r5
        bl plot
    ;   if (x0==x1 && y0==y1) break;
        cmp r4, r6
        bne plot_line_7$
        cmp r5, r7
        beq plot_line_leaving$
        plot_line_7$:
    ;   e2 = err;
        mov r1, r12     ; r1 = err
        rsb r2, r8, #0  ; r2 = -dx
    ;   if (e2 >-dx)
        cmp r2, r1
        bge plot_line_8$
    ;       { err -= dy; x0 += sx; }
            sub r12, r10
            cmp r9, #0
            addne r4, #1
            subeq r4, #1
plot_line_8$:
    ;   if (e2 < dy) 
        cmp r1, r10
        bge plot_line_loop$
    ;       { err += dx; y0 += sy; }
            add r12, r8
            cmp r11, #0
            addne r5, #1
            subeq r5, #1
        b plot_line_loop$
    ;}
plot_line_leaving$:
    pop {pc, r4, r5, r6, r7, r8, r9, r10, r11, r12}


; in {r0:framebuffer
;     r1:x
;     r2:y
;     r3:w (must be a multiple of 32)
;     r4:h
;     r5:color}
draw_rect:
    push {r4, r5, r6, r7}
    m32 r7, SCREEN_X
    ; validate rectangle
    mov r6, r1
    add r6, r3
    cmp r6, r7
    subgt r6, r7
    subgt r3, r6
    ; fb += 4*(x + y*SCREEN_X)
    mul r2, r7 ; y*SCREEN_X
    add r1, r2 ; x + ...
    add r0, r1, lsl #2

    ; store pitch - width in r7
    sub r7, r3
    lsl r7, #2 ; 4*

    draw_rect_row$:
        mov r6, r3 ; r6 = w
        draw_rect_pixel$:
            rept 32 {
                str r5, [r0] ; store color in framebuffer
                add r0, #4
            }
            sub r6, $20
            teq r6, #0
            bne draw_rect_pixel$
        add r0, r7
        sub r4, #1
        teq r4, #0
        bne draw_rect_row$

    pop {r4, r5, r6, r7}
    mov pc, lr

; in {r0:framebuffer
;     r1:x
;     r2:y
;     r3:w (must be a multiple of 32)
;     r4:h
;     r5:color}
draw_tri:
    push {r4, r5, r6, r7}
    m32 r7, SCREEN_X
    ; validate rectangle
    mov r6, r1
    add r6, r3
    cmp r6, r7
    subgt r6, r7
    subgt r3, r6
    ; fb += 4*(x + y*SCREEN_X)
    mul r2, r7 ; y*SCREEN_X
    add r1, r2 ; x + ...
    add r0, r1, lsl #2

    ; store pitch - width in r7
    sub r7, r3
    lsl r7, #2 ; 4*

    draw_tri_row$:
        mov r6, r3 ; r6 = w
        draw_tri_pixel$:
            str r5, [r0] ; store color in framebuffer
            add r0, #4
            sub r6, $1
            teq r6, #0
            bne draw_tri_pixel$
        add r0, r7
        sub r4, #1
        add r7, #4
        sub r3, #1
        cmp r3, #0
        beq break_tri$
        teq r4, #0
        bne draw_tri_row$

    break_tri$:
    pop {r4, r5, r6, r7}
    mov pc, lr

draw_stars:
    push{lr, r4, r5, r6, r7, r8, r9, r10}
    m32 r8, STARS

    m32 r4, SCREEN_X
    lsr r4, #1         ; r4 = half screen width
    m32 r9, SCREEN_Y
    lsr r9, #1

    mov r5, r0

    rept 128 {
        ldr r6 ,[r8, #0] ; r6, r7 = x, y
        ldr r7 ,[r8, #4]
        ldr r10,[r8, #8] ; r10 = zdepth

        mov r0, r6
        lsl r0, #8
        mov r1, r10
        bl div
        add r0, r4
        mov r6, r0

        mov r0, r7
        lsl r0, #8
        mov r1, r10
        bl div
        add r0, r4
        mov r7, r0

        mov r0, r5
        mov r1, r6
        mov r2, r7
        m32 r3, SCREEN_X
        bl plot

        add r8, #12
    }
    pop {pc, r4, r5, r6, r7, r8, r9, r10}

update_stars:
    push{lr, r4, r5}
    m32 r4, STARS
    rept 128 {
        ldr r0, [r4, #8]
        sub r0, #16
        cmp r0, #16
        addlt r0, #4096
        str r0, [r4, #8]
        ; bllt shuffle_star

        add r4, #12
    }
    pop {pc, r4, r5}

shuffle_star:
    push{lr}
    bl rand_2048
    str r0, [r4, #0]
    bl rand_2048
    str r0, [r4, #4]
    pop{pc}

setup_stars:
    push{lr, r4, r5}
    m32 r4, STARS
    rept 128 {
        bl rand_2048
        str r0, [r4, #0]
        bl rand_2048
        str r0, [r4, #4]
        bl rand_2048
        lsl r0, #1
        cmp r0, #0
        negmi r0
        str r0, [r4, #8]
        add r4, #12
    }
    
    pop {pc, r4, r5}

STARS:
    rept 128 {
    dw 0, 0, 0
    }


; divide functions compiled from gcc
__udivmodsi4: ;(unsigned int, unsigned int):
	push	{r4, lr}
	sub	sp, sp, #8
	mov	r3, r0
	sub	r4, r1, #0
	beq	.L5
	mov	r2, #1
	cmp	r4, #0
	blt	.L10
.L12:
	lsl	r4, r4, #1
	lsl	r2, r2, #1
	cmp	r4, #0
	bge	.L12
	mov	r0, r2
	cmp	r2, #0
	beq	.L8
.L10:
	mov	r0, #0
	b	.L7
.L15:
	lsr	r4, r4, #1
.L7:
	cmp	r4, r3
	bhi	.L11
	sub	r3, r3, r4
	add	r0, r0, r2
.L11:
	lsr	r2, r2, #1
	cmp	r2, #0
	bne	.L15
.L8:
	add	sp, sp, #8
	pop	{r4, pc}
.L5:
        ERR 2, 2
div: ;__aeabi_idiv: ;(int, int):
	push	{r4, r5, lr}
	sub	sp, sp, #12
	mov	r4, r1
	cmp	r0, #0
	blt	.L30
	mov	r3, #1
	mov	r5, #0
	cmp	r4, #0
	blt	.L31
.L18:
	sub	r3, r4, #0
	beq	.L19
.L34:
	mov	r2, #1
.L23:
	lsl	r3, r3, #1
	lsl	r2, r2, #1
	cmp	r3, #0
	bge	.L23
	mov	r4, #0
	cmp	r2, #0
	bne	.L21
	b	.L35
.L33:
	lsr	r3, r3, #1
.L21:
	cmp	r0, r3
	bcc	.L25
	sub	r0, r0, r3
	add	r4, r4, r2
.L25:
	lsr	r2, r2, #1
	cmp	r2, #0
	bne	.L33
	mov	r0, r4
.L22:
	cmp	r5, #0
	beq	.L27
	neg	r0, r0
.L27:
	add	sp, sp, #12
	pop	{r4, r5, pc}
.L30:
	neg	r0, r0
	mov	r3, #0
	mov	r5, #1
	cmp	r4, #0
	bge	.L18
.L31:
	neg	r4, r4
	mov	r5, r3
	sub	r3, r4, #0
	bne	.L34
.L19:
        ERR 2, 2
.L35:
	mov	r0, r2
	b	.L22

