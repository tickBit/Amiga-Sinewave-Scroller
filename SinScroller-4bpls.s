; Sinewave scroller with 4 bpls
;
; This can be compiled at least with PhxAss assembler
; I hope, it can be still found in the Aminet
;
; The code isn't state of the art assembly, but hopefully easier to understand...
;
; You need 68040 Amiga system for this, the code uses 68040's move16 instruction
; for clearing the screen.
;
; If you use Amiga emulation, please use 68040 system and see the magic! :-)
;
; I try to find the time to improve the code...
;

        MACHINE  68040

; I don't have ADCD_2.1 right now with my laptop, so I use NDK3.1 below

;        incdir  "ADCD_2.1:NDK/NDK_3.5/Include/include_i"

;        include "exec/types.i"
;        include "libraries/dosextens.i"
;        include "graphics/gfxbase.i"
;        include "exec/libraries.i"
;        include "exec/execbase.i"

; Amiga Developer CD v1.1 can be freely downloaded from the internet
; Use this instead, if you don't have ADCD_2.1

        incdir  "Amiga_Dev_CD_v1.1:NDK_3.1/includes&libs/include_i"
        include "exec/types.i"
        include "libraries/dosextens.i"
        include "graphics/gfxbase.i"
        include "exec/libraries.i"
        include "exec/execbase.i"

;------------------------------------------------------------------------------
; Macros
;------------------------------------------------------------------------------
WaitForBlitter: MACRO
W\@:    btst.w  #14,$dff002
        bne.s   W\@
        ENDM

;------------------------------------------------------------------------------
; Constants
;------------------------------------------------------------------------------
Forbid         equ     -$0084
Permit         equ     -$008a
Disable        equ     -$0078
Enable         equ     -$007e
Write          equ     -$0030
Output         equ     -$003c
OpenLibrary    equ     -$0228
CloseLibrary   equ     -$019e

Execbase       equ      4

NOCHIPREV      equ      0

;------------------------------------------------------------------------------
; Startup code, works with AGA machnies. I found this back in the day somewhere
;------------------------------------------------------------------------------

        SECTION CODE,code

startup:
        movem.l d0/a0,-(sp)             ; 
        move.l  4,a6                    ; SysBase
        move.l  #0,a1
        jsr     -$0126(a6)              ; 
        move.l  d0,a4
        move.l  d0,process
        tst.l   pr_CLI(a4)              ; CLI?
                                        ; 
        bne.s   check_aga               ; check_aga
wb:
        lea     pr_MsgPort(a4),a0       ; 
                                        ; 
        jsr     -$0180(a6)              ; 
        lea     pr_MsgPort(a4),a0
        jsr     -$0174(a6)              ; 
                                        ; GetMsg()
        move.l  d0,wbenchmsg            ; 
                                        ; 
check_aga:                              ; 
        moveq   #0,d0                   ; 
        lea     gfxname,a1
        jsr     -$0228(a6)              ; OpenLibrary()
        move.l  d0,gfxbase
        beq.w   reply_to_wb             ; 
        move.l  d0,a4

        moveq   #0,d0
        lea     intuiname,a1
        jsr     -$0228(a6)
        move.l  d0,intuibase
        beq     close

        move.l  4,a6
        jsr     -$0078(a6)              ; Disable()
        cmp.w   #39,LIB_VERSION(a4)     ; 
                                        ; cmp.w #39,$14(a4)
        bne.s   no_chiprev

        move.b  gb_ChipRevBits0(a4),chiprev
                                        ; move.b $ec(a4),chiprev
        bra.s   check_proc
no_chiprev:
        move.b  #NOCHIPREV,chiprev      ; 
check_proc:
        move.w  AttnFlags(a6),processor ; CPU and FPU
                                        ; move.w $128(a6),processor
clear_view:
        move.l  gfxbase,a6
        move.l  gb_ActiView(a6),oldview ; 
                                        ; 
        move.l  #0,a1                   ; 
        jsr     -$00de(a6)              ; 

        jsr     -$010e(a6)
        jsr     -$010e(a6)              ; WaitTOF()

        move.l  4,a6                    ; 
        movem.l (sp)+,d0/a0             ; 
        bsr.s   _start                  ;
        move.l  d0,-(sp)                ; 
old_view:
        move.l  gfxbase,a0
        move.l  $26(a0),$dff080         ; Copperlistan palautus

        move.l  gfxbase,a6
        move.l  oldview,a1              ; old View
        jsr     -$00de(a6)              ; LoadView()
                                                                                                         
        move.l  4,a6
        jsr     -$007e(a6)              ; Enable()
                                                                                                        
        move.l  intuibase,a6
        jsr     -$0186(a6)              ; RethinkDisplay()

        move.l  4,a6
        move.l  intuibase,a1
        jsr     -$019e(a6)              ; CloseLibrary()

close   move.l  4,a6
        move.l  gfxbase,a1              ;
        jsr     -$019e(a6)              ; CloseLibrary()
                                                                                                         
reply_to_wb:
        tst.l   wbenchmsg               ; workbench?
        beq.s   exit                    ; 
        jsr     -$0084(a6)              ; 
                                        ; Forbid()
        move.l  wbenchmsg,a1
        jsr     -$017a(a6)              ; ReplyMsg()
exit:
        move.l  (sp)+,d0
        rts                             ; 


_start

;------------------------------------------------------------------------------
; The program starts..
;------------------------------------------------------------------------------

        movem.l d0-d7/a0-a6,-(sp)

        move.l  4,a6
        jsr     Forbid(a6)

        move.l  4,a6
        move.l  #10240*4,d0              ; 320 x 256 ; 4 bitplanes
        move.l  #65538,d1
        jsr     -$00c6(a6)
        move.l  d0,bitmap1
        beq     Exit

        move.l  4,a6
        move.l  #10240*4,d0              ; 320 x 256 ; 4 bitplanes
        move.l  #65538,d1
        jsr     -$00c6(a6)
        move.l  d0,bitmap2
        beq     freebitmap1

        move.l  #1536*4,d0               ; 384 * 32 * 4 chip mem area (scroll)
        move.l  #65538,d1
        jsr     -$00c6(a6)
        move.l  d0,scrollarea
        beq     freebitmap2

        move.l  #Copperlist,$dff080
        tst.w   $dff088                ; Own Copperlist on..

        move.w  #$83c0,$dff096         ; DMACON
        move.w  #$0420,$dff096         ; DMACON (sprites off)
                                       ; Sprites must be explicitly set off, if they're
                                       ; not used, otherwise one gets "phantom graphics" flickering
                                       ; on the screen...

        fmove.x  #0,fp7                ;
        fmove.x  #0.004363*320.0,fp1   ; Approximation in radians of (PI / 4) * screenwidth
                                        
        fdiv.x  #360.0,fp1

        
MainProgram:       
        bsr     SwapScreens
        bsr     Show
        bsr     ClearScreen
    	bsr     Scroll
        bsr     SinEffect
        bsr     WaitForBeam

        move.l  #fontw,a0       ; Font width
        subq.l  #1,(a0)
        cmp.l   #0,(a0)         ; is it time to draw next letter?
        bne.s   mousebutton
        bsr     drawLetter    
 
mousebutton
        btst    #6,$bfe001      ; Left mousebutton to exit the app
        bne.s   MainProgram

CleanUp
        move.l  4,a6
        move.l  #1536*4,d0
        move.l  scrollarea,a1
        jsr     -$00d2(a6)

freebitmap2
        move.l  4,a6
        move.l  #10240*4,d0
        move.l  bitmap2,a1
        jsr     -$00d2(a6)

freebitmap1
        move.l  4,a6
        move.l  #10240*4,d0
        move.l  bitmap1,a1
        jsr     -$00d2(a6)

Exit:   
        move.l  4,a6
        jsr     Permit(a6)
        movem.l (sp)+,d0-d7/a0-a6
        moveq   #0,d0
        rts

ClearScreen:
        move.l DrawScreen,a0
        move.l #clears,a1
        move.l #640-1,d7

; clear all 4 bitplanes

clear1
        move16 (a1)+,(a0)+
        sub.l  #16,a1
        dbf    d7,clear1

        move.l DrawScreen,a0
        add.l  #10240,a0
        move.l #640-1,d7
clear2
        move16 (a1)+,(a0)+
        sub.l  #16,a1
        dbf    d7,clear2

        move.l DrawScreen,a0
        add.l  #10240*2,a0
        move.l #640-1,d7
clear3
        move16 (a1)+,(a0)+
        sub.l  #16,a1
        dbf    d7,clear3

        move.l DrawScreen,a0
        add.l  #10240*3,a0
        move.l #640-1,d7
clear4
        move16 (a1)+,(a0)+
        sub.l  #16,a1
        dbf    d7,clear4

        rts

drawLetter
        move.l  #32,fontw       ; font width
        move.l  #t_pointer,a2
        move.l  (a2),d0
        move.l  #scrolltext,a4
        add.l   d0,a4
        moveq   #0,d2
        move.b  (a4),d2
        cmp.b   #0,(a4)         ; end of text?
        bne.s   space_
        move.l  #0,t_pointer
        move.l  #t_pointer,a2
        move.l  #scrolltext,a4
        move.b  (a4),d2
space_:
        cmp.b   #32,d2          ; space
        beq.s   space

subtract_A_ascii
      
        sub.l   #65,d2          ; the ASCII code of 'A'
        lsl.l   #7,d2           ; multiply by 128

        addq.l  #1,(a2)         ; next drawLetter

        WaitForBlitter
        
        move.w  #$0000,$dff042  ; BLTCON1
        move.w  #$09f0,$dff040  ; BLTCON0

        move.l  #Font,a1
        add.l   d2,a1
        move.l  a1,$dff050      ; BLTAPTR source
        move.l  scrollarea,a0
        add.l   #40,a0
        move.l  a0,$dff054      ; BLTDPTH dest

        move.w  #$ffff,$dff044
        move.w  #$ffff,$dff046

        move.w  #0000,$dff064   ; BLTAMOD (source modulo)
        move.w  #0044,$dff066   ; BLTDMOD (dest modulo)

        moveq   #0,d0
        move.w  #32,d0          ; height
        lsl.w   #6,d0           ; height to appropriate bits
        or.w    #2,d0           ; width / 16
        move.w  d0,$dff058      ; BLTSIZE       

; bitplane 2

        add.l   #1536,a0
        add.l   #5504,a1
        WaitForBlitter
        move.l  a1,$dff050      ; BLTAPTR source
        move.l  a0,$dff054      ; BLTDPTH dest        
        move.w  d0,$dff058

; bitplane 3

        add.l   #1536,a0
        add.l   #5504,a1
        WaitForBlitter
        move.l  a1,$dff050      ; BLTAPTR source
        move.l  a0,$dff054      ; BLTDPTH dest
        move.w  d0,$dff058

        add.l   #1536,a0
        add.l   #5504,a1

; bitplane 4

        WaitForBlitter
        move.l  a1,$dff050      ; BLTAPTR source
        move.l  a0,$dff054      ; BLTDPTH dest
        move.w  d0,$dff058

        rts



WaitForBeam        
        move.w  $dff004,d0
        btst.l  #0,d0                   
        beq.s   WaitForBeam
        cmp.b   #$2d,$dff006
        bne.s   WaitForBeam
        rts

space:
        addq.l  #1,(a2)
        WaitForBlitter
        
        move.w  #$0000,$dff042  ; BLTCON1
        move.w  #$09f0,$dff040  ; BLTCON0

        move.l  #spaceg,a1
        move.l  a1,$dff050      ; BLTAPTH source
        move.l  scrollarea,a0
        add.l   #40,a0
        move.l  a0,$dff054      ; BLTDPTH dest

        move.w  #$ffff,$dff044
        move.w  #$ffff,$dff046

        move.w  #0000,$dff064   ; BLTAMOD (source modulo)
        move.w  #0044,$dff066   ; BLTDMOD (dest modulo)

        moveq   #0,d0
        move.w  #32,d0          ; height
        lsl.w   #6,d0           ; height to approriate bits
        or.w    #2,d0           ; width / 16
        move.w  d0,$dff058      ; BLTSIZE       

        add.l   #1536,a0
        WaitForBlitter
        move.l  a1,$dff050      ; BLTAPTR source
        move.l  a0,$dff054      ; BLTDPTH dest        
        move.w  d0,$dff058

        add.l   #1536,a0
        move.l  a1,$dff050      ; BLTAPTR source
        move.l  a0,$dff054      ; BLTDPTH dest        
        WaitForBlitter
        move.w  d0,$dff058

        add.l   #1536,a0
        WaitForBlitter
        move.l  a1,$dff050      ; BLTAPTR source
        move.l  a0,$dff054      ; BLTDPTH dest        
        move.w  d0,$dff058

        rts

Scroll:           
        WaitForBlitter
        move.w  #$0002,$dff064  ; BLTAMOD (source modulo)
        move.w  #$0002,$dff066  ; BLTDMOD (dest modulo)

        
        move.w  #0000,$dff042 ; BLTCON1
        moveq   #0,d0
        moveq   #0,d2
        move.w  #$09f0,d0
        move.w  #15,d2
        mulu    #$1000,d2
        or.w    d2,d0
        move.w  d0,$dff040     ; BLTCON0
        move.l  scrollarea,a1
        addq.l  #2,a1
        move.l  a1,$dff050     ; BLTAPTH source
        move.l  scrollarea,a0
        add.l   #0,a0
        move.l  a0,$dff054     ; BLTDPTH dest
        moveq   #0,d0
        move.w  #32,d0         ; height
        lsl.w   #6,d0          ; height to appropriate bits
        or.w    #23,d0         ; width / 16
        move.w  d0,$dff058     ; BLTSIZE

        add.l   #1536,a0
        add.l   #1536,a1
        WaitForBlitter
        move.l  a1,$dff050      ; BLTAPTR source
        move.l  a0,$dff054      ; BLTDPTH dest
        move.w  d0,$dff058

        add.l   #1536,a0
        add.l   #1536,a1
        WaitForBlitter
        move.l  a1,$dff050      ; BLTAPTR source
        move.l  a0,$dff054      ; BLTDPTH dest
        move.w  d0,$dff058

        add.l   #1536,a0
        add.l   #1536,a1
        WaitForBlitter
        move.l  a1,$dff050      ; BLTAPTR source
        move.l  a0,$dff054      ; BLTDPTH dest
        move.w  d0,$dff058

        rts
      
SinEffect:
        move.l  #20-1,d7        ; 320 / 16 - 1
        moveq   #0,d6
        moveq   #0,d5
        move.w  #$8000,d5       ; bitmask
        moveq   #0,d0
        moveq   #32-1,d1        ; height counter
        moveq   #16-1,d4        ; width counter

        fsub.x  #320.0*0.004363,fp7
        fadd.x  fp1,fp7

        fmove.x  fp7,fp0
        fsin.x   fp0
        fmul.x   #64,fp0
        fmove.l  fp0,d3
        muls     #40,d3   


        ; copy 1 x 32 pixels of font
copybits:
        moveq   #0,d0
        moveq   #0,d2
        
        move.l  scrollarea,a0
        move.l  DrawScreen,a1
        add.l   d6,a0
        add.l   d6,a1
        add.l   #40*112,a1
        add.l   d3,a1

; bitplane 1
cloop1
        move.w  (a0),d0         ; copy 1 x 32 pixels from scrollarea
        and.w   d5,d0
        move.w  (a1),d2
        or.w    d0,d2
        move.w  d2,(a1)
        add.l   #48,a0          ; next line
        add.l   #40,a1          ; next line
        dbf     d1,cloop1

        move.l  scrollarea,a0
        move.l  DrawScreen,a1
        add.l   d6,a0           ; x position
        add.l   d6,a1           ; x position
        add.l   #40*112,a1      ; y centering
        add.l   d3,a1           ; add sinewave value to destination address of the screen
        add.l   #1536,a0
        add.l   #10240,a1
        moveq   #32-1,d1        ; height counter
        moveq   #0,d0
        moveq   #0,d2

; bitplane 2
cloop2
        move.w  (a0),d0         ; copy 1 x 32 pixels from scrollarea
        and.w   d5,d0
        move.w  (a1),d2
        or.w    d0,d2
        move.w  d2,(a1)
        add.l   #48,a0          ; next line
        add.l   #40,a1          ; next line
        dbf     d1,cloop2

        move.l  scrollarea,a0
        move.l  DrawScreen,a1

        add.l   #1536*2,a0
        add.l   #10240*2,a1
        add.l   d6,a0
        add.l   d6,a1
        add.l   #40*112,a1
        add.l   d3,a1
        moveq   #32-1,d1        ; height counter
        moveq   #0,d0
        moveq   #0,d2

; bitplane 3
cloop3
        move.w  (a0),d0         ; copy 1 x 32 pixels from scrollarea
        and.w   d5,d0
        move.w  (a1),d2
        or.w    d0,d2
        move.w  d2,(a1)
        add.l   #48,a0          ; next line
        add.l   #40,a1          ; next line
        dbf     d1,cloop3

        move.l  scrollarea,a0
        move.l  DrawScreen,a1

        add.l   #1536*3,a0
        add.l   #10240*3,a1
        add.l   d6,a0
        add.l   d6,a1
        add.l   #40*112,a1
        add.l   d3,a1

        moveq   #32-1,d1        ; height counter
        moveq   #0,d0
        moveq   #0,d2

; bitplane 4
cloop4
        move.w  (a0),d0         ; copy 1 x 32 pixels from scrollarea
        and.w   d5,d0
        move.w  (a1),d2
        or.w    d0,d2
        move.w  d2,(a1)
        add.l   #48,a0          ; next line
        add.l   #40,a1          ; next line
        dbf     d1,cloop4

        moveq   #32-1,d1
        lsr.w   #1,d5

        fadd.x  fp1,fp7

        fmove.x  fp7,fp0
        fsin.x   fp0
        fmul.x   #64,fp0
        fmove.l  fp0,d3

        muls     #40,d3         ; sine wave value multiplied by 40 (width of the screen in bytes)       
    
        dbf     d4,copybits

         
        fadd.x  fp1,fp7

        fmove.x  fp7,fp0
        fsin.x   fp0
        fmul.x   #64,fp0
        fmove.l  fp0,d3

        muls     #40,d3     

        addq.l  #2,d6
        moveq   #32-1,d1
        moveq   #16-1,d4
        move.w  #$8000,d5
        dbf     d7,copybits
        rts

Show:   move.l  ShowScreen,d1
        move.w  d1,low1
        swap    d1
        move.w  d1,high1
        swap    d1
        add.l   #10240,d1
        move.w  d1,low2
        swap    d1
        move.w  d1,high2
        swap    d1
        add.l   #10240,d1
        move.w  d1,low3
        swap    d1
        move.w  d1,high3
        swap    d1
        add.l   #10240,d1
        move.w  d1,low4
        swap    d1
        move.w  d1,high4        
        rts

SwapScreens:
        cmp.b   #1,which
        beq.s   LetItBeOneThen
        move.l  bitmap2,DrawScreen
        move.l  bitmap1,ShowScreen
        move.b  #1,which
        rts
LetItBeOneThen:
        move.l  bitmap1,DrawScreen
        move.l  bitmap2,ShowScreen
        move.b  #2,which
        rts



gfxname         dc.b    "graphics.library",0
intuiname       dc.b    "intuition.library",0
dosname		dc.b    "dos.library",0

scrolltext      dc.b    "FOUR BITPLANES SINEWAVE SCROLLER        ",0
        even


        section variables,DATA

wbenchmsg       dc.l    0
oldview         dc.l    0
process         dc.l    0
processor       dc.w    0
chiprev         dc.b    0
                even

intuibase       dc.l    0
gfxbase         dc.l    0
dosbase		dc.l    0

fontw           dc.l    32
t_pointer       dc.l    0

DrawScreen      dc.l    0
ShowScreen      dc.l    0
bitmap1         dc.l    0
bitmap2         dc.l    0
scrollarea      dc.l    0

which           dc.b    1
                even

        section ChipData,DATA,CHIP


Copperlist:
        dc.w    $00e0
high1:  dc.w    $0000
        dc.w    $00e2
low1:   dc.w    $0000
        dc.w    $00e4
high2:  dc.w    $0000
        dc.w    $00e6
low2:   dc.w    $0000
        dc.w    $00e8
high3:  dc.w    $0000
        dc.w    $00ea
low3:   dc.w    $0000
        dc.w    $00ec
high4:  dc.w    $0000
        dc.w    $00ee
low4:   dc.w    $0000        
        dc.w    $0100,$4200 ; BPLCON0 one bitplane...
        dc.w    $0102,$0000 ; BPLCON1
        dc.w    $0104,$0000 ; BPLCON2
        dc.w    $0108,$0000 ; BPL1MOD
        dc.w    $010a,$0000 ; BPL2MOD
        dc.w    $0092,$0038 ; DDFSTRT
        dc.w    $0094,$00d0 ; DDFSTOP
        dc.w    $008e,$2c81 ; DIWSTRT
        dc.w    $0090,$2cc1 ; DIWSTOP 
        
        ; generated colors from the font
        DC.W $0180,$079F,$0182,$0FFF,$0184,$0DEC,$0186,$0BDA
	DC.W $0188,$0AC7,$018A,$08A7,$018C,$0797,$018E,$0687
	DC.W $0190,$0577,$0192,$0467,$0194,$0356,$0196,$0255
	DC.W $0198,$0243,$019A,$0223,$019C,$0212,$019E,$0202

        dc.w    $ffff,$fffe

spaceg  ds.b    (32/8)*32
clears  ds.b    8               ; for clearing the screen with 68040's move16
        even

Font    incbin  "gfx/gradbubble-32x32-wip-4bpls.raw"

        end
