 lst off

 org $c00

*-------------------------------------------------

 dum 0
curpage ds 1
xsave ds 1
ysave ds 1
asave ds 1
temp ds 1
tmplo ds 1
tmphi ds 1
level ds 1
isGS? ds 1
 dend

framebase = $1000

*------------------------------------------------- show
*
* put on the show!
*

show bit $C010

 lda #0
 sta isGS?

 bit $C081
 sec
 jsr $fe1f ;GS?
 bcs :notGS

 inc isGS?

* Use special show frame routine for //GS that
* writes directly to bank $E0, since page two
* text is not properly shadowed to that bank.

 ldx #$4C ;jmp
 ldy #GSshowframe
 lda #>GSshowframe
 stx showframe
 sty showframe+1
 sta showframe+2

* Make our lookup tables up in ramcard area

:notGS bit $C083
 bit $C083

 jsr MAKEfade_tbls

 jsr lgr

:again

 ldx #0
:fadein stx level
 lda #0
 jsr showframe
 ldx level
 inx
 cpx #15
 bcc :fadein

* Here we go...

 lda #0
:floop pha
 ldx #15
 jsr showframe
 pla
 clc
 adc #1
 cmp #23
 bcc :floop

 ldx #15
:fadeout stx level
 lda #22
 jsr showframe
 ldx level
 dex
 bpl :fadeout

 bit $C000
 bpl *-3
 bit $C010

 jmp :again

*------------------------------------------------- lgr
*
* Clear and display lo-resolution screen
*

lgr sta $C000 ;turn off 55.54 select
 sta $C00C ;40 columns
 bit $C052 ;full screen
 bit $C055 ;show page two
 bit $C056 ;lores
 bit $C050 ;graphics on

 lda #4 ;use page one next
 sta curpage

 ldy #0
 sty tmplo
 sta tmphi

 tya
 ldx #8

:0 sta (tmplo),y
 iny
 bne :0

 inc tmphi
 dex
 bne :0

 rts

*------------------------------------------------- loget
*
* Enter with a:frame number
*            x:fade level
*

showframe asl
 asl
 adc #>framebase
 sta :src+2 ;hi byte

 txa
 ora #>fade_table
 sta :fademod+2

 lda curpage
 sta :dst+2
 eor #4!8
 sta curpage

 lda #4
 sta temp

 ldx #0
:loop
:src ldy $1100,x
:fademod lda fade_table+$F00,y
:dst sta $0400,x
 inx
 bne :loop

 inc :src+2 ;hibyte
 inc :dst+2 ; "  "

 dec temp
 bne :loop

]waitvbl jsr waitvbl

 bit $C055
 lda curpage
 cmp #4
 beq *+5
 bit $C054

 rts

GSshowframe asl
 asl
 adc #>framebase
 sta :src+2 ;hi byte

 txa
 ora #>fade_table
 sta :fademod+2

 lda curpage
 sta :dst+2
 eor #4!8
 sta curpage

 lda #4
 sta temp

 ldx #0
:loop
:src ldy $1100,x
:fademod lda fade_table+$F00,y
:dst stal $E00400,x
 inx
 bne :loop

 inc :src+2 ;hibyte
 inc :dst+2 ; "  "

 dec temp
 bne :loop
 beq ]waitvbl

*------------------------------------------------- waitvbl
*
* Wait for a few vbl's to go by!
*

waitvbl ldx #6
:0 bit $C019
 bpl :0
:1 bit $C019
 bmi :1
 dex
 bne :0
 rts

*------------------------------------------------- MAKEfade_tbls
*
* Make 16 lookup tables each containing 256 bytes
* for the 16 levels of fade-in.
*

MAKEfade_tbls dum 0
:curtmp ds 2 ;ptr into current tmp_scale table
:curfade ds 2 ;ptr into current page of fade table
:temp ds 1
:ysave ds 1
 dend

 jsr MAKEtmp_scale

 ldy #tmp_scale
 lda #>tmp_scale
 sty :curtmp
 sta :curtmp+1

 ldy #fade_table
 lda #>fade_table
 sty :curfade
 sta :curfade+1

* byte loop

 ldy #0

:bloop tya
 and #$0F
 jsr :convert
 sta :temp

 tya
 lsr
 lsr
 lsr
 lsr
 jsr :convert
 asl
 asl
 asl
 asl
 ora :temp

 sta (:curfade),y

 iny
 bne :bloop

* next fade table

 inc :curfade+1

* next tmp table

 clc
 lda :curtmp
 adc #16
 sta :curtmp
 bcc :bloop

 rts

* given a=0-15, in lores unsequential grey scale,
* convert it back to sequential, lookup new value
* in tmp_scale table and then convert back to
* lores unsequential.

:convert sty :ysave

* Convert lores color back to sequential 00-0F

 tax
 lda :unlores,x

* Scale it

 tay
 lda (:curtmp),y

* Convert back to unsequential lores color

 tax
 lda isGS?
 beq :notGS
 lda :loresGS,x
 bra :isGS

:notGS lda :lores2e,x

:isGS ldy :ysave
 rts

:unlores hex 000301070405020a
 hex 06080b0c090e0d0f

:loresGS hex 0002060104050803
 hex 090c070a0b0e0d0f

:lores2e hex 00000000
 hex 02020202
 hex 06060606
 hex 07070707

*------------------------------------------------- MAKEtmp_scale
*
* Make lookup table that contains values
* for 0-15 multiplied by 1/16...  16/16.
*

MAKEtmp_scale dum 0
:color ds 1
:scale ds 1
 dend

 lda #1 ;start with 1/16th
 sta :scale

:sloop ldy #0
:cloop sty :color
 lda #0
 ldx :scale
:mloop clc
 adc :color
 dex
 bne :mloop
 lsr
 lsr
 lsr
 lsr
:smc sta tmp_scale,y
 iny
 cpy #16
 bne :cloop
 inc :scale
 lda :smc+1
 clc
 adc #16
 sta :smc+1
 bcc :sloop
 rts

*-------------------------------------------------

 dum $D000
fade_table ds $1000
tmp_scale ds $100
 dend

*------------------------------------------------- EOF
