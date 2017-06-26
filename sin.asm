rotz: ;(int, int, int, int):
    push	{r4, r5, r6, r7, r8, lr}
    sub	sp, sp, #16
    mov	r7, r0
    mov	r0, r3
    mov	r5, r1
    mov	r8, r2
    mov	r6, r3
    bl	cos
    mov	r4, r0
    mov	r0, r6
    bl	sin
    mov	r3, r5
    mov	r2, r7
    mul	r2, r4
    mul	r4, r5
    mul	r3, r0
    mul	r7, r0
    sub	r3, r2, r3
    asr r3, #9
    str	r3, [sp, #12]
    add	r0, r4, r7
    mov	r3, r8
    asr r0, #9
    str	r0, [sp, #8]
    str	r3, [sp, #4]
    ldr r0, [sp, #12]
    ldr r1, [sp,  #8]
    ldr r2, [sp,  #4]
    add	sp, sp, #16
    pop	{r4, r5, r6, r7, r8, pc}
roty: ;(int, int, int, int):
    push	{r4, r5, r6, r7, r8, lr}
    sub	sp, sp, #16
    mov	r7, r0
    mov	r0, r3
    mov	r5, r2
    mov	r6, r3
    mov	r8, r1
    bl	cos
    mov	r4, r0
    mov	r0, r6
    bl	sin
    mov	r2, r5
    mov	r3, r7
    mul	r3, r4
    mul	r4, r5
    mul	r2, r0
    mul	r7, r0
    add	r3, r2, r3
    asr r3, #9
    str	r3, [sp, #12]
    sub	r0, r4, r7
    mov	r3, r8
    str	r3, [sp, #8]
    asr r0, #9
    str	r0, [sp, #4]
    ldr r0, [sp, #12]
    ldr r1, [sp,  #8]
    ldr r2, [sp,  #4]
    add	sp, sp, #16
    pop	{r4, r5, r6, r7, r8, pc}
rotx: ;(int, int, int, int):
    push	{r4, r5, r6, r7, lr}
    sub	sp, sp, #20
    mov	r5, r2
    str	r0, [sp, #12]
    mov	r0, r3
    mov	r6, r3
    mov	r7, r1
    bl	cos
    mov	r4, r0
    mov	r0, r6
    bl	sin
    mov	r3, r5
    mov	r2, r7
    mul	r2, r4
    mul	r4, r5
    mul	r7, r0
    mul	r3, r0
    add	r0, r4, r7
    sub	r3, r2, r3
    asr r3, #9
    str	r3, [sp, #8]
    asr r0, #9
    str	r0, [sp, #4]
    ldr r0, [sp, #12]
    ldr r1, [sp,  #8]
    ldr r2, [sp,  #4]
    add	sp, sp, #20
    pop	{r4, r5, r6, r7, pc}

; x' = x cos f - y sin f
;(x, y, f)->(x')
rotate_x:
    push{lr, r4, r5}

    push{r0}   ; backup x
    mov r0, r2 ; r0 = f
    bl cos     ; cos(f)
    mov r4, r0 ; r4 = cos(f)
    pop{r0}    ; reget x
    mul r4, r0 ; r4 = x*cos(f)
    
    mov r0, r2 ; r0 = f
    bl sin     ; sin(f)
    mov r5, r0 ; r5 = sin(f)
    mul r5, r1 ; r5 = y*sin(f)

    sub r0, r4, r5 ; r0 = x*cos(f) - y*sin(f)

    asr r0, #9 ; x/=512
    pop {pc, r4, r5}

; y' = y cos f + x sin f
;(y, x, f)->(y')
rotate_y:
    push{lr, r4, r5}

    push{r0}   ; backup y
    mov r0, r2 ; r0 = f
    bl cos     ; cos(f)
    mov r4, r0 ; r4 = cos(f)
    pop{r0}    ; reget y
    mul r4, r0 ; r4 = y*cos(f)
    
    mov r0, r2 ; r0 = f
    bl sin     ; sin(f)
    mov r5, r0 ; r5 = sin(f)
    mul r5, r1 ; r5 = x*sin(f)

    add r0, r4, r5 ; r0 = y*cos(f) + x*sin(f)

    asr r0, #9 ; x/=512
    pop {pc, r4, r5}

;(degrees)->(sin(degrees)*512)
sin:
    push{lr, r4}
    cmp r0, #0
    blt sinlow
    cmp r0, #360
    bge sinhi
    m32 r4, SIN_LOOKUP
    add r4, r0, lsl #2
    ldr r0, [r4]
    pop {pc, r4}

cos:
    push{lr, r4}
    cmp r0, #0
    blt coslow
    cmp r0, #360
    bge coshi
    cmp r0, #272
    addlt r0, #88
    subge r0, #272
    m32 r4, SIN_LOOKUP
    add r4, r0, lsl #2
    ldr r0, [r4]
    pop {pc, r4}

sinlow: ERR 1, 1
sinhi : ERR 1, 2
coslow: ERR 1, 3
coshi : ERR 1, 4
SIN_LOOKUP: dw 0,8,17,26,35,44,53,62,71,80,88,97,106,115,123,132,141,149,158,166,175,183,191,200,208,216,224,232,240,248,255,263,271,278,286,293,300,308,315,322,329,335,342,349,355,362,368,374,380,386,392,397,403,408,414,419,424,429,434,438,443,447,452,456,460,464,467,471,474,477,481,484,486,489,492,494,496,498,500,502,504,505,507,508,509,510,510,511,511,511,511,511,511,511,510,510,509,508,507,505,504,502,500,498,496,494,492,489,486,484,481,477,474,471,467,464,460,456,452,447,443,438,434,429,424,419,414,408,403,397,392,386,380,374,368,362,355,349,342,335,329,322,315,308,300,293,286,278,271,263,256,248,240,232,224,216,208,200,191,183,175,166,158,149,141,132,123,115,106,97,88,80,71,62,53,44,35,26,17,8,0,-8,-17,-26,-35,-44,-53,-62,-71,-80,-88,-97,-106,-115,-123,-132,-141,-149,-158,-166,-175,-183,-191,-200,-208,-216,-224,-232,-240,-248,-255,-263,-271,-278,-286,-293,-300,-308,-315,-322,-329,-335,-342,-349,-355,-362,-368,-374,-380,-386,-392,-397,-403,-408,-414,-419,-424,-429,-434,-438,-443,-447,-452,-456,-460,-464,-467,-471,-474,-477,-481,-484,-486,-489,-492,-494,-496,-498,-500,-502,-504,-505,-507,-508,-509,-510,-510,-511,-511,-511,-511,-511,-511,-511,-510,-510,-509,-508,-507,-505,-504,-502,-500,-498,-496,-494,-492,-489,-486,-484,-481,-477,-474,-471,-467,-464,-460,-456,-452,-447,-443,-438,-434,-429,-424,-419,-414,-408,-403,-397,-392,-386,-380,-374,-368,-362,-355,-349,-342,-335,-329,-322,-315,-308,-300,-293,-286,-278,-271,-263,-256,-248,-240,-232,-224,-216,-208,-200,-191,-183,-175,-166,-158,-149,-141,-132,-123,-115,-106,-97,-88,-80,-71,-62,-53,-44,-35,-26,-17,-8
