//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Luigi C. Filho
// 
// Create Date: 09:19 09/12/2011 
// Design Name: Register File
// Module Name: regfile 
// Project Name: MIPS
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.02 - Minor changes
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module regfile (
	clk, 
	w_data, 
	w_ena, 
	r1_data, 
	r2_data, 
	w_addr, 
	r1_addr, 
	r2_addr
	);
	
//parameter declarations
parameter MEM_WIDTH = 16;
parameter MEM_DEPTH = 31;
parameter ADDR_WIDTH = 5; //2^5= 32

//Input and output declarations
input clk;
input w_ena;
input [MEM_WIDTH-1:0] w_data;
input [ADDR_WIDTH-1:0] w_addr, r1_addr;
input [ADDR_WIDTH-1:0] r2_addr;
output reg [MEM_WIDTH-1:0]r1_data;
output reg [MEM_WIDTH-1:0]r2_data;

//the register memory
reg [MEM_WIDTH-1:0]MEM[0:MEM_DEPTH];

always @(r1_addr or r2_addr)
begin
		if (r1_addr == 5'd0)
			r1_data = 32'd0;
		else
			r1_data = MEM[r1_addr];
		if (r2_addr == 5'd0)
			r2_data = 32'd0;
		else
			r2_data = MEM[r2_addr];
end

always @(posedge clk)
begin
	if (w_ena)
		begin
			MEM[w_addr] <= w_data;
		end
end

endmodule