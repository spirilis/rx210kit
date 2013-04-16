/* Renesas RX210 basic test -- Hello World for the GCC/GNURX world
 *
 * Designed for the LED pinout of the YRPBRX210 promo board
 * Includes setting Option bytes
 */

#include "iodefine.h"
#include <stdint.h>


int main()
{
	uint32_t i=0, j=0;


/*	SYSTEM.PRCR.WORD = 0xA507;
	SYSTEM.OPCCR.BIT.OPCM = 0x00;
	while (SYSTEM.OPCCR.BIT.OPCMTSF)
		;
	SYSTEM.HOCOPCR.BYTE = 0;
	SYSTEM.HOCOCR.BYTE = 0;
	SYSTEM.HOCOCR2.BYTE = 0x03;
	
	SYSTEM.VRCR = 0;
	SYSTEM.SCKCR3.WORD = 0x0100;
	SYSTEM.PRCR.WORD = 0xA500; */
	

	// P15 = LED2
	PORT1.PMR.BIT.B5 = 0; // GPIO port
	PORT1.PDR.BIT.B5 = 1; // Output mode
	PORT1.PODR.BIT.B5 = 1;  // off

	PORT1.PMR.BIT.B6 = 0; PORT1.PDR.BIT.B6 = 1; PORT1.PODR.BIT.B6 = 0;


	PORT1.PODR.BIT.B5 = SYSTEM.SCKCR3.BIT.CKSEL & 0x01;
	//while(1) ;

	while (1) {
		PORT1.PODR.BIT.B5 ^= 1;
		for (i=0; i < 80000; i++)
			j++;
	}
	return 0;
}
