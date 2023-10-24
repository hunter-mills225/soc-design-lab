/*
 * Hunter Mills
 * lab4.c: Play audio from DDS Compiler, user inputs frequency
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
#include <stdlib.h>
#include <string.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xgpio_l.h"
#include "xuartps.h"
#include "xiic_l.h"
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
	print("Switch Controls Data Path (FIR/DDS)");
	print("Press F to enter new frequency.\n\r");
	print("Press U/u to increase frequency by 1000/100Hz.\n\r");
	print("Press D/d to decrease frequency by 1000/100Hz.\n\r");
	print("Press R to reset DDS Phase.\n\r");
	print("Press P to pause until a key is pressed\n\r");
	print("Press E to exit program.\n\r");

	// Wait for input and read UART Transaction
	while(XUartPs_IsReceiveData(XPAR_PS7_UART_1_BASEADDR) == 0);
	char cmd_char = (char)XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);

	return cmd_char;
}

// Function to read frequency
int read_freq(){
	int num_chars = 5; // Number of chars in < 100kHz
	int number_input_chars = 0;
	char freq[5] = "00000";

	// Read number in as a char array
	for(int i = 0; i < num_chars; i++){
		// Wait for input and read UART Transaction
		while(XUartPs_IsReceiveData(XPAR_PS7_UART_1_BASEADDR) == 0);
		char in_char = (char)XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
		if(in_char == 13){	// Enter is ascii 13
			break;
		}
		else{
			number_input_chars += 1;
			freq[i] = in_char;
		}
	}

	// If the input frequency is 5 chars, wait for enter
	if(number_input_chars == 5){
		while(1){
			if(XUartPs_IsReceiveData(XPAR_PS7_UART_1_BASEADDR) == 0){
				char in_char = (char)XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
				if(in_char == 13){	// Enter is ascii 13
					break;
				}
			}
		}
	}

	// Convert to integer and return
	char return_freq[number_input_chars];
	strncpy(return_freq, freq, number_input_chars);
	return atoi(return_freq);
}

float calc_phase_inc(int freq){
	float phase_inc = freq * 1.073741824; // Random number is from 2^27/125M
	return phase_inc;
}

int main()
{
    init_platform();

    // Display header for Lab2
    print("********************************************************\n\r");
    print("*************** Hunter Mills ----- Lab 4 ***************\n\r");
    print("********************************************************\n\r");
    print("\n\r");
    print("Configuring CODEC over I2C ... ");
    config_codec();
    print("Done\n\r");
    print("Initial Freq must be less than 100kHz and under 5 chars\n\r");
	print("Enter initial frequency: ");
	int freq = read_freq();
	print("\n\r");
	printf("	Initial Frequency: %d\n\r", freq);

	// Variables
	char uart_input_val;
	int phase_inc;

	// Setting initial frequency and pulling DDS out of reset
	phase_inc = calc_phase_inc(freq);
	printf("	Initial Phase Inc: %d\n\r", phase_inc);
	XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA2_OFFSET, 1);
	XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA_OFFSET, phase_inc);

	while(1){
		uart_input_val = print_menu();

		// Logic for input values
		if(uart_input_val == 'U'){
			freq += 1000;
			phase_inc = calc_phase_inc(freq);
			printf("	New frequency: %d\n\r", freq);
			printf("	New Phase inc %d\n\r", phase_inc);
			XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA_OFFSET, phase_inc);
		}
		else if(uart_input_val == 'u'){
			freq += 100;
			phase_inc = calc_phase_inc(freq);
			printf("	New frequency: %d\n\r", freq);
			printf("	New Phase inc %d\n\r", phase_inc);
			XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA_OFFSET, phase_inc);
		}
		else if(uart_input_val == 'D'){
			if(freq - 1000 < 0){
				print("	ERROR: Frequency cannot go below 0Hz");
			}
			else{
				freq -= 1000;
				phase_inc = calc_phase_inc(freq);
				printf("	New frequency: %d\n\r", freq);
				printf("	New Phase inc %d\n\r", phase_inc);
				XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA_OFFSET, phase_inc);
			}
		}
		else if(uart_input_val == 'd'){
			if(freq - 100 < 0){
				print("	ERROR: Frequency cannot go below 0Hz");
			}
			else{
				freq -= 100;
				phase_inc = calc_phase_inc(freq);
				printf("	New frequency: %d\n\r", freq);
				printf("	New Phase inc %d\n\r", phase_inc);
				XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA_OFFSET, phase_inc);
			}
		}
		else if(uart_input_val == 'f' || uart_input_val == 'F'){
			print("	Input new frequency (freq < 100kHz and < 5 chars): ");
			freq = read_freq();
			print("\n\r");
			phase_inc = calc_phase_inc(freq);
			printf("	New frequency: %d\n\r", freq);
			printf("	New Phase inc %d\n\r", phase_inc);
			XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA_OFFSET, phase_inc);
		}
		else if(uart_input_val == 'E' || uart_input_val == 'e'){
			print("EXIT PROGRAM\n\r");
			XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA2_OFFSET, 0);
			break;
		}
		else if(uart_input_val == 'R' || uart_input_val == 'r'){
			print("	Resetting DDS ... ");
			XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA2_OFFSET, 0);
			usleep(10);
			XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA2_OFFSET, 1);
			print("DONE.\n\r");
		}
		else if(uart_input_val == 'P' || uart_input_val == 'p'){
			print("	Pausing DDS by holding reset low ... ");
			XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA2_OFFSET, 0);
			while(XUartPs_IsReceiveData(XPAR_PS7_UART_1_BASEADDR) == 0);
			(char)XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
			XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA2_OFFSET, 1);
			print("RESUMED. \n\r");
		}
		else{
			print("	ERROR: Unknown input character\n\r");
		}
	}

    cleanup_platform();
    return 0;
}
