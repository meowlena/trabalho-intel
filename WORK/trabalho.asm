;====================================================================
;                           Milena Silva Braga
;                                00319002
;       Livro The Art of Assembly Language usado como referência
;====================================================================

.model small

.STACK 100h


.DATA
    Buffer      DB 0 ; buffer dos char 
    FileHandler DW 0 ; file handler dos arquivos
    FileNameEntrada    DB 128 DUP(?)    ; nome do arquivo de entrada
    FileNameSaida      DB 128 DUP(?)    ; nome do arquivo de entrada
    Frase              DB 1024 DUP(?)   ; frase lida pra ser encriptada
    ChaveLida          DB 256 DUP(?)    ; chave lida do arquivo de entrada
    bufferCripto    DB 0             ; buffer pra criptografia
    temp DW 0
    indexArquivo DW 0
    strResult DB 16 DUP(?) ; string pra conversão de numero pra ascii
    tempIndex DW 0 ; variavel pra salvar index que tá percorrendo frase pq vai ser usado por outro proc
    Quociente DB 132
    Resto DB 0
    NumAlgarismos DB 0
    fileHandleEscrita DW 0
    charEscrita DB 0
    tempWord DW 0
    outroFileHandle DW 0
    numeroString DB 256 DUP(0)
    zeroFinal DB 0
    tamFrase DW 0
    tamArquivoEntrada DW 0

.CONST
    CR          equ 0Dh         ; Código ASCII de CR
    LF          equ 0Ah         ; Código ASCII de LF
    MsgCRL      DB CR, LF, 0    ; Quebra de Linha
    MaxFrase    DB 100

    ;; interações com o usuário
    inputEntrada DB "Digite o nome do arquivo de entrada: ", CR, LF, 0
    inputSaida  DB "Digite o nome do arquivo de saida: ", CR, LF, 0
    inputFrase  DB "Digite a frase a ser criptografada: ", CR, LF, 0

    Sucesso     DB "Processamento realizado sem erros", CR, LF, 0
    msgTamFrase DB "Tamanho da frase (em bytes): ", CR, LF, 0
    msgTamArquivo DB "Tamanho do arquivo de entrada (em bytes): ", CR, LF, 0

    ;; msgs de erro
    ErroLeitura DB "Erros na abertura do arquivo", CR, LF, 0
    ErroFechamento DB "Erro no fechamento do arquivo", CR, LF, 0
    ArquivoGde  DB "Arquivo de entrada muito grande (excedeu o tamanho maximo)", CR, LF, 0
    SimbNaoEnc  DB "Nao foi possivel encontrar um dos simbolos da frase, no arquivo de entrada fornecido", CR, LF, 0
    SimbInvalido  DB "Um dos simbolos inseridos na frase e invalido", CR, LF, 0
    ErroArqSaida DB "Erro na criacao do arquivo de saida", CR, LF, 00
    FraseMuitoGrande DB "Frase maior que o tamanho permitido", CR, LF, 00
    ErroFraseVazia DB "Frase vazia", CR, LF, 00

    ConstDez DB 10
.CODE ; Begin code segment
.STARTUP ; Generate start-up code
;--------------------------------------------------------------------------------cut

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

;criptografia--------------------------------------------------------

    ; cria arquivo pra escrita
    lea ax, FileNameSaida
    call criaArquivoParaEscrita
    mov FileHandler, ax    ; Save output file handle


    lea bp, ChaveLida   ; chave lida 
    mov di, 0           ; indica a posição no arquivo
    mov indexArquivo, 0
    lea si, Frase       ; frase lida 
    
    loopCriptografia:
        cmp byte ptr [si], 0    ; verifica se é o fim da frase
        je fimCripto            ; se for, pula pro fim do loop

        ;------verifica se o char está dentro do range que deve ser criptografado
        cmp byte ptr [si], ' '
        jle vaiProProximo

        cmp byte ptr [si], '~'
        jg vaiProProximo
        ;-------------------------------------------------------------------
    loopArquivo:
        mov al, byte ptr [bp+di+0]  ; coloca bp+di(chave) em al para poder comparar
        cmp al, byte ptr [si]       ; compara com a frase
        je criptografa              ; se igual, pula pra criptografia
        
        ;checar se chegou no fim do arquivo
        ;se chegou, erro
        cmp byte ptr [bp+di+0], 0
        je CharNaoEnc
        
        inc di ; pula para próximo char da chave
        inc indexArquivo ; guarda posição
        
        jmp loopArquivo

    criptografa: 
        mov ax, indexArquivo ; bota em ax pra dividir
        mov Quociente, al
        NumPraASCIIDivisaoLoop: ;divisão pra separar cada caractere do numero
            mov al, Quociente
            mov ah, 0

            div ConstDez
            mov Quociente, al
            mov Resto, ah

            add Resto, 48 ;soma pra converter pro código ascii
            mov al, Resto
            mov ah, 0
            push ax ; usa a pilha pois o número fica invertido

            inc numAlgarismos

            cmp Quociente, 0
            je loopEscreveNumero
            jmp NumPraASCIIDivisaoLoop

    loopEscreveNumero:
        lea di, numeroString
    loopdoloop:
        cmp numAlgarismos, 0
        je fimEscreveNumero

        pop bx ; puxa o algarismo da pilha

        mov byte ptr [di], bl ; move o caractere pra numeroString

        dec numAlgarismos
        inc di

        jmp loopdoloop

    fimEscreveNumero:
        mov byte ptr [di], 0 ; marca final

        lea di, numeroString ; bota o ponteiro pra começo de numeroString
    escreveNumeroLoop:
        cmp byte ptr [di], 0 ; se final, pula pra terminou de escrever
        je terminouDeEscrever

        ; se não, escreve no arquivo
        mov ax, FileHandler
        mov bl, byte ptr [di]
        call escreveCharNoArquivo
        inc di
        jmp escreveNumeroLoop

    terminouDeEscrever: ;imprime quebra de linha 
        mov ax, FileHandler
        mov bl, CR
        call escreveCharNoArquivo

        mov ax, FileHandler
        mov bl, LF
        call escreveCharNoArquivo

        mov di, 0
        
    loopinc: ; move o valor de indexArquivo de volta pra di
        cmp indexArquivo, 0
        je fiminc
        inc di
        dec indexArquivo
        jmp loopinc

    fiminc:
        mov byte ptr [bp+di+0], ' ' ; substitui char já usado como chave por ' ' pra ser ignorado
        
        ; move ponteiros da chave pro inicio
        mov indexArquivo, 0 
        mov di, 0
    vaiProProximo:
        inc si ; incrementa ponteiro do char da frase
        jmp loopCriptografia

    fimCripto:
        ;; fecha o arquivo
        call Escreve0000        
        
        call printEnter

        lea si, Sucesso
        call printMsg

        call printEnter

        lea si, msgTamFrase
        call printMsg

        call printEnter

        mov ax, tamFrase
        call printNumero

        call printEnter

        lea si, msgTamArquivo
        call printMsg

        call printEnter

        mov ax, tamArquivoEntrada
        call printNumero

        mov bx, FileHandler
        mov ah, 3Eh                     ; fecha arquivo
        int 21h                         ; chama uma função do MS-DOS
        jc CloseError
;--------------------------------------------------------------------
.EXIT
;--------------------------------------------------------------------

_end:
.EXIT                               ; Gera exit code

;; procedimentos
;--------------------------------------------------------------------
;Funcao: Lê arquivo de entrada 
;Entra:  (A) -> Si -> ponteiro pra onde vai ser salva a chave
;--------------------------------------------------------------------
leituraArquivo proc near
    lea ax, FilenameEntrada
    call abreArquivoParaLeitura
    
    mov FileHandler, ax             ; Save file handle

    LP: 
        mov ax, FileHandler
        lea bx, Buffer
        call leCharDoArquivo
        
        cmp ax, cx                      ; EOF encontrado?
        jne EOF

        mov al, Buffer
        mov [si], al                    ; guarda o char lido na Chave
        inc si

        jmp LP                          ; Lê próximo byte
    EOF: 
        mov [si], 0                     ; concatena 0 no fim da chave
        call printEnter
        
        mov ax, fileHandler
        call fechaArquivo

        ret 
leituraArquivo endp

;Tendo um fileHandle em ax e o endereço de um buffer em bx,
;lê um byte do arquivo e guarda no buffer
leCharDoArquivo proc near
    mov tempWord, bx
    mov dx, tempWord ;buffer em dx

    mov tempWord, ax
    mov bx, tempWord ;handle em bx

    mov cx, 1                       ; Quantos bytes vão ser lidos

    mov ah, 3Fh                     ; 3fh é o opcode de readFile no MS-DOS
    int 21h                         ; chama uma função do MS-DOS
    inc tamArquivoEntrada

    jc ReadError 
    ret
leCharDoArquivo endp

;tendo uma file handle em ax (com o arquivo aberto para escrita) e um caractere no bl, 
;escreve o caractere no arquivo
escreveCharNoArquivo proc near
    mov fileHandleEscrita, ax
    mov charEscrita, bl

    mov bx, fileHandleEscrita     ; file handle
    mov cx, 1               ; numeros de bytes a escrever
    lea dx, charEscrita
    mov ah, 40h             ; opcode pra escrever
    int 21h                 ; chama uma função do MS-DOS

    ret
escreveCharNoArquivo endp

;tendo um ponteiro para o endereço de arquivo em ax, cria este arquivo e
;retorna o file handle em ax
criaArquivoParaEscrita proc near
    mov tempWord, ax
    mov dx, tempWord

    mov cx, 0           ; Normal file attributes
    mov ah, 3Ch         ; Create file call
    int 21h             ; chama uma função do ms-dos
    jc BadOpen
    ret
criaArquivoParaEscrita endp

;tendo um ponteiro para o endereço de arquivo em ax, abre este arquivo e
;retorna o file handle em ax
abreArquivoParaLeitura proc near
    mov tempWord, ax
    mov dx, tempWord
    mov ah, 3Dh                     ; Open the file
    mov al, 0                       ; Open for reading
    int 21h                         ; chama uma função do MS-DOS
    jc BadOpen
    ret
abreArquivoParaLeitura endp

;tendo um fileHandle em ax, fecha este arquivo
fechaArquivo proc near
    mov tempWord, ax
    mov bx, tempWord
    mov ah, 3Eh                     ; fecha arquivo
    int 21h                         ; chama uma função do MS-DOS
    jc CloseError
    ret
fechaArquivo endp

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
        inc tamFrase

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
;Funcao: imprime erros referente a frase 
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

;--------------------------------------------------------------------
;Funcao: escreve '0000' num arquivo
;--------------------------------------------------------------------
Escreve0000 proc near
    loop0000:
        mov ax, FileHandler
        mov bl, '0'
        call escreveCharNoArquivo
        inc zeroFinal
        cmp zeroFinal, 4
        jne loop0000
    ret
Escreve0000 endp

;--------------------------------------------------------------------
;Funcao: printa um numero na tela
;Entra:  (A) -> ax -> numero a ser printado
;--------------------------------------------------------------------
printNumero proc near
    mov Quociente, al
    NumPraASCIIDivisaoLoop2:
            mov al, Quociente
            mov ah, 0

            div ConstDez
            mov Quociente, al
            mov Resto, ah

            add Resto, 48
            mov al, Resto
            mov ah, 0
            push ax

            inc numAlgarismos

            cmp Quociente, 0
            je loopEscreveNumero2
            jmp NumPraASCIIDivisaoLoop2

    loopEscreveNumero2:
        cmp numAlgarismos, 0
        je fimEscreveNumero2

        pop ax
        call printChar

        dec numAlgarismos

        jmp loopEscreveNumero2

    fimEscreveNumero2:
    ret
printNumero endp

;
;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------
	