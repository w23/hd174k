; hd174k, a <s>4k</s> 854bytes intro by Ye Olde Laptops Posse
; 	code: w23 (me@w23.ru)
; 	color model: korvin
;		additional help: decelas

; created somewhere in the middle of august 2011
; released 28.08.2011 @ Hackday17, Novosibirsk, Russia

; PARTYVERSION, WITHOUT SOUND (is incomplete atm)

; Params
%define WIDTH   720
%define HEIGHT  480
%define LENGTH  120
;%define	FULLSCREEN	0x80000000
%define FULLSCREEN	0

; Useful!
%define BSSADDR(a) ebp + ((a) - bss_begin)
%define F(f)	[ebp + ((f) - bss_begin)]

; where to load?
org     0x00040000

; x86, not x86-64
BITS 32

ehdr:
; ELF magic
db 0x7f
db 'ELF'
db 1		;	EI_CLASS == ELFCLASS32
db 1		; EI_DATA
db 1		; EI_VERSION
db 0		; ?? abi
times 8 db 0 	; -- unused -- 8 --

dw 2	; e_type = ET_EXEC
dw 3	; e_machine	=	EM_386
dd 1	; e_version = EV_CURRENT
dd _start		; e_entry
dd phdrs - $$		; e_phoff
dd 0		; e_shoff
dd 0		;	e_flags			-- possibly unused -- 4
dw ehdrsize		;	e_ehsize == sizeof(Elf32_Ehdr)
dw phdrsize		;	e_phentsize == sizeof(Elf32_Phdr)
dw 3		;	e_phnum
phdrs:
;dw 0		;	e_shentsize	-- unused --
;dw 0		;	e_shnum			-- unused --
;dw 0		;	e_shstrndx	-- unused -- 6 --

ehdrsize 	equ 	($-ehdr) + 6

; end of elf header

;phdrs:
; program and data
dd 1		; p_type = PT_LOAD
dd 0		; p_offset
dd $$		; p_vaddr
dd $$		; p_paddr			-- possibly unused -- 4
dd file_size		;	p_filesz
dd mem_size		;	p_memsz
dd 7		;	p_flags = PF_X | PF_R | PF_W
dd 0x1000		;	p_align
; end of phdr 1
phdrsize 	equ 	($-phdrs)
dd 2     ; PT_DYNAMIC
dd dynamic - $$
dd dynamic
dd dynamic
dd dynamic_size
dd dynamic_size
dd 6     ; PF_R | PF_W
dd 4
; end of phdr 2
dd 3		; p_type = PT_INTERP
dd interp - $$		; p_offset
dd interp
dd interp
dd interp_size
dd interp_size
dd 4
dd 1

; oh data

interp:	db	'/lib/ld-linux.so.2', 0
interp_size equ $ - interp

dynamic_unpadded:
times (4 - (($$-$) % 4)) db 0x23
dynamic:
	dd 	1,	libdl_name	; DT_NEEDED
;	dd	1,	libSDL_name	; DT_NEEDED
;	dd	1,	libGL_name	; DT_NEEDED
dd 4,	hash	; DT_HASH
dd 5,	strtab	; DT_STRTAB
dd 6,	symtab	; DT_SYMTAB
dd 10, strtab_size	; DT_STRSZ
dd 11, symtab_size	;	DT_SYMENT
dd 17, reltext		;	DT_REL
dd 18, reltext_size		;	DT_RELSZ
dd 19, 8	;	DT_RELENT
symtab:	; overlaps
dd 0, 0	; DT_NULL - end of .dynamic section
dynamic_size equ $ - dynamic 

;dd 0, 0 overlaps
dd 0
dw 0, 0		; SHN_UNDEF
dd dlopen_name, 0, 0
dw 0x12, 0		; { 19, 0, 0, ELF32_ST_INFO(STB_GLOBAL, STT_FUNC), STV_DEFAULT, SHN_UNDEF },
dd dlsym_name, 0, 0
dw 0x12, 0		; { 12, 0, 0, ELF32_ST_INFO(STB_GLOBAL, STT_FUNC), STV_DEFAULT, SHN_UNDEF
; symtab_count equ 3
symtab_size equ $ - symtab

; copied from gcc+ld-generated executable
; don't really get the meaning
hash:
dd 1, 3	; buckets, chains
dd 2
dd 0, 0, 1	; ???

strtab:
	libdl_name equ $ - strtab
	db 	'libdl.so.2', 0
	dlopen_name equ $ - strtab
	db 	'dlopen', 0
	dlsym_name equ $ - strtab
	db 	'dlsym', 0	
	strtab_size equ $ - strtab

reltext:
	dd	dlopen_rel
	db	1, 1, 0, 0
	dd	dlsym_rel
	db	1, 2, 0, 0
reltext_size equ $ - reltext

;;;;;
; program
;;;;;

_start:

	; edi почему-то содержит в себе адрес _start
	; TODO: как можно этим воспользоваться при загрузке bss_begin в ebp?
;	lea	ebp, [edi+(bss_begin - _start)]	; ЖИРНАЯ ИНСТРУКЦИЯ 6 БАЙТ
	
	mov	ebp, bss_begin	; 5 байт и жмется лучше

;	mov ebp, edi ;	add ebp, (bss_begin - _start) ; 8 байт! пиздец!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; dynamic linking {

;	lea edi, [BSSADDR(libs_syms)]			; edi <- места для адресов функций							3 байт
;	lea esi, [BSSADDR(libs_to_dl+1)]	; esi <- строки с именами библиотек и функций, 	6 байт
	
;	mov	esi, libs_to_dl+1											; 5b
;	lea edi, [esi+(libs_syms-libs_to_dl)-1]		;	6b

	mov esi, libs_to_dl+1						; 5b
	lea edi, [BSSADDR(libs_syms)]		; 3b

;	TODO: push/call участки можно как-нибудь объединить наверняка,
; 	тем самым удавив это все еще байт на 10

ld_load:
	dec esi
	push	1
	push	esi
	call	[BSSADDR(dlopen_rel)]
;	add esp, 8   ; do we need it really? let's pollute the stack! it's FUN
	mov ebx, eax	

; скипаем все до \0
ld_skip_to_zero:

	lodsb
	test al, al
	jnz ld_skip_to_zero

; если следующий тоже \0 то конец
	lodsb
	test al, al
	jz ld_second_zero

; это еще не конец, куда собрался, это еще не конец!
	dec esi
	push esi
	push ebx
	call	[BSSADDR(dlsym_rel)]
	stosd
	jmp	ld_skip_to_zero

ld_second_zero:
	; если третий не ноль, то подгрузим что-нибудь еще!
	lodsb
  test al, al
	jnz	ld_load

	; первые 8 байт после .bss (ebp) нам больше не нужны!

;; } dynamic linking
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; prepare constants for teh synth

; globals

; OLD
;	push	dword 44100
;	fild	dword [esp]				;	{44100;}
;	push	dword 32767
;	fild	dword [esp]				; {32767, 44100;}
;	push	dword 0x40c90fdb	; 2pi
;	push	dword	0x40490fdb	; pi
;	fld	dword [esp]					; {2pi, 32767, 44100;}

;	fldpi

; частота
	fldz
	fldz

; огибающая
	fldz
	fldz										; {env(=0), de(=0), phase(=0), dp(=0);}
	fnsave 	[BSSADDR(snd_reg_state)]

; lets USE something
	push 0x31									; SDL_INIT_ TIMER | AUDIO | VIDEO
	call F(SDL_Init)

	push 0
	push SDL_AudioSpec
	call F(SDL_OpenAudio)

	push 	2 | FULLSCREEN	; SDL_OPENGL
	push	32
	push	HEIGHT
	push	WIDTH
	call	F(SDL_SetVideoMode)
;call    errcheck

	; WxH уже есть в стеке! cdecl ftw!
	push 0
	push 0
	call F(glViewport)
;call    errcheck
	call F(SDL_ShowCursor)
	call F(SDL_PauseAudio)

	; shaders
	
	call F(glCreateProgram)
;call    errcheck
	mov edi, eax
	xor	esi, esi
	mov si, 0x8B31
	mov dword [ebp], shader_vtx
	call shader
	dec esi
	mov dword [ebp], shader_frg
	call shader
	push edi
	call  F(glLinkProgram)
;call    errcheck
	call  F(glUseProgram)
;call    errcheck
	jmp shaders_end

shader:
		push 	esi
		call	F(glCreateShader)
;		call 	errcheck
		mov		ebx, eax
		push	0
		push	ebp
		push	1
		push	eax
		call	F(glShaderSource)
; NVIDIA drivers spoil our stack! the angriness!
		push	 ebx
;		call    errcheck
		call	F(glCompileShader)
;		call    errcheck
; lol nvidia
		push	ebx
		push	edi
		call	F(glAttachShader)	; TODO: reuse ret ! (gcc does that!)
;		call    errcheck
; doesn't work on some drivers (intel?)
;		call	F(glLinkProgram)
;		call	F(glUseProgram)

;		add		esp, 4*8
		pop	eax
		pop	eax
		pop	eax
		pop	eax
		pop	eax
		pop	eax
		pop	eax
		pop	eax
; pops give -1 compressed byte
		ret

;errcheck:
;	pushad
;	call F(glGetError)
;	cmp	eax, 0
;	popad
;	jz	noerr
;	int 3
;noerr:
;	ret
	
shaders_end:

	; edi == program

;	fldpi
;	f2xm1	;	= 2^pi - 1 ~= 7
;	f2xm1	;	~= 2^7 - 1 = 127
	push	dword 5000
	fild	dword [esp]
	sub		esp, 108
	fnsave	[esp]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VECHNY CIKL LOLZ

mainloop:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; THE POLEZNAYA RABOTA

	call F(SDL_GetTicks)
	; eax == time

	frstor	[esp]
	mov		[ebp], eax
	fild	dword [ebp]
	fadd	st1
	fdiv	st0, st1
	fst		dword [ebp]
	mov		eax, [ebp]
	fchs
	fstp	dword [ebp]
	mov		ebx, [ebp]
	push 	ebx
	push	ebx
	push	eax
	push	eax
	call 	F(glRectf)

;add		esp, 4*4
; vs
	pop	eax
	pop	eax
	pop	eax
	pop eax
; pop x 4 = 1 byte less, lol
	fnsave	[esp]

;; END OF THE RABOTA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	call [BSSADDR(SDL_GL_SwapBuffers)]

	lea	edx, [BSSADDR(SDL_Event)]
	push	edx
	call	F(SDL_PollEvent)
	pop	edx
	cmp	byte [edx], 2
	jnz	mainloop

;; LOOP ENDS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RUN AWAY! TO THE HELICOPTER!

	call	F(SDL_Quit)
	xor	eax, eax
	inc	ax
	; xor ebx, ebx  ; couldn't care less
	int	0x80

;;;;;;;;;;;
;; UADIO

snd_play:
	mov		eax, [esp+8]
	mov		ecx, [esp+12]
	shr		ecx, 1
	pushad
	mov   ebp, snd_reg_state
	frstor  [ebp]   ; {env, de, phase, dp;}
snd_loop:
	mov		ebx,	[ebp+snd_reg_size]
	dec		ebx
	jns		snd_proc

	; update state
	xor		ebx, ebx
	mov		esi,	[ebp+snd_reg_size+4]
	mov		bx,	word [snd_pattern+4*esi]
	shl		ebx, 1

; update env
  fsub	st0, st0		; {env=0, ...}
	push  0x3a9b9f23
	fld dword [esp]		; {c_de, env, de, ...}
	fstp  st2					;	{env(=0), de(=c_de), phase, dp;}

; update phase delta
	push  dword 44100
	fild	word [snd_pattern+4*esi+2]	; {freq, env, de, phase, dp;}
	fadd	st0, st0 	; * 2		; {freq*2, ...}
	fldpi	;	{pi, freq*2, ...}
	fmulp	;	* pi	; {pi*freq*2, ...}
	fild	dword [esp]	; {rate, pi*freq*2, ...}
	fdivp						; / rate	; {2*pi*freq/rate, env, de, phase, dp;}
	fstp  st4

	inc	esi
	and	esi, 7
	mov	[ebp+snd_reg_size+4], esi

	; esi is not needed anymore here
	pop esi
	pop esi

snd_proc:	; fpu : {env, de, phase, dp;}
	mov		[ebp+snd_reg_size], ebx

; update env
	fadd  st1
	fldpi	; {pi, env}
	fcomip	st0, st1	; {env, de, phase, dp;}
	jnc	snd_env_no_overflow	; st0<st1?
	fsub	st0, st0	; {env(=0), de, phase, dp;}
	fstp	st1	; {de(=0), phase, dp;}
	fldpi	; {env(=pi), de, phase, dp;}
	
snd_env_no_overflow:
	fld	st0
	fsin	; {envsig, env, de, phase, dp;}

; update phase
	fld	st3		; {phase, envsig, env, de, phase, dp;}
	fadd	st0, st5
	fst	st4
	fsin	; {signal, envsig, env, de, phase, dp;}

; mix signal+envelope
	fmulp	; {mixed, env, de, phase, dp;}

; delay fx BROKEN? HOW COULD THAT BE?!
	lea	edi, [ebp+(snd_delay_buffer-snd_data)]
	lea	esi, [edi+4]
	push ecx
	mov	ecx, snd_delay_size-1
	fld	dword [edi]
	fldpi
	fdivp
	faddp
	rep movsd
	fst dword [esi-4]
	pop ecx

; output
	mov	word [eax], 16383 ;32767
	fild	word [eax]
	fmulp
	
; output
;	fmul	st0, st4
	fistp	word [eax]
	add		eax, byte 2

; fixme !!
;	loop snd_loop
	dec ecx
	jnz	snd_loop

	fnsave	[ebp]
	popad
	ret

;;;;;
; data
;;;;;

shader_vtx:
	db	'varying vec4 p;'
	db	'void main(){p=gl_Position=gl_Vertex;p.z=length(p.xy);}'
	db	0

shader_frg:
	db	'varying vec4 p;'
	db	'void main(){'
	db	'float c,f=p.z;'
	db	'vec2 '
	db	'v=4.*vec2(sin(-f),cos(-f)),'
	db	'h=7.*vec2(sin(f*3.),cos(f*3.));'
	db	'c=sin(3.*p.x+v.x)*sin(4.*p.y+v.y)'
	db	'+sin(7.*p.x+h.x)*sin(2.*p.y+h.y);'
	db	'gl_FragColor='
	db	'vec4(c*c,c/5.+.3,log2(c)+exp(c),0.);'
	db	'}'
	db	0

; END of known
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; more technical bootstrapping stuff

; libraries to load
libs_to_dl:
;db	'libSDL-1.2.so.0', 0
db	'libSDL.so', 0
	db	'SDL_Init', 0
	db	'SDL_SetVideoMode', 0
	db	'SDL_PollEvent', 0
	db	'SDL_GetTicks', 0
	db	'SDL_OpenAudio', 0
	db	'SDL_ShowCursor', 0
	db  'SDL_PauseAudio', 0
	db	'SDL_GL_SwapBuffers', 0
	db	'SDL_Quit', 0
	db	0
db	'libGL.so', 0
	db	'glViewport', 0
	db	'glCreateShader', 0
	db  'glShaderSource', 0
	db  'glCompileShader', 0
	db  'glCreateProgram', 0
	db  'glAttachShader', 0
	db  'glLinkProgram', 0
	db  'glUseProgram', 0
	db	'glRectf', 0
	db	0, 0

SDL_AudioSpec:
	dd 44100
	dw 0x8010			; S16SYS
	db 1					; channels
	times 9 db 0
	dd snd_play

; todo: 2^(1/12) == 0x3f879c7d use that!
;snd_delta_env:
;	dd	0x3a9b9f23
snd_pattern:
	dw	11050, 440
	dw	 5525, 587
	dw	 5525, 659
	dw	11050, 784
	dw	11050, 440
	dw	 5525, 587
	dw	 5525, 659
	dw	11050, 988

file_size equ	($-$$)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; .bss
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ABSOLUTE $

bss_begin:

libdl_syms:
dlopen_rel: resd 1
dlsym_rel: resd 1

libs_syms:
SDL_Init: resd 1
SDL_SetVideoMode: resd 1
SDL_PollEvent: resd 1
SDL_GetTicks: resd 1
SDL_OpenAudio: resd 1
SDL_PauseAudio: resd 1
SDL_ShowCursor: resd 1
SDL_GL_SwapBuffers: resd 1
SDL_Quit: resd 1
glViewport: resd 1
glCreateShader: resd 1
glShaderSource: resd 1
glCompileShader: resd 1
glCreateProgram: resd 1
glAttachShader: resd 1
glLinkProgram: resd 1
glUseProgram: resd 1
glRectf: resd 1

SDL_Event: resb 24

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
snd_data:

snd_reg_size equ 108 ; может 94 тоже охуенчик?
snd_reg_state: resb snd_reg_size
snd_evt_countdown:	resd 1
snd_evt_line:	resd 1

snd_delay_size	equ 16575
snd_delay_buffer:	resd snd_delay_size

mem_size equ ($-$$)
