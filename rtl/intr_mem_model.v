//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Luigi C. Filho
// 
// Create Date: 16:48 4/10/2011 
// Design Name: Instruction Memory Model
// Module Name: intr_mem 
// Project Name: MIPS
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Revision 0.02 - Minor Changes
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module instr_mem (
	data, 
	addr
);

//parameter declarations
parameter MEM_WORD = 32;
parameter ADDR_WIDTH = 32;

//Input and output declarations
input [ADDR_WIDTH-1:0] addr;
output reg [MEM_WORD-1:0] data;

//the register memory
reg [ADDR_WIDTH-1:0]MEM2[0:MEM_WORD];

initial $readmemh("intruction.hex",MEM2);

always @(addr)
begin
	data = MEM2[addr];
end

endmodule
