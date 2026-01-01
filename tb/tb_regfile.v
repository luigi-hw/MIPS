`timescale 1ns / 1ps

module tb_regfile;

    // Inputs
    reg clk;
    reg w_ena;
    reg [31:0] w_data;
    reg [4:0] w_addr;
    reg [4:0] r1_addr;
    reg [4:0] r2_addr;

    // Outputs
    wire [31:0] r1_data;
    wire [31:0] r2_data;

    // Instantiate the Unit Under Test (UUT)
    regfile #(.MEM_WIDTH(32), .MEM_DEPTH(32), .ADDR_WIDTH(5)) uut (
        .clk(clk), 
        .w_data(w_data), 
        .w_ena(w_ena), 
        .r1_data(r1_data), 
        .r2_data(r2_data), 
        .w_addr(w_addr), 
        .r1_addr(r1_addr), 
        .r2_addr(r2_addr)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Initialize Inputs
        w_ena = 0;
        w_data = 0;
        w_addr = 0;
        r1_addr = 0;
        r2_addr = 0;

        $dumpfile("tb_regfile.vcd");
        $dumpvars(0, tb_regfile);

        // Wait for global reset
        #100;
        
        // Test 1: Write to Register 1
        @(negedge clk);
        w_ena = 1;
        w_addr = 5'd1;
        w_data = 32'hDEADBEEF;
        @(negedge clk);
        w_ena = 0;
        
        // Test 2: Read from Register 1
        r1_addr = 5'd1;
        #1;
        if (r1_data !== 32'hDEADBEEF) $display("FAIL: Read Reg 1, expected DEADBEEF, got %h", r1_data);
        else $display("PASS: Write/Read Reg 1");

        // Test 3: Write to Register 0 (Should stay 0)
        @(negedge clk);
        w_ena = 1;
        w_addr = 5'd0;
        w_data = 32'hFFFFFFFF;
        @(negedge clk);
        w_ena = 0;

        // Test 4: Read from Register 0
        r1_addr = 5'd0;
        #1;
        if (r1_data !== 32'd0) $display("FAIL: Reg 0 is not 0, got %h", r1_data);
        else $display("PASS: Reg 0 Hardwired to 0");

        // Test 5: Dual Read
        // Write Reg 2
        @(negedge clk);
        w_ena = 1;
        w_addr = 5'd2;
        w_data = 32'hCAFEBABE;
        @(negedge clk);
        w_ena = 0;

        r1_addr = 5'd1; // DEADBEEF
        r2_addr = 5'd2; // CAFEBABE
        #1;
        if (r1_data == 32'hDEADBEEF && r2_data == 32'hCAFEBABE) $display("PASS: Dual Read");
        else $display("FAIL: Dual Read r1=%h r2=%h", r1_data, r2_data);

        $finish;
    end
      
endmodule
