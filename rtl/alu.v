//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Luigi C. Filho
// 
// Create Date:    16:42:29 04/06/2011 
// Design Name: ALU
// Module Name: alu
// Project Name: MIPS Processor
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module alu(
			rega,
			regb,
			control,
			out_alu,
			cout,
			equal,
			zero
			);
	
parameter DATA_WIDTH = 16;
parameter OP_SIZE = 4;
localparam SHIFT_BITS = (DATA_WIDTH==32) ? 5 : 4;

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
`define SRA 4'd12
`define SUBO 4'd13
`define SIG 4'd14
`define SOME 4'd15
`define ONE_BIT_ONE 1'b1
`define ONE_BIT_ZERO 1'b0

    input 		[DATA_WIDTH-1:0] rega;
    input 		[DATA_WIDTH-1:0] regb;
	input 		[OP_SIZE-1:0] 	control;
    output reg 	[DATA_WIDTH-1:0]	out_alu;
    output reg 					cout;
	output reg 					zero;
	output reg					equal;

	reg 		[DATA_WIDTH:0]	pre_out;
	
always @(rega or regb or control)
begin
	equal = (rega == regb) ? 1'b1 : 1'b0;
	case (control)
		`ADD  : pre_out = ({1'b0, rega} + {1'b0, regb});
		`SUB  : pre_out = ({1'b0, rega} - {1'b0, regb});
		`AND  : pre_out = {1'b0, (rega & regb)};
		`OR   : pre_out = {1'b0, (rega | regb)};
		`XOR  : pre_out = {1'b0, (rega ^ regb)};
		`L_SH : pre_out = {1'b0, (rega << regb[SHIFT_BITS-1:0])};
		`R_SH : pre_out = {1'b0, (rega >> regb[SHIFT_BITS-1:0])};
		`NAND : pre_out = {1'b0, ~(rega & regb)};
		`NOR  : pre_out = {1'b0, ~(rega | regb)};
		`XNOR : pre_out = {1'b0, ~(rega ^ regb)};
		`NOT  : pre_out = {1'b0, ~rega};
		`COMP : begin
					pre_out = {1'b0, {DATA_WIDTH{1'b0}}};
				end
		`SRA  : pre_out = {1'b0, $signed(rega) >>> regb[SHIFT_BITS-1:0]};
		`SUBO : pre_out = ({1'b0, rega} - {{DATA_WIDTH{1'b0}}, 1'b1});
		`SIG  : pre_out = ({1'b0, (~rega)} + {{DATA_WIDTH{1'b0}}, 1'b1});
		`SOME : pre_out = ({1'b0, rega} + {1'b0, ~regb});
	endcase
end

always @(pre_out)
begin
		out_alu = pre_out[DATA_WIDTH-1:0];
		cout = pre_out[DATA_WIDTH];
		if (out_alu == {DATA_WIDTH{1'b0}})
			zero = `ONE_BIT_ONE;
		else
			zero = `ONE_BIT_ZERO;
end		

endmodule
