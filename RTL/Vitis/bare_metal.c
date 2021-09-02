#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
//#include "xparameters.h"

#include "arrays.h"


int main()
{

	unsigned int config3, config4, config5, config6;
	int miss_count = 0;
	int i = 0;

	Xil_DCacheDisable();
	Xil_ICacheDisable();
    init_platform();

	config3 = 0x0019014a;
	config4 = 0;
	config4 |= 64 << 12;
	config5 = 8;

	Xil_Out32(CONFIG_BASE_ADDRESS + 0, 10*10*16*8);							// config1 upis
	printf("config1: %d\n", (unsigned int)Xil_In32(CONFIG_BASE_ADDRESS + 0));

	Xil_Out32(CONFIG_BASE_ADDRESS + 4, (10*10*16 + 3*3*64*16) * 8);			// config2 upis
	printf("config2: %d\n", (unsigned)Xil_In32(CONFIG_BASE_ADDRESS + 4));

	Xil_Out32(CONFIG_BASE_ADDRESS + 12, config4);							// config4 upis
	printf("config4: %d\n", (unsigned)Xil_In32(CONFIG_BASE_ADDRESS + 12));

	Xil_Out32(CONFIG_BASE_ADDRESS + 16, config5);							// config5 upis
	printf("config5: %d\n", (unsigned)Xil_In32(CONFIG_BASE_ADDRESS + 16));

	Xil_Out32(CONFIG_BASE_ADDRESS + 24, dram_content);						// config7 upis
	printf("config7: %d\n", (unsigned)Xil_In32(CONFIG_BASE_ADDRESS + 24));

	Xil_Out32(CONFIG_BASE_ADDRESS + 8, config3);							// config3 upis
	printf("config3: %d\n", (unsigned)Xil_In32(CONFIG_BASE_ADDRESS + 8));

	while((Xil_In32(CONFIG_BASE_ADDRESS + 20) & (unsigned int)WMEM_DONE_MASK) == 0);	// config6 citanje

	printf("Ucitane tezine u memoriju.\n");

	config3 = 0x00190153;
	Xil_Out32(CONFIG_BASE_ADDRESS + 8, config3);							// config3 upis
	printf("novi config3: %d\n", (unsigned)Xil_In32(CONFIG_BASE_ADDRESS + 8));

	while((Xil_In32(CONFIG_BASE_ADDRESS + 20) & (unsigned int)CACHE_DONE_MASK) == 0);		// config6 citanje

	printf("Izracunata hardver konvolucija.\n");


	for(i = 0; i < 4096; i++)
	{
		if(dram_content[i + (10*10*16 + 3*3*64*16)] != expected_result[i])
		{
			miss_count++;
		}
		//printf("%" PRIu64 "\n", dram_content[i + (10*10*16 + 3*3*64*16)]);
		printf("Dobijena vrednost: %" PRIu64 "\t ocekivana vrednost: %" PRIu64 "\n", dram_content[i + (10*10*16 + 3*3*64*16)], expected_result[i]);
	}
	printf("miss_count: %d\n", miss_count);
	printf("bazna adresa sadrzaja drama: %d\n", dram_content);

	//int temp = Xil_In32(10816+4095);

	printf("Adresa prvog: %d\t adresa poslednjeg: %d\n", &dram_content[0], &dram_content[29823]);


    print("Successfully ran Upsampling application");
    cleanup_platform();
    return 0;
}
