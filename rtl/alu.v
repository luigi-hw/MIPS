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
			zero,
			overflow
			);
	
parameter DATA_WIDTH = 16;
parameter OP_SIZE = 4;
localparam SHIFT_BITS = (DATA_WIDTH==32) ? 5 : 4;

// MIPS I operations (16 total) mapped to 4-bit control field.
// Mantidas apenas operações do conjunto MIPS I; operações não-MIPS I removidas.
// Expansões futuras possíveis (MIPS32r2): ROTR/ROTRV, CLZ/CLO, etc. Não implementadas aqui devido ao limite de 16 códigos.
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
`define ONE_BIT_ONE 1'b1
`define ONE_BIT_ZERO 1'b0

    input 		[DATA_WIDTH-1:0] rega;
    input 		[DATA_WIDTH-1:0] regb;
	input 		[OP_SIZE-1:0] 	control;
    output reg 	[DATA_WIDTH-1:0]	out_alu;
    output reg 					cout;
	output reg 					zero;
	output reg					equal;
	output reg                  overflow;

	reg 		[DATA_WIDTH:0]	pre_out;
	
always @(rega or regb or control)
begin
	equal = (rega == regb) ? 1'b1 : 1'b0;
	overflow = 1'b0;
	pre_out = {1'b0, {DATA_WIDTH{1'b0}}};
	case (control)
		`ADD  : begin
					pre_out = ({1'b0, rega} + {1'b0, regb});
					overflow = (~(rega[DATA_WIDTH-1] ^ regb[DATA_WIDTH-1])) & (pre_out[DATA_WIDTH-1] ^ rega[DATA_WIDTH-1]);
				end
		`SUB  : begin
					pre_out = ({1'b0, rega} - {1'b0, regb});
					overflow = ((rega[DATA_WIDTH-1] ^ regb[DATA_WIDTH-1])) & (pre_out[DATA_WIDTH-1] ^ rega[DATA_WIDTH-1]);
				end
		`AND  : pre_out = {1'b0, (rega & regb)};
		`OR   : pre_out = {1'b0, (rega | regb)};
		`XOR  : pre_out = {1'b0, (rega ^ regb)};
		`SLLV : pre_out = {1'b0, (rega << regb[SHIFT_BITS-1:0])};
		`SRLV : pre_out = {1'b0, (rega >> regb[SHIFT_BITS-1:0])};
		`SLT  : pre_out = {1'b0, ({ {DATA_WIDTH-1{1'b0}}, ($signed(rega) < $signed(regb)) } )};
		`NOR  : pre_out = {1'b0, ~(rega | regb)};
		`SLTU : pre_out = {1'b0, ({ {DATA_WIDTH-1{1'b0}}, (rega < regb) } )};
		`SLL  : pre_out = {1'b0, (rega << regb[SHIFT_BITS-1:0])};
		`COMP : pre_out = {1'b0, {DATA_WIDTH{1'b0}}};
		`SRAV : pre_out = {1'b0, $signed(rega) >>> regb[SHIFT_BITS-1:0]};
		`SUBU : begin
					pre_out = ({1'b0, rega} - {1'b0, regb});
					overflow = 1'b0;
				end
		`ADDU : begin
					pre_out = ({1'b0, rega} + {1'b0, regb});
					overflow = 1'b0;
				end
		`SRL  : pre_out = {1'b0, (rega >> regb[SHIFT_BITS-1:0])};
		default: begin
					pre_out = {1'b0, {DATA_WIDTH{1'b0}}};
					overflow = 1'b0;
				end
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
