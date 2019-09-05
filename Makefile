all:
	gcc -Wall sendRawEth.c -o sendRawEth
	gcc -Wall sendRawEthRandom.c -o sendRawEthRandom
clean:
	rm -f sendRawEth sendRawEthRandom
