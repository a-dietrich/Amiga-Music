;***********************
; Music Player
; s: 28.04.89
;***********************
;-------------------------------------
Open         = -30
Close        = -36
Read         = -42
OpenLib      = -408
CloseLibrary = -414
ExecBase     =  4
Disable      = -120
Enable       = -126
Forbid       = -132
Permit       = -138
AllocMem     = -198
FreeMem      = -210
;-------------------------------------
VPosR        = $dff004
IntReqR      = $dff01e
DMACon       = $dff096
IntEna       = $dff09a
IntReq       = $dff09c
ADkCon       = $dff09e
Aud0LCH      = $dff0a0
Aud0Len      = $dff0a4
Aud0Per      = $dff0a6
Aud0Vol      = $dff0a8
Aud1LCH      = $dff0b0
Aud1Len      = $dff0b4
Aud1Per      = $dff0b6
Aud1Vol      = $dff0b8
Aud2LCH      = $dff0c0
Aud2Len      = $dff0c4
Aud2Per      = $dff0c6
Aud2Vol      = $dff0c8
Aud3LCH      = $dff0d0
Aud3Len      = $dff0d4
Aud3Per      = $dff0d6
Aud3Vol      = $dff0d8
;-------------------------------------------------------------------
Run:           move.l  ExecBase,a6
               jsr     Forbid(a6)
               jsr     Disable(a6)
               bsr     OpenDos
               bsr     SoundLoad
;*******************************************************************
; PlayRoutine
; s: 28.04.89 i:29.04.89
;*******************************************************************
SoundStart:    move.w  #$000f,DMACon
               move.w  #$00ff,ADkCon
               move.w  #$0780,IntReq
               move.l  #TrackTable,Step
               clr.w   Note
               clr.w   Arpeggio

PlayLoop:      move.w  #3,Speed
BeamSync:      move.l  #$8100,d1
               bsr     WaitBeam
               btst    #2,$dff016
               beq     Ende

InitRegs:      move.l  #$a000,d1
               bsr     WaitBeam
               move.w  #%1000000000000000,d7

               clr.l   d1
               bsr     SetPattern
               lea     Aud0LCH,a2
               move.w  #%1,d6
               bsr     SetChannel
               move.w  #4,d1
               bsr     SetPattern
               lea     Aud1LCH,a2
               move.w  #%10,d6
               bsr     SetChannel
               move.w  #8,d1
               bsr     SetPattern
               lea     Aud2LCH,a2
               move.w  #%100,d6
               bsr     SetChannel
               move.w  #12,d1
               bsr     SetPattern
               lea     Aud3LCH,a2
               move.w  #%1000,d6
               bsr     SetChannel

SetHull:       move.l  #$b000,d1
               bsr     WaitBeam
               move.w  d7,DMACon
               move.l  #$d000,d1
               bsr     WaitBeam
               move.l  #OffSample,Aud0LCH
               move.w  #1,Aud0Len
               ;move.l  #OffSample,Aud1LCH
               ;move.w  #1,Aud1Len
               ;move.l  #OffSample,Aud2LCH
               ;move.w  #1,Aud2Len
               ;move.l  #OffSample,Aud3LCH
               ;move.w  #1,Aud3Len
               sub.w   #1,Speed
               bne     BeamSync
               bchg    #1,$bfe001
               add.w   #2,Note
               cmp.w   #64,Note
               bne     PlayLoop
               clr.w   Note
               add.l   #16,Step
               move.l  Step,a0
               cmp.b   #$40,3(a0)
               bls     PlayLoop
Instruction:   add.l   #16,Step
               cmp.b   #$ff,3(a0)
               bne     PlayLoop
               clr.l   d0
               move.b  (a0),d0
               asl.w   #4,d0
               lea     TrackTable,a0
               lea     (a0,d0),a0
               move.l  a0,Step
               bra     PlayLoop

;*******************************************************************
NextNote:      lea     SamplePeriods,a5
               move.w  Note,d1
               move.w  (a0,d1),d0
               move.w  d0,d1
               move.w  d1,d2
               move.w  d2,d3
               asr.w   #8,d0
               asr.w   #4,d0
               asr.w   #8,d1
               asr.w   #4,d3
               and.l   #$f,d0
               and.l   #$f,d1
               and.l   #$f,d2
               and.l   #$f,d3
               tst.b   d2
               bne     NextNote1
               clr.b   Volume
NextNote1:     btst    #0,d3
               bne     NextNote2
               cmp.w   #3,Speed
               bne     Pause
NextNote2:     sub.w   #$1,d0
               bmi     Pause
	       ;clr.w   DecayControl	
               bsr     Transposing
               asl.w   #1,d0
               add.w   d0,a5
               move.w  (a5),d5
               asr.w   d1,d5
               sub.w   #1,d2
               asl.w   #2,d2
               lea     SoundAdr,a0
               lea     SoundLenght,a1
               move.l  (a0,d2),d3
               move.l  (a1,d2),d4
               rts
Pause:         ;move.b  #4,DecayControl
               clr.l   d3
               clr.l   d4
               clr.l   d5
               rts
SetChannel:    bsr     NextNote
	       ;tst.w   DecayControl
	       ;bne     SetDecay
               move.b  Volume,8(a2)
               ;bra     SetRegs
SetDecay:      ;sub.b   #4,8(a2)		
SetRegs:       tst.w   d3
               beq     NextChannel
               move.w  d6,DMACon
               move.l  d3,(a2)
               asr.l   #1,d4
               move.w  d4,4(a2)
               move.w  d5,6(a2)
               or.w    d6,d7
NextChannel:   rts
SetPattern:    move.l  Step,a4
               lea     Pattern1,a0
               clr.l   d0
               move.b  (a4,d1),d0
               move.b  3(a4,d1),Volume
               move.b  1(a4,d1),Transpose
               subq.b  #1,d0
               asl.w   #6,d0
               add.l   d0,a0
               rts
Transposing:   mulu    #$0c,d1
               add.b   d1,d0
               add.b   Transpose,d0
               btst    #0,d3
               beq     Transposing1
               lea     ArpeggioTable,a1
               move.w  Arpeggio,d4
               move.b  (a1,d4),d4
               add.b   d4,d0
               add.w   #1,Arpeggio
               cmp.w   #8,Arpeggio
               bne     Transposing1
               clr.w   Arpeggio
Transposing1:  divu    #$0c,d0
               move.b  d0,d1
               swap    d0
Transposing2:  rts

;*******************************************************************
Step:          dc.l    0
Volume:        dc.b    0
Transpose:     dc.b    0
DecayControl:  dc.w    0
Arpeggio:      dc.w    0
OffSample:     dc.w    0
Note:          dc.w    0
Speed:         dc.w    0
SamplePeriods: dc.w    854,808,762,718,678,640,604,570,538,508,480,452
ArpeggioTable: dc.b    $00,$03,$07,$0a,$00,$03,$07,$0a

Pattern1:      dc.w    $7101,$0101,$b101,$0101
               dc.w    $9101,$0101,$b101,$0201
               dc.w    $7101,$0101,$2201,$0101
               dc.w    $b101,$0101,$2201,$0201
               dc.w    $7101,$0101,$4201,$0101
               dc.w    $2201,$0101,$4201,$0201
               dc.w    $7101,$0101,$2201,$0101
               dc.w    $b101,$0101,$2201,$0201

Pattern2:      dc.w    $7102,$0111,$7102,$0111
               dc.w    $7102,$0111,$7202,$0111
               dc.w    $7202,$0202,$7102,$0111
               dc.w    $7102,$0111,$7202,$0111
               dc.w    $7102,$0111,$7102,$0111
               dc.w    $7102,$0111,$7202,$0111
               dc.w    $7202,$0202,$7102,$0111
               dc.w    $7102,$0111,$7202,$0111

Pattern3:      dc.w    $7111,$0110,$7111,$0110
               dc.w    $7111,$0110,$7111,$0110
               dc.w    $7111,$0110,$7111,$0110
               dc.w    $7111,$0110,$7111,$0110
               dc.w    $7111,$0110,$7111,$0110
               dc.w    $7111,$0110,$7111,$0110
               dc.w    $7111,$0110,$7111,$0110
               dc.w    $7111,$0110,$7111,$0110

Pattern4:      dc.w    $3204,$0201,$0101,$0201
               dc.w    $0201,$0201,$0101,$0201
               dc.w    $0201,$0201,$0101,$0201
               dc.w    $0201,$0201,$0101,$0201
               dc.w    $0201,$0111,$0101,$0111
               dc.w    $0201,$0001,$0001,$0111
               dc.w    $0201,$0001,$0101,$0111
               dc.w    $0201,$0111,$0101,$0111

Pattern5:      ds.w    32

Pattern6:      dc.w    $b003,$0111,$0102,$0111
               dc.w    $0111,$0111,$0202,$0111
               dc.w    $0111,$0111,$0102,$0111
               dc.w    $0111,$0111,$0202,$0111
               dc.w    $0103,$0111,$0102,$0111
               dc.w    $0111,$0111,$0202,$0111
               dc.w    $0111,$0111,$0102,$0111
               dc.w    $0111,$0111,$0202,$0111

Pattern7:      dc.w    $3101,$0111,$0101,$0111
               dc.w    $6101,$0111,$0101,$0111
               dc.w    $1201,$0111,$0101,$0111
               dc.w    $a101,$0111,$0101,$0111
               dc.w    $0001,$0111,$0101,$0111
               dc.w    $a101,$0101,$a101,$0111
               dc.w    $a101,$0101,$0101,$0111
               dc.w    $a101,$0101,$0101,$0111

Pattern8:      dc.w    $3104,$0111,$0101,$0111
               dc.w    $0101,$0111,$0101,$0111
               dc.w    $0101,$0111,$0101,$0111
               dc.w    $0101,$0111,$0101,$0111
               dc.w    $3104,$0111,$0101,$0111
               dc.w    $6104,$0101,$0101,$0111
               dc.w    $1204,$0101,$0101,$0111
               dc.w    $a104,$0101,$0101,$0111

Pattern9:      dc.w    $3105,$0111,$0101,$0101
               dc.w    $0105,$0111,$0105,$0101
               dc.w    $3105,$0111,$0105,$0105
               dc.w    $3105,$0111,$0105,$0105
               dc.w    $0105,$0111,$3105,$0105
               dc.w    $0105,$0101,$3105,$0101
               dc.w    $0105,$0101,$3105,$0105
               dc.w    $3105,$0101,$3105,$0101

;                      Track1 l  Track2 r  Track3 r  Track4 l
;		       Bass      Drums     Accomb    Lead	
;---------------------------------------------------------------------
TrackTable:    dc.l    $02fc0020,$05f40000,$04f40008,$05000000
	       dc.l    $02fc0020,$05f40000,$04f40018,$05000000
	       dc.l    $02fc0020,$05f40000,$04f40028,$05000000
	       dc.l    $02fc0028,$09fb0030,$09000030,$09030030
	       dc.l    $02fc0028,$09f90030,$09fe0030,$09020030
	       dc.l    $02fc0028,$09f70030,$09fb0030,$09fe0030
	       dc.l    $02fc0028,$09f90030,$09fd0030,$09000030
	       dc.l    $02fc0028,$09fb0030,$09000030,$09030030
	       dc.l    $02fc0028,$09f90030,$09fe0030,$09020030
	       dc.l    $02fc0028,$09f70030,$09fb0030,$09fe0030
	       dc.l    $02fc0028,$09f90020,$09fd0020,$09000020
	       dc.l    $02fc0020,$01ff0030,$04f40028,$06000000
	       dc.l    $02fa0020,$01ff0030,$04f20028,$06000000
	       dc.l    $02f80020,$01ff0030,$04f00028,$06000000
	       dc.l    $02fc0020,$08f40040,$07f40040,$01ff0030
	       dc.l    $02030020,$08fb0040,$07fb0040,$01060030
	       dc.l    $02fe0020,$08f60040,$07f60040,$01010030
	       dc.l    $02050020,$08fd0040,$07fd0040,$01080030
	       dc.l    $02fc0020,$01ff0040,$07000040,$08000030
	       dc.l    $02030020,$01060040,$07070040,$08070030
	       dc.l    $02fe0020,$01010040,$07020040,$08020030
	       dc.l    $02050020,$01080040,$07090040,$08090030
	       dc.l    $02fc0020,$01ff0030,$04f40028,$06000038
	       dc.l    $02fc0020,$01ff0030,$04f40028,$06000038
	       dc.l    $02fc0020,$01ff0020,$04f40018,$06000038
	       dc.l    $02fc0020,$01ff0010,$04f40008,$06000038
	       dc.l    $02fc0020,$01ff0000,$04f40000,$06000038
	       dc.l    $02fc0020,$01ff0000,$04f40000,$06000038
	       dc.l    $02fc0020,$08f40040,$07f40040,$06000030
	       dc.l    $02030020,$08fb0040,$07fb0040,$06000030
	       dc.l    $02fe0020,$08f60040,$07f60040,$06000030
	       dc.l    $02050020,$08fd0040,$07fd0040,$06000030
	       dc.l    $02fc0020,$01ff0040,$07000040,$06000030
	       dc.l    $02030020,$01060040,$07070040,$06000030
	       dc.l    $02fe0020,$01010040,$07020040,$06000030
	       dc.l    $02050020,$01080040,$07090040,$06000030
	       dc.l    $02fc0020,$03fc0040,$07f40040,$06000030
	       dc.l    $02030020,$03030040,$07fb0040,$06000030
	       dc.l    $02fe0020,$03fe0040,$07f60040,$06000030
	       dc.l    $02050020,$03050040,$07fd0040,$06000030

	       dc.l    $02fc0020,$03fc0038,$07f40038,$06000030
	       dc.l    $02030020,$03030030,$07fb0030,$06000030
	       dc.l    $02fe0020,$03fe0028,$07f60028,$06000028
	       dc.l    $02050020,$03050020,$07fd0020,$06000020
	       dc.l    $02fc0020,$03fc0018,$07f40018,$06000018
	       dc.l    $02030020,$03030010,$07fb0010,$06000010
	       dc.l    $02fe0020,$03fe0008,$07f60008,$06000008
	       dc.l    $02050020,$03050000,$07fd0000,$06000000

               dc.l    $000000ff,$00000000,$00000000,$00000000


;*******************************************************************
; PlayRoutine
; s: 28.04.89 i:29.04.89
;*******************************************************************
Ende:          move.w  #%0000000000001111,DMACon
               move.l  ExecBase,a6
               move.l  SoundAdr,a1
               move.l  SoundLenght,d0
               jsr     FreeMem(a6)
               move.l  Sound2Adr,a1
               move.l  Sound2Lenght,d0
               jsr     FreeMem(a6)
               move.l  Sound3Adr,a1
               move.l  Sound3Lenght,d0
               jsr     FreeMem(a6)
               move.l  Sound4Adr,a1
               move.l  Sound4Lenght,d0
               jsr     FreeMem(a6)
               move.l  Sound5Adr,a1
               move.l  Sound5Lenght,d0
               jsr     FreeMem(a6)
               bsr     CloseDos
               move.l  ExecBase,a6
               jsr     Enable(a6)
               jsr     Permit(a6)
               rts
;-------------------------------------------------------------------
OpenDos:       move.l  ExecBase,a6
               lea     DosName,a1
               jsr     OpenLib(a6)
               move.l  d0,DosBase
               rts
CloseDos:      move.l  ExecBase,a6
               move.l  DosBase,a1
               jsr     CloseLibrary(a6)
               rts
WaitBeam:      move.l  VPosR,d0
               and.l   #$0001ff00,d0
               cmp.l   d1,d0
               bne     WaitBeam
               rts
WaitM:         btst    #6,$bfe001
               bne     WaitM
               rts
WaitMR:        btst    #2,$dff016
               bne     WaitMR
               rts
OpenFile:      move.l  DosBase,a6
               jsr     Open(a6)
               move.l  d0,FileHd
               rts
CloseFile:     move.l  DosBase,a6
               move.l  FileHd,d1
               jsr     Close(a6)
               rts
SoundLoad:     move.l  #SoundName,d1
               lea     SoundLenght,a4
               lea     SoundAdr,a3
               bsr     SoundXLoad
               move.l  #Sound2Name,d1
               lea     Sound2Lenght,a4
               lea     Sound2Adr,a3
               bsr     SoundXLoad
               move.l  #Sound3Name,d1
               lea     Sound3Lenght,a4
               lea     Sound3Adr,a3
	       bsr     SoundXLoad	
               move.l  #Sound4Name,d1
               lea     Sound4Lenght,a4
               lea     Sound4Adr,a3
	       bsr     SoundXLoad 	
               move.l  #Sound5Name,d1
               lea     Sound5Lenght,a4
               lea     Sound5Adr,a3
SoundXLoad:    move.l  #1005,d2
               bsr     OpenFile
               move.l  DosBase,a6
               move.l  FileHd,d1
               move.l  a4,d2
               move.l  #4,d3
               jsr     Read(a6)
               move.l  (a4),d0
               move.l  #$10003,d1
               move.l  ExecBase,a6
               jsr     AllocMem(a6)
               move.l  d0,(a3)
               move.l  DosBase,a6
               move.l  FileHd,d1
               move.l  #Buffer,d2
               move.l  #2,d3
               jsr     Read(a6)
               move.l  DosBase,a6
               move.l  FileHd,d1
               move.l  (a3),d2
               move.l  (a4),d3
               jsr     Read(a6)
               bra     CloseFile
;-------------------------------------------------------------------
SoundName:     dc.b    'Zyrcor:Sounds/String.snd',0
               even
Sound2Name:    dc.b    'Zyrcor:Sounds/Bass2.snd',0
               even
Sound3Name:    dc.b    'Zyrcor:Sounds/Disco.snd',0
               even
Sound4Name:    dc.b    'Zyrcor:Sounds/Brass.snd',0
               even
Sound5Name:    dc.b    'Zyrcor:Sounds/Piano.snd',0
               even
SoundLenght:   dc.l    0
Sound2Lenght:  dc.l    0
Sound3Lenght:  dc.l    0
Sound4Lenght:  dc.l    0
Sound5Lenght:  dc.l    0
SoundAdr:      dc.l    0
Sound2Adr:     dc.l    0
Sound3Adr:     dc.l    0
Sound4Adr:     dc.l    0
Sound5Adr:     dc.l    0
Buffer:        dc.l    0
FileHd:        dc.l    0
DosBase:       dc.l    0
DosName:       dc.b    'dos.library',0
ByteCounter:   dc.w    0
ByteCounter2:  dc.w    0
Info:	       dc.b    'ZYRCOR THEME composed and programmed in 1989'
	       dc.b    'By Andreas Dietrich'
	       even
               END
