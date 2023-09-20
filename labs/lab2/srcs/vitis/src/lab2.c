/*
 * Hunter Mills
 * lab2.c: Load and play audio
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xgpio_l.h"
#include "xuartps.h"
#include "xiic_l.h"
#include "xllfifo.h"
#include "sleep.h"
#include "malloc.h"

// Function to write I2C streams to codec
void write_codec_register(int addr, u8 val){
	u8 config_arr[2];
	config_arr[0] = addr;
	config_arr[1] = val;
	unsigned bytes_sent = XIic_Send(XPAR_AXI_IIC_0_BASEADDR, 0x1a, &config_arr[0], 2, 0);
	if (bytes_sent != 2) {
		print("ERROR I2C Didnt send correct number of bytes");
	}
}

// Function to create codec init values
void config_codec(){
	// Hold low level dac in reset during config
	XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA_OFFSET, 1);

	// Config over I2C
	write_codec_register(30, 0x00);	// Reset Codec
	usleep(1000);
	write_codec_register(12, 0x37);	// Power Management
	write_codec_register(0,  0x80);	// L-C Volume ADC
	write_codec_register(2,  0x80);	// R-C Volume ADC
	write_codec_register(4,  0x79);	// L-C Volume DAC
	write_codec_register(6,  0x79);	// R-C Volume DAC
	write_codec_register(8,  0x10);	// Analog audio path
	write_codec_register(10, 0x00);	// Digital audio path
	write_codec_register(14, 0x02);	// Digital audio I/F
	write_codec_register(16, 0x00);	// Sample rate
	usleep(75000);
	write_codec_register(12, 0x27);
	usleep(75000);
	write_codec_register(18, 0x01);	// Active

	// Deassert reset pin for low level DAC
	XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA_OFFSET, 0);
}

// Function to print out menu
char print_menu(){
	// Read out any leftover UART transactions
	while(XUartPs_IsReceiveData(XPAR_PS7_UART_1_BASEADDR)){
			XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
	}

	// Print Menu
	print("\n\r");
	print("MENU: \n\r");
	print("Press L to load file and play once.\n\r");
	print("Press C to play back loaded file continuously.\n\r");
	print("Press B to continuously play 6kHz tone.\n\r");
	print("Press E to exit program.\n\r");

	// Wait for input and read UART Transaction
	while(XUartPs_IsReceiveData(XPAR_PS7_UART_1_BASEADDR) == 0);
	char cmd_char = (char)XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);

	return cmd_char;
}

// Play hardcoded 6kHz tone
void play_hardcode() {
	while(1){
		// Check UART for exit command
		if (XUartPs_IsReceiveData(XPAR_PS7_UART_1_BASEADDR) != 0){
			XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
			return;
		}

		// Check to make sure FIFO isnt full
		int tx_vacancy = XLlFifo_ReadReg(XPAR_AXI_FIFO_0_BASEADDR, XLLF_TDFV_OFFSET);
		if (tx_vacancy < 8){
			while(XLlFifo_ReadReg(XPAR_AXI_FIFO_0_BASEADDR, XLLF_TDFV_OFFSET) < 256);
		}

		// Play Hard Coded 6Hz Sin wave
		XLlFifo_WriteReg(XPAR_AXI_FIFO_0_BASEADDR, XLLF_TDFD_OFFSET, 0);
		XLlFifo_WriteReg(XPAR_AXI_FIFO_0_BASEADDR, XLLF_TDFD_OFFSET, 7070);
		XLlFifo_WriteReg(XPAR_AXI_FIFO_0_BASEADDR, XLLF_TDFD_OFFSET, 10000);
		XLlFifo_WriteReg(XPAR_AXI_FIFO_0_BASEADDR, XLLF_TDFD_OFFSET, 7070);
		XLlFifo_WriteReg(XPAR_AXI_FIFO_0_BASEADDR, XLLF_TDFD_OFFSET, 0);
		XLlFifo_WriteReg(XPAR_AXI_FIFO_0_BASEADDR, XLLF_TDFD_OFFSET, -7070);
		XLlFifo_WriteReg(XPAR_AXI_FIFO_0_BASEADDR, XLLF_TDFD_OFFSET, -10000);
		XLlFifo_WriteReg(XPAR_AXI_FIFO_0_BASEADDR, XLLF_TDFD_OFFSET, -7070);
	}
}

// Function to play loaded tone once
void play_once(int* samples, int samp_len){
	for(int i = 0; i < samp_len; i++){
		// Check to make sure FIFO isnt full
		int tx_vacancy = XLlFifo_ReadReg(XPAR_AXI_FIFO_0_BASEADDR, XLLF_TDFV_OFFSET);
		if (tx_vacancy < 8){
			while(XLlFifo_ReadReg(XPAR_AXI_FIFO_0_BASEADDR, XLLF_TDFV_OFFSET) < 256);
		}

		// Play Hard Coded 6Hz Sin wave
		XLlFifo_WriteReg(XPAR_AXI_FIFO_0_BASEADDR, XLLF_TDFD_OFFSET, samples[i]);
	}
}

// Function to load bin file over UART
int* load_file(int* samples, int* sample_len){
	// Wait for file to be sent
	while(XUartPs_IsReceiveData(XPAR_PS7_UART_1_BASEADDR) == 0);

	// Read length of file
	for(int i=0; i<4; i++){
		*sample_len += (char)XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR) << (8*i);
	}

	char left_lsb;
	char left_msb;
	char right_lsb;
	char right_msb;
	for(int i = 0; i < *sample_len; i++){
		left_lsb = (char)XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
		left_msb = (char)XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
		right_lsb = (char)XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
		right_msb = (char)XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
		samples[i] = left_lsb + (left_msb << 8) + (right_lsb << 16) + (right_msb << 24);
	}
	return samples;
}

int main()
{
    init_platform();

    // Display header for Lab2
    print("********************************************************\n\r");
    print("*************** Hunter Mills ----- Lab 2 ***************\n\r");
    print("********************************************************\n\r");
    print("\n\r");
    print("Configuring CODEC over I2C ... ");
    config_codec();
    print("Done\n\r");

    // Variables
    int* samples;
    samples = (int*)malloc(4096 * sizeof(int));
    int samp_len = 0;
    int loaded = 0;

    // Check memory allocation
    if (samples == NULL){
    	print("ERROR: Memory could not be allocated");
    	return -1;
    }

    while(1){
    	char cmd_char = print_menu();

    	// Branching logic
    	if (cmd_char == 'L' || cmd_char == 'l') {
    		// Branch to load
    		print("Send file from UART terminal\n\r");
    		print("---- File must not be longer than 4096 samples. ----\n\r");
    		samp_len = 0;
    		load_file(samples, &samp_len);
    		play_once(samples, samp_len);
    		loaded = 1;
    	}
    	else if (cmd_char == 'C' || cmd_char == 'c') {
    		// Check if data is loaded to play continuously
    		if (loaded == 0){
    			print("***** WARNING: No file has been uploaded *****\n\r");
    		}
    		else {
    			print("Press any key to exit ... ");
    			while(1){
					// Check UART for exit command
					if (XUartPs_IsReceiveData(XPAR_PS7_UART_1_BASEADDR) != 0){
						XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
						break;
					}
					play_once(samples, samp_len);
    			}
    			print("DONE\n\r");
    		}
    	}
    	else if (cmd_char == 'B' || cmd_char == 'b'){
    		// Play 6kHz Beep continuously
    		print("Playing hard coded wave\n\r");
			print("Press any button to exit ...");
			play_hardcode();
			print(" DONE\n\r");
    	}
    	else if (cmd_char == 'E' || cmd_char == 'e'){
    		print("Exiting program ... DONE\n\r");
    		break;
    	}
    	else {
    		printf("ERROR: Input Character %c not recognized\n\r", cmd_char);
    	}
    }

    cleanup_platform();
    return 0;
}
