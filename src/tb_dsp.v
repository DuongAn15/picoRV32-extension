`timescale 1ns/1ps

module tb_dsp;
    reg clk;
    reg resetn;
    
    // CPU Interfaces
    reg         mem_ready;
    reg  [31:0] mem_rdata;
    wire        mem_valid;
    wire        mem_instr;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;

    // Instantiate picoRV32
    picorv32 #(
        .ENABLE_REGS_DUALPORT(1),
        .TWO_CYCLE_ALU(1),
        .ENABLE_IRQ(0),
        .REGS_INIT_ZERO(1)
    ) cpu (
        .clk      (clk      ),
        .resetn   (resetn   ),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr (mem_addr ),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Memory Model (Simple ROM for Instructions)
    always @(posedge clk) begin
        mem_ready <= 0;
        if (mem_valid && !mem_ready) begin
            mem_ready <= 1;
            case (mem_addr)
                // LUI x1, 0x7FFF0 (x1 = 0x7FFF0000)
                32'h0000_0000: mem_rdata <= 32'h7FFF00B7;
                // ADDI x1, x1, 1 (x1 = 0x7FFF0001)
                32'h0000_0004: mem_rdata <= 32'h00108093;

                // LUI x2, 0x00010 (x2 = 0x00010000)
                32'h0000_0008: mem_rdata <= 32'h00010137;
                // ADDI x2, x2, 2 (x2 = 0x00010002)
                32'h0000_000C: mem_rdata <= 32'h00210113;

                // ADDI x4, x0, 10 (x4 = 10)
                32'h0000_0010: mem_rdata <= 32'h00A00213;

                // PADDS16 x5, x1, x2 (x5 = sat_add(0x7FFF, 0x0001) | sat_add(0x0001, 0x0002))
                // Expect x5 = 0x7FFF0003
                // Opcode: 0x0B, funct3: 000, funct7: 0x07, rd: x5 (00101) -> 0000 1110 0010 0000 1000 0010 1000 1011
                32'h0000_0014: mem_rdata <= 32'h0E20828B;

                // PSUBS16 x3, x1, x2 (x3 = sat_sub(0x7FFF, 0x0001) | sat_sub(0x0001, 0x0002))
                // Expect x3 = 0x7FFEFFFF
                // funct3: 001 -> 0000 1110 0010 0000 1001 0001 1000 1011
                32'h0000_0018: mem_rdata <= 32'h0E20918B;

                // PMAC16 x4, x1, x2 (x4 = x4 + (x1_lo * x2_lo) = 10 + 1 * 2 = 12)
                // funct3: 010, rd: x4 (00100) -> 0000 1110 0010 0000 1010 0010 0000 1011
                32'h0000_001C: mem_rdata <= 32'h0E20A20B;

                // J . (Infinite Loop)
                32'h0000_0020: mem_rdata <= 32'h0000006F;
                
                default: mem_rdata <= 32'h00000013; // NOP
            endcase
        end
    end

    // Expose CPU registers as wires for GTKWave
    wire [31:0] x1 = cpu.cpuregs[1];
    wire [31:0] x2 = cpu.cpuregs[2];
    wire [31:0] x3 = cpu.cpuregs[3];
    wire [31:0] x4 = cpu.cpuregs[4];
    wire [31:0] x5 = cpu.cpuregs[5];

    // Test Sequence
    initial begin
        $dumpfile("tb_dsp.vcd");
        $dumpvars(0, tb_dsp);
        
        resetn = 0;
        #20 resetn = 1;

        #250;
        $display("Register x4 at time 270: %08x", cpu.cpuregs[4]);

        #250;
        
        $display("PMAC Debug: pmac16_mul_reg=%08x, cpuregs_rs1=%08x, sat_pmac16=%08x", cpu.pmac16_mul_reg, cpu.cpuregs_rs1, cpu.sat_pmac16);
        $monitor("[%0t] alu_wait=%b, alu_wait_2=%b, cpu_state=%b, instr_pmac16=%b", $time, cpu.alu_wait, cpu.alu_wait_2, cpu.cpu_state, cpu.instr_pmac16);
        $display("Register x1: %08x", cpu.cpuregs[1]);
        $display("Register x2: %08x", cpu.cpuregs[2]);
        $display("Register x5: %08x (Expected 0x7FFF0003 after PADDS16)", cpu.cpuregs[5]);
        $display("Register x3: %08x (Expected 0x7FFEFFFF after PSUBS16)", cpu.cpuregs[3]);
        $display("Register x4: %08x (Expected 0x0000000C after PMAC16)", cpu.cpuregs[4]);
        
        $finish;
    end
endmodule
