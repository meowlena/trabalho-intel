;====================================================================
;                           Milena Silva Braga
;                                00319002
;       Livro The Art of Assembly Language usado como referência
;====================================================================

.model small

.STACK
.DATA
    Buffer      DB 0 ; buffer dos char 
    FileHandler DW 0 ; file handler dos arquivos
    endereco    DW 0
    indexTemp   DW 0
    charMsg     DB 0
    charKey     DB 0
    FileNameEntrada    DB 128 DUP(?)    ; nome do arquivo de entrada
    FileNameSaida      DB 128 DUP(?)    ; nome do arquivo de entrada
    Frase              DB 1024 DUP(?)   ; frase lida pra ser encriptada
    zero               DB 0
    ChaveLida          DB 256 DUP(?)    ; chave lida do arquivo de entrada
    bufferCripto    DB 0             ; buffer pra criptografia
    numCripto DB 0
    temp DW 0
    temp2 DB 0
    indexArquivo DB 0
    strResult DB 16 DUP(?) ; string pra conversão de numero pra ascii
    tempIndex DW 0 ; variavel pra salvar index que tá percorrendo frase pq vai ser usado por outro proc

.CONST
    CR          equ 0Dh         ; Código ASCII de CR
    LF          equ 0Ah         ; Código ASCII de LF
    MsgCRL      DB CR, LF, 0    ; Quebra de Linha
    MaxFrase    DB 100

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

    Sucesso     DB "Processamento realizado sem erros", CR, LF, 0
    
    ;; msgs de erro
    ErroLeitura DB "Erros na leitura do arquivo de entrada", CR, LF, 0
    ErroFechamento DB "Erro no fechamento do arquivo", CR, LF, 0
    ArquivoGde  DB "Arquivo de entrada muito grande (excedeu o tamanho maximo)", CR, LF, 0
    SimbNaoEnc  DB "Nao foi possivel encontrar um dos simbolos da frase, no arquivo de entrada fornecido", CR, LF, 0
    SimbInvalido  DB "Um dos simbolos inseridos na frase e invalido", CR, LF, 0
    ErroArqSaida DB "Erro na criacao do arquivo de saida", CR, LF, 00
    FraseMuitoGrande DB "Frase maior que o tamanho permitido", CR, LF, 00
    ErroFraseVazia DB "Frase vazia", CR, LF, 00

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
    lea si, ChaveLida
    call leituraArquivo

    lea si, ChaveLida
    call converteLower

;--------------------------------------------------------------------

;---interação com usuário (frase)------------------------------- 
    lea si, inputFrase
    call printMsg
    call printEnter

    lea si, Frase
    call readString
    call printEnter

    lea si, Frase
    call validaTamFrase
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


 ;; abre o arquivo
    mov ah, 3Ch         ; Create file call
    mov cx, 0           ; Normal file attributes
    lea dx, FileNameSaida ; File to open
    int 21h             ; chama uma função do ms-dos
    jc BadOpen
    mov FileHandler, ax    ; Save output file handle

;criptografia--------------------------------------------------------
    lea bp, ChaveLida   ; chave lida 
    mov di, 0           ; indica a posição no arquivo
    mov indexArquivo, 0
    lea si, Frase       ; frase lida 
    
    loopCriptografia:
        cmp byte ptr [si], 0    ; verifica se é o fim da frase
        je fimCripto            ; se for, pula pro fim do loop

    loopArquivo:
        mov al, byte ptr [bp+di+0]  ; coloca bp+di em al para poder comparar
        cmp al, byte ptr [si]       ; compara com a frase
        je criptografa              ; se igual, pula pra criptografia
        
        ;checar se chegou no fim do arquivo
        ;se chegou, erro
        cmp byte ptr [bp+di+0], 0
        je CharNaoEnc
        
        inc di
        inc indexArquivo
        
        jmp loopArquivo

    criptografa: 
        mov ah, 0
        mov al, indexArquivo
        
        call converteNumPraASCII    

        mov [bp+di+0], '×'
        mov indexArquivo, 0
        mov di, 0
        inc si
        cmp [si], 0
        jnz loopCriptografia

    fimCripto:

;--------------------------------------------------------------------

;---escrita no arquivo----------------------------------------------- 
   
    

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
    lea si, Sucesso                 ; indica a mensagem que vai ser impressa 
    call printMsg
.EXIT                               ; Gera exit code

;; procedimentos
;--------------------------------------------------------------------
;Funcao: converte numero pra ASCII
;Entra:  (A) -> al -> numero a ser convertido
;--------------------------------------------------------------------
converteNumPraASCII proc near
    mov dx, 0
    mov bufferCripto, dl
    mov strResult, dl

    lea bx, strResult
    mov cl, 10
   

    lpCtAscii:
        mov cl, 10
        div cl ;ax = numero /10, ah = resto
        mov temp, ax
        mov tempIndex, bx

        add al, 48
        mov bufferCripto, al

        mov bx, FileHandler     ; file handle
        mov cx, 1               ; numeros de bytes a escrever
        lea dx, bufferCripto
        mov ah, 40h             ; opcode pra escrever
        int 21h                 ; chama uma função do MS-DOS

        mov ax, temp
        add ah, 48
        mov bufferCripto, ah

        mov bx, FileHandler     ; file handle
        mov cx, 1               ; numeros de bytes a escrever
        lea dx, bufferCripto
        mov ah, 40h             ; opcode pra escrever
        int 21h                 ; chama uma função do MS-DOS

        mov ax, temp
        mov bx, tempIndex
    ret

converteNumPraASCII endp

;--------------------------------------------------------------------
;Funcao: valida tamanho da frase
;Entra:  (A) -> [si] -> frase a ser validada
;--------------------------------------------------------------------
validaTamFrase proc near
    mov bl, 0
    lpTamFrase:
        cmp byte ptr [si], 0
        je eofTAM
        inc si

        inc bl
        cmp bl, 100
        jg FraseGrande
        jmp lpTamFrase
    eofTAM:
        cmp bl, 0
        jz FraseVazia
        ret
validaTamFrase endp

;--------------------------------------------------------------------
;Funcao: converte uma string em caixa baixa
;Entra:  (A) -> [si] -> string a ser convertido
;--------------------------------------------------------------------
converteLower proc near
    loopConversao:
        cmp byte ptr [si], 'A' ; [si]- 'A', [si]< 'A'
        jl proxConv
        cmp byte ptr [si], 'Z' ;[si] - 'Z', [si] < 'Z'
        jg proxConv
        jmp soma20H 
    proxConv:
        inc si
        cmp byte ptr [si], 0
        jne loopConversao    
        ret
    soma20H:
        add byte ptr [si], 20h
        jmp proxConv
converteLower endp
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
;Funcao: Lê caractere do teclado
;Entra:  (A) -> Si -> ponteiro pra onde vai ser salvo o conteúdo lido
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
;Funcao: Lê arquivo de entrada 
;Entra:  (A) -> Si -> ponteiro pra onde vai ser salva a chave
;--------------------------------------------------------------------
leituraArquivo proc near
    mov ah, 3Dh                     ; Open the file
    mov al, 0                       ; Open for reading
    lea dx, FilenameEntrada         ; Presume DS points at filename
    int 21h                         ; chama uma função do MS-DOS
    jc BadOpen
    mov FileHandler, ax             ; Save file handle

    LP: 
        mov ah, 3Fh                     ; 3fh é o opcode de readFile no MS-DOS
        lea dx, Buffer                  ; Ponteiro de buffer
        mov cx, 1                       ; Quantos bytes vão ser lidos
        mov bx, FileHandler             ; Get file handle value
        int 21h                         ; chama uma função do MS-DOS
        jc ReadError 
        
        cmp ax, cx                      ; EOF encontrado?
        jne EOF

        mov al, Buffer
        mov [si], al                    ; guarda o char lido na Chave
        inc si

        jmp LP                          ; Lê próximo byte
    EOF: 
        mov [si], 0                     ; concatena 0 no fim da chave
        call printEnter
        mov bx, FileHandler
        mov ah, 3Eh                     ; fecha arquivo
        int 21h                         ; chama uma função do MS-DOS
        jc CloseError

        ret 
leituraArquivo endp
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
        cmp [si], 0
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

FraseGrande proc near
    call printEnter
    lea si, FraseMuitoGrande
    call printMsg
    jmp _end
    ret
FraseGrande endp

FraseVazia proc near
    call printEnter
    lea si, ErroFraseVazia
    call printMsg
    jmp _end
    ret
FraseVazia endp



;
;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------
	