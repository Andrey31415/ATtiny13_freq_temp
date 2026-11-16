; На входе Х0 -  r21:r20
; На выходе y1 - r21:r20, y0 - r17:r16

; === КАСКАД 1: Y1 = Y1 + (X0 - Y1) >> 4 ===
	lds	r18, Y1_L
	lds	r19, Y1_H     ; Достали старый Y1

	movw	r17:r16, r21:r20  ; Копируем X0
	sub	r20, r18
	sbc	r21, r19      ; r21:r20 = (X0 - Y1)

	; Сдвиг на 4 (деление на 16)
    asr	r21
    ror	r20
    asr	r21
    ror	r20
    asr	r21
    ror	r20
    asr	r21
    ror	r20

	add	r18, r20
	adc	r19, r21      ; r19:r18 = Новый Y1

    ; ===--- ЛИМИТЕР ДЛЯ Y1 ---===
    cpi   r19, $02
    brge  reset_y1        ; Если старший байт >= 2, улетели вверх
    cpi   r19, $fd
    brlt  reset_y1        ; Если старший байт < 0xFD (-3), улетели вниз
    rjmp  save_y1

reset_y1:
    mov   r18, ZER        ; Насильно гасим автоколебания в ноль
    mov   r19, ZER

save_y1:
	sts	Y1_L, r18
	sts	Y1_H, r19

; === КАСКАД 2: Y2 = Y2 + (Y1 - Y2) >> 4 ===
	lds	r20, Y2_L
	lds	r21, Y2_H     ; Достали старый Y2

	movw	r17:r16, r19:r18 ; Берем результат первого каскада (Y1)
	sub	r16, r20
	sbc	r17, r21      ; r17:r16 = (Y1 - Y2)

	; Сдвиг на 4 (деление на 16)
    asr	r17
    ror	r16
    asr	r17
    ror	r16
    asr	r17
    ror	r16
    asr	r17
    ror	r16

	add	r20, r16
	adc	r21, r17      ; r21:r20 = Новый Y2 (Финальный выход фильтра!)

	; ===--- ЛИМИТЕР ДЛЯ Y2 ---===
    cpi   r21, $02
    brge  reset_y2
    cpi   r21, $fd
    brlt  reset_y2
    rjmp  save_y2

reset_y2:
    mov   r20, ZER        ; Если второй каскад пошел в разнос — гасим его
    mov   r21, ZER

;save_y2:
;; ===
;    ; Проверка верхнего лимита (> 511, то есть > 0x01FF)
;    cpi   r18, low(512)
;    ldi   r16, high(512)
;    cpc   r17, r16
;    brge  reset_filter       ; Если улетели в космос — на сброс
;
;    ; Проверка нижнего лимита (< -512, то есть < 0xFE00)
;    cpi   r18, low(-512)
;    ldi   r16, high(-512)
;    cpc   r17, r16
;    brlt  reset_filter       ; Если пробили дно — на сброс
;    rjmp  save_y1
;
;reset_filter:
;    clr   r18
;    clr   r19                ; Насильно обнуляем каскад
;
;save_y1:
;; ===
save_y2:
	lds	r16, Y2_L
	lds	r17, Y2_H
	sts	Y2_L, r20
	sts	Y2_H, r21

;	; На выходе: в r21:r20 находится y1 (текущий отфильтрованный отсчет)