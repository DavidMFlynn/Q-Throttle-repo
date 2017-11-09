;====================================================================================================
;
;    Filename:      RS232_Parse.inc
;    Date:          11/9/2015                                    
;    File Version:  1.0d1
;
;    Author:        David M. Flynn
;    Company:       Oxford V.U.E., Inc.
;    E-Mail:        dflynn@oxfordvue.com
;
;====================================================================================================
;====================================================================================================
; Notes:
;
; History:
; 1.0d1  11/9/2015	Adapted for QD Tester
; 1.0    12/6/2013	First Rev'd version
;
; RS232_Parse	(X/0) Parse any bytes received by the serial port
; Binary data frame	0xFFccddddFF (5 bytes)
;	 Receive 0xFF,Command,Data bytes (2 bytes), 0xFF
;=========================================================================================
; Bank0 variable used by RS232_Parse:
;
;RX_ParseFlags	RES	1
;#Define	SyncByteRXd	RX_ParseFlags,0
;#Define	CmdRXd	RX_ParseFlags,1
;#Define	Data0RXd	RX_ParseFlags,2
;#Define	Data1RXd	RX_ParseFlags,3
;
;RX_Flags	RES	1
;#Define	RXDataValidFlag	RX_Flags,0
;#Define	RXDataIsNew	RX_Flags,1
;
;RX_Command	RES	1
;RX_Data	RES	2
;
; *** put in main loop
;	CALL	RS232_Parse
; if RXDataValidFlag is set data may be used
;
;=========================================================================================
; Parse any bytes received by the serial port
;
; Receive 0xFF,Cmd,Data0,Data1,0xFF
; 
;
; Entry: none
; Exit: none
; Ram Used: Param78, FSR
; Calls (1+0): GetSerIn
;
RS232_Parse	CALL	GetSerIn
	BTFSS	Param78,0
	RETURN
;
;	CALL	StoreSerOut	;tc
;	RETURN		;tc
;
	MOVWF	Param78	;Data Byte RXd
; Command inturpreter
;
RS232_Parse_Sync	MOVF	RX_ParseFlags,F
	SKPZ		;Beginning new packet?
	BRA	RS232_Parse_1	; No
	MOVLW	0xFF
	SUBWF	Param78,W
	SKPNZ		;Sync byte OK?
	BSF	SyncByteRXd	; Yes
	BRA	RS232_Parse
;
; Command
RS232_Parse_1	MOVLW	0x01	;SyncByteRXd
	SUBWF	RX_ParseFlags,W
	SKPZ		;SyncByteRXd only?
	BRA	RS232_Parse_2	; No
	INCF	Param78,W
	SKPNZ		;Extra sync byte?
	BRA	RS232_Parse	; yes
	MOVF	Param78,W
	MOVWF	RX_Command
	BSF	CmdRXd
	BCF	RXDataValidFlag
	BRA	RS232_Parse
;
; Data 0
RS232_Parse_2	MOVLW	0x03	;SyncByteRXd+CmdRXd
	SUBWF	RX_ParseFlags,W
	SKPZ		;Looking for Data0?
	BRA	RS232_Parse_3	; No
;
	MOVF	Param78,W
	MOVWF	RX_Data
	BSF	Data0RXd
	GOTO	RS232_Parse
;
; Data 1
RS232_Parse_3	MOVLW	0x07	;SyncByteRXd+CmdRXd+Data0RXd
	SUBWF	RX_ParseFlags,W
	SKPZ		;Looking for Data1?
	BRA	RS232_Parse_4	; No
;
	MOVF	Param78,W
	MOVWF	RX_Data+1
	BSF	Data1RXd
	GOTO	RS232_Parse
;
; 0xFF, End of packet
RS232_Parse_4	MOVLW	0x0F	;SyncByteRXd+CmdRXd+Data0RXd+Data1RXd
	SUBWF	RX_ParseFlags,W
	SKPZ		;Looking for End of packet?
	BRA	RS232_Parse_5	; No
;
	INCF	Param78,W
	SKPZ		;Is this a sync byte?
	GOTO	RS232_Parse_Error	; No
	CLRF	RX_ParseFlags	; Yes, we're done with this packet
	BSF	RXDataValidFlag
	BSF	RXDataIsNew
	GOTO	RS232_Parse
;
; Somehow we got out of sync
RS232_Parse_5	CLRF	RX_ParseFlags
	INCF	Param78,W
	SKPZ		;Is this a sync byte?
	GOTO	RS232_Parse	; No
	GOTO	RS232_Parse_Sync
;
; We didn't get the sync byte we were expecting so restart the parser
RS232_Parse_Error	CLRF	RX_ParseFlags
	GOTO	RS232_Parse
;
;