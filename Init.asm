	
	ldi		tmp_0, LOW(RAMEND)
	out		SPL, tmp_0
	
	clr		ZER

	in	tmp_0, OSCCAL
;	ldi	tmp_0, $2f
	mov	osc, tmp_0

;;	Изначально в ЕЕПРОМ по адресу $01 надо записать $00 - калибровочное смещение
;	ldi		tmp_1, $01
;	rcall	read_byte
;	mov		calibr, tmp_1

;;	Изначально в ЕЕПРОМ по адресу $00 надо записать фабричны калибровочный байт для частоты 9.6 МГц
;	clr		tmp_1
;	rcall	read_byte
;	out		OSCCAL, tmp_1

; Настройка портов	
	out		PortB, ZER
;.if SIMULATION == 1
;	ldi		tmp_0, (1<<DAT|1<<SH|1<<LC|1<<LED) 		; 
;.else
	ldi		tmp_0, (1<<DAT|1<<SH|1<<LC)  
;.endif
    out		DDRB, tmp_0     ; Настраиваем PB0 на выход

; Настройка таймера
	ldi		tmp_0, $00		;
	out		TCCR0A, tmp_0
	ldi		tmp_0, (1<<CS01)		; Fпрерывания = f / 8 / 256 = 4687,5 Гц Tt = 213 икс (В периоде синуса 50Гц примерно 94 такта).
	out		TCCR0B, tmp_0

	ldi		tmp_0, (1<<TOIE0)
	out		TIMSK0, tmp_0

; --- НАСТРОЙКА АЦП (С автоматическим триггером от Таймера 0) ---
; REFS0 = 0 -> Опорное напряжение VCC
; MUX1:0 = 00 -> Вход ADC2 (пин PB4)
	ldi		tmp_0, P_ADC                      
	out		ADMUX, tmp_0

; ADATE = 1 -> Включить автотриггер
; ADPS2:0 = 110 -> Делитель частоты АЦП на 64 (9.6 МГц / 64 = 150 кГц)
; Одно преобразование займет 13 тактов АЦП = 87 мкс
	ldi		tmp_0, (1<<ADEN|1<<ADATE|1<<ADSC|1<<ADPS2|1<<ADPS1)
	out		ADCSRA, tmp_0

; ADCSRB: TS2:0 = 011 -> Источник триггера: переполнение таймера
; Как только таймер дойдет до OVF, АЦП сам начнет замер, без участия ядра!
	ldi		tmp_0, (1<<ADTS2)		;(1<<ADTS1|1<<ADTS0)
	out		ADCSRB, tmp_0

;; Настройка прерывание от кнопки	
;    sbi		PORTB, BUT			; Включаем Pull-up резистор на PB3 (если кнопка на землю)
;    
;    ldi		tmp_0, (1<<PCIE)
;    out		GIMSK, tmp_0     ; Разрешаем общее прерывание Pin Change Interrupt
;    
;    ldi		tmp_0, (1<<PCINT3)
;    out		PCMSK, tmp_0     ; Маскируем прерывание строго на ножку PB3

; Ну и наконец исходные значения переменных
	ldi		rdis, period_disp
	ldi		pseg, 2
	ldi		obnov, Disp_new

	clr	ow_state
	inc	ow_state
	clr ow_wait
	dec ow_wait
	
	clr calibr

	clr		xl

	sts		Smooth_l, ZER
	sts		Smooth_h, ZER
