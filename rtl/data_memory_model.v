//////////////////////////////////////////////////////////////////////////////////
// Company: LC Desenvolvimentos
// Engineer: Luigi C. Filho
// 
// Create Date: 17:16 4/10/2011 
// Design Name: Data Memory Model
// Module Name: data_mem 
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
module data_mem (
	clk, 
	w_data, 
	w_ena, 
	r_data, 
	addr
);

//parameter declarations
parameter MEM_WORD = 32;
parameter ADDR_WIDTH = 32;

//Input and output declarations
input [ADDR_WIDTH-1:0] addr;
input clk;
input w_ena;
input [MEM_WORD-1:0] w_data;
output [MEM_WORD-1:0] r_data;

//the register memory
reg [ADDR_WIDTH-1:0]MEM1[0:MEM_WORD];

assign r_data = MEM1[addr];

always @(posedge clk)
begin
	if (w_ena)
		begin
			MEM1[addr] <= w_data;
			$writememh("data.hex", MEM1); 
		end
end


endmodule
