    LED_ON

	mov tmp_0, ow_state
	cpi	tmp_0, 2		; Если tmp_0=ow_state == 2, то продолжаем
	brne next_rs_3		; иначе скачем на проверку других тиков

	sbi   DDRB, OW_BIT
	ldi tmp_0, 79
    out	OCR0A, tmp_0
	rjmp	Skip_1Wire_Phase

next_rs_3:				
	cpi tmp_0, 5			; Если tmp_0=ow_state < 5, то заканчиваем этот такт
	brsh next_rs_5			; иначе - продолжаем
    rjmp	Skip_1Wire_Phase
next_rs_5:
    cbi	DDRB, OW_BIT		; Отпускаем шину 1-wire в 1
;	cpi	tmp_0, 5			; Если tmp_0=ow_state != 5, то продолжаем
	breq st_wait			; иначе переходим к ожиданию ответа

	cpi	tmp_0, 6			; Такт 6 Готовим передачу команды 0xCC и более ничего
	brne	next_comp		; иначе продолжаем автомат
	ldi	tmp_0, $CC
	mov	ow_buf, tmp_0
	rjmp	Skip_1Wire_Phase

next_comp:
	cpi tmp_0, 15
	brne next_wr_44			; иначе меняем ow_buf на команду датчику

	ldi	tmp_1, $44			; Установим в tmp_1 команду 0х44
	mov	tmp_0, ow_wait
	cpi tmp_0, ds18b20_wait		; Если мы находимся в инициализации измерения, то скачим на передачу
	breq set_ow_buf		
	ldi	tmp_1, $be			; иначе установим в tmp_1 команду 0хbe
set_ow_buf:
	mov	ow_buf, tmp_1		; Записываем команду в регистр вывода
	rjmp st_bit_wr			; Переходим к передаче байта

next_wr_44:
	cpi	tmp_0, 23
	brne prod_rd

	ldi	tmp_0, 20			; Пауза для последующего чтения первого бита 
	out OCR0A, tmp_0

	mov	tmp_1, ow_wait
	cpi	tmp_1, ds18b20_wait	; Если такт "ожидания измерения", то начинаем уменьшать счетчик
	brne next_rd			; иначе переходим к чтению температуры

	dec ow_wait				; уменьшаем счетчик ожидания измерения
	clr	ow_state			; обнуляем статусы автомата дптчика
	inc ow_state			; запускаем автомат с 1-го такта
	rjmp	Skip_1Wire_Phase

prod_rd:
	brsh	next_rd

st_bit_wr:
    mov tmp_1, ow_state
	cpi	tmp_1, 7
	breq st_rep_wr
	cpi tmp_1, 15
	breq st_rep_wr
	lsr	ow_buf
st_rep_wr:
	sbi	DDRB, OW_BIT	   ; Шину 1-wire притянуть в 0. Старт передачи бита
st_wait:
	ldi	tmp_0, 86          ; <-- ВЫЧИСЛЕНО: Идеальный "0" (~65 мкс с учетом всех задержек)
	sbrc ow_buf, 0         ; Проверяем нулевой бит
	ldi	tmp_0, 14          ; <-- ВЫЧИСЛЕНО: Идеальная "1" (~9 мкс с учетом всех задержек)
st_read:
	out	OCR0A, tmp_0
next_rd_bit:
    ldi tmp_0, (1<<OCIE0A|1<<TOIE0)
	out TIFR0, tmp_0
	out TIMSK0, tmp_0
rjmp	Skip_1Wire_Phase

next_rd:
	cpi	tmp_0, 39
	brsh ow_calculate_osccal

	sbi   DDRB, OW_BIT			; Линию в 0
    ldi   tmp_0, 6				; [1 т.]
delay_start:
    dec   tmp_0					; [1 т.]
    brne  delay_start			; [2 т.]                       ; Держим 2 мкс
	cbi   DDRB, OW_BIT			; Отпустили
	rjmp next_rd_bit

; === ТИК 14: МАТЕМАТИКА КОРРЕКЦИИ OSCCAL ===
ow_calculate_osccal:
;	ldi yh, HIGH(Pos)
;	ldi yl, LOW(Pos)

	ldi   tmp_1, 56
	sub   tmp_1, ow_buf     ; Если ow_buf > 48, то C = 1
;	st	Y, ow_buf

	mov   tmp_0, tmp_1
	brcc  no_carry          ; Если C = 0 (температура <= 48), перепрыгиваем
	neg   tmp_0             ; Если C = 1 (температура > 48), инвертируем остаток, чтобы сглаживал в другую сторону.
no_carry:
	andi  tmp_0, $03
	mov   calibr, tmp_0


	asr   tmp_1
	asr   tmp_1
	add   tmp_1, osc

	out   OSCCAL, tmp_1

	dec	ow_wait			; Перезапуск цикла измерения и чтения температуры
	clr	ow_state
	inc ow_state
Skip_1Wire_Phase:
