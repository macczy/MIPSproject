#Program zamieniaj¹cy sta³e binarne w programie Ÿród³owym w jêzyku C na zgodne ze
#standardem ANSI sta³e szesnastkowe o mo¿liwie najkrótszej reprezentacji (0b100001 na
#0x21). Program nie mo¿e modyfikowaæ ³añcuchów tekstowych ani komentarzy.
	.data
buffer:	.space 128 ##IF CHANGE, NEED TO CHANGE IN getc
bufferWrite: .space 128 ##IF CHANGE, NEED TO CHANGE IN main, opening file for writing section 
filename: .asciiz "mian.c"
str_exit: .asciiz "mian2.c"
	.align 2
	.text
	.globl main
main:	
#Open the file for writing:
	li $v0, 13
	la $a0, str_exit
	li $a1, 1	#write
	li $a2, 0
   	syscall
   	move	$s0, $v0 #save file descriptor in S0
 	la	$s5, bufferWrite		#index of writing file
 	####HARDCODED LENGTH OF bufferWrite####
 	addiu	$s1, $s5, 128	#end of buffor to write
 	
#FILE OPENING FOR READING
	li	$v0, 13		#open a file
	li	$a1, 0		#read only
	la	$a0, filename	#file name to be read
	li	$a2, 0		#ignoring mode
	syscall
	move 	$t0, $v0	#saving file pointer to t0
	li	$s3, 1		#current index of reading buffer, set to 1 to force reading on first loop
	li	$s4, 0		#current lenght of reading buffer
	
	li	$s7, 0 	#stan 0
loop: #main loop
	jal	getc
	beq	$s7, 7, isBin		#state 7 - checking if after 0b we have binary number
	beq	$s7, 8, inside		#state 8 - loading binary number
	#the above states need special treatment for end of file
	bne	$s6, 0, stayIn
	li	$s7, 9		#state 9 - program end
	b	flush
stayIn:
	beq	$s7, 1, except		#state 1 - start of a comment
	beq	$s7, 2, quote		#state 2	- inside a quote
	beq	$s7, 3, ifBin		#state 3 - met 0, checking if binary
	beq	$s7, 4, inLine		#state 4	- inside inline comment
	beq	$s7, 5,	block		#state 5	- inside block comment
	beq	$s7, 6, blockAfter	#state 6 - inside block comment after met *
stan0:	
	jal	putc
	bne	$t1, '/', notComment	#comments exception
	li	$s7, 1			#stan 1 - comment
	b	loop			#comments exception
notComment:	
	bne	$t1, '"', notQuot
	li	$s7, 2			#stan 2 - quote
	b	loop
notQuot:
	bne	$t1, '0', notZero
	li	$s7, 3			#stan 3 - zero
notZero:
	b	loop
	
except: #comments exception loop
	jal	putc
	bne	$t1, '/', notInline 
	li	$s7, 4		# Stan 4 - in-line comment
	b loop
notInline:	
	bne	$t1, '*', notBlock #if not one-line comment or a block comment, go back to main loop
	li	$s7, 5			#stan5 - /* comment
	b	loop
notBlock:
	li	$s7, 0	#back to stan0
	b	loop

block:	#block comment exception loop
	beq	$s6, 0, flush
	jal	putc
	bne	$t1, '*', loop	#searching for */ pattern
	li	$s7, 6
	b	loop
	
blockAfter:	
	jal	putc
	bne	$t1, '/', loop
	li	$s7, 0
	b	loop
	
inLine:	##searh for the end of inline comment
	jal	putc	
	bne	$t1, '\n', loop
	li	$s7, 0	#back to stan0
	b	loop
	
quote:
	jal	putc
	bne	$t1, '"', loop
	li	$s7, 0
	b 	loop
	
ifBin:			
	bne	$t1, 'b', notBin	#if read char is 'b', go to check if it's a binary number
	li	$s7, 7				#remember about 'b'
	li	$t5, 0   #initialize t5 to 0 to store out binary number
	b	loop
notBin:
	li	$s7, 0
	jal	putc
	b	loop
	
isBin:  
	bne	$s6, 0, continue	#if file ends here, have to write b and end program
	li	$t1, 'b'
	jal	putc
	li	$s7, 9	#end program
	b	flush
continue:	
	beq	$t1, '0', inside
	beq	$t1, '1', inside #if not binary, leave as it was
	move	$t9, $t1
	li	$t1, 'b'
	jal	putc
	move	$t1, $t9
	jal	putc
	li	$s7, 0
	b	loop

inside:
	bne	$s6, 0, contConvert	#if file ends here, have to write b and end program
	li	$s7, 9	#end if the end of file
	b	outBin
contConvert:
	bltu	$t1, '0', outBin
	bgtu	$t1, '1', outBin
	
	li	$s7, 8	#stan 8
	sll	$t5, $t5, 1	#multiply t5 by 2
	subiu	$t1, $t1, '0'	#substract '0'
	addu	$t5, $t5, $t1	#add 1 or 0
	b	loop	
	
outBin:		##out of the binary number, time to calculate it
	move	$t7, $t1 	#save this char to write after the number
	li	$t1, 'x'
	jal	putc
	move 	$t9, $sp	#save stack pointer to t9
genHex:			####GENERATING HEX TO BE WRITTEN, REVERSED for easier writing
	and	$t8, $t5, 15	#save our binary number modulo 16 to t8
	addu	$t8, $t8, '0'
	bleu	$t8, '9', next
	addiu	$t8, $t8, 7 ##if 10-15, add ('A' - '0' + 1)
next: 
	subu	$sp, $sp, 4
	sw	$t8, ($sp)
	srl	$t5, $t5, 4 	#div binary by 16 and save in t5
	bgtz	$t5, genHex	#if binary greater than 0, stay in hex generating loop
writeHex:	###UN-REVERSING HEX AND WRITING IT
	lw	$t1, ($sp)
	addu	$sp, $sp, 4
	jal	putc
	bgtu	$t9, $sp, writeHex #finish loop when going out of buffer space
	move	$t1, $t7
	jal	putc
	beq	$s7, 9, flush	#end if state 9 
	li	$s7, 0
	b	loop
	
getc: #puts the next char into $t1
	bgtu	$s3, $s4, newBuffer #if already read the last char, need a new buffer
	lb	$t1, buffer($s3)
	addiu	$s3, $s3, 1	#point to the next char
	jr	$ra
newBuffer:	
	la	$t2, buffer
	li	$v0, 14		#reading from file
	move	$a0, $t0	#from FILENAME file
	la	$a1, ($t2)	#to which buffer read
	###HARDCODED BUFFER LENGTH###
	li	$a2, 10	#fill the buffer
	syscall			#read from file		
	lb 	$t1, ($t2)	#read the char
	#beqz	$v0, flush	#end of file detected
	la	$s6, ($v0)
	la	$s4, ($v0)	#load the buffer length to $s4
	subiu	$s4, $s4, 1 	#correction - counting from 0
	li	$s3, 0		#load reading index to 0
	b	getc

putc:
	bltu	$s1, $s5, flush #if first free spot is out of range, flush
	sb	$t1, ($s5)
	addiu	$s5, $s5, 1	#$s5 should point to the first free spot in bufferWrite
	jr	$ra
flush:	# $s1 = bufferWrite + buffer length
	#$s5 - spot for the next char to be written in
	###writing to file
	move 	$a0, $s0  		#file descriptor in $a0
	li 	$v0, 15			#write
	la 	$a1, bufferWrite	#write from bufferWrite begining
	subu	$a2, $s5, $a1		#put bufferWrite length into a2
 	syscall
	subiu	$t7, $s5, 1		
 	la	$s5, bufferWrite
 	bne	$s7, 9, putc		#if state 9, end program, otherwise continue putc

end:
	li   	$v0, 16 
	move 	$a0, $s0
	syscall	           # close file for writing
	li   	$v0, 16
	move 	$a0, $t0
	syscall	           # close file for reading
	li	$v0, 10
	syscall