//////////////////////////////////////////////////////////////////////////////////
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
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module decoder_mips (
						opcode,
						funct,
						outsaida,
						ctrol
					);

input	[5:0]	opcode;
input	[6:0]	funct;
output	[x:0]	ctrol;
output	[x:0]	outsaida;

always (opcode)
begin
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
						outsaida = ADD;
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
						outsaida = ADD;
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
									outsaida = ADD;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
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
									outsaida = ADD;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
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
									outsaida = AND;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
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
									outsaida = OR;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
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
									outsaida = XOR;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
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
									outsaida = add;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
								end
						SLTI : 	begin
									// rt <= rs < imm pag 190
									if (rsmaior == 1'b1)
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
									outsaida = 0;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1; // mux to UC write
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
								end
						SLTIU : begin
									// pag 191 apendice B
									// rt <= rs < imm pag 190
									if (rsmaior == 1'b1)
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
									outsaida = 0;
									// -------------
									// Destination Decision
									instype = 1'b1;
									// -------------
									// Write back Decision
									reoral = 1'b1; // mux to UC write
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
								end
					endcase
				end
			else if (opcode[2] == 1'b1)
				begin
					case(opcode[1:0])
						BEQ :	begin //pag 25
									// Alu Decision
									rori = 1'b0;
									// -------------
									// ALU OP
									outsaida = 0;
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
									rori = 1'b0;
									// -------------
									// ALU OP
									outsaida = 0;
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
									rori = 1'b0;
									// -------------
									// ALU OP
									outsaida = 0;
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
									rori = 1'b0;
									// -------------
									// ALU OP
									outsaida = 0;
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
						// PC PATH
						jorf = 1'b0;
						ctrl = 1'b0;
						addorn = 1'b1;
						// ------------
						// Alu Decision
						rori = 1'b0;
						// -------------
						// ALU OP
						outsaida = 0;
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
									outsaida = add;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
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
									outsaida = add;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
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
									outsaida = sub;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
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
									outsaida = sub;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
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
									outsaida = (and);
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
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
									outsaida = or;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
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
									outsaida = xor;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
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
									outsaida = nor;
									// -------------
									// Destination Decision
									instype = 1'b0;
									// -------------
									// Write back Decision
									reoral = 1'b1;
									// -------------
									// REGFILE Write enable
									ref_w_ena = 1'b1;
									// -------------
									// Data Mem Enable
									d_mem_wena = 1'b0;
									// -------------
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
					outsaida = 0;
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
					outsaida = 0;
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
				end
		end
end
		
		
		
		
		
