;====================================================================
;                           Milena Silva Braga
;                                00319002
;       Livro The Art of Assembly Language usado como referência
;====================================================================

.model small

.STACK
.DATA
    hFile       DWORD 0
    pMemory     DWORD 0
    ReadSize    DWORD 0
    Buffer      DB 0
    FileHandler DW 0
    endereco    DW 0
    indexTemp   DW 0
    charMsg     DB 0
    charKey     DB 0
    FileNameEntrada    DB 128 DUP(?)
    FileNameSaida      DB 128 DUP(?)
    Frase              DB 1024 DUP(?)
    
    temp DW 0


.CONST
    CR          equ 0Dh
    LF          equ 0Ah
    MsgCRL      DB CR, LF, 0 ; Quebra de Linha

    ;;;BE CAREFUL
    MaxArquivo  EQU 65535 ; Tamanho máximo do arquivo de entrada
    TamArquivo  EQU 0 ; Tamanho real do arquivo de entrada
    Index       DW 0
    seExiste    DB 0 ; Indica se caractere já existe no arquivo
    BufferChar  DB 0 ; Qual caractere está sendo encriptado

    ;; interações com o usuário
    inputEntrada DB "Digite o nome do arquivo de entrada: ", CR, LF, 0
    inputSaida  DB "Digite o nome do arquivo de saida: ", CR, LF, 0
    inputFrase  DB "Digite a frase a ser criptografada: ", CR, LF, 0

    Sucesso     DB "Processamento realizado sem erro", CR, LF, 0
    
    ;; msgs de erro
    ErroLeitura DB "Erros na leitura do arquivo de entrada", CR, LF, 0
    ErroFechamento DB "Erro no fechamento do arquivo", CR, LF, 0
    ArquivoGde  DB "Arquivo de entrada muito grande (excedeu o tamanho maximo)", CR, LF, 0
    SimbNaoEnc  DB "Nao foi possível encontrar um dos simbolos da frase, no arquivo de entrada fornecido", CR, LF, 0
    SimbInvalido  DB "Um dos simbolos inseridos na frase e invalido", CR, LF, 0
    ErroArqSaida DB "Erro na criacao do arquivo de saida", CR, LF, 00

.CODE ; Begin code segment
.STARTUP ; Generate start-up code

;---interação com usuário (arq entrada)------------------------------ 
    lea si, inputEntrada
    call printMsg
    call printEnter

    lea si, FileNameEntrada
    call readString
    call concatenateTXT
    call printEnter
;--------------------------------------------------------------------

;----leitura arquivo entrada-----------------------------------------
    mov ah, 3Dh                     ; Open the file
    mov al, 0                       ; Open for reading
    lea dx, FilenameEntrada         ; Presume DS points at filename
    int 21h                         ; chama uma função do MS-DOS
    jc BadOpen
    mov FileHandler, ax                 ; Save file handle

LP: 
    mov ah, 3Fh                     ; 3fh é o opcode de readFile no MS-DOS
    lea dx, Buffer                  ; Ponteiro de buffer
    mov cx, 1                       ; Quantos bytes vão ser lidos
    mov bx, FileHandler                 ; Get file handle value
    int 21h                         ; chama uma função do MS-DOS
    jc ReadError 
    
    cmp ax, cx                      ; EOF encontrado?
    jne EOF

    mov al, Buffer
    call printChar

    jmp LP                          ; Lê próximo byte
EOF: 
    call printEnter
    mov bx, FileHandler
    mov ah, 3Eh                     ; fecha arquivo
    int 21h                         ; chama uma função do MS-DOS
    jc CloseError
;--------------------------------------------------------------------

;---interação com usuário (arq. saída)------------------------------- 
    lea si, inputFrase
    call printMsg
    call printEnter

    lea si, Frase
    call readString
    call printEnter
;--------------------------------------------------------------------

;---interação com usuário (arq. saída)------------------------------- 
    lea si, inputSaida
    call printMsg
    call printEnter

    lea si, FileNameSaida
    call readString
    call concatenateKRP

    call printEnter
;--------------------------------------------------------------------

;---escrita no arquivo----------------------------------------------- 
    ;; abre o arquivo
    mov ah, 3Ch         ; Create file call
    mov cx, 0           ; Normal file attributes
    lea dx, FileNameSaida ; File to open
    int 21h
    jc BadOpen
    mov FileHandler, ax    ; Save output file handle
    
    lea si, SimbInvalido   ;;aponta pro que vai ser escrito no arquivo de saída

    loopEscrita:
        mov bx, FileHandler     ; file handle
        mov cx, 1               ; numeros de bytes a escrever
        mov dx, si 
        mov ah, 40h             ; opcode pra escrever
        int 21h

        cmp [si], LF            ; verifica se o char lido é enter
        jz _endSucesso          ; se for, pula pro final, 
        call testaChar
        inc si                  ; se não, continua lendo
        jmp loopEscrita

    ;; fecha o arquivo
    call printEnter
    mov bx, FileHandler
    mov ah, 3Eh                     ; fecha arquivo
    int 21h                         ; chama uma função do MS-DOS
    jc CloseError
;--------------------------------------------------------------------

_end:
.EXIT                               ; Gera exit code

    
_endSucesso:
    lea si, Sucesso
    call printMsg
.EXIT                               ; Gera exit code

;; procedimentos
;
;--------------------------------------------------------------------
;Funcao: verifica se um char está dentro do range pré-determinado de
;   chars que podem ser encriptados    
;Entra:  (A) -> [si] -> char a ser testado
;--------------------------------------------------------------------
testaChar proc near
    CMP byte ptr [si], '~' ; maior char admitido
    JG CharInvalido
    CMP byte ptr [si], ' ' ; menor char admitido
    JL carriageReturn
    ret
carriageReturn:
    CMP byte ptr [si], CR ; testa se é carriage return
    JNE CharInvalido
testaChar endp


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
;Funcaoo: Concatena .krp num filename
;Entra:  (A) -> Si -> ponteiro pra filename
;        (S) -> [Si] -> 'filename'.krp
;--------------------------------------------------------------------
concatenateKRP proc near 
    mov [si], '.'
    inc si
    mov [si], 'k'
    inc si
    mov [si], 'r'
    inc si
    mov [si], 'p'
    ret
concatenateKRP endp

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
;
;--------------------------------------------------------------------
;Funcao: imprime erro de leitura 
;--------------------------------------------------------------------
BadOpen proc near
    call printEnter
    lea si, ErroLeitura
    call printMsg
    jmp _end
    ret
BadOpen endp

ReadError proc near
    call printEnter
    lea si, ErroLeitura
    call printMsg
    jmp _end
    ret    
ReadError endp

CloseError proc near
    call printEnter
    lea si, ErroFechamento
    call printMsg
    jmp _end
    ret    
CloseError endp
;
;--------------------------------------------------------------------
;Funcao: imprime erro referente a frase 
;--------------------------------------------------------------------
CharNaoEnc proc near
    call printEnter
    lea si, SimbNaoEnc
    call printMsg
    jmp _end
    ret    
CharNaoEnc endp

CharInvalido proc near
    call printEnter
    lea si, SimbInvalido
    call printMsg
    jmp _end
    ret    
CharInvalido endp
;
;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------
	