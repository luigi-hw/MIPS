`timescale 1ns / 1ps

module tb_alu;

    // Inputs
    reg [31:0] rega;
    reg [31:0] regb;
    reg [3:0] control;

    // Outputs
    wire [31:0] out_alu;
    wire cout;
    wire equal;
    wire zero;

    // Instantiate the Unit Under Test (UUT)
    alu #(.DATA_WITH(32)) uut (
        .rega(rega), 
        .regb(regb), 
        .control(control), 
        .out_alu(out_alu), 
        .cout(cout), 
        .equal(equal), 
        .zero(zero)
    );

    // ALU Macros (matching alu.v)
    `define ADD 4'd0
    `define SUB 4'd1
    `define AND 4'd2
    `define OR 4'd3
    `define XOR 4'd4
    `define L_SH 4'd5
    `define R_SH 4'd6
    `define NAND 4'd7
    `define NOR 4'd8
    `define XNOR 4'd9
    `define NOT 4'd10
    `define COMP 4'd11
    `define ADDO 4'd12
    `define SUBO 4'd13
    `define SIG 4'd14
    `define SOME 4'd15

    initial begin
        // Initialize Inputs
        rega = 0;
        regb = 0;
        control = 0;

        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);

        // Wait 100 ns for global reset to finish
        #100;

        // Test 1: ADD
        rega = 32'd10; regb = 32'd20; control = `ADD;
        #10;
        if (out_alu !== 32'd30) $display("FAIL: ADD 10+20 != 30, got %d", out_alu);
        else $display("PASS: ADD");

        // Test 2: SUB
        rega = 32'd50; regb = 32'd20; control = `SUB;
        #10;
        if (out_alu !== 32'd30) $display("FAIL: SUB 50-20 != 30, got %d", out_alu);
        else $display("PASS: SUB");

        // Test 3: AND
        rega = 32'h00FF; regb = 32'h0F0F; control = `AND;
        #10;
        if (out_alu !== 32'h000F) $display("FAIL: AND");
        else $display("PASS: AND");

        // Test 4: OR
        rega = 32'h00FF; regb = 32'h0F0F; control = `OR;
        #10;
        if (out_alu !== 32'h0FFF) $display("FAIL: OR");
        else $display("PASS: OR");

        // Test 5: COMP (Equality)
        rega = 32'd100; regb = 32'd100; control = `COMP;
        #10;
        if (equal !== 1'b1) $display("FAIL: COMP Equal");
        else $display("PASS: COMP Equal");

        rega = 32'd100; regb = 32'd101; control = `COMP;
        #10;
        if (equal !== 1'b0) $display("FAIL: COMP Not Equal");
        else $display("PASS: COMP Not Equal");

        // Test 6: Zero Flag
        rega = 32'd10; regb = 32'd10; control = `SUB; // 10-10=0
        #10;
        if (zero !== 1'b1) $display("FAIL: Zero Flag not set");
        else $display("PASS: Zero Flag");
        
        $finish;
    end
      
endmodule
