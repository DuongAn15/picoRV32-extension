`timescale 1ns/1ps

module tb_soc;
    reg clk;
    reg reset_button_n;
    reg uart_rx;
    wire uart_tx;
    wire [5:0] leds;

    top uut (
        .clk(clk),
        .reset_button_n(reset_button_n),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .leds(leds)
    );

    // 27MHz clock (Tang Nano 9K)
    initial begin
        clk = 0;
        forever #18.518 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_soc.vcd");
        $dumpvars(0, tb_soc);
        
        reset_button_n = 0;
        uart_rx = 1;
        #200 reset_button_n = 1;
        
        // Wait for enough time for UART transmission
        // The benchmark runs fast, but UART takes time.
        #100000000; // 100ms
        $display("\nSimulation Timeout reached.");
        $finish;
    end
endmodule
