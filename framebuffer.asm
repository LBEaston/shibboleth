
init_framebuffer:
    m32 r0, FB_STRUCT + MAIL_TAGS
    m32 r1, PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS
    str r0, [r1]

    ldr r0, [FB_POINTER]
    cmp r0, 0
    beq init_framebuffer
    mov pc, lr

align 16
FB_STRUCT:
    dw FB_STRUCT_END - FB_STRUCT ; Buffer Size in bytes (including header, values, end tag, and padding
    dw $00000000 ; Buffer request/response code
                 ; Req : $00000000
                 ; Proc request response: $80000000 Success
                 ;                        $80000001 Partial response

    ; Tag layout
    ; dw Tag id
    ; dw Value buffer size in bytes
    ; dw 1 bit (most significant) Request(0)/Response(1) indicator
    ;    31 bits (least significant) value length in bytes
    ; Value buffer...

    ; Tags
    dw Set_Physical_Display
    dw $00000008
    dw $00000008
    dw SCREEN_X
    dw SCREEN_Y

    dw Set_Virtual_Buffer
    dw $00000008
    dw $00000008
    dw SCREEN_X
    dw SCREEN_Y*2

    dw Set_Depth
    dw $00000004
    dw $00000004
    dw BITS_PER_PIXEL

    dw Set_Virtual_Offset
    dw 00000008
    dw 00000008
        dw 0
        dw 0

    dw Set_Palette
    dw $00000010
    dw $00000010
    dw 0 ; Offset: Fisrt palette index to set (0-255)
    dw 2 ; Length: Number of palette entries to set (1-256)
    FB_PAL:
    dw $00000000, $FFFFFFFF ; RGBA Palette values (Offset to Offset+Length-1)
   
    dw Allocate_Buffer
    dw $00000008
    dw $00000008
    FB_POINTER:
        dw 0
        dw 0

    dw $00000000 ; End tag
FB_STRUCT_END:
    

