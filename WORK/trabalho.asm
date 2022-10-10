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
    FileNameEntrada    DB 42 DUP(?)
    FileNameSaida      DB 42 DUP(?)
    
    CR          equ 0Dh
    LF          equ 0Ah
    MsgCRL      DB CR, LF, 0

    ;; interações com o usuário
    inputEntrada DB "Digite o nome do arquivo de entrada: ", CR, LF, 0
    inputSaida  DB "Digite o nome do arquivo de saida: ", CR, LF, 0
    inputFrase  DB "Digite a frase a ser criptografada: ", CR, LF, 0

    Sucesso     DB "Processamento realizado sem erro", CR, LF, 0
    
    ;; msgs de erro
    ErroLeitura DB "Erros na leitura do arquivo de entrada", CR, LF, 0
    ArquivoGde  DB "Arquivo de entrada muito grande (excedeu o tamanho maximo)", CR, LF, 0
    SimbNaoEnc  DB "Nao foi possível encontrar um dos simbolos da frase, no arquivo de entrada fornecido", CR, LF, 0
    ErroArqSaida DB "Erro na criacao do arquivo de saida", CR, LF, 00

.CODE ; Begin code segment
.STARTUP ; Generate start-up code
    
    lea si, inputEntrada
    call printMsg
    call printEnter

    lea si, FileNameEntrada
    call readString
    call concatenateTXT
    call printEnter
    
    ;lea si, FileNameEntrada

    mov ah, 3Dh                     ; Open the file
    mov al, 0                       ; Open for reading
    lea dx, FilenameEntrada         ; Presume DS points at filename
    int 21h                         ; chama uma função do MS-DOS
    jc BadOpen
    mov FHndl, ax                   ; Save file handle

LP: 
    mov ah, 3Fh                     ; 3fh é o opcode de readFile no MS-DOS
    lea dx, Buffer                  ; Address of data buffer
    mov cx, 1                       ; Read one byte
    mov bx, FHndl                   ; Get file handle value
    int 21h                         ; chama uma função do MS-DOS
    jc ReadError 
    
    cmp ax, cx                      ; EOF reached?
    jne EOF

    mov al, Buffer
    call printChar
    

    jmp LP ; Read next byte
EOF: 
    call printEnter
    mov bx, FHndl
    mov ah, 3Eh                     ; Close file
    int 21h                         ; chama uma função do MS-DOS
    jc CloseError

    lea si, inputSaida
    call printMsg
    call printEnter

    lea si, FileNameSaida
    call readString
    call concatenateTXT
    call printEnter

    lea si, FileNameSaida
    call printMsg

_end:
    ;;lea si, Sucesso
    ;;call printMsg

.EXIT                               ; Generate exit code

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
readString proc near
read:
    mov ah, 0h      ;; seta modo
    int 16h         ;; pra ler caractere do teclado

    cmp al, 0Dh     ;; compara se caractere é enter
    jz readRet      ;; se for, condição de parada 
    
    mov [si], al
    inc si
    call printChar  ;; imprime caractere lido
    
    jmp read   ;; se não, continua chamadas recursivas
readRet:
    ret
readString endp
;
;--------------------------------------------------------------------
;Funcao: imprime erro de leitura 
;--------------------------------------------------------------------
BadOpen proc near
    lea si, ErroLeitura
    call printMsg
    jmp _end
    ret
BadOpen endp

ReadError proc near
    lea si, ErroLeitura
    call printMsg
    jmp _end
    ret    
ReadError endp

CloseError proc near
    lea si, ErroLeitura
    call printMsg
    jmp _end
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

;--------------------------------------------------------------------
;Funcao: Printa uma mensagem
;Entra:  (A) -> Si -> ponteiro pra mensagem
;--------------------------------------------------------------------
printMsg proc near
loopPM:
    mov al, [si]
    call printChar
    inc si
    cmp [si], LF
    jz retPM
    jmp loopPM
retPM:
    ret
printMsg endp
;--------------------------------------------------------------------
;Funcao: Printa uma quebra de linha
;--------------------------------------------------------------------
printEnter proc near
    mov al, CR
    call printChar
    mov al, LF
    call printChar
    ret
printEnter endp

;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------
	