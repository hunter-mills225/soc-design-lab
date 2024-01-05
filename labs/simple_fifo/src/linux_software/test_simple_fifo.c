#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h> 
#include <fcntl.h> 
#include <unistd.h>
#include <time.h>
#include <unistd.h>
#define _BSD_SOURCE

#define SIMPLE_FIFO_DATA_OFFSET 0
#define SIMPLE_FIFO_COUNTER_OFFSET 1
#define SIMPLE_FIFO_RESET_OFFSET 2
#define SIMPLE_FIFO_ID_OFFSET 3
#define SIMPLE_FIFO_ADDRESS 0x43c00000

// the below code uses a device called /dev/mem to get a pointer to a physical
// address.  We will use this pointer to read/write the custom peripheral
volatile unsigned int * get_a_pointer(unsigned int phys_addr)
{
	int mem_fd = open("/dev/mem", O_RDWR | O_SYNC); 
	void *map_base = mmap(0, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, mem_fd, phys_addr); 
	volatile unsigned int *fifo_base = (volatile unsigned int *)map_base; 
	return (fifo_base);
}

// Function to check if Simple FIFO data is correct
void check_fifo(int * fifo_data, int num_reads){
    // Fill test array
    int test_values[num_reads];
    for(int i = 0; i < num_reads; i++){
        test_values[i] = i + 1;
    }

    // Compare Test array and Simple FIFO data
    int num_errors = 0;
    for(int i = 0; i < num_reads; i++){
        if(test_values[i] != fifo_data[i]){
            //printf("ERROR at sample %d: Value = %d, Test Value = %d\n\r", i, fifo_data[i], test_values[i]);
            num_errors++;
        }
    }
    printf("NUMBER OF ERRORS: %d\n\r", num_errors);
}

// Function to read a specified number from the Simple FIFO
void read_fifo(volatile unsigned int *ptrToFifo, int *fifo_values, int num_reads) {
    for(int i=0; i<num_reads; i++){
        //Check to see if fifo is empty
        if(*(ptrToFifo+SIMPLE_FIFO_COUNTER_OFFSET) < 10){
            while(*(ptrToFifo+SIMPLE_FIFO_COUNTER_OFFSET) < 10){}
        }
        else{
        	fifo_values[i] = *(ptrToFifo+SIMPLE_FIFO_DATA_OFFSET);
        }
    }
    check_fifo(fifo_values, num_reads);
}

void print_benchmark(float time, int num_reads){
// Find the benchmark metrics
float throughput=0; 
unsigned int bytes_transferred = num_reads*4;				// # of Reads * 4bytes (32bits)
throughput = bytes_transferred/time;					// bytes / time / 1MB
printf("You transferred %u bytes of data in %f seconds\n",bytes_transferred,time);
printf("Measured Transfer throughput = %f Mbytes/sec\n",throughput);
}

int main(int argc, char* argv[]) {
    // Check only one command line arg
    if(argc != 2){
        printf("ERROR: Number of command line args must be 1\n\r");
        return -1;
    }
    char *num_reads_str = argv[1];
    int num_reads = atoi(num_reads_str);

    // Get Pointer to Simple FIFO
    volatile unsigned int *simple_fifo = get_a_pointer(SIMPLE_FIFO_ADDRESS);	

    // Menu
    printf("\r\n\r\n\r\nMilestone 1 Hunter Mills - Simple FIFO\n\r");
    printf("Number of reads: %d\n\r", num_reads);
    
    // Reset PL
    *(simple_fifo+SIMPLE_FIFO_RESET_OFFSET) = 0;
    *(simple_fifo+SIMPLE_FIFO_RESET_OFFSET) = 1;

    printf("WORK IN PROGRESS: Not reading correctly after full, benchmark");
    
    // Read from Simple FIFO
    int fifo_data[num_reads];
    printf("Reading ... \n\r");
    clock_t start = clock();    // Find start time
    read_fifo(simple_fifo, fifo_data,  num_reads);
    clock_t end = clock();       // Find end time
    printf("DONE\n\r");
    
    // Print Metrics
    //print_benchmark((float)(end-start)/CLOCKS_PER_SEC, num_reads);
    return 0;
}
