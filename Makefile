PROD=tgl

# можно рассчитать
ELF_HEADER_SIZE=346

release: $(PROD)

clean: $(PROD)
	rm	$(PROD) $(PROD).gz $(PROD).elf 

compress: $(PROD).gz

show: $(PROD)
	udcli -s $(ELF_HEADER_SIZE) $(PROD).elf | less

compile: $(PROD).elf

debug: $(PROD)
	readelf -a $(PROD).elf|grep Entry
	gdb $(PROD).elf

$(PROD): $(PROD).gz
	echo "T=/tmp/i;tail -n+2 \$$0|zcat>\$$T;chmod +x \$$T;\$$T;rm \$$T;exit" > $(PROD)
	echo -ne "\x1f\x8b\x08\x001337" >> $(PROD)
	tail -c +9 $(PROD).gz >> $(PROD)
	chmod +x $(PROD)
	wc -c $(PROD)

$(PROD).gz: $(PROD).elf
	cat $(PROD).elf | 7z a dummy -tGZip -mx=9 -si -so > $(PROD).gz

$(PROD).elf: $(PROD).asm
	nasm -f bin $(PROD).asm -o $(PROD).elf
	chmod +x $(PROD).elf
	wc -c $(PROD).elf
