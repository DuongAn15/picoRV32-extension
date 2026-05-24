module my_coprocessor (
    input         clk,
    input         resetn,

    input         pcpi_valid,
    input  [31:0] pcpi_insn,
    input  [31:0] pcpi_rs1,
    input  [31:0] pcpi_rs2,

    output reg        pcpi_wr,
    output reg [31:0] pcpi_rd,
    output reg        pcpi_wait,
    output reg        pcpi_ready
);

    wire [6:0] opcode = pcpi_insn[6:0];
    wire [2:0] funct3 = pcpi_insn[14:12];

    wire is_custom = (opcode == 7'b0001011);

    reg busy;

    always @(posedge clk) begin
        if (!resetn) begin
            busy <= 0;
            pcpi_ready <= 0;
            pcpi_wr <= 0;
            pcpi_wait <= 0;
        end else begin
            pcpi_ready <= 0;
            pcpi_wr <= 0;

            if (pcpi_valid && is_custom && !busy) begin
                busy <= 1;
                pcpi_wait <= 1;
            end
            else if (busy) begin
                case (funct3)
                    3'b000: pcpi_rd <= pcpi_rs1 + pcpi_rs2;               // cadd
                    3'b001: pcpi_rd <= pcpi_rs1 ^ pcpi_rs2;               // cxor
                    3'b010: pcpi_rd <= pcpi_rs1 << (pcpi_rs2 & 5'b11111); // cshl
                    default: pcpi_rd <= 32'hDEADBEEF;
                endcase

                pcpi_wr <= 1;
                pcpi_ready <= 1;
                pcpi_wait <= 0;
                busy <= 0;
            end
        end
    end

endmodule