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
    wire overflow;

    // Instantiate the Unit Under Test (UUT)
    alu #(.DATA_WIDTH(32)) uut (
        .rega(rega), 
        .regb(regb), 
        .control(control), 
        .out_alu(out_alu), 
        .cout(cout), 
        .equal(equal), 
        .zero(zero),
        .overflow(overflow)
    );

    `define ADD 4'd0
    `define SUB 4'd1
    `define AND 4'd2
    `define OR 4'd3
    `define XOR 4'd4
    `define SLLV 4'd5
    `define SRLV 4'd6
    `define SLT 4'd7
    `define NOR 4'd8
    `define SLTU 4'd9
    `define SLL 4'd10
    `define COMP 4'd11
    `define SRAV 4'd12
    `define SUBU 4'd13
    `define ADDU 4'd14
    `define SRL 4'd15

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

        // Test 7: XOR
        rega = 32'hAAAA5555; regb = 32'hFFFF0000; control = `XOR;
        #10;
        if (out_alu !== 32'h55555555) $display("FAIL: XOR");
        else $display("PASS: XOR");

        // Test 8: NOR
        rega = 32'hFF00FF00; regb = 32'h00FF00FF; control = `NOR;
        #10;
        if (out_alu !== 32'h00000000) $display("FAIL: NOR");
        else $display("PASS: NOR");

        // Test 9: SLLV with mask
        rega = 32'h00000001; regb = 32'd33; control = `SLLV;
        #10;
        if (out_alu !== 32'h00000002) $display("FAIL: SLLV mask 33->1");
        else $display("PASS: SLLV mask");

        // Test 10: SRLV with mask
        rega = 32'h00000002; regb = 32'd33; control = `SRLV;
        #10;
        if (out_alu !== 32'h00000001) $display("FAIL: SRLV mask 33->1");
        else $display("PASS: SRLV mask");

        // Test 11: SRAV sign replicate
        rega = 32'h80000000; regb = 32'd1; control = `SRAV;
        #10;
        if (out_alu !== 32'hC0000000) $display("FAIL: SRAV sign");
        else $display("PASS: SRAV sign");

        // Test 12: SLT
        rega = 32'hFFFFFFFF; regb = 32'd1; control = `SLT;
        #10;
        if (out_alu !== 32'd1) $display("FAIL: SLT");
        else $display("PASS: SLT");

        // Test 13: SLTU
        rega = 32'd1; regb = 32'd2; control = `SLTU;
        #10;
        if (out_alu !== 32'd1) $display("FAIL: SLTU 1<2");
        else $display("PASS: SLTU 1<2");

        // Test 14: SLTU false
        rega = 32'hFFFFFFFF; regb = 32'd1; control = `SLTU;
        #10;
        if (out_alu !== 32'd0) $display("FAIL: SLTU FFFF<1");
        else $display("PASS: SLTU FFFF<1");

        // Test 15: ADDU carry-out
        rega = 32'hFFFFFFFF; regb = 32'h00000001; control = `ADD;
        #10;
        if (out_alu !== 32'h00000000 || cout !== 1'b1) $display("FAIL: ADD carry-out");
        else $display("PASS: ADD carry-out");

        // Test 16: SUBU borrow-out
        rega = 32'h00000000; regb = 32'h00000001; control = `SUB;
        #10;
        if (out_alu !== 32'hFFFFFFFF || cout !== 1'b1) $display("FAIL: SUB borrow-out");
        else $display("PASS: SUB borrow-out");

        // Test 17: SLL immediate
        rega = 32'h00000001; regb = 32'd1; control = `SLL;
        #10;
        if (out_alu !== 32'h00000002) $display("FAIL: SLL imm");
        else $display("PASS: SLL imm");

        // Test 18: SRL immediate
        rega = 32'h00000002; regb = 32'd1; control = `SRL;
        #10;
        if (out_alu !== 32'h00000001) $display("FAIL: SRL imm");
        else $display("PASS: SRL imm");

        // Test 19: ADD signed overflow
        rega = 32'h7FFFFFFF; regb = 32'h00000001; control = `ADD;
        #10;
        if (overflow !== 1'b1) $display("FAIL: ADD signed overflow");
        else $display("PASS: ADD signed overflow");

        // Test 20: SUB signed overflow
        rega = 32'h80000000; regb = 32'h00000001; control = `SUB;
        #10;
        if (overflow !== 1'b1) $display("FAIL: SUB signed overflow");
        else $display("PASS: SUB signed overflow");

        // Test 21: ADDU no overflow
        rega = 32'h7FFFFFFF; regb = 32'h00000001; control = `ADDU;
        #10;
        if (overflow !== 1'b0) $display("FAIL: ADDU overflow set");
        else $display("PASS: ADDU no overflow");

        // Test 22: SUBU no overflow
        rega = 32'h80000000; regb = 32'h00000001; control = `SUBU;
        #10;
        if (overflow !== 1'b0) $display("FAIL: SUBU overflow set");
        else $display("PASS: SUBU no overflow");
        
        $finish;
    end
      
endmodule
