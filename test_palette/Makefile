all:
	yasm Input.asm -f elf -g dwarf2 -o Input.o
	ld -Ttext=0x7c00 -melf_i386 Input.o -o Input.elf 
	objcopy -O binary Input.elf Input.bin
	rm Input.o

run:
	qemu-system-x86_64 --drive format=raw,file=Input.bin

debug:
	qemu-system-x86_64 -S -gdb tcp::1234 --drive format=raw,file=Input.bin