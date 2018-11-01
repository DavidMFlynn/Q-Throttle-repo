;====================================================================================================
;
;    Filename:      Q-Throttle.asm
;    Date:          7/11/2017
;    File Version:  1.0d1
;
;    Author:        David M. Flynn
;    Company:       DMFE
;    E-Mail:        dflynn@oxfordvue.com
;    Web Site:      http://www.oxfordvue.com/
;
;====================================================================================================
;    Q-Throttle is an electronic throttle for model trains
;
;
;    History:
; 1.01d   7/11/2017	First Code
;
;====================================================================================================
; Options
;
;====================================================================================================
;====================================================================================================
; What happens next:
;   At power up the system LED will blink.
;
;====================================================================================================
;
;   Pin 1  Vpp/MCLR/RE3	Vpp
;   Pin 2  RA0/AN0		AN0, VFB (Track Voltage Feedback)
;   Pin 3  RA1/AN1		AN1, Current Limit Setting
;   Pin 4  RA2/AN2		RA2, ITrip+ Track Current (drive high to force short LED)
;   Pin 5  RA3/AN3		AN3, Direction Input from DMFE handheld
;   Pin 6  RA4/T0CKI		RA4, SysLED (Active High)
;   Pin 7  RA5/AN4		AN4, VRef Input from DMFE handheld
;   Pin 8  Vss	GND
;   Pin 9  RA7/OSC1		RA7, RCMode Serial select (0=RS-485, 1=X-BEE)
;   Pin 10 RA6/OSC2	VCAP
;   Pin 11 RC0		ADC/DCC Select Switch (Active High)
;   Pin 12 RC1/CCP2		mosfet Drive enable/PWM
;   Pin 13 RC2/CCP1		mosfet Drive East/West select
;   Pin 14 RC3		SCL I2C RAM
;
;   Pin 15 RC4		SDA I2C RAM
;   Pin 16 RC5		RS-485 Send/Recieve*
;   Pin 17 RC6/TX		RS-232 TX
;   Pin 18 RC7/RX		RS-232 RX
;   Pin 19 Vss	GND
;   Pin 20 Vdd	+5V
;   Pin 21 RB0/AN12		East LED (Active High)
;   Pin 22 RB1/AN10		VOut LED (Active High)
;   Pin 23 RB2/AN8		DCC/ADC* LED (Active High)
;   Pin 24 RB3/AN9/CCP2	VOUTPWM
;   Pin 25 RB4/AN11		AN11 IFB Track Current
;   Pin 26 RB5/AN13		West LED (Active High)
;   Pin 27 RB6/ICSPCLK		ICSPCLK
;   Pin 28 RB7/ICSPDAT		ICSPDAT
;
;====================================================================================================
;
;
	list	p=16f1938,r=hex,W=1	; list directive to define processor
	nolist
	include	p16f1938.inc	; processor specific variable definitions
	list
;
	__CONFIG _CONFIG1,_FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _IESO_OFF
;
;
; INTOSC oscillator: I/O function on CLKIN pin
; WDT disabled
; PWRT disabled
; MCLR/VPP pin function is digital input
; Program memory code protection is disabled
; Data memory code protection is disabled
; Brown-out Reset enabled
; CLKOUT function is disabled. I/O or oscillator function on the CLKOUT pin
; Internal/External Switchover mode is disabled
; Fail-Safe Clock Monitor is enabled
;
	__CONFIG _CONFIG2,_WRT_OFF & _PLLEN_OFF & _LVP_OFF & _VCAPEN_RA6
;
; Write protection off
; Vcap Off
; 4x PLL disabled
; Stack Overflow or Underflow will cause a Reset
; Brown-out Reset Voltage (Vbor), low trip point selected.
; Low-voltage programming disabled
; Enable VCAP on RA6
;
; '__CONFIG' directive is used to embed configuration data within .asm file.
; The lables following the directive are located in the respective .inc file.
; See respective data sheet for additional information on configuration word.
;
	constant	oldCode=0
	constant	useRS232=0
;
#Define	_C	STATUS,C
#Define	_Z	STATUS,Z
;
;====================================================================================================
	nolist
	include	F1938_Macros.inc
	list
;
CCPCON_Clr	EQU	b'00001001'
CCPCON_Set	EQU	b'00001000'
CCPCON_Idle	EQU	b'00001010'
;
ADCON1_Value	EQU	b'11110011'	;Right Justify, Frc clock,
			; FVR & Vss Vref
;    Port A bits
PortADDRBits	EQU	b'11111111'
PortAValue	EQU	b'00010000'
ANSELA_Value	EQU	b'00101111'
#Define	SystemLED	LATA,4	;Output, always 0=LED ON
#Define	SystemLEDTris	TRISA,4
#Define	RA5_In	PORTA,5	;unused
#Define	RA6_In	PORTA,6	;unused
#Define	LatchedDataIn	PORTA,7	;RA7, Latched I/O Data
#Define	LatchedDataOut	LATA,7
#Define	LatchedDataTris	TRISA,7
;
OUT_AddrDataMask	EQU	0xF0
OUT_AddrMask	EQU	0x07
;
;
;    Port B bits
PortBDDRBits	EQU	b'11010000'	;outputs
PortBValue	EQU	b'11000011'
;
#Define	EastLED	LATB,0	;East LED (Active High)
#Define	VOutLED	LATB,1	;VOut LED (Active High)
#Define	DCCLED	LATB,2	;DCC/ADC* LED (Active High)
;			;RB3=CCP2 VOUTPWM
;			;RB4=AN11 IFB Track Current
#Define	WestLED	LATB,5	;West LED (Active High)
;			;RB6=ICSPCLK
;			;RB7=ICSPDAT
;
PortCDDRBits	EQU	b'11111001'
PortCValue	EQU	b'00000000'
;
#Define	SW1_Btn	PORTC,0	;ADC/DCC Select Switch (Active High)
#Define	DRVENA	LATC,1	;mosfet Drive enable/PWM
#Define	DRV_Dir	LATC,2	;mosfet Drive East/West* select
#Define	RC3_In	PORTC,3	;SCL I2C RAM
#Define	RC4_In	PORTC,4	;SDA I2C RAM
#Define	RS485Send	PORTC,5	;RS-485 Send/Recieve*
#Define	RS232TXBit	LATC,6	;RS-232 TX
#Define	RS232RXBit	LATC,7	;RS-232 RX
;
;=========================================================================================
;=========================================================================================
;
;Constants
All_In	EQU	0xFF
All_Out	EQU	0x00
;
TMR0Val	EQU	0xB2	;0xB2=100Hz, 0.000128S/Count
LEDTIME	EQU	d'100'	;1.00 seconds
LEDErrorTime	EQU	d'10'
kWDTime	EQU	d'200'	;2 seconds
;
T1CON_Val	EQU	b'00000001'	;PreScale=1,Fosc/4,Timer ON
TMR1L_Val	EQU	0x3C	; -2500 = 2.5 mS, 400 steps/sec
TMR1H_Val	EQU	0xF6
;
;TMR1L_Val	EQU	0x1E	; -1250 = 1.25 mS, 800 steps/sec
;TMR1H_Val	EQU	0xFB
;
;TMR1L_Val	EQU	0x8F	; -625 = 0.625 mS, 1600 steps/sec
;TMR1H_Val	EQU	0xFD
;
BAUDCON_Value	EQU	b'00001000'
TXSTA_Value	EQU	b'00100100'	;8 bit, TX enabled, Async, High speed
RCSTA_Value	EQU	b'10010000'	;RX enabled, 8 bit, Continious receive
; 8MHz clock low speed (BRGH=0,BRG16=1)
;Baud_300	EQU	d'1666'	;0.299, -0.02%
;Baud_1200	EQU	d'416'	;1.199, -0.08%
;Baud_2400	EQU	d'207'	;2.404, +0.16%
;Baud_9600	EQU	d'51'	;9.615, +0.16%
; 8MHz clock high speed (BRGH=1,BRG16=1)
Baud_300	EQU	d'6666'	;0.299, -0.02%
Baud_1200	EQU	d'1666'	;1.199, -0.08%
Baud_2400	EQU	d'832'	;2.404, +0.16%
Baud_9600	EQU	d'207'	;9.615, +0.16%
Baud_19_2	EQU	d'103'	;19.23k, +0.16
Baud_57_6	EQU	d'34'	;57.14k, -0.79
BaudRate	EQU	Baud_9600
;-------------
DebounceTime	EQU	d'10'
;
;================================================================================================
;***** VARIABLE DEFINITIONS
; there is 1024 bytes of ram, Bank0 0x20..0x7F, Bank1 0xA0..0xEF, Bank2 0x120..0x16F ...
; there are 256 bytes of EEPROM starting at 0x00 the EEPROM is not mapped into memory but
;  accessed through the EEADR and EEDATA registers
;================================================================================================
;  Bank0 Ram 020h-06Fh 80 Bytes
;
	cblock	0x20 
;
	LED_Time	
	tickcount		;Timer tick count
;
;
;------------------------
; Needed for serial module
	TXByte		;Next byte to send
	RXByte		;Last byte received
	WorkingRXByte	
	SerFlags
;-------------------------
;
	EEAddrTemp		;EEProm address to read or write
	EEDataTemp		;Data to be writen to EEProm
;
	Timer1Lo		;1st 16 bit timer
	Timer1Hi		; one second RX timeiout
	Timer2Lo		;2nd 16 bit timer
	Timer2Hi		;
	Timer3Lo		;3rd 16 bit timer
	Timer3Hi		;GP wait timer
	Timer4Lo		;4th 16 bit timer
	Timer4Hi		; debounce timer
;
	SysFlags
	SysFlags2	
;
	RX_ParseFlags	
;
	RX_Flags	
;
	RX_Command
	RX_Data:2
;
	endc
;
;SerFlags	
#Define	DataReceivedFlag	SerFlags,1
#Define	DataSentFlag	SerFlags,2
;
;
#Define	DCC_ActiveFlag	SysFlags,0
#Define	PWMSyncBit	SysFlags,1
;
#Define	DispDec3pl	SysFlags,2
#Define	DispDec2pl	SysFlags,3
#Define	DispDec1pl	SysFlags,4
#Define	Disp_LZO	SysFlags,5
#Define	Disp_NLS	SysFlags,6
;
#Define	SyncByteRXd	RX_ParseFlags,0
#Define	CmdRXd	RX_ParseFlags,1
#Define	Data0RXd	RX_ParseFlags,2
#Define	Data1RXd	RX_ParseFlags,3
;
#Define	RXDataValidFlag	RX_Flags,0
#Define	RXDataIsNew	RX_Flags,1
;
;=========================================================================================
; Bank 1 Ram 0A0h-0EFh 80 Bytes
;
	cblock	0xA0
;
;Analog data
	RawAN0:2
	RawAN1:2
	RawAN2:2
	RawAN4:2
	CurrentADC		;0..LastADC
	ADCFlags
	TargetVolts:2
;
	endc
;
OutputVolts	equ	RawAN0	;AN0
MaxCurrentPot	equ	RawAN1	;AN1
OutputCurrent	equ	RawAN2	;AN2
VRefVolts	equ	RawAN4	;AN4
;
PWM_Max	equ	0x7F
;
LastADC	equ	3	;AN0,AN1,AN2,AN4
#Define	ADC_AquireFlag	ADCFlags,0
#Define	ADC_ConvertFlag	ADCFlags,1
;
;=========================================================================================
;  Bank2 Ram 120h-16Fh 80 Bytes
; Serial module data
;
#Define	Ser_Buff_Bank	0x02
;
;
	cblock	0x120
;
	Ser_In_Bytes		;Bytes in Ser_In_Buff
	Ser_Out_Bytes		;Bytes in Ser_Out_Buff
	Ser_In_InPtr	
	Ser_In_OutPtr	
	Ser_Out_InPtr	
	Ser_Out_OutPtr	
	Ser_In_Buff:20
	Ser_Out_Buff:20
;
	endc
;
;=========================================================================================
; Bank3 Ram 1A0h-1EFh 80 Bytes
;=========================================================================================
; Bank4 Ram 220h-26Fh 80 Bytes
;=========================================================================================
;  Bank5 Ram 2A0h-2EFh 80 Bytes
;
	cblock	0x2A0
;
	CalcdDwell		;scratch var
	CalcdDwellH
	SigOutTime:2		;Current position
	ServoFlags
;
	PWMValue
;
	endc
;ServoFlags
#Define	SF_High	ServoFlags,0
;
;=========================================================================================
; Bank6 Ram 320h-36Fh 80 Bytes
;=========================================================================================
; Bank7 Ram 3A0h-3EFh 80 Bytes
;=========================================================================================
; Bank8 Ram 420h-46Fh 80 Bytes
;=========================================================================================
; Bank9 Ram 4A0h-4EFh 80 Bytes
;=========================================================================================
; Bank10 Ram 520h-56Fh 80 Bytes
;=========================================================================================
; Bank11 Ram 5A0h-5EFh 80 Bytes
;=========================================================================================
; Bank12 Ram 620h-54Fh 48 Bytes
;=========================================================================================
;  Common Ram 70-7F same for all banks
;      except for ISR_W_Temp these are used for paramiter passing and temp vars
;=========================================================================================
;
	cblock	0x70
	Param70
	Param71
	Param72
	Param73
	Param74
	Param75
	Param76
	Param77
	Param78
	Param79
	Param7A
	Param7B
	Param7C
	Param7D
	Param7E
	Param7F
	endc
;
;=========================================================================================
;Conditionals
;
HasISR	EQU	0x80	;used to enable interupts 0x80=true 0x00=false
;
;=========================================================================================
;=========================================================================================
; ID Locations
	__idlocs	0x10D1
;
;=========================================================================================
; EEPROM locations (NV-RAM) 0x00..0x7F (offsets)
	cblock	0x0000
;
nvMinSpdLo;	RES	1	;0x1E; -1250 = 1.25 mS, 60RPM
nvMinSpdHi;	RES	1	;0xFB
nvMaxSpdLo;	RES	1	;0x8F; -625 = 0.625 mS, 120RPM
nvMaxSpdHi;	RES	1	;0xFD
;
nvSysFlags;	RES	1
	endc
;
#Define	nvFirstParamByte	nvMinSpdLo
#Define	nvLastParamByte	nvSysFlags
;
;=========================================================================================
; Routines	(stack) Description
; ----------------------------------------------------------------------------------------
; Reset Vector 	Hard wired at 0x0000
; Interrupt Vector	Hard wired ar 0x0004
;  OnTheTick	Called 100 times per second by ISR
; start	Reset vector jumps to here, initialization
; MainLoop	Main event loop, serial I/O, Analog and Digital I/O
;  CMD_Interp	Handle incoming serial data.
;   EchoCMD	Echo the serial CMD byte to the serial out buffer.
;   SendNewLine	Sent a \n to the serial out buffer.
; Disp_decword	(1+2) 16 bit version of Disp_decbyteW
;  Fix_decword	(0) Used to convert a word value to a string
;  DisplayOrPut	Send W to serial out buffer.
; Disp_Hex_Byte	(1+2) Send a byte to the serial out buffer as 2 hex digits
;  Disp_Hex_Nibble	(1+1) Send a nibble to the serial out buffer as a hex digit
; AdjustPWM	(0) 
; ReadAnalogInputs	(1+0) Read the analog inputs in rotation.
;
;=========================================================================================
;=========================================================================================
;
;
	ORG	0x000	; processor reset vector
	CLRF	STATUS
	CLRF	PCLATH
  	goto	start	; go to beginning of program
;
;=========================================================================================
; Interupt Service Routine
;
; we loop through the interupt service routing every 0.008192 seconds
;
;
	ORG	0x004	; interrupt vector location
	MOVLB	0	; bank0
	CLRF	PCLATH	;Needed only if program extends beyond segment 0.
;
;-------------------------------
; Stuff that happens every 1/100 second
;
	btfss	PIR1,TMR2IF
	bra	ISR_Timer2_End
;
	bcf	PIR1,TMR2IF
;
;Decrement timers until they are zero
; 
	call	DecTimer1	;if timer 1 is not zero decrement
	call	DecTimer2
	call	DecTimer3
	call	DecTimer4
;
	call	OnTheTick	;Called 100 times per second.
;-----------------------------------------------------------------
; blink LEDs
	MOVLB	1
	bsf	SystemLEDTris	;LED off
	MOVLB	0
;
	decfsz	tickcount,F
	bra	ISR_Timer2_End
;
	MOVLB	1
	BCF	SystemLEDTris	;LED ON
	MOVLB	0
;
	MOVLW	LEDTIME
	MOVWF	tickcount
;
;
ISR_Timer2_End:
;
;---------------------------------------------------------------
;AUSART Serial ISR
;
IRQ_Ser	BTFSS	PIR1,RCIF	;RX has a byte?
	BRA	IRQ_Ser_End
	CALL	RX_TheByte
;
IRQ_Ser_End:
;
;-----------------------------------------------------------------
; ISR for PWM period timer
	MOVLB	0
	BTFSS	PIR3,TMR4IF
	BRA	ISR_PWM_End
	BSF	PWMSyncBit
	BCF	PIR3,TMR4IF
ISR_PWM_End:
;
;-----------------------------------------------------------------
	if oldCode
;
; Handle CCP1 Interupt Flag, Enter w/ bank 0 selected
;
IRQ_Servo1	MOVLB	0	;bank 0
	BTFSS	PIR2,CCP2IF
	BRA	IRQ_Servo1_End
;
	BCF	PIR2,CCP2IF
	MOVLB	0x05
	BTFSS	SF_High	;Output just went high?
	BRA	IRQ_Servo1_OL	; No
; An output just went high
;
	MOVF	SigOutTime,W	;Put the pulse into the CCP reg.
	ADDWF	CCPR2L,F
	MOVF	SigOutTime+1,W
	ADDWFC	CCPR2H,F
	BCF	SF_High
	MOVLW	CCPCON_Clr	;Clear output on match
	MOVWF	CCP2CON	;CCP1 clr on match
;Calculate dwell time
	MOVLW	LOW kServoDwellTime
	MOVWF	CalcdDwell
	MOVLW	HIGH kServoDwellTime
	MOVWF	CalcdDwellH
	MOVF	SigOutTime,W
	SUBWF	CalcdDwell,F
	MOVF	SigOutTime+1,W
	SUBWFB	CalcdDwellH,F
	BRA	IRQ_Servo1_X
;
; output went low so this cycle is done
IRQ_Servo1_OL	MOVF	CalcdDwell,W
	ADDWF	CCPR2L,F
	MOVF	CalcdDwellH,W
	ADDWFC	CCPR2H,F
;
	BSF	SF_High
	MOVLW	CCPCON_Set	;Set output on match
	MOVWF	CCP2CON
;
IRQ_Servo1_X	MOVLB	0x00
	
IRQ_Servo1_End:
	endif
;-----------------------------------------------------------------
;
	retfie		; return from interrupt
;
;==============================================================================================
; Called 100 times per second
;
OnTheTick:
;
	return
;
;==============================================================================================
;==============================================================================================
;
;
;==============================================================================================
;
start	MOVLB	0x01	; select bank 1
	bsf	OPTION_REG,NOT_WPUEN	; disable pullups on port B
	bcf	OPTION_REG,TMR0CS	; TMR0 clock Fosc/4
	bcf	OPTION_REG,PSA	; prescaler assigned to TMR0
	bsf	OPTION_REG,PS0	;111 8mhz/4/256=7812.5hz=128uS/Ct=0.032768S/ISR
	bsf	OPTION_REG,PS1	;101 8mhz/4/64=31250hz=32uS/Ct=0.008192S/ISR
	bsf	OPTION_REG,PS2
;
	MOVLB	0x01	; bank 1
	MOVLW	b'01110000'	; 8 MHz
	MOVWF	OSCCON
	movlw	b'00010111'	; WDT prescaler 1:65536 period is 2 sec (RESET value)
	movwf	WDTCON 	
;	
	MOVLB	0x03	; bank 3
	MOVLW	ANSELA_Value
	MOVWF	ANSELA
	CLRF	ANSELB	;Digital I/O
;
;----------------------------
;setup FVR
FVRCON_Value	EQU	b'10000001'
; Enable FVR, Output 1.024V to ADC
	BANKSEL	FVRCON
	MOVLW	FVRCON_Value
	MOVWF	FVRCON
;
;----------------------------
;setup ADC
ADCON0_Value	EQU	b'00000001'	;enable ADC
	BANKSEL	ADCON1
	MOVLW	ADCON1_Value
	MOVWF	ADCON1
	MOVLW	ADCON0_Value	;enable ADC
	MOVWF	ADCON0
;
;----------------------------
;
; setup Timer 2 for 1/100 second interrupts
;
;8MHz/4: Pre=16 PR=125 Post=10
T2CON_Value	EQU	b'01001110'
;32MHz/4: Pre=64 PR=125 Post=10
;T2CON_Value	EQU	b'01001111'
PR2_Value	EQU	.125
;
	MOVLB	0	;Bank 0
	MOVLW	T2CON_Value
	MOVWF	T2CON
	MOVLW	PR2_Value
	MOVWF	PR2
	MOVLB	1	;Bank 1
	BSF	PIE1,TMR2IE
;
;------------------------------
;
; setup timer 1 for 1uS/count
;
	MOVLB	0x00	; bank 0
	bcf	T1CON,TMR1CS0	; Fosc/4 = 2Mhz
	bcf	T1CON,TMR1CS1
	bsf	T1CON,T1CKPS0	; prescale /2
	bcf	T1CON,T1CKPS1
	bsf	T1CON,NOT_T1SYNC	;not sync'ed
	bsf	T1CON,TMR1ON	;always on
	bcf	T1GCON,TMR1GE
;
	CLRWDT
; clear memory to zero
	CALL	ClearRam
;
;==============================
; setup CCP2 for PWM
;
CCP2CON_Value	equ	b'00001100'	;PWM mode
;
	MOVLB	5	;Bank 5
	MOVLW	CCP2CON_Value
	MOVWF	CCP2CON
	MOVLW	b'00000100'	;use TMR4
	MOVWF	CCPTMRS0
	MOVLW	0x01	;0.4% duty
	MOVWF	CCPR2L
;
; Config Timer4 to control PWM on CCP1, Fosc/4(2MHz) / 101 = 19.8KHz	
	MOVLB	8
	MOVLW	b'00000101'	;4:1 pre,ON,1:1 post
	MOVWF	T4CON
	MOVLW	0xFF	; 7.8KHz
	MOVWF	PR4
; default to the highest volt setting
	MOVLB	1	;Bank 1

;	BSF	PIE1,CCP2IE	;not used in PWM mode
	BSF	PIE3,TMR4IE	;may be used to sync updates
			; one update per duty cycle
;=========================================
;
	MOVLB	0x00	;Bank 0
; setup data ports
	movlw	PortBValue
	movwf	PORTB	;init port B
	movlw	PortAValue
	movwf	PORTA
	movlw	PortCValue
	movwf	PORTC
	MOVLB	0x01	; bank 1
	movlw	PortADDRBits
	movwf	TRISA
	movlw	PortBDDRBits	;setup for programer
	movwf	TRISB
	movlw	PortCDDRBits
	movwf	TRISC
;
;---------------------------------
; setup serial I/O
	movlb	0x03	; bank 3
	MOVLW	BAUDCON_Value
	MOVWF	BAUDCON
	MOVLW	TXSTA_Value
	MOVWF	TXSTA
	MOVLW	low BaudRate
	MOVWF	SPBRGL
	MOVLW	high BaudRate
	MOVWF	SPBRGH
	MOVLW	RCSTA_Value
	MOVWF	RCSTA
	movlb	0x01	; bank 1
	BSF	PIE1,RCIE	; Serial Receive interupt
	movlb	0x00	; bank 0
;
;------------------------------
	CLRWDT
;
	MOVLW	LEDTIME	;LEDErrorTime
	MOVWF	LED_Time
;
	MOVLW	0x01
	MOVWF	tickcount
;
	bsf	INTCON,PEIE	; enable periferal interupts
;	bsf	INTCON,T0IE	; enable TMR0 interupt
	bsf	INTCON,GIE	; enable interupts
;
;=========================================================================================
;=========================================================================================
;  Main Loop
;
;
;=========================================================================================
MainLoop	CLRWDT
;
	MOVLB	0x00	; bank 0
;
	CALL	ReadAnalogInputs
	CALL	AdjustPWM
;
;
;-----------------------------------------------------------------------------------------
; Serial stuff
; Handle Serial Communications
	MOVLB	0
	BTFSC	PIR1,TXIF	;TX done?
	CALL	TX_TheByte	; Yes
;
; move any serial data received into the 32 byte input buffer
	BTFSS	DataReceivedFlag
	BRA	ML_Ser_Out
	MOVF	RXByte,W
	BCF	DataReceivedFlag
	CALL	StoreSerIn
;
;------------------------
; If the serial data has been sent and there are bytes in the buffer, send the next byte
;
ML_Ser_Out	BTFSS	DataSentFlag
	BRA	ML_Ser_End
	CALL	GetSerOut
	BTFSS	Param78,0
	BRA	ML_Ser_End
	MOVWF	TXByte
	BCF	DataSentFlag
ML_Ser_End:
;
	CALL	RS232_Parse
	BTFSS	RXDataIsNew
	BRA	ML_Ser_NoData
	BTFSS	RXDataValidFlag
	BRA	ML_Ser_NoData
;
	BCF	RXDataIsNew
;
;	CALL	CMD_Interp
;
ML_Ser_NoData:
;
;
	goto	MainLoop
;
;=========================================================================================
;*****************************************************************************************
;=========================================================================================
;
SetADCWest	movlb	2
	bcf	EastLED
	bcf	DRV_Dir
	bsf	WestLED
	bcf	DCCLED
	movlb	0
	bcf	DCC_ActiveFlag
	return
;
SetADCEast	movlb	2
	bsf	EastLED
	bsf	DRV_Dir
	bcf	WestLED
	bcf	DCCLED
	movlb	0
	bcf	DCC_ActiveFlag
	return
;
;=========================================================================================
; Handle RS-232 Commands
CMD_SendAN0	EQU	'A'	;Batt Volts, Returns A00000\n
CMD_SendAN1	EQU	'B'	;Input Current, Returns B00000\n
CMD_SendAN2	EQU	'C'	;Batt Current, Returns C00000\n
CMD_SendAN3	EQU	'D'	;Motor Volts, Returns D00000\n
CMD_SendAN4	EQU	'E'	;PWM Volts, Returns E00000\n
;
;
CMD_Interp	MOVLW	CMD_SendAN0
	SUBWF	RX_Command,W
	SKPZ
	BRA	SendAN0_End
	
SendAN0_End:
	return
;==================================
;==================================
;
;	
;tc
;Echo RS-232 Data
;	BCF	RXDataIsNew
;	MOVLW	0xFF
;	CALL	StoreSerOut
;	MOVF	RX_Command,W
;	CALL	StoreSerOut
;	MOVF	RX_Data,W
;	CALL	StoreSerOut
;	MOVF	RX_Data+1,W
;	CALL	StoreSerOut
;	MOVLW	0xFF
;	CALL	StoreSerOut
;etc
;
EchoCMD	MOVF	RX_Command,W
	GOTO	StoreSerOut
;
SendNewLine	MOVLW	'\n'
	GOTO	StoreSerOut
;
;==============================================================================
; Used to convert a word value to a string
; Entry: Param7A:Param79=multiplier (10000,1000,100 or 10), Param77:Param76=data
; Exit: Param77:Param76 remainder, Param78=result('0'..'9')
; RAM used: Param76, Param77, Param78, Param79, Param7A
; Calls:(0) none
;
Fix_decword	CLRF	Param78
;if multiplier >= data
Fix_decword_L1	MOVF	Param7A,W
	SUBWF	Param77,W	
	BTFSC	STATUS,Z
	BRA	Fix_decword_1	;high data = high multi
	BTFSS	STATUS,C	;skip if not barrowed data>=multi
	BRA	Fix_decword_End	;high data < high multiplier
	BRA	Fix_decword_2	;high data > high multiplier
;
Fix_decword_1	MOVF	Param79,W
	SUBWF	Param76,W	;low data - low multi
	BTFSS	STATUS,C	;skip if not barrowed data>=multi
	BRA	Fix_decword_End	;data < multiplier
;result++
;data -= multiplier
Fix_decword_2	INCF	Param78,F
	MOVF	Param79,W
	SUBWF	Param76,F	;low data - low multi
	MOVF	Param7A,W
	SUBWFB	Param77,F	;high data - high multi
	BRA	Fix_decword_L1	;Param77>=100
; else done
Fix_decword_End	RETURN
;
;===============================================================================================
; 16 bit version of Disp_decbyteW
; if DispDec2pl is cleared
;  output to DisplaysW is '00000'..'65535'
;  else output to DisplaysW is '##0.00'..'655.35'
; Enrty: Param77:Param76  16 bit value
; Exit: none
; RAM used: Param76, Param77, Param78, Param79, Param7A
; Calls: (1+2) Fix_decword, DisplaysW
;
Disp_decword	MOVLB	0	;Bank0
	BTFSC	DispDec2pl
	BSF	Disp_LZO
	BTFSC	DispDec1pl
	BSF	Disp_LZO
	MOVLW	low d'10000'
	MOVWF	Param79
	MOVLW	high d'10000'
	MOVWF	Param7A
	CALL	Fix_decword	;(1+0)
	MOVF	Param78,W
	BTFSS	Disp_LZO	;if set ##0.00
	BRA	Disp_decword_1	; else disp 0
	BTFSC	STATUS,Z	; don't disp 0
	BRA	Disp_decword_2A	; show a <space> instead
Disp_decword_1	ADDLW	'0'
	BCF	Disp_LZO
Disp_decword_1sp	CALL	DisplayOrPut	;(1+2)
	BRA	Disp_decword_2
;
Disp_decword_2A	MOVLW	' '
	BTFSS	Disp_NLS
	BRA	Disp_decword_1sp
;
Disp_decword_2	MOVLW	low d'1000'
	MOVWF	Param79
	MOVLW	high d'1000'
	MOVWF	Param7A
	CALL	Fix_decword
	MOVF	Param78,W
	BTFSS	Disp_LZO
	BRA	Disp_decword_3
;
	BTFSC	STATUS,Z	; don't disp 0
	BRA	Disp_decword_4A	; show a <space> instead
Disp_decword_3	ADDLW	'0'
	BCF	Disp_LZO
Disp_decword_3Sp	CALL	DisplayOrPut
	BRA	Disp_decword_4
;
Disp_decword_4A	MOVLW	' '
	BTFSS	Disp_NLS
	BRA	Disp_decword_3Sp
;
Disp_decword_4	MOVLW	d'100'
	MOVWF	Param79
	CLRF	Param7A
	CALL	Fix_decword
	MOVF	Param78,W
	BTFSS	Disp_LZO
	BRA	Disp_decword_5LZ
	BTFSS	DispDec1pl
	BRA	Disp_decword_5LZ
	SKPNZ		; don't disp 0
	BRA	Disp_decword_5D	; show a <space> instead
;
Disp_decword_5LZ	ADDLW	'0'
	BCF	Disp_LZO
Disp_decword_4sp	CALL	DisplayOrPut
	BRA	Disp_decword_5B
;
Disp_decword_5D	MOVLW	' '
	BTFSS	Disp_NLS
	BRA	Disp_decword_4sp
;
Disp_decword_5B	BTFSS	DispDec2pl
	BRA	Disp_decword_5
	MOVLW	'.'
	CALL	DisplayOrPut
;
Disp_decword_5	MOVLW	d'10'
	MOVWF	Param79
	CLRF	Param7A
	CALL	Fix_decword
	MOVF	Param78,W
	ADDLW	'0'
	CALL	DisplayOrPut
;
	BTFSS	DispDec1pl
	BRA	Disp_decword_7
	MOVLW	'.'
	CALL	DisplayOrPut
Disp_decword_7	MOVLW	'0'
	ADDWF	Param76,W
;reset defaults
	BCF	DispDec3pl
	BCF	DispDec2pl
	BCF	DispDec1pl
	BCF	Disp_LZO
	BCF	Disp_NLS
;
;================================================================
;
DisplayOrPut	MOVLB	0	;Bank0
	GOTO	StoreSerOut
;
;=========================================================================================
; Disp_Hex_Byte send a byte to the display as 2 hex digits
; entry: W=value
; exit: none
; RAM used:Param76, Param79
; Calls:(1+2) Disp_Hex_Nibble, DisplaysW
;
Disp_Hex_Byte	MOVWF	Param76	;save the data
Disp_Hex_Byte_E2	SWAPF	Param76,W	;get hi nibble in low nibble of W
	CALL	Disp_Hex_Nibble	;output the high nibble
	MOVF	Param76,W	; now the low nibble
;
;fall through to Disp_Hex_Nibble
;
;===============================================================
; Send a nibble to the display as a hex digit
; Entry: W:0..3 = Nibble to display
; RAM used: Param79
; Calls:(1+1) DisplaysW
;
Disp_Hex_Nibble	ANDLW	0x0F	;kill the other nibble
	ADDLW	'0'	; add offset
	MOVWF	Param79
	MOVLW	0x3A	;'9'+1 should barrow if 0..9
	SUBWF	Param79,W	
	CLRW
	BTFSC	STATUS,C	;skip if barrowed
	MOVLW	0x07
	ADDWF	Param79,W
;
	GOTO	DisplayOrPut
;
;=========================================================================================
;=========================================================================================
;=========================================================================================
; Battery voltage control.
; Compare the output with the target and adjust the PWM duty-cycle
;
; Entry: none
; Exit: none, Bank 0 selected
; Ram used: Param78,Param79
; Calls:
;
AdjustPWM	MOVLB	0	;Bank 0
	BTFSS	PWMSyncBit	;time?
	return		; not yet
	BCF	PWMSyncBit
;	bra	AdjustPWM_Lower	;tc
	MOVLB	1
;Increasing the PWM duty cycle increases the voltage.
;Param79:Param78=OutputVolts-VRefVolts
	MOVF	VRefVolts,W
	SUBWF	OutputVolts,W
	MOVWF	Param78
	MOVF	VRefVolts+1,W
	SUBWFB	OutputVolts+1,W
	MOVWF	Param79
;
	BTFSC	Param79,7	;OutputVolts<VRefVolts?
	bra	AdjustPWM_Higher	; yes, adjust higher
	MOVF	Param79,F
	SKPZ		;PWMVolts>TargetBVolts?
	bra	AdjustPWM_Lower	; yes by a lot, adjust lower
	MOVLW	0xFE
	ANDWF	Param78,W
	SKPNZ		;PWMVolts>TargetBVolts+1?
	bra	AdjustPWM_End	; no, we're done
			; yes, adjust lower	
;
AdjustPWM_Lower	MOVLB	5	;Bank 5
	MOVF	PWMValue,F
	SKPNZ
	bra	AdjustPWM_End
	incf	PWMValue,F
	bra	AdjustPWM_Set
;
AdjustPWM_Higher	MOVLB	5	;Bank 5
	incf	PWMValue,W
	SKPNZ		;at 255?
	bra	AdjustPWM_End	; yes
	INCF	PWMValue,F	; no
;
AdjustPWM_Set	movf	PWMValue,W
;	BCF	CCP1CON,DC1B0
;	BTFSC	_C
;	BSF	CCP1CON,DC1B0
;	LSRF	WREG,F
;	BCF	CCP1CON,DC1B1
;	BTFSC	_C
;	BSF	CCP1CON,DC1B1
	MOVWF	CCPR1L
;
AdjustPWM_End	MOVLB	0
	return
;
;=========================================================================================
; Reads analog inputs (call from main loop)
; Read the 5 analog inputs in rotation.
;
; Entry: none
; Exit: none, Bank 0 selected
; Ram used:FSR0
; Calls: (1+0)
;
ReadAnalogInputs	MOVLB	1	;bank 1, ADCON0
	BTFSS	ADC_AquireFlag	;Acquiring?
	BRA	ReadAnalogInputs_1	; No
;
	BCF	ADC_AquireFlag
	BSF	ADC_ConvertFlag
	BSF	ADCON0,ADGO	;Start conversion
	BRA	ReadAnalogInputs_End	; & Exit
;
ReadAnalogInputs_1	BTFSS	ADC_ConvertFlag	;Converting?
	BRA	ReadAnalogInputs_3	; No
;
	BTFSC	ADCON0,ADGO	;Still converting?
	BRA	ReadAnalogInputs_End	; Yes
	BCF	ADC_ConvertFlag
;
	LSLF	CurrentADC,W	;x2
	ADDLW	low RawAN0
	MOVWF	FSR0L
	MOVLW	high RawAN0
	MOVWF	FSR0H
;
	MOVF	ADRESL,W
	MOVWI	FSR0++
	MOVF	ADRESH,W
	MOVWI	FSR0++
;
ReadAnalogInputs_3	INCF	CurrentADC,F
;
	MOVLW	LastADC+1
	SUBWF	CurrentADC,W
	SKPNZ		;Past end?
	clrf	CurrentADC	; Yes, start over at AN0
;
	call	GetANSelectValue
	MOVWF	ADCON0
	BSF	ADC_AquireFlag
;
ReadAnalogInputs_End	MOVLB	0
	return
;
;
GetANSelectValue	movf	CurrentADC,W
	BRW
	retlw	b'00000001'	;AN0
	retlw	b'00000101'	;AN1
	retlw	b'00001001'	;AN2
	retlw	b'00010001'	;AN4
;	
;=========================================================================================
;=========================================================================================
	include	F1938_Common.inc
	include	SerBuff1938.inc
	include	RS232_Parse.inc
;=========================================================================================
;
;
;
;
;
	END
;
