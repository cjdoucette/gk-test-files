/*
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 */

#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>

#define MY_DEST_MAC0	0x06
#define MY_DEST_MAC1	0x05
#define MY_DEST_MAC2	0x5e
#define MY_DEST_MAC3	0xfd
#define MY_DEST_MAC4	0x41
#define MY_DEST_MAC5	0xfc

#define DEFAULT_IF	"ens5"
#define BUF_SIZ		1024

uint32_t ip_checksum_add(uint32_t current, const void* data, int len)
{
    uint32_t checksum = current;
    int left = len;
    const uint16_t* data_16 = data;
    while (left > 1) {
        checksum += *data_16;
        data_16++;
        left -= 2;
    }
    if (left) {
        checksum += *(uint8_t*)data_16;
    }
    return checksum;
}

uint16_t ip_checksum_fold(uint32_t temp_sum)
{
    while (temp_sum > 0xffff) {
       temp_sum = (temp_sum >> 16) + (temp_sum & 0xFFFF);
    }
    return temp_sum;
}

uint16_t ip_checksum_finish(uint32_t temp_sum)
{
    return ~ip_checksum_fold(temp_sum);
}

uint16_t ip_checksum(const void* data, int len)
{
    uint32_t temp_sum;
    temp_sum = ip_checksum_add(0, data, len);
    return ip_checksum_finish(temp_sum);
}

int main(int argc, char *argv[])
{
	int sockfd;
	struct ifreq if_idx;
	struct ifreq if_mac;
	int tx_len = 0;
	char sendbuf[BUF_SIZ];
	struct ether_header *eh = (struct ether_header *) sendbuf;
	struct sockaddr_ll socket_address;
	
	/* Open RAW socket to send on */
	if ((sockfd = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW)) == -1) {
		perror("socket");
	}

	/* Get the index of the interface to send on */
	memset(&if_idx, 0, sizeof(struct ifreq));
	strncpy(if_idx.ifr_name, DEFAULT_IF, IFNAMSIZ-1);
	if (ioctl(sockfd, SIOCGIFINDEX, &if_idx) < 0)
		perror("SIOCGIFINDEX");
	/* Get the MAC address of the interface to send on */
	memset(&if_mac, 0, sizeof(struct ifreq));
	strncpy(if_mac.ifr_name, DEFAULT_IF, IFNAMSIZ-1);
	if (ioctl(sockfd, SIOCGIFHWADDR, &if_mac) < 0)
		perror("SIOCGIFHWADDR");

	/* Construct the Ethernet header */
	memset(sendbuf, 0, BUF_SIZ);
	/* Ethernet header */
	eh->ether_shost[0] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[0];
	eh->ether_shost[1] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[1];
	eh->ether_shost[2] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[2];
	eh->ether_shost[3] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[3];
	eh->ether_shost[4] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[4];
	eh->ether_shost[5] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[5];
	eh->ether_dhost[0] = MY_DEST_MAC0;
	eh->ether_dhost[1] = MY_DEST_MAC1;
	eh->ether_dhost[2] = MY_DEST_MAC2;
	eh->ether_dhost[3] = MY_DEST_MAC3;
	eh->ether_dhost[4] = MY_DEST_MAC4;
	eh->ether_dhost[5] = MY_DEST_MAC5;
	/* Ethertype field */
	eh->ether_type = htons(ETH_P_IP);
	tx_len += sizeof(struct ether_header);

	/* Packet data */
	sendbuf[tx_len++] = 0xde;
	sendbuf[tx_len++] = 0xad;
	sendbuf[tx_len++] = 0xbe;
	sendbuf[tx_len++] = 0xef;

	/* Index of the network device */
	socket_address.sll_ifindex = if_idx.ifr_ifindex;
	/* Address length*/
	socket_address.sll_halen = ETH_ALEN;
	/* Destination MAC */
	socket_address.sll_addr[0] = MY_DEST_MAC0;
	socket_address.sll_addr[1] = MY_DEST_MAC1;
	socket_address.sll_addr[2] = MY_DEST_MAC2;
	socket_address.sll_addr[3] = MY_DEST_MAC3;
	socket_address.sll_addr[4] = MY_DEST_MAC4;
	socket_address.sll_addr[5] = MY_DEST_MAC5;
	uint8_t bytes[64] = {
		0x06, 0x9c, 0xe1, 0x4c, 0xda, 0x44, 0x06, 0xfa, 0x3d, 0x93, 0x9b, 0x68, 0x08, 0x00, 0x45, 0x00,
		0x00, 0x32, 0x28, 0x1c, 0x40, 0x00, 0x40, 0x11, 0xb6, 0x35, 0xac, 0x1f, 0x00, 0x63, 0xac, 0x1f,
		0x03, 0xc8, 0xc3, 0x61, 0x1f, 0x90, 0x00, 0x1e, 0x5c, 0x99, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66,
		0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76
	};

	/* Send packet */
	unsigned long long i = 0;
	//uint32_t *src_addr = (uint32_t *)(bytes + 26);
	//uint32_t *dst_addr = (uint32_t *)(bytes + 30);
	while (1) {
		/*
		 * Round robin through IP addresses to hit all
		 * lcores; see Gatekeeper startup output to
		 * find which addresses 10.0.0.x hit which lcores,
		 * and fill in the array with x below.
		 * Change the number of samples according to how
		 * many lcores there are.
		 */
		//int samples[4] = { 0xf6, 0xf7, 0xf8, 0xf9 };
		//bytes[29] = samples[i % 4];
		if (sendto(sockfd, bytes, sizeof(bytes), 0,
				(struct sockaddr*)&socket_address,
				sizeof(struct sockaddr_ll)) < 0)
			printf("Send failed\n");
		i++;
	}

	return 0;
}
