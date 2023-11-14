#include <stdio.h>
#include <sys/mman.h> 
#include <fcntl.h> 
#include <unistd.h>
#include <time.h>
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



// Function to assert and deassert Reset
void reset(volatile unsigned int *ptrToFifo, int set){
    // Toggle reset
    if(set == 1){
        *(ptrToFifo+SIMPLE_FIFO_RESET_OFFSET) = 1;
    }
    else {
        *(ptrToFifo+SIMPLE_FIFO_RESET_OFFSET) = 0;
    }
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
            printf("ERROR at sample %d", i);
            num_errors++;
        }
    }
    printf("NUMBER OF ERRORS: %d", num_errors);
}

// Function to read a specified number from the Simple FIFO
void read_fifo(volatile unsigned int *ptrToFifo, int num_reads) {
    int fifo_values[num_reads];
    for(int i=0; i<num_reads; i++){
        //Check to see if fifo is empty
        if(*(ptrToFifo+SIMPLE_FIFO_COUNTER_OFFSET) > 0){
            fifo_values[i] = *(ptrToFifo+SIMPLE_FIFO_DATA_OFFSET);
        }
    }
    check_fifo(&fifo_values, num_reads);
}

// void print_benchmark(int time){
//     // Find the benchmark metrics
//     printf("Elapsed time: %f\n",stop_time-start_time);
//     float throughput=0; 
//     // please insert your code here for calculate the actual throughput in Mbytes/second
//     // how much data was transferred? How long did it take?
//     unsigned int bytes_transferred = 2048*4;					// # of Reads * 4bytes (32bits)
//     float clk_cycles = stop_time - start_time;					// Get number of clk cycles
//     float time_spent = clk_cycles / 125000000;					// clk cycles / clk speed
//     throughput = bytes_transferred/time_spent/1000000;			// bytes / time / 1MB
//     printf("You transferred %u bytes of data in %f seconds\n",bytes_transferred,time_spent);
//     printf("Measured Transfer throughput = %f Mbytes/sec\n",throughput);
// }

int main(int argc, char* argv[]) {
    // Check only one command line arg
    if(argc != 1){
        printf("ERROR: Number of command line args must be 1\n\r");
        return -1;
    }

    // Get Pointer to Simple FIFO
    volatile unsigned int *simple_fifo = get_a_pointer(SIMPLE_FIFO_ADDRESS);	

    // Menu
    printf("\r\n\r\n\r\nMilestone 1 Hunter Mills - Simple FIFO\n\r");
    printf("Number of reads: %d", *argv[0]);
    
    // Reset PL
    reset(simple_fifo, 0);
    
    // Read from Simple FIFO
    int * fifo_data;
    //printf("Reading ... \n\r");
    clock_t start = clock();    // Find start time
    read_fifo(simple_fifo, *argv[0]);
    //clock_t end = clock();       // Find end time
    printf("DONE\n\r");


    
    // Print Metrics
    //print_benchmark(int(end-start));
    return 0;
}
