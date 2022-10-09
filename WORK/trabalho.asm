.model small

.STACK
.DATA
    hFile    DWORD 0
    pMemory  DWORD 0
    ReadSize DWORD 0
    Buffer  DB 0
    FHndl   DW 0
    temp    DB 0

.CONST
    FileName DB	"texto.txt", 0    

.CODE ; Begin code segment
.STARTUP ; Generate start-up code
    mov ah, 3Dh ; Open the file
    mov al, 0 ; Open for reading
    lea dx, Filename ; Presume DS points at filename
    int 21h ; chama uma função do MS-DOS
    jc BadOpen
    mov FHndl, ax ; Save file handle

LP: 
    mov ah, 3Fh ;; 3fh é o opcode de readFile no MS-DOS
    lea dx, Buffer ; Address of data buffer
    mov cx, 1 ;Read one byte
    mov bx, FHndl ;Get file handle value
    int 21h ; chama uma função do MS-DOS
    jc ReadError 
    
    cmp ax, cx ;EOF reached?
    jne EOF

    mov al, Buffer
    call printChar


    jmp LP ;Read next byte
EOF: 
    mov bx, FHndl
    mov ah, 3Eh  ;Close file
    int 21h ; chama uma função do MS-DOS
    jc CloseError

    call readChar

here:


.EXIT ; Generate exit code

;; procedimentos
;
;--------------------------------------------------------------------
;Funcao: imprime um char na tela
;Entra:  (A) -> AL -> char a ser impresso
;--------------------------------------------------------------------
printChar proc near 
    mov ah, 0Eh ; imprime cada caractere incrementando o cursor 
    mov bh, 0 ; page number (???)
    mov cx, 1 ; times to print the character
    int 10h ;calls interruption
    ret
printChar endp
;
;--------------------------------------------------------------------
;Funcao: Lê char enquanto não lê enter e imprime na tela
;Entra:  (A) -> AX -> Valor "Hex" a ser convertido
;        (S) -> DS:BX -> Ponteiro para o string de destino
;--------------------------------------------------------------------
readChar proc near
    mov ah, 0h      ;; seta modo
    int 16h         ;; pra ler caractere do teclado
    call printChar  ;; imprime caractere lido
    cmp al, 0Dh     ;; compara se caractere é enter
    jz here         ;; se for, condição de parada 
    call readChar   ;; se não, continua chamadas recursivas
    ret
readChar endp


BadOpen proc near
    ret
BadOpen endp

;
;--------------------------------------------------------------------
;Fun��o: Converte um valor HEXA para ASCII-DECIMAL
;Entra:  (A) -> AX -> Valor "Hex" a ser convertido
;        (S) -> DS:BX -> Ponteiro para o string de destino
;--------------------------------------------------------------------
ReadError proc near
    ret    
ReadError endp

CloseError proc near
    ret    
CloseError endp

;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------
	