///////////////////////////////////////////////////////////////////////////////
// Company: LC Desenvolvimentos
// Engineer: Luigi C. Filho
// 
// Create Date: 21:10 17/10/2011 
// Design Name: Mips Decoder 
// Module Name: Decoder Mips 
// Project Name: MIPS
// Description: 
// Implementation of the Instruction decoder for MIPS processor, only basic 
// instructions.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Revision 0.02 - Review of Instruction Decode
// Revision 0.03 - Completing Instruction decoder first version
// Additional Comments: 
//
///////////////////////////////////////////////////////////////////////////////
module decoder_mips (
						opcode,
						funct,
						equalrsrt,
						rsmaior,
						rsmrt,
						outsaida,
						ctrol,
						rt,
						slt_mux,
						zero_ext
					);

input	[5:0]	opcode;
input	[5:0]	funct; // MIPS standard: 6 bits
input           equalrsrt;
input           rsmaior;
input           rsmrt; // rs < rt? or rs > rt?
output	[7:0]	ctrol; // Adjust width based on concatenation
output	[3:0]	outsaida;
output reg [31:0] rt; // Direct output to register file/datapath
output reg slt_mux; // Selects Decoder RT output for Writeback
output reg zero_ext; // Selects zero-extend for logical immediates (ANDI/ORI/XORI)

// Internal Control Signals
reg jorf;
reg ctrl;
reg addorn;
reg rori;
reg instype;
reg reoral;
reg ref_w_ena;
reg d_mem_wena;
reg [3:0] outsaida_reg;

assign ctrol = {jorf, ctrl, addorn, rori, instype, reoral, ref_w_ena, d_mem_wena};
assign outsaida = outsaida_reg;

// ALU Opcode Parameters (Matching alu.v)
parameter ADD  = 4'd0;
parameter SUB  = 4'd1;
parameter AND  = 4'd2;
parameter OR   = 4'd3;
parameter XOR  = 4'd4;
parameter L_SH = 4'd5;
parameter R_SH = 4'd6;
parameter NOR  = 4'd8;
parameter COMP = 4'd11;

// Instruction Decoding Parameters
parameter ADDI = 3'b000;
parameter ADDIU = 3'b001;
parameter SLTI = 3'b010;
parameter SLTIU = 3'b011;
parameter ANDI = 3'b100;
parameter ORI = 3'b101;
parameter XORI = 3'b110;
parameter LUI = 3'b111;

parameter BEQ = 2'b00;
parameter BNE = 2'b01;
parameter BLEZ = 2'b10;
parameter BGTZ = 2'b11;

always @(opcode or funct or equalrsrt or rsmaior or rsmrt)
begin
	// Default assignments
	rt = 32'd0;
    slt_mux = 1'b0;
    zero_ext = 1'b0;
	
	if(opcode[5] == 1'b1)
			begin
				if (opcode[3] == 1'b1)
					begin
						// SW
						// mem[rs + imm] <= rt  
						// PC PATH
						jorf = 1'b0;
						ctrl = 1'b0;
						addorn = 1'b0;
						// ------------
						// Alu Decision
						rori = 1'b0;
						// -------------
						// ALU OP
						outsaida_reg = ADD;
						// -------------
						// Destination Decision
						instype = 1'b0;
						// -------------
						// Write back Decision
						reoral = 1'b0;
						// -------------
						// REGFILE Write enable
						ref_w_ena = 1'b0;
						// -------------
						// Data Mem Enable
						d_mem_wena = 1'b1;
						// -------------
                        zero_ext = 1'b0;
					end
				else
					begin
						// LW
						// rt <= mem[rs + imm]
						// PC PATH
						jorf = 1'b0;
						ctrl = 1'b0;
						addorn = 1'b0;
						// ------------
						// Alu Decision
						rori = 1'b0;
						// -------------
						// ALU OP
						outsaida_reg = ADD;
						// -------------
						// Destination Decision
						instype = 1'b1;
						// -------------
						// Write back Decision
						reoral = 1'b0;
						// -------------
						// REGFILE Write enable
						ref_w_ena = 1'b1;
						// -------------
						// Data Mem Enable
						d_mem_wena = 1'b0;
						// -------------
                        zero_ext = 1'b0;
					end
			end
	else
		begin
			if(opcode[3] == 1'b1)
				begin
					case(opcode[2:0])
						ADDI :	begin
									// rt <= rs + imm (overflow = trap)
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b0;
									// ------------
									// Alu Decision
									rori = 1'b0;
									// -------------
									// ALU OP
									outsaida_reg = ADD;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								end
						ADDIU : begin
									// rt <= rs + imm (overflow dont trap)
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b0;
									// ------------
									// Alu Decision
									rori = 1'b0;
									// -------------
									// ALU OP
									outsaida_reg = ADD;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								end
						ANDI :	begin
									// rt <= rs AND imm (zero_extended (not here))
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b0;
									// ------------
									// Alu Decision
									rori = 1'b0;
									// -------------
									// ALU OP
									outsaida_reg = AND;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b1;
								end
						ORI : 	begin
									// rt <= rs or imm (zero_extended (not here))
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b0;
									// ------------
									// Alu Decision
									rori = 1'b0;
									// -------------
									// ALU OP
									outsaida_reg = OR;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b1;
								end
						XORI : 	begin
									// rt <= rs xor imm (zero_extended (not here))
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b0;
									// ------------
									// Alu Decision
									rori = 1'b0;
									// -------------
									// ALU OP
									outsaida_reg = XOR;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b1;
								end
						LUI : 	begin
									// rt <= imm (really rs(0) + imm)
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b0;
									// ------------
									// Alu Decision
									rori = 1'b0;
									// -------------
									// ALU OP
									outsaida_reg = ADD;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								end
						SLTI : 	begin
									// rt <= rs < imm pag 190
									if (rsmaior == 1'b0)
									rt = 32'd1;
									else
									rt = 32'd0;
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b0;
									// ------------
									// Alu Decision
									rori = 1'b0;
									// -------------
									// ALU OP
									outsaida_reg = 0;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1; // mux to UC write
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								end
						SLTIU : begin
									// pag 191 apendice B
									// rt <= rs < imm pag 190
									if (rsmaior == 1'b0)
									rt = 32'd1;
									else
									rt = 32'd0;
								
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b0;
									// ------------
									// Alu Decision
									rori = 1'b0;
									// -------------
									// ALU OP
									outsaida_reg = 0;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1; // mux to UC write
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								end
					endcase
				end
			else if (opcode[2] == 1'b1)
				begin
					case(opcode[1:0])
						BEQ :	begin //pag 25
									// Alu Decision
									rori = 1'b1; // Use rt_data for comparison
									// -------------
									// ALU OP
									outsaida_reg = COMP; // Use COMP to set equal output
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1; // mux to UC write
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								if (equalrsrt == 1'b1)
									begin
										addorn = 1'b0;
										ctrl = 1'b0;
										jorf = 1'b1;
									end
								else
									begin
										addorn = 1'b0;
										ctrl = 1'b0;
										jorf = 1'b0;
									end
								end
						BNE :	begin // pag 41
									// Alu Decision
									rori = 1'b1; // Use rt_data for comparison
									// -------------
									// ALU OP
									outsaida_reg = COMP; // Use COMP to set equal output
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1; // mux to UC write
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								if (equalrsrt == 1'b0)
									begin
										addorn = 1'b0;
										ctrl = 1'b0;
										jorf = 1'b1;
									end
								else
									begin
										addorn = 1'b0;
										ctrl = 1'b0;
										jorf = 1'b0;
									end
								end
						BGTZ :	begin // pag 32
									// Alu Decision
									rori = 1'b1; // Use rt_data for comparison
									// -------------
									// ALU OP
									outsaida_reg = COMP; // Use COMP to set equal output
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1; // mux to UC write
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								if (!equalrsrt && !rsmrt)
									begin
										addorn = 1'b0;
										ctrl = 1'b0;
										jorf = 1'b1;
									end
								else
									begin
										addorn = 1'b0;
										ctrl = 1'b0;
										jorf = 1'b0;
									end
								end
						BLEZ : 	begin // pag 34
																// Alu Decision
									rori = 1'b1; // Use rt_data for comparison
									// -------------
									// ALU OP
									outsaida_reg = COMP; // Use COMP to set equal output
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1; // mux to UC write
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								if (equalrsrt || rsmrt)
									begin
										addorn = 1'b0;
										ctrl = 1'b0;
										jorf = 1'b1;
									end
								else
									begin
										addorn = 1'b0;
										ctrl = 1'b0;
										jorf = 1'b0;
									end
								end
					endcase
				end
			else if (opcode[1:0] == 2'b0)
				begin
					//SPECIAL
					if (funct[5] == 1'b0)
						begin
						// SHIFT INSTRUCTIONS (SLL, SRL)
						    // funct[5:0]: SLL=000000, SRL=000010, SRA=000011
						    if (funct[1:0] == 2'b00) // SLL
						       outsaida_reg = L_SH;
						    else if (funct[1:0] == 2'b10) // SRL
						       outsaida_reg = R_SH;
						    else
						       outsaida_reg = 0;
						       
						// PC PATH
						jorf = 1'b0;
						ctrl = 1'b0;
						addorn = 1'b1;
						// ------------
						// Alu Decision
						rori = 1'b1; // Shift uses Shift amount? Or register?
						// -------------
						// ALU OP
						// outsaida = 0; // Handled above
						// -------------
						// Destination Decision
						instype = 1'b0;
						// -------------
						// Write back Decision
						reoral = 1'b1;
						// -------------
						// REGFILE Write enable
						ref_w_ena = 1'b1; // Write result
						// -------------
						// Data Mem Enable
						d_mem_wena = 1'b0;
						// -------------
                        zero_ext = 1'b0;
						end
					else
					case (funct[2:0])
						3'd0: 	begin
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									// ------------
									// Alu Decision
									rori = 1'b1;
									// -------------
									// ALU OP
									outsaida_reg = ADD;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								end
						3'd1:	begin
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									// ------------
									// Alu Decision
									rori = 1'b1;
									// -------------
									// ALU OP
									outsaida_reg = ADD;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								end
						3'd2:	begin
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									// ------------
									// Alu Decision
									rori = 1'b1;
									// -------------
									// ALU OP
									outsaida_reg = SUB;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								end
						3'd3:	begin
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									// ------------
									// Alu Decision
									rori = 1'b1;
									// -------------
									// ALU OP
									outsaida_reg = SUB;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								end
						3'd4:	begin
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									// ------------
									// Alu Decision
									rori = 1'b1;
									// -------------
									// ALU OP
									outsaida_reg = AND;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								end
						3'd5:	begin
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									// ------------
									// Alu Decision
									rori = 1'b1;
									// -------------
									// ALU OP
									outsaida_reg = OR;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								end
						3'd6:	begin
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									// ------------
									// Alu Decision
									rori = 1'b1;
									// -------------
									// ALU OP
									outsaida_reg = XOR;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								end
						3'd7:	begin
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									// ------------
									// Alu Decision
									rori = 1'b1;
									// -------------
									// ALU OP
									outsaida_reg = NOR;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
                                    zero_ext = 1'b0;
								end
					endcase
				end
			else if (opcode[0] == 1'b1)
				begin
					// JAL
					// Jump and Link (GPR 31 <= new_pc) here not
					// PC PATH
					jorf = 1'b1;
					ctrl = 1'b1;
					addorn = 1'b0;
					// ------------
					// Alu Decision
					rori = 1'b0;
					// -------------
					// ALU OP
					outsaida_reg = 0;
					// -------------
					// Destination Decision
					instype = 1'b0;
					// -------------
					// Write back Decision
					reoral = 1'b0;
					// -------------
					// REGFILE Write enable
					ref_w_ena = 1'b0;
					// -------------
					// Data Mem Enable
					d_mem_wena = 1'b0;
					// -------------
                    zero_ext = 1'b0;
				end
			else
				begin
					// J
					// Jump target
					// PC PATH
					jorf = 1'b1;
					ctrl = 1'b1;
					addorn = 1'b0;
					// ------------
					// Alu Decision
					rori = 1'b0;
					// -------------
					// ALU OP
					outsaida_reg = 0;
					// -------------
					// Destination Decision
					instype = 1'b0;
					// -------------
					// Write back Decision
					reoral = 1'b0;
					// -------------
					// REGFILE Write enable
					ref_w_ena = 1'b0;
					// -------------
					// Data Mem Enable
					d_mem_wena = 1'b0;
					// -------------
                    zero_ext = 1'b0;
				end
		end
end
		
endmodule
