; coded by Reverend

;===============================================================================
;       routine encoding some buffer in base64
.DATA
	_b64_table_encode	db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
				db 'abcdefghijklmnopqrstuvwxyz'
				db '0123456789+/='

	_b64_jump_table_encode	dd _encode_finish
				dd _1byte
				dd _2byte
				dd _3byte
				dd _default

.CODE
base64_encode	proc		input, output, len, break
	push	ebx
	push	edi
	push	esi
	mov	ecx, [len]
	xor	edx, edx
	mov	ebx, offset _b64_table_encode
	mov	esi, [input]
	mov	edi, [output]

;-------beginning-of-loop-------------------------------------------------------
  @@encode_loop:
	mov	eax, 4
	cmp	ecx, eax
	cmovna	eax, ecx
	jmp	[_b64_jump_table_encode + eax*4]

;-------handle-all-possibilities-to-prevent-i/o-errors--------------------------
  _1byte	= $
	movzx	eax, byte ptr [esi]
	dec	ecx
	jmp	@@encode
  _2byte	= $
	movzx	eax, word ptr [esi]
	sub	ecx, 2
	jmp	@@encode
  _3byte	= $
	movzx	eax, byte ptr [esi + 2]
	shl	eax, 16
	or	ax, word ptr [esi]
	sub	ecx, 3
	jmp	@@encode
  _default	= $
	mov	eax, dword ptr [esi]
	add	esi, 3
	sub	ecx, 3

;-------encode-the-data---------------------------------------------------------
  @@encode:
	push	eax

;       11111100 00000000 00000000
	and	eax, (00000000b shl 16) or (00000000b shl 8) or 11111100b
	shr	eax, 2
	xlatb
	stosb
	inc	edx
	cmp	edx, [break]
	jnz	@F
	mov	ax, 0D0Ah
	stosw
	xor	edx, edx

;       00000011 11110000 00000000
  @@:
	mov	eax, [esp]
	and	eax, (00000000b shl 16) or (11110000b shl 8) or 00000011b
	shl	al, 4
	shr	ah, 4
	or	al, ah
	movzx	eax, al
	xlatb
	stosb
	inc	edx
	cmp	edx, [break]
	jnz	@F
	mov	ax, 0D0Ah
	stosw
	xor	edx, edx

;       00000000 00001111 11000000
  @@:
	mov	eax, [esp]
	and	eax, (11000000b shl 16) or (00001111b shl 8) or 00000000b
	shr	eax, 8
	shl	al, 2
	shr	ah, 6
	or	al, ah
	movzx	eax, al
	test	ecx, ecx
	jnz	@F
	test	eax, eax
	jnz	@F
	mov	eax, 64
    @@:
	xlatb
	stosb
	inc	edx
	cmp	edx, [break]
	jnz	@F
	mov	ax, 0D0Ah
	stosw
	xor	edx, edx

;       00000000 00000000 00111111
  @@:
	pop	eax
	and	eax, (00111111b shl 16) or (00000000b shl 8) or 00000000b
	shr	eax, 16
	test	ecx, ecx
	jnz	@F
	test	eax, eax
	jnz	@F
	mov	eax, 64
    @@:
	xlatb
	stosb
	inc	edx
	cmp	edx, [break]
	jnz	@@encode_loop
	mov	ax, 0D0Ah
	stosw
	xor	edx, edx
	jmp	@@encode_loop

  _encode_finish = $
	sub	edi, [output]
	mov	eax, edi
	pop	esi
	pop	edi
	pop	ebx
	ret
base64_encode	endp

;    | 00 01 02 03 04 05 06 07 08 09
; ---+------------------------------
; 00 | 41 42 43 44 45 46 47 48 49 4A
; 10 | 4B 4C 4D 4E 4F 50 51 52 53 54
; 20 | 55 56 57 58 59 5A|61 62 63 64
; 30 | 65 66 67 68 69 6A 6B 6C 6D 6E
; 40 | 6F 70 71 72 73 74 75 76 77 78
; 50 | 79 7A|30 31 32 33 34 35 36 37
; 60 | 38 39|2B 2F|3D
.DATA
	_b64_table_decode	db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, 62, -1, -1, -1, 63, 52, 53
				db 54, 55, 56, 57, 58, 59, 60, 61, -1, -1
				db -1, -1, -1, -1, -1, 00, 01, 02, 03, 04
				db 05, 06, 07, 08, 09, 10, 11, 12, 13, 14
				db 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
				db 25, -1, -1, -1, -1, -1, -1, 26, 27, 28
				db 29, 30, 31, 32, 33, 34, 35, 36, 37, 38
				db 39, 40, 41, 42, 43, 44, 45, 46, 47, 48
				db 49, 50, 51, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
				db -1, -1, -1, -1, -1, -1

.CODE
base64_decode	proc		input, output, len
	push	ebx
	push	edi
	push	esi
	mov	ecx, [len]
	mov	ebx, offset _b64_table_decode
	mov	edi, [output]
	mov	esi, [input]

  @@loop:
	xor	eax, eax
  @@:
	dec	ecx
	js	@@no_input
	lodsb
	xlatb
	test	al, al
	js	@B
	mov	edx, eax
	shl	edx, 2

  @@:
	dec	ecx
	js	@@save_last
	lodsb
	xlatb
	test	al, al
	js	@B
	mov	ah, al
	shr	al, 4
	shl	ah, 4
	or	edx, eax
  @@:
	dec	ecx
	js	@@save_last
	lodsb
	xlatb
	test	al, al
	js	@B
	mov	ah, al
	shr	al, 2
	shl	ah, 6
	shl	eax, 8
	or	edx, eax
  @@:
	dec	ecx
	js	@@save_last
	lodsb
	xlatb
	test	al, al
	js	@B
	shl	eax, 16
	or	edx, eax
	mov	[edi], edx
	add	edi, 3
	jmp	@@loop

  @@save_last:
	mov	[edi], edx
	add	edi, 3

  @@no_input:
	sub	edi, [output]
	mov	eax, edi
	pop	esi
	pop	edi
	pop	ebx
	ret
base64_decode	endp