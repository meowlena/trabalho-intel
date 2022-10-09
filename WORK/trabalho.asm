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
    FileNameCte DB	"texto.txt", 0  
    FileName    DB 42 DUP(?)
    CR          equ 0Dh
    LF          equ 0Ah
    MsgCRL      DB CR, LF, 0

.CODE ; Begin code segment
.STARTUP ; Generate start-up code
    
    lea si, FileName
    call readChar

here:
    call concatenateTXT
    call printEnter
    lea si, FileName


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

_end:
    call printEnter
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
;Funcao: Lê filename do arquivo
;Entra:  (A) -> Si -> ponteiro pra filename
;--------------------------------------------------------------------
readChar proc near
read:
    mov ah, 0h      ;; seta modo
    int 16h         ;; pra ler caractere do teclado

    cmp al, 0Dh     ;; compara se caractere é enter
    jz readRet         ;; se for, condição de parada 
    
    mov [si], al
    inc si
    call printChar  ;; imprime caractere lido
    
    jmp read   ;; se não, continua chamadas recursivas
readRet:
    ret
readChar endp



BadOpen proc near
    ret
BadOpen endp

;
;--------------------------------------------------------------------
;Fun��o: Converte um valor HEXA para ASCII-DECIMAL
;Entra:  (A) -> Si -> ponteiro pra filename
;        (S) -> DS:BX -> Ponteiro para o string de destino
;--------------------------------------------------------------------
ReadError proc near
    ret    
ReadError endp

CloseError proc near
    ret    
CloseError endp
;
;--------------------------------------------------------------------
;Funcaoo: Concatena .txt num filename
;Entra:  (A) -> Si -> ponteiro pra filename
;        (S) -> [Si] -> 'filename'.txt
;--------------------------------------------------------------------
concatenateTXT proc near 
    mov [si], '.'
    inc si
    mov [si], 't'
    inc si
    mov [si], 'x'
    inc si
    mov [si], 't'
    ret
concatenateTXT endp

;
;--------------------------------------------------------------------
;Funcaoo: Printa uma mensagem
;Entra:  (A) -> Si -> ponteiro pra mensagem
;--------------------------------------------------------------------
printMsg proc near
loopPM:
    mov al, [si]
    call printChar
    inc si
    cmp [si], 0
    jz retPM
    jmp loopPM
retPM:
    ret
printMsg endp

printEnter proc near
    lea si, MsgCRL
    call printMsg
    ret
printEnter endp

;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------
	