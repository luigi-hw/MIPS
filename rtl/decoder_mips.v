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
// Additional Comments: 
//
///////////////////////////////////////////////////////////////////////////////
module decoder_mips (
						opcode,
						funct,
                        sa,
						rt_code,
						equalrsrt,
						rsmaior,
						rsmrt,
						rsneg,
						outsaida,
						ctrol,
						rt,
						slt_mux,
						zero_ext,
						jr_ctrl,
                        shift_imm,
                        shift_var,
                        shamt_ext,
                        jal
					);

input	[5:0]	opcode;
input	[5:0]	funct; // MIPS standard: 6 bits
input   [4:0]   sa;
input   [4:0]   rt_code; // rt field for REGIMM (BLTZ/BGEZ)
input           equalrsrt;
input           rsmaior;
input           rsmrt; // rs < rt? or rs > rt?
input           rsneg; // rs < 0 (signed)
output	[7:0]	ctrol; // Adjust width based on concatenation
output	[3:0]	outsaida;
output reg [31:0] rt; // Direct output to register file/datapath
output reg slt_mux; // Selects Decoder RT output for Writeback
output reg zero_ext; // Selects zero-extend for logical immediates (ANDI/ORI/XORI)
output reg jr_ctrl; // Selects PC = rs for JR/JALR
output          shift_imm;
output          shift_var;
output [31:0]   shamt_ext;
output          jal;

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
assign shift_imm = (opcode == 6'b000000) && ((funct == 6'b000000) || (funct == 6'b000010) || (funct == 6'b000011));
assign shift_var = (opcode == 6'b000000) && ((funct == 6'b000100) || (funct == 6'b000110) || (funct == 6'b000111));
assign shamt_ext = {27'd0, sa};
assign jal = (opcode == 6'b000011);

// ALU Opcode Parameters (Matching alu.v MIPS I set)
parameter ADD  = 4'd0;
parameter SUB  = 4'd1;
parameter AND  = 4'd2;
parameter OR   = 4'd3;
parameter XOR  = 4'd4;
parameter SLLV = 4'd5;
parameter SRLV = 4'd6;
parameter SLT  = 4'd7;
parameter NOR  = 4'd8;
parameter SLTU = 4'd9;
parameter SLL  = 4'd10;
parameter COMP = 4'd11;
parameter SRAV = 4'd12;
parameter SUBU = 4'd13;
parameter ADDU = 4'd14;
parameter SRL  = 4'd15;

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

always @(opcode or funct or rt_code or equalrsrt or rsmaior or rsmrt or rsneg)
begin
	// Default assignments
	rt = 32'd0;
    slt_mux = 1'b0;
    zero_ext = 1'b0;
    jr_ctrl = 1'b0;
	
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
									// rt <= rs + imm (overflow dont trap) usando ADDU na ALU
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b0;
									// ------------
									// Alu Decision
									rori = 1'b0;
									// -------------
									// ALU OP
									outsaida_reg = ADDU;
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
								if (!equalrsrt && !rsneg)
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
								if (equalrsrt || rsneg)
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
			else if (opcode == 6'b000001)
				begin
					// REGIMM group: BLTZ (rt=00000) and BGEZ (rt=00001)
					rori = 1'b1;
					outsaida_reg = COMP;
					instype = 1'b1;
					reoral = 1'b1;
					ref_w_ena = 1'b0;
					d_mem_wena = 1'b0;
                    zero_ext = 1'b0;
					addorn = 1'b0;
					ctrl = 1'b0;
					if (rt_code == 5'b00000) // BLTZ
						begin
							if (rsneg)
								jorf = 1'b1;
							else
								jorf = 1'b0;
						end
					else // BGEZ (rt_code == 00001)
						begin
							if (!rsneg)
								jorf = 1'b1;
							else
								jorf = 1'b0;
						end
				end
			else if (opcode[1:0] == 2'b0)
				begin
					//SPECIAL
					if (funct == 6'b001000)
						begin
						jorf = 1'b1;
						ctrl = 1'b0;
						addorn = 1'b0;
						rori = 1'b0;
						outsaida_reg = 0;
						instype = 1'b0;
						reoral = 1'b0;
						ref_w_ena = 1'b0;
						d_mem_wena = 1'b0;
                        zero_ext = 1'b0;
                        jr_ctrl = 1'b1;
						end
					else if (funct == 6'b001001)
						begin
						jorf = 1'b1;
						ctrl = 1'b0;
						addorn = 1'b0;
						rori = 1'b0;
						outsaida_reg = 0;
						instype = 1'b0;
						reoral = 1'b0;
						ref_w_ena = 1'b0;
						d_mem_wena = 1'b0;
                        zero_ext = 1'b0;
                        jr_ctrl = 1'b1;
						end
					else if (funct == 6'b000000 || funct == 6'b000010 || funct == 6'b000011 || 
                             funct == 6'b000100 || funct == 6'b000110 || funct == 6'b000111)
						begin
							// Shift operations (SPECIAL): 
							// 000000 SLL, 000010 SRL, 000011 SRA (imediato/shamt),
							// 000100 SLLV, 000110 SRLV, 000111 SRAV (variável)
							jorf = 1'b0;
							ctrl = 1'b0;
							addorn = 1'b1;
							rori = 1'b1; // usa rt_data como quantidade no datapath atual
							if (funct == 6'b000000)      outsaida_reg = SLL;
							else if (funct == 6'b000010) outsaida_reg = SRL;
							else if (funct == 6'b000011) outsaida_reg = SRAV;
							else if (funct == 6'b000100) outsaida_reg = SLLV;
							else if (funct == 6'b000110) outsaida_reg = SRLV;
							else                         outsaida_reg = SRAV;
							instype = 1'b0;
							reoral = 1'b1;
							ref_w_ena = 1'b1;
							d_mem_wena = 1'b0;
                            zero_ext = 1'b0;
						end
					else
					begin
					if (funct == 6'b101010)
						begin
							// SLT (signed) - resultado via ALU
							jorf = 1'b0;
							ctrl = 1'b0;
							addorn = 1'b1;
							rori = 1'b1;
							outsaida_reg = SLT;
							instype = 1'b0;
							reoral = 1'b1;
							ref_w_ena = 1'b1;
                            slt_mux = 1'b0;
							d_mem_wena = 1'b0;
                            zero_ext = 1'b0;
						end
					else if (funct == 6'b101011)
						begin
							// SLTU (unsigned) - resultado via ALU
							jorf = 1'b0;
							ctrl = 1'b0;
							addorn = 1'b1;
							rori = 1'b1;
							outsaida_reg = SLTU;
							instype = 1'b0;
							reoral = 1'b1;
							ref_w_ena = 1'b1;
                            slt_mux = 1'b0;
							d_mem_wena = 1'b0;
                            zero_ext = 1'b0;
						end
					else
					case (funct)
						6'b100000: 	begin // ADD (signed, overflow trap via ALU overflow se integrado)
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
						6'b100001:	begin // ADDU (unsigned)
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									// ------------
									// Alu Decision
									rori = 1'b1;
									// -------------
									// ALU OP
									outsaida_reg = ADDU;
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
						6'b100010:	begin // SUB (signed)
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
						6'b100011:	begin // SUBU (unsigned)
									// PC PATH
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									// ------------
									// Alu Decision
									rori = 1'b1;
									// -------------
									// ALU OP
									outsaida_reg = SUBU;
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
						6'b100100:	begin // AND
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
						6'b100101:	begin // OR
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									rori = 1'b1;
									outsaida_reg = OR;
									instype = 1'b0;
									reoral = 1'b1;
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									d_mem_wena = 1'b0;
                                    zero_ext = 1'b0;
								end
						6'b100110:	begin // XOR
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									rori = 1'b1;
									outsaida_reg = XOR;
									instype = 1'b0;
									reoral = 1'b1;
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									d_mem_wena = 1'b0;
                                    zero_ext = 1'b0;
								end
						6'b100111:	begin // NOR
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									rori = 1'b1;
									outsaida_reg = NOR;
									instype = 1'b0;
									reoral = 1'b1;
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									d_mem_wena = 1'b0;
                                    zero_ext = 1'b0;
								end
						default: begin
									jorf = 1'b0;
									ctrl = 1'b0;
									addorn = 1'b1;
									rori = 1'b1;
									outsaida_reg = ADD;
									instype = 1'b0;
									reoral = 1'b1;
									ref_w_ena = 1'b1;
                                    slt_mux = 1'b0;
									d_mem_wena = 1'b0;
                                    zero_ext = 1'b0;
								end
					endcase
				end
			end
			else if (opcode[0] == 1'b1)
				begin
					jorf = 1'b1;
					ctrl = 1'b1;
					addorn = 1'b0;
					rori = 1'b0;
					outsaida_reg = 0;
					instype = 1'b0;
					reoral = 1'b0;
					ref_w_ena = 1'b0;
					d_mem_wena = 1'b0;
                    zero_ext = 1'b0;
				end
			else
				begin
					jorf = 1'b1;
					ctrl = 1'b1;
					addorn = 1'b0;
					rori = 1'b0;
					outsaida_reg = 0;
					instype = 1'b0;
					reoral = 1'b0;
					ref_w_ena = 1'b0;
					d_mem_wena = 1'b0;
                    zero_ext = 1'b0;
				end
		end
end
		
endmodule
