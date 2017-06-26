macro m16 reg,value {
  mov reg,(value) and $FF
  orr reg,(value) and $FF00
}

macro m16eq reg,value {
  moveq reg,(value) and $FF
  orreq reg,(value) and $FF00
}

macro m16ne reg,value {
  movne reg,(value) and $FF
  orrne reg,(value) and $FF00
}

macro m16lt reg,value {
  movlt reg,(value) and $FF
  orrlt reg,(value) and $FF00
}

macro m16gt reg,value {
  movgt reg,(value) and $FF
  orrgt reg,(value) and $FF00
}

macro m32 reg,value {
  mov reg,(value) and $FF
  orr reg,(value) and $FF00
  orr reg,(value) and $FF0000
  orr reg,(value) and $FF000000
}

macro m32eq reg,value {
  moveq reg,(value) and $FF
  orreq reg,(value) and $FF00
  orreq reg,(value) and $FF0000
  orreq reg,(value) and $FF000000
}

macro m32ne reg,value {
  movne reg,(value) and $FF
  orrne reg,(value) and $FF00
  orrne reg,(value) and $FF0000
  orrne reg,(value) and $FF000000
}

macro m32lt reg,value {
  movlt reg,(value) and $FF
  orrlt reg,(value) and $FF00
  orrlt reg,(value) and $FF0000
  orrlt reg,(value) and $FF000000
}

macro m32gt reg,value {
  movgt reg,(value) and $FF
  orrgt reg,(value) and $FF00
  orrgt reg,(value) and $FF0000
  orrgt reg,(value) and $FF000000
}

macro FOR label, register, max{
    mov register, max
    cmp register, 0
    beq label # _end$
    label # _begin$:
    sub register, #1
}

macro FOR_END label, register {
    cmp register, #0
    bne label # _begin$
    label # _end$:
}

