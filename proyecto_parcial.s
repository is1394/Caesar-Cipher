# ================================================================
#
# ESPOL 2016-2T
# Computer Organization and Architecture Project Partial
# Group #6
# Members:
# Carvajal Edgar
# Fernandez Israel
# Velez Washington
#
# ================================================================
# Main:
#   $s0 -> Operacion
#   $s1 -> Key
#   $s2 -> longitud string
#   $s3 -> string calculado
#   $s4 -> Orientacion (izq/der)
#
.data
mainprompt: .asciiz "Escoja la operacion? (1: encriptar - 2: desencriptar - 0: salir)\n>"
stringprompt: .asciiz "Ingrese el texto: \n>"
keyprompt: .asciiz "Ingrese la cantidad de desplazamientos: (debe ser mayor a 0) \n>"
orientationprompt: .asciiz "Ingrese el sentido de despliazamiento (0: derecha - 1: izquierda)\n>"
encryprompt: .asciiz "Encriptando con la llave: "
decryprompt: .asciiz "Desencriptando con la llave: "
resultprompt: .asciiz "Resultado:\n"
conprompt: .asciiz "Presione '1' para continuar: \n"
exitprompt: .asciiz "Adios! \n"
errstrprompt: .asciiz "Cadena Invalida \n"
errkeyprompt: .asciiz "Llave Invalida\n"
endl: .asciiz "\n"


string:       .space 256

.globl main

.text

main:
  li $v0, 4
  la $a0, mainprompt
  syscall

  li $v0, 5                     # lee operacion
  syscall

  beq $v0, $zero, __exit        # OP = 0 -> EXIT
  bltz $v0, main                # OP < 0 -> MAIN
  bgt $v0, 2, main              # OP > 2 -> MAIN

  addi $s0, $v0, 0              # $s0 <- operacion

__keyAsk:                       # lee llave
  li $v0, 4                     #  la llave no puede ser 0
  la $a0, keyprompt             #         se calcula el modulo con 26
  syscall

  li $v0, 5
  syscall

  li $t0, 26                    # Guarda en t0 el valor del modulo
  div $v0, $t0
  mfhi $t1                      # $t1 <- $v0 % 26

  beqz $t1, __keyAsk
  blt $t1, $0, __keyAsk
  addi $s1, $t1, 0              # $s1 <- key

__stringAsk:                    # Lee el string para cifrar/descifrar
  li $v0, 4
  la $a0, stringprompt
  syscall

  li $v0, 8
  la $a0, string
  li $a1, 255
  syscall

  la $a0, string
  jal __strlen

  beq $v1, 0, __stringOk
  j __stringAsk

__stringOk:
  addi $s2, $v0, 0              # $s2 <- strlen( string )

__orientationAsk:
  li $v0, 4
  la $a0, orientationprompt
  syscall

  li $v0, 5
  syscall

  bltz $v0, __orientationAsk # <0 main
  bgt $v0, 1, __orientationAsk #>1 main

  addi $s4, $v0, 0  #Guarda la orientacion en $s4


__allowMemory:
  li $v0,9                      # crea un buffer en memoria
  addi $a0, $s2, 1              # para guardar el nuevo string
  syscall

  addi $s3, $v0, 0

__selectOp:
  beq $s0, 1, __encryptMode
  beq $s0, 2, __decryptMode
  j main

__decryptMode:
  add $t0, $s1, $s1             # calcula el opuesto
  sub $s1, $s1, $t0             # de la llave

  li $v0, 4
  la $a0, decryprompt
  syscall

  li $v0, 1
  addi $a0, $s1, 0
  syscall

  li $v0, 4
  la $a0, endl
  syscall

  beq $s4, 0, __cipherCall

  li $t1, 2
  div $t0, $t1
  mflo $s1
  j __cipherCall

__encryptMode:
  li $v0, 4
  la $a0, encryprompt
  syscall

  li $v0, 1
  addi $a0, $s1, 0
  syscall

  li $v0, 4
  la $a0, endl
  syscall

  beq $s4, 0, __cipherCall

  add $t0, $s1, $s1             # calcula el opuesto
  sub $s1, $s1, $t0             # de la llave

__cipherCall:                 # Llama a la funcion de encriptado
  addi $a0, $s2, 0              #   $a0 <- longitud string
  li $a1, 0                     #   $a1 <- indice actual
  addi $a2, $s3, 0              #   $a2 <- direccion de retorno del string
  jal __caesarCipher

  j __done

__done:
  li $v0, 4
  la $a0, resultprompt
  syscall

  addi $a0, $s3, 0
  li $v0, 4
  syscall

  li $a0, 4
  la $a0, endl
  syscall

  li $v0, 4
  la $a0, conprompt
  syscall

  li $v0, 5
  syscall

  addi $t0, $v0, 0              # $t0 <- reply

  li $v0, 4
  la $a0, endl
  syscall

  beq $t0, 1, main              # $t0 != 1 -> EXIT

__exit:
  li $v0, 4
  la $a0, exitprompt
  syscall

  li $v0, 10
  syscall

  ##############################
  ####   F U N C I O N E S   ###
  ##############################

# =================================================
# caesarCipher
#
# Paramethers:
#   $a0 <- String length
#   $a1 <- Current index
#   $a2 <- Result string address
#
# Return values
#   $v0 <- String length
#   $v1 <- error (-1/0)
# =================================================
__caesarCipher:
  addi $sp, $sp -16
  sw $a0, 0($sp)                #  length(string)
  sw $a1, 4($sp)                #  indice actual
  sw $a2, 8($sp)                #  direccion resultado
  sw $ra, 12($sp)

  li $t5, 0
  sb $t5, 0($a2)

  bge $a1, $a0, __caesarCipherend

  ## CIPHER CHARACTER
  addi $t1, $a0, 0

  lb $a0, string($a1)

  jal __isaSpecialChar
  beq $v0, 1, __caesarCipherisSpecialChar

  jal __getcharoffset
  addi $t2, $v0, 0              # $t2 <- offset

  __thecipheralgorithm:
    li $t7, 26                  # $t7 <- modulus
    sub $t3, $a0, $t2           # $t3 = Char - offset
    add $t3, $t3, $s1           # $t3 += key
    div $t3, $t7                # $t3 % modulus (26)
    mfhi $t3
    add $t3, $t3, $t2           # $t3 += offset

    sb $t3, 0($a2)

  __caesarCiphernextchar:
    addi $a0, $t1, 0
    addi $a1, $a1, 1
    addi $a2, $a2, 1
    jal __caesarCipher

  __caesarCipherend:

    lw $a0, 0($sp)
    lw $a1, 4($sp)
    lw $a2, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra

  __caesarCipherisSpecialChar:
    move $t5, $a0
    sb $t5, 0($a2)
    j __caesarCiphernextchar

# =================================================
# getCharOffset
#
# Calcula el siguiente caracter
# cuando son caracteres frontera
#
# Paramether:
#   $a0 <- Character to test
#
# Return:
#   $v0 <- offset
# =================================================
__getcharoffset:
  addi $sp, $sp, -8
  sw $a0, 0($sp)
  sw $ra, 4($sp)

  jal __islowercase

  lw $a0, 0($sp)
  lw $ra, 4($sp)
  addi $sp, $sp, 8

  __caesarCipherlowercase:
    beq $s0, 2, __deciphercorelowercase
    li $v0, 97

    beq $s4,0, __jumpRa
    li $v0, 122
    jr $ra

  __deciphercorelowercase:
    li $v0, 122

    beq $s4, 0, __jumpRa
    li $v0, 97
    jr $ra

  __jumpRa:
    jr $ra


# =================================================
# strLen
#
# calcula longitud de la cadena y desprecia las
# mayusculas
#
# Paramether;
#   $a0 <- string to validate
#
# Return:
#   $v0 <- string length
#   $v1 <- error (-1/0)
# =================================================
__strlen:
  addi $sp, $sp, -8
  sw $a0, 0($sp)
  sw $ra, 4($sp)

  li $t0, 0
  li $t1, 0
  addi $t2, $a0, 0
  li $t3, 10                  # New line character

  __strlenloop:
    lb $t1, 0($t2)
    beqz $t1, __strlenexit    # $t1 = \00 ?
    beq $t1, $t3 __strlenexit # $t1 = \n  ?

    addi $a0, $t1, 0          # $a0 <- Currenct char
    jal __isavalidchar        # returns 1 if it's valid
    bne $v0, 1, __strlenerror

    addi $t2, $t2, 1
    addi $t0, $t0, 1
    j __strlenloop

  __strlenexit:
    lw $a0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8

    addi $v0, $t0, 0
    li $v1, 0
    jr $ra

  __strlenerror:
    lw $a0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8

    li $v0, 4
    la $a0, errstrprompt
    syscall

    li $v0, -1
    li $v1, -1
    jr $ra

# =================================================
# isavalidchar
#
# Paramether
#   $a0 <- Character to test
#
# Returns:
#   $v0 <- 1: valid char
#          0: not valid char
# =================================================
__isavalidchar:
  addi $sp, $sp, -8
  sw $a0, 0($sp)
  sw $ra, 4($sp)

  jal __isaletter
  beq $v0, 1, __validcharfound

  jal __isaSpecialChar
  beq $v0, 1, __validcharfound

  lw $a0, 0($sp)
  lw $ra, 4($sp)
  addi $sp, $sp, 8

  li $v0, 0
  jr $ra

  __validcharfound:
    lw $a0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8

    li $v0, 1
    jr $ra

# =================================================
# isALetter
#
# Paramether:
#   $a0 <- Character to test
#
# Returns:
#   $v0 <- 1: is a letter
#          0: not a letter
# =================================================
__isaletter:
  addi $sp, $sp, -8
  sw $a0, 0($sp)
  sw $ra, 4($sp)

  jal __islowercase
  beq $v0, 1, __isaletterok
  blt $v0, 0, __isalettererror

  __isalettererror:
    lw $a0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8

    li $v0, 0
    jr $ra

  __isaletterok:
    lw $a0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8

    li $v0, 1
    jr $ra

# =================================================
# isASpecialChar
#
# caracteres antes de 64 ok
# entonces mayres no son caracteres especiales
#
# Paramether
#   $a0 <- Char to test
#
# Returns
#   $v0 <- 1: is a special char
#          0: not a special char
# =================================================
__isaSpecialChar:
  bge $a0, 64, __isnotaspace

  li $v0, 1
  jr $ra

  __isnotaspace:
    li $v0, 0
    jr $ra

# =================================================
# isLowerCase
#
# Paramether
#   $a0 <- Char to test
#
# Return
#   $v0 <- 1: is lowercase
#          0: not lowercase
#         -1: not a letter
# =================================================
__islowercase:
  blt $a0, 97, __isnotlowercase
  bgt $a0, 122, __islowercaseerror

  li $v0, 1
  jr $ra
  __islowercaseerror:
    li $v0, -1
    jr $ra
  __isnotlowercase:
    li $v0, 0
    jr $ra
