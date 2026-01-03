`timescale 1ns / 1ps

module tb_decoder;

    // Inputs
    reg [5:0] opcode;
    reg [6:0] funct;
    reg equalrsrt;
    reg rsmaior;
    reg rsmrt;

    // Outputs
    wire [7:0] ctrol;
    wire [3:0] outsaida;
    wire [31:0] rt;
    wire slt_mux;

    // Instantiate the Unit Under Test (UUT)
    decoder_mips uut (
        .opcode(opcode), 
        .funct(funct), 
        .equalrsrt(equalrsrt),
        .rsmaior(rsmaior),
        .rsmrt(rsmrt),
        .outsaida(outsaida),
        .ctrol(ctrol),
        .rt(rt),
        .slt_mux(slt_mux)
    );

    initial begin
        // Initialize Inputs
        opcode = 0;
        funct = 0;
        equalrsrt = 0;
        rsmaior = 0;
        rsmrt = 0;

        $dumpfile("tb_decoder.vcd");
        $dumpvars(0, tb_decoder);

        // Wait 100 ns for global reset
        #100;
        
        // Test 1: R-Type ADD (Opcode 0, Funct 32/0x20)
        opcode = 6'd0;
        funct = 7'd32; // 0x20
        #10;
        $display("R-Type ADD: Control=%b, ALU_Ctrl=%b", ctrol, outsaida);

        // Test 2: LW (Opcode 35/0x23)
        opcode = 6'd35;
        funct = 0;
        #10;
        $display("LW: Control=%b, ALU_Ctrl=%b", ctrol, outsaida);

        // Test 3: SW (Opcode 43/0x2B)
        opcode = 6'd43;
        funct = 0;
        #10;
        $display("SW: Control=%b, ALU_Ctrl=%b", ctrol, outsaida);

        // Test 4: BEQ (Opcode 4/0x04)
        opcode = 6'd4;
        funct = 0;
        equalrsrt = 1; // Simulate equality
        #10;
        $display("BEQ (Taken): Control=%b, ALU_Ctrl=%b", ctrol, outsaida);
        
        // Test 5: SLTI (Opcode 10)
        opcode = 6'd10;
        funct = 0;
        rsmaior = 1; // Result sets rt=1
        #10;
        $display("SLTI (rs>imm): Control=%b, ALU_Ctrl=%b, rt=%d", ctrol, outsaida, rt);

        $finish;
    end
      
endmodule
