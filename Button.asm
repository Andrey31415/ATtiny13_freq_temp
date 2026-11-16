    ; 1. Проверяем физический уровень. Если кнопка отпущена — сразу уходим
	sbic	PINB, BUT    
	reti

    ; 2. Вычисления смещения и записи в EEPROM (средина $49 между 50=$6b и 60=$2c)
	ldi	 tmp_0, $6a
;	mov	tmp_1, cur_val
    ; --- СИСАДМИНСКИЙ СБРОС СТАРОЙ КОРРЕКЦИИ ---
    mov     tmp_1, cur_val       ; Берем текущее (уже искаженное калибровкой) значение
    sub     tmp_1, calibr        ; ВЫЧИТАЕМ старый calibr. Теперь в tmp_1 строго "сырой" период!

	cpi	tmp_1, $49
	brsh	set_calibr
	ldi	 tmp_0, $2c

set_calibr:
	sub	tmp_0, tmp_1
	mov	calibr, tmp_0
	ldi	tmp_1,	$01		; Адрес в EEPROM для калибровки
	rcall	write_byte
WAIT_EEPROM:
	sbic EECR, EEPE		; Ожидаем окончагние записи в EEPROM
	rjmp WAIT_EEPROM

wait_release:
    ; 3. Дожидаемся, пока отпустят кнопку:
	sbis	PINB, BUT		; Ждем, пока на PB3 снова не появится "1" (кнопку отпустили)
	rjmp	wait_release

	sts   Y1_L, ZER
	sts   Y1_H, ZER
	sts   Y2_L, ZER
	sts   Y2_H, ZER

    ; 4. Сбрасываем взведенный флаг PCINT, 
    ; который неизбежно появился в регистре флагов при отпускании кнопки и её дребезге.
	ldi	tmp_0, (1<<PCIF)
	out	GIFR, tmp_0      ; Запись единицы в GIFR очищает флаг PCIF!
