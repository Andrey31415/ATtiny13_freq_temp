; Подпрограмма записи байта в EEPROM по адресу из tmp_1 байта из tmp_0
; Вахно! на момент выхода запись еще продолжается и прерывания разрешать нельзя
write_byte:
	; Ожидаем окончания предыдущей записи
	sbic	EECR, EEPE
	rjmp	write_byte
	; Устанавливаем режим программирования
	out		EECR, ZER
	out		EEARL, tmp_1        ; Задаем адрес 0x00 в EEPROM
	out		EEDR, tmp_0		; Записываем полученную команду

	; Устанавливаем EEMPE в 1 в регистр EECR
	sbi		EECR, EEMPE
	; Стартуем запись в EEPROM
	sbi		EECR, EEPE
	ret

; Подпрограмма чтения байта из EEPROM по адресу из tmp_1
; Выход в тот же tmp_1 - считанный байт
read_byte:
	sbic	EECR, EEPE        ; Ждем готовности EEPROM, если была запись
	rjmp	read_byte
	out		EEARL, tmp_1      ; Задаем адрес в EEPROM
	sbi		EECR, EERE        ; Выставляем строб чтения
	in		tmp_1, EEDR       ; В TMP_1 считанный из EEPROM
	ret
