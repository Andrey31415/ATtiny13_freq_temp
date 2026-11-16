; На входе регистр pseg = сегменту, который будет показываться
; В адресе Flash Dig -  два байта с двоично-десятичными данными индикатора:  10 X2 

	ldi yh, HIGH(Pos)
	ldi yl, LOW(Pos)

	mov tmp_0, pseg
	lsr tmp_0

	add yl, tmp_0
	adc yh, ZER
	ld tmp_0, y

	sbrc pseg, 0
	swap	tmp_0
	andi tmp_0, $0f
	
	ldi zh, HIGH(Dig*2)
	ldi zl, LOW(Dig*2)
	add zl, tmp_0
	adc zh, ZER
	lpm tmp_0, z

; Всегда рисуем точку в среднем сегменте	
	cpi	pseg, 1
	brne	wo_point
	sbr	tmp_0, $08
;	sbr	tmp_0, $01		; для Тараса
; Продвинем биты из tmp_0 в 164/595 регистр 
wo_point:
	cbi PortB, LC	; Убираем сигнал продвижения байта на ыход для 595 регистра
	ldi tmp_1, 8
NextS:
	cbi PortB, SH	; Цикл сдвига битов из tmp_0 в 164/595 регистр
	sbrc tmp_0, 7
	rjmp SetBit
	DISP_LOW
	rjmp Shift
SetBit:
	DISP_HIGH
Shift:
	sbi	PortB, SH	
	lsl tmp_0
	dec tmp_1
	brne NextS
	sbi PortB, LC	; Продвигаем байт 595 регистра на выход

; А вот тепрь установим сигналы управления знакоместами
	cpi pseg, 2
	brne Vis1
;	sbi PortB, LC
	cbi PortB, SH
	cbi PortB, DAT
	rjmp EndDisp
Vis1:
	cpi pseg, 1
	brne Vis0
	sbi PortB, DAT
	cbi PortB, LC
	cbi PortB, SH
	rjmp EndDisp
Vis0:
    cpi pseg, 0
	breq Vis2
	ldi	pseg, $02
Vis2:
;	sbi PortB, SH
	cbi PortB, DAT
	cbi	PortB, LC

;; для Тараса
;	cpi pseg, 2
;	brne Vis1
;	cbi PortB, LC
;;	sbi PortB, SH
;	sbi PortB, DAT
;	rjmp EndDisp
;Vis1:
;	cpi pseg, 1
;	brne Vis0
;	cbi PortB, DAT
;;	sbi PortB, LC
;;	sbi PortB, SH
;	rjmp EndDisp
;Vis0:
;    cpi pseg, 0
;	breq Vis2
;	rjmp	Zatyk
;Vis2:
;	cbi PortB, SH
;	sbi PortB, DAT
;;	sbi	PortB, LC
EndDisp:
