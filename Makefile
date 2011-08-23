PROD=tgl

release: $(PROD)

compress: $(PROD).gz

compile: $(PROD).elf

debug: $(PROD).elf
	readelf -a $(PROD).elf|grep Entry
	gdb $(PROD).elf

$(PROD): $(PROD).gz
	echo "T=/tmp/i;tail -n+2 \$$0|zcat>\$$T;chmod +x \$$T;\$$T;rm \$$T;exit" > $(PROD)
	cat $(PROD).gz >> $(PROD)
	chmod +x $(PROD)
	wc -c $(PROD)

$(PROD).gz: $(PROD).elf
	7z a -tGZip -mx=9 $(PROD).gz $(PROD).elf

$(PROD).elf: $(PROD).asm
	nasm -f bin $(PROD).asm -o $(PROD).elf
	chmod +x $(PROD).elf
	wc -c $(PROD).elf
