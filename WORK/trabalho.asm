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

    ;PRINT--------------------------------------
    mov al, Buffer
    mov ah, 0Eh ; imprime cada caractere incrementando o cursor 
    mov bh, 0 ; page number (???)
    mov cx, 1 ; times to print the character
    int 10h ;calls interruption
    ;---------------------------------------------


    jmp LP ;Read next byte
EOF: 
    mov bx, FHndl
    mov ah, 3Eh  ;Close file
    int 21h ; chama uma função do MS-DOS
    jc CloseError

READ_FILENAME:
    mov ah, 0h
    int 16h ; pra ler caractere do teclado
    mov ah, 0Eh ; imprime cada caractere incrementando o cursor 
    mov bh, 0 ; page number (???)
    mov cx, 1 ; times to print the character
    int 10h ;calls interruption

    cmp al, 0Dh
    jz here
    jmp READ_FILENAME

here:


.EXIT ; Generate exit code

;; procedimentos

;
;--------------------------------------------------------------------
;Fun��o: Converte um valor HEXA para ASCII-DECIMAL
;Entra:  (A) -> AX -> Valor "Hex" a ser convertido
;        (S) -> DS:BX -> Ponteiro para o string de destino
;--------------------------------------------------------------------
BadOpen proc near
    
BadOpen endp

;
;--------------------------------------------------------------------
;Fun��o: Converte um valor HEXA para ASCII-DECIMAL
;Entra:  (A) -> AX -> Valor "Hex" a ser convertido
;        (S) -> DS:BX -> Ponteiro para o string de destino
;--------------------------------------------------------------------
ReadError proc near
    
ReadError endp

CloseError proc near
    
CloseError endp

;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------
	