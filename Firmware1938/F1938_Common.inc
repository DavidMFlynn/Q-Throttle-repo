;=========================================================================================
; Commonly used routines PIC16F1938,39 version
;
;    Filename:      F1938_Common.inc
;    Date:          10/7/2015
;    File Version:  1.0
;
;    Author:        David M. Flynn
;    Company:       Oxford V.U.E., Inc.
;    E-Mail:        dflynn@oxfordvue.com
;    Web Site:      http://www.oxfordvue.com/
;
;=========================================================================================
;    History:
;
; 1.0   10/7/2015	Updated from F1847_Common.inc
; 1.0   11/16/2013	Updated from F648A Common.inc
;
;=========================================================================================
; Routines:
;
; ClearRam	(2+0) Clears all RAM, call once before initializing variables, FSR0
; CopyToRam	(1+0) copy param memory (EEPROM) to ram, call once, FSR0
; SaveParams	(1+0) copy ram to param memory (EEPROM), FSR0
;
; DecTimer4	(0+0) Decrement routine for 16 bit timers, FSR0
; DecTimer3
; DecTimer2
; DecTimer1
;
; TestT4_Zero	Test for 16 bit timers = zero
; TestT3_Zero	If Timer is zero return Z flag,1 else Z=0
; TestT2_Zero
; TestT1_Zero
;
; Delay10uS	(0+0)Delay uS    1 cycle = 1uS, 8Mhz clock version
; Delay100uS
; Delay40uS
; DelayWuS
;
; EEReadW	(0+0) Read EEPROM address in W
; EERead	(0+0) Read EEPROM address in EEAddrTemp
; EEWriteW	(0+0) Write EEPROM address in W, Data in EEDataTemp
; EEWrite	(0+0) Write EEPROM address in EEAdrTemp, Data in EEDataTemp, FSR0
;
;=========================================================================================
	ifndef UseEEParams
	constant UseEEParams=0
	endif
;=========================================================================================
; Clears all RAM (1024 bytes)
; Entry: none
; Exit: none, bank0
; RAM used: All
; Calls:(2+0) ClearRam_L2
;
ClearRam	MOVLB	0x00
	MOVLW	.95	;Clear 20h-7Eh, 95 bytes
	MOVWF	Param7F
	MOVLW	0x20
	MOVWF	FSR0L
	CLRF	FSR0H
	CALL	ClearRam_3
;
	CALL	ClearRam_4	;Clear A0h-EFh, 80 bytes
;
	INCF	FSR0H,F	
	CALL	ClearRam_2	;Banks 2,3
	INCF	FSR0H,F	
	CALL	ClearRam_2	;Banks 4,5
	INCF	FSR0H,F
	CALL	ClearRam_2	;Banks 6,7
	INCF	FSR0H,F	
	CALL	ClearRam_2	;Banks 8,9
	INCF	FSR0H,F
	CALL	ClearRam_2	;Banks 10,11
	INCF	FSR0H,F	;Bank 12
	MOVLW	.48	;Clear 48 bytes
	MOVWF	Param7F
	MOVLW	0x20
	MOVWF	FSR0L
	BRA	ClearRam_3
;	
ClearRam_2	MOVLW	0x20
	MOVWF	FSR0L
	CALL	ClearRam_5
;
ClearRam_4	MOVLW	0xA0
	MOVWF	FSR0L
;
ClearRam_5	MOVLW	.80	;Clear A0h-EFh, 80 bytes
	MOVWF	Param7F
;
ClearRam_3	MOVLW	0x00
ClearRam_L2	MOVWI	FSR0++
	DECFSZ	Param7F,F
	BRA	ClearRam_L2
	RETURN
;
	if UseEEParams
;==========================================================================
; copy param memory to ram
;
; Entry: none
; Exit: none, bank0
; RAM used: none
; Calls:(1+0) EERead
;
CopyToRam	MOVLB	0	;EEAddrTemp must be in bank0
	MOVLW	nvFirstParamByte
	MOVWF	EEAddrTemp
	MOVLW	low FirstRAMParam
	MOVWF	FSR0L
	MOVWF	high FirstRAMParam
	MOVWF	FSR0H
CopyToRam_L1	CALL	EERead
	MOVWI	FSR0++
	MOVLW	LastRAMParam+1
	SUBWF	FSR0L,W
	SKPNZ
	RETURN
	INCF	EEAddrTemp,F
	BRA	CopyToRam_L1
;
;===========================================================================
; copy ram to param memory
;
; Entry: none
; Exit: none, bank0
; RAM used: none
; Calls:(1+0) EEWrite
;
SaveParams	MOVLB	0	;EEAddrTemp must be in bank0
	MOVLW	nvFirstParamByte
	MOVWF	EEAddrTemp
	MOVLW	low FirstRAMParam
	MOVWF	FSR0L
	MOVWF	high FirstRAMParam
	MOVWF	FSR0H
SaveParams_L1	MOVIW	FSR0++
	MOVWF	EEDataTemp
	CALL	EEWrite
	MOVLW	LastRAMParam+1	;last byte
	SUBWF	FSR0L,W
	SKPNZ
	RETURN
	INCF	EEAddrTemp,F
	BRA	SaveParams_L1
;
	endif
;=====================================================================================================
;=========================================================================================================
; Decrement routine for 16 bit timers
;
DecTimer4	movlw	Timer4Hi
	bra	DecTimer
DecTimer3	movlw	Timer3Hi
	bra	DecTimer
DecTimer2	movlw	Timer2Hi
	bra	DecTimer
DecTimer1	movlw	Timer1Hi
;DecTimer
; entry: FSR=Timer(n)Hi
DecTimer	MOVWF	FSR0L
	MOVLW	High Timer1Hi
	MOVWF	FSR0H
	MOVIW	FSR0--	;TimerNHi
	IORWF	INDF0,W	;TimerNLo
	SKPNZ		;Already zero?
	RETURN		; Yes
	MOVLW	0x01
	SUBWF	INDF0,F	;TimerNLo
	CLRW
	INCF	FSR0L,F
	SUBWFB	INDF0,F	;TimerNHi
	RETURN
;
;==============================================================================================
; Test for 16 bit timers = zero
;If Timer is zero return Z flag,1 else Z=0
;
TestT4_Zero	movf	Timer4Lo,W
	iorwf	Timer4Hi,W
	return
;
TestT3_Zero	movf	Timer3Lo,W
	iorwf	Timer3Hi,W
	return
;
TestT2_Zero	movf	Timer2Lo,W
	iorwf	Timer2Hi,W
	return
;
TestT1_Zero	movf	Timer1Lo,W
	iorwf	Timer1Hi,W
	return	
;
;======================================================================================
;Delay uS    1 cycle = 1uS, 8Mhz clock version
; RAM used: Param77
; Calls:(0) none
Delay10uS	MOVLW	0x05	;(2*3+5)/2=10
	BRA	DelayWuS
Delay100uS	MOVLW	d'65'	;(28*3+5)/2=100
	BRA	DelayWuS
Delay40uS	MOVLW	d'25'	;(11*3+5)=40
DelayWuS	MOVWF	Param77
DelayWuS_Loop	DECFSZ	Param77,F
	BRA	DelayWuS_Loop
	RETURN
;
;==============================================================================================
; Read EEPROM
; entry: EEPROM address to read in W
;        Bank 0 selected
; exit: W=EEDATA, Bank 0 selected
;
EEReadW	movwf	EEAddrTemp
;
;==============================================================================================
; Read EEPROM
; entry: EEPROM address to read in EEAddrTemp
;        Bank 0 selected
; exit: W=EEDATA, Bank 0 selected
;
EERead	movf	EEAddrTemp,W
	BANKSEL	EEADRL	;Bank 3
	movwf	EEADRL	;Address to read
	bcf	EECON1,CFGS	;Deselect Config space
	bcf	EECON1,EEPGD	;Point to DATA memory
	bsf	EECON1,RD	;EE Read
	movf	EEDATL,W	;W=EEDAT
	MOVLB	0x00	;Bank 0
	return
;
;==============================================================================================
; Write EEPROM
; entry: EEPROM address to write in W
;        EEPROM data to write in EEDataTemp
;        Bank 0 selected
; exit: Bank 0 selected
;
EEWriteW	movwf	EEAddrTemp
;
;==============================================================================================
; Write EEPROM
; entry: EEPROM address to write in EEAdrTemp
;        EEPROM data to write in EEDataTemp
;        Bank 0 selected
; exit: Bank 0 selected
;
EEWrite	MOVLB	0
	MOVF	EEAddrTemp,W
	BANKSEL	EEADRL	;Bank 3
	movwf	EEADRL	;Address to write
	MOVLB	0
	MOVF	EEDataTemp,W
	BANKSEL	EEADRL	;Bank 3
	movwf	EEDATL
	bcf	EECON1,CFGS
	bcf	EECON1,EEPGD
	bsf	EECON1,WREN
	bcf	INTCON,GIE	;Disale Ints
	btfsc	INTCON,GIE
	bra	$-2
;
	movlw	0x55
	movwf	EECON2	;write 55
	movlw	0xAA
	movwf	EECON2	;write AA
	bsf	EECON1,WR	;begin write
	bsf	INTCON,GIE	;Enable Interrupts
EEWriteLoop	btfsc	EECON1,WR	;wait for write to complete
	bra	EEWriteLoop
	bcf	EECON1,WREN
	MOVLB	0x00	;Bank 0
	return
;
;	
;=========================================================================================
;=========================================================================================
;
;
;
