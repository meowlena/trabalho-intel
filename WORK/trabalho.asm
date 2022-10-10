;====================================================================
;                           Milena Silva Braga
;                                00319002
;       Livro The Art of Assembly Language usado como referência
;====================================================================

; nota: eu vou terminar o trabalho e enviar por email ainda de madrugada 
; mas atualmente eu leio o arquivo, e escrevo num arquivo de saida. :) 

.model small

.STACK
.DATA
    hFile    DWORD 0
    pMemory  DWORD 0
    ReadSize DWORD 0
    BufferIn  DB 0
    BufferOut  DB 0
    FHndlIn   DW 0
    FHndlOut    DW 0

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

;---interação com usuário--------------------------------------------- 
    lea si, inputEntrada
    call printMsg
    call printEnter

    lea si, FileNameEntrada
    call readString
    call concatenateTXT
    call printEnter
;--------------------------------------------------------------------

    ;lea si, FileNameEntrada

    mov ah, 3Dh                     ; Open the file
    mov al, 0                       ; Open for reading
    lea dx, FilenameEntrada         ; Presume DS points at filename
    int 21h                         ; chama uma função do MS-DOS
    jc BadOpen
    mov FHndlIn, ax                 ; Save file handle

LP: 
    mov ah, 3Fh                     ; 3fh é o opcode de readFile no MS-DOS
    lea dx, BufferIn                ; Ponteiro de buffer
    mov cx, 1                       ; Quantos bytes vão ser lidos
    mov bx, FHndlIn                 ; Get file handle value
    int 21h                         ; chama uma função do MS-DOS
    jc ReadError 
    
    cmp ax, cx                      ; EOF encontrado?
    jne EOF

    mov al, BufferIn
    call printChar
    

    jmp LP                          ; Lê próximo byte
EOF: 
    call printEnter
    mov bx, FHndlIn
    mov ah, 3Eh                     ; fecha arquivo
    int 21h                         ; chama uma função do MS-DOS
    jc CloseError

;---interação com usuário--------------------------------------------- 
    lea si, inputSaida
    call printMsg
    call printEnter

    lea si, FileNameSaida
    call readString
    call concatenateTXT
    call printEnter
;--------------------------------------------------------------------
    mov ah, 'a'
    mov BufferOut, ah

    mov ah, 3Ch         ; Create file call
    mov cx, 0           ; Normal file attributes
    lea dx, FileNameSaida ; File to open
    int 21h
    jc BadOpen

    mov FHndlOut, ax    ; Save output file handle
    mov bx, FHndlOut    ; file handle
    mov cx, 1           ; numeros de bytes a escrever
    lea dx, BufferOut   
    mov ah, 40h         ; opcode pra escrever
    int 21h
_end:
    ;;lea si, Sucesso
    ;;call printMsg

.EXIT                               ; Gera exit code

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
	