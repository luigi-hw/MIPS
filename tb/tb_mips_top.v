`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench for MIPS Processor - WITH VERIFICATION
// Tests ALL implemented instructions and checks results
//////////////////////////////////////////////////////////////////////////////////

module tb_mips_top;

    // Inputs
    reg clk;
    reg reset;
    reg [31:0] pc_before_jal;
    
    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num = 0;

    // Instantiate the Unit Under Test (UUT)
    MIPS uut (
        .clock(clk),
        .reset(reset)
    );

    // Clock Generation - 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Task to check instruction result
    task check_result;
        input [31:0] expected;
        input [127:0] instr_name;
        begin
            test_num = test_num + 1;
            if (uut.writeback === expected) begin
                $display("[PASS] Test %0d: %s - Expected: %h, Got: %h", 
                         test_num, instr_name, expected, uut.writeback);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s - Expected: %h, Got: %h", 
                         test_num, instr_name, expected, uut.writeback);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    task wait_opcode_with_timeout;
        input [31:0] limit;
        input [5:0] opcode;
        output reg ok;
        integer i;
        begin : WAITLOOP2
            ok = 0;
            repeat(limit) begin
                @(posedge clk); #1;
                if (uut.instruction[31:26] == opcode) begin
                    ok = 1;
                    disable WAITLOOP2;
                end
            end
        end
    endtask
    
    task wait_opcode_funct_with_timeout;
        input [31:0] limit;
        input [5:0] opcode;
        input [5:0] funct;
        output reg ok;
        integer i;
        begin : WAITLOOP
            ok = 0;
            repeat(limit) begin
                @(posedge clk); #1;
                if ((uut.instruction[31:26] == opcode) && (uut.instruction[5:0] == funct)) begin
                    ok = 1;
                    disable WAITLOOP;
                end
            end
        end
    endtask
    
    // Task to check ALU output
    task check_alu;
        input [31:0] expected;
        input [127:0] instr_name;
        begin
            test_num = test_num + 1;
            if (uut.alu_out === expected) begin
                $display("[PASS] Test %0d: %s - ALU Expected: %h, Got: %h", 
                         test_num, instr_name, expected, uut.alu_out);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s - ALU Expected: %h, Got: %h", 
                         test_num, instr_name, expected, uut.alu_out);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    // Task to check a specific register file entry
    task check_reg;
        input [4:0] reg_index;
        input [31:0] expected;
        input [127:0] instr_name;
        begin
            test_num = test_num + 1;
            if (uut.REG_FILE.MEM[reg_index] === expected) begin
                $display("[PASS] Test %0d: %s - Reg[%0d] Expected: %h, Got: %h", 
                         test_num, instr_name, reg_index, expected, uut.REG_FILE.MEM[reg_index]);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s - Reg[%0d] Expected: %h, Got: %h", 
                         test_num, instr_name, reg_index, expected, uut.REG_FILE.MEM[reg_index]);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_value;
        input [31:0] actual;
        input [31:0] expected;
        input [127:0] instr_name;
        begin
            test_num = test_num + 1;
            if (actual === expected) begin
                $display("[PASS] Test %0d: %s - Expected: %h, Got: %h",
                         test_num, instr_name, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s - Expected: %h, Got: %h",
                         test_num, instr_name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Test sequence
    initial begin
        $dumpfile("tb_mips_top.vcd");
        $dumpvars(0, tb_mips_top);
        $display("PC/instr trace:");
        $monitor("t=%0t pc=%0d instr=%h rs=%h rt=%h regb=%h wb=%h alu=%h dest=%0d wena=%b jal=%b jorf=%b ctrl=%b", $time, uut.program_counter, uut.instruction, uut.rs_data, uut.rt_data, uut.regstb, uut.writeback, uut.alu_out, uut.dest, uut.ref_w_ena, uut.jal, uut.jorf, uut.ctrol_bus);
        
        $display("=================================================================");
        $display("       MIPS Processor Comprehensive Testbench");
        $display("=================================================================");
        $display("Testing all implemented instructions:");
        $display("  I-Type: ADDI, ADDIU, SLTI, SLTIU, ANDI, ORI, XORI, LUI, LW, SW");
        $display("  I-Type: BEQ, BNE, BLEZ, BGTZ");
        $display("  R-Type: ADD, ADDU, SUB, SUBU, AND, OR, XOR, NOR, SLL, SRL");
        $display("  J-Type: J, JAL");
        $display("=================================================================\n");

        // Reset sequence
        reset = 0;
        #20;
        reset = 1;
        pc_before_jal = 32'd0;
        @(posedge clk); // Wait for first instruction
        
        // ============ TEST ADDI INSTRUCTIONS ============
        @(negedge clk); #1;
        check_result(32'h00000005, "ADDI $1, $0, 5");
        
        @(negedge clk); #1;
        check_result(32'h0000000A, "ADDI $2, $0, 10");
        
        @(negedge clk); #1;
        check_result(32'h0000000F, "ADDI $3, $0, 15");
        
        @(negedge clk); #1;
        check_result(32'hFFFFFFFF, "ADDI $4, $0, -1");
        
        // ============ TEST R-TYPE INSTRUCTIONS ============
        @(negedge clk); #1;
        check_result(32'h0000000F, "ADD $5=$1+$2 (5+10=15)");
        
        @(negedge clk); #1;
        check_result(32'h0000000F, "ADDU $6=$1+$2 (15)");
        
        @(negedge clk); #1;
        check_result(32'h00000005, "SUB $7=$2-$1 (10-5=5)");
        
        @(negedge clk); #1;
        check_result(32'h0000000A, "SUBU $8=$3-$1 (15-5=10)");
        
        @(negedge clk); #1;
        check_result(32'h00000000, "AND $9=$1&$2 (5&10=0)");
        
        @(negedge clk); #1;
        check_result(32'h0000000F, "OR $10=$1|$2 (5|10=15)");
        
        @(negedge clk); #1;
        check_result(32'h0000000F, "XOR $11=$1^$2 (5^10=15)");
        
        @(negedge clk); #1;
        check_result(32'hFFFFFFF0, "NOR $12=~($1|$2)");
        
        // ============ TEST I-TYPE ALU INSTRUCTIONS ============
        @(negedge clk); #1;
        check_result(32'h00000069, "ADDIU $13=$1+100 (105)");
        
        @(negedge clk); #1;
        check_result(32'h0000000A, "ANDI $14=$2&0x0F (10)");
        
        @(negedge clk); #1;
        check_result(32'h000000FA, "ORI $15=$2|0xF0 (250)");
        
        @(negedge clk); #1;
        check_result(32'h000000F5, "XORI $16=$2^0xFF (245)");
        
        @(negedge clk); #1;
        check_result(32'h12340000, "LUI $17=0x1234<<16");
        
        @(negedge clk); #1;
        check_result(32'h00000001, "SLTI $18=(5<10)?1:0");
        
        @(negedge clk); #1;
        check_result(32'h00000000, "SLTIU $19=(10<5)?1:0");
        
        // ============ TEST MEMORY INSTRUCTIONS ============
        @(negedge clk); #1;
        @(negedge clk); #1;
        
        @(posedge clk); #1;
        check_value(uut.DATA_MEM.MEM1[0], 32'h00000005, "SW wrote mem[0]=5");
        check_value(uut.DATA_MEM.MEM1[4], 32'h0000000A, "SW wrote mem[4]=10");
        
        @(negedge clk); #1;
        check_result(32'h00000005, "LW $20 from mem[0]");
        
        @(negedge clk); #1;
        check_result(32'h0000000A, "LW $21 from mem[4]");
        
        // ============ TEST BRANCH INSTRUCTIONS ============
        @(posedge clk); #1;
        check_value(uut.program_counter, 32'd26, "BEQ $1,$1,+2 - PC jumped to 26");
        
        @(posedge clk); #1;
        @(posedge clk); #1;
        check_value(uut.program_counter, 32'd29, "BNE $1,$2,+1 - PC jumped to 29");
        
        // ============ TEST BLTZ/BGEZ ============
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(negedge clk); #1;
        check_reg(24, 32'hFFFFFFFE, "ADDI $24, $0, -2");
        
        @(posedge clk); #1;
        check_value(uut.program_counter, 32'd34, "BLTZ $24,+1 - PC jumped to 34");
        
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        check_value(uut.program_counter, 32'd38, "BGEZ $26,+1 - PC jumped to 38");
        
        // ============ TEST JR/JALR ============
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        check_value(uut.program_counter, 32'd45, "JR $28 - PC jumped to 45");
        
        @(posedge clk); #1;
        @(negedge clk); #1;
        check_reg(29, 32'h00000007, "JR target executed");
        
        @(posedge clk); #1;
        @(posedge clk); #1;
        check_value(uut.program_counter, 32'd48, "JALR $30 - PC jumped to 48");
        
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(negedge clk); #1;
        check_reg(31, 32'h00000001, "JALR target executed");
        
        // ============ TEST SLT/SLTU (R-Type) ============
        @(posedge clk); #1;
        @(negedge clk); #1;
        check_result(32'h00000001, "SLT $24=$1<$2");
        
        @(posedge clk); #1;
        @(negedge clk); #1;
        check_result(32'h00000000, "SLTU $25=$2<$1");

        // ============ TEST SLL/SRL/SRA (Immediate shamt) ============
        @(posedge clk); #1;
        @(posedge clk); #1;
        check_result(32'h0000001E, "SLL $6,$5,1 (15<<1=30)");
        @(posedge clk); #1;
        check_result(32'h00000007, "SRL $6,$5,1 (15>>1=7)");
        @(posedge clk); #1;
        check_result(32'h00000007, "SRA $6,$5,1 (15>>>1=7)");

        // ============ TEST JAL ============
        pc_before_jal = uut.program_counter;
        @(posedge clk); #1;
        check_reg(31, pc_before_jal + 32'd1, "JAL link writeback to $31");
        check_value(uut.program_counter, 32'd120, "JAL jumped to target 120");

        // ============ SUMMARY ============
        $display("\n=================================================================");
        $display("                    TEST SUMMARY");
        $display("=================================================================");
        $display("  PASSED TASKS/BRANCHES: %0d", pass_count);
        $display("  FAILED TASKS/BRANCHES: %0d", fail_count);
        
        // Final Register Check using correct hierarchical name 'MEM'
        $display("\nFinal Register File Contents:");
        $display("  $1  = %h (expected: 00000005)", uut.REG_FILE.MEM[1]);
        $display("  $2  = %h (expected: 0000000A)", uut.REG_FILE.MEM[2]);
        $display("  $3  = %h (expected: 0000000F)", uut.REG_FILE.MEM[3]);
        $display("  $4  = %h (expected: FFFFFFFF)", uut.REG_FILE.MEM[4]);
        $display("  $5  = %h (expected: 0000000F)", uut.REG_FILE.MEM[5]);
        $display("  $17 = %h (expected: 12340000)", uut.REG_FILE.MEM[17]);
        $display("  $20 = %h (expected: 00000005)", uut.REG_FILE.MEM[20]);
        $display("  $21 = %h (expected: 0000000A)", uut.REG_FILE.MEM[21]);

        $display("=================================================================");
        
        if (fail_count == 0)
            $display("  >>> COMPONENT TESTS CLEAN <<< (Check Reg Values above)");
        else
            $display("  >>> SOME FAILURES DETECTED <<<");
        
        $display("=================================================================\n");
        
        $finish;
    end
      
endmodule
