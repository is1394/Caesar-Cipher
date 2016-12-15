.data
mainprompt: .asciiz "Escoja la operacion? (1: encriptar - 2: desencriptar - 0: salir)\n>"
stringprompt: .asciiz "Ingrese el texto: \n>"
keypromt: .asciiz "Ingrese la cantidad de desplazamientos: (debe ser mayor a 0) \n>"
orientationpromt: .asciiz "Ingrese el sentido de despliazamiento (0: derecha - 1: izquierda)\n>"
encryprompt: .asciiz "Encriptando con la llave: "
decryprompt: .asciiz "Desencriptando con la llave: "
resultprompt: .asciiz "Resultado:\n"
conprompt: .asciiz "Presione '1' para continuar: \n"
errorstrpromt: .asciiz "Cadena Invalida \n"
exitprompt: .asciiz "Adios! \n"
endl: .asciiz "\n"
string: .space 256

.text
.globl main
# Main:
# $s0 -> Operacion
# $s1 -> Key
# $s2 -> Orientacion
# $s3 -> Longitud de string
main:
  # Mostrando mensaje de que escoja la operacion
  li $v0, 4
  la $a0, mainprompt
  syscall

  #lee el valor que escoje el usuario
  li $v0, 5
  syscall

  beq $v0, $zero, __exit # 0 = exit
  bltz $v0, main # <0 main
  bgt $v0, 2, main #>2 main

  addi $s0, $v0, 0 #Guarda en $s0 la operacion

#En este bloque se realiza el pedido al usuario
#de la llave de encriptacion que es el valor el cual
#se va a desplazar ya sea izq o der el texto para
#encriptar y desencriptar, dicha llave se almacena
#en $s1
__keyAsk:
  li $v0, 4
  la $a0, keypromt
  syscall

  li $v0, 5
  syscall

  li $t0, 26 #guarda en t0 26
  div $v0, $t0 #divide la clave $t1 <- $v0 % 26
  mfhi $t1

  beqz $t1, __keyAsk
  blt $t1, $0, __keyAsk
  addi $s1, $t1, 0 # guarda la llave en $s1

# En este bloque se solicita la palabra que se va
# a encriptar o desencriptar y se almacena en $
__stringAsk:
  li $v0, 4
  la $a0, stringprompt
  syscall

  li $v0, 8
  la $a0, string
  la $a1, 255
  syscall

  la $a0, string
  jal __strLen

  li $v0, 1
  move $a0, $v1
  syscall

__orientationAsk:
  li $v0, 4
  la $a0, orientationpromt
  syscall

  li $v0, 5
  syscall

  bltz $v0, __orientationAsk # <0 main
  bgt $v0, 1, __orientationAsk #>1 main

  addi $s2, $v0, 0  #Guarda la orientacion en $s2


__allowMemory:
  li $v0,9          #Asignacion de un buffer
  addi $a0, $s2, 1  #para el string calculado
  syscall

  addi $s3, $v0, 0

# Seleccionador de operacion
__selectOp:
  beq $s0, 1, __encryptMode
  beq $s0, 2, __decryptMode
  j main


__decryptMode:
  add $t0, $s1, $s1   #calculando el opuesto de la clave
  sub $s1, $s1, $t0

  li $v0, 4
  la $a0, decryprompt
  syscall

  li $v0, 1
  addi $a0, $s1, 0
  syscall

  li $v0, 4
  la $a0, endl
  syscall
  # mandar a las diferentes orientaciones

  j __exit

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


# Llamada a funcion caesarCipher
__cipherCall:
  addi $a0, $s2, 0    # $a0 <- orientacion
  li $a1,0            # $a1 <- indice actual
  addi $a2, $s3, 0    # $a2 <- string resultante
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

  li $v0,4
  la $a0, endl
  syscall

  beq $t0, 1, main


# li $v0, 1
# move $a0, $s0 #imprime el numero de la operacion
# syscall


__exit:                         # Print goodbye message and exit
  li $v0, 4
  la $a0, exitprompt
  syscall

  li $v0, 10
  syscall

##############################
####   F U N C I O N E S   ###
##############################

########################################################

#caesarCipher
# Parametros:
#  $a0 <- orientacion
#  $a1 <- indice actual
#  $a2 <- direccion string resultado
#
# Resultados:
# $v0 <- longitud string
# $v1 <- error (-1/0)
#
__caesarCipher:
  jal __exit
#   beq $a0, 0, __rightOrientation
#   beq $a0, 1, __leftOrientation
#
# __rightOrientation:
# # cifrado convencional
#   addi $sp, $sp -16
#   sw $a0

#strLen
# Parametro:
# $a0 <- string a validar
# $v1 <- length string
#
__strLen:
  li $t0, 0
  loop:
    lb $t1, 0($a0)
    beqz $t1, exit
    addi $a0, $a0, 1
    addi $t0, $t0, 1
    j loop
    exit:
      move $v1, $a1
      sub $v1, $t0, 1
      jr $ra
