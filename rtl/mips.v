//////////////////////////////////////////////////////////////////////////////////
// Company: LC Desenvolvimentos
// Engineer: Luigi C. Filho
// 
// Create Date: 21:10 17/10/2011 
// Design Name: MIPS
// Module Name: MIPS 
// Project Name: MIPS
// Description: 
// Implementation of the MIPS processor without pipeline and just basic
// instructions and 32-bits fetch from memory.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Revision 0.02 - Review of Instruction Decode
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module MIPS (
			clock,
			reset
			);
			
// -------------- Signal declaration --------------------------------------------
input clock; // Clock Signal
input reset; // Reset Signal
// ---------------- Register that will become an flip-flop ----------------------
reg [31:0]program_counter;

// ---------------- Register that won't become an flip-flop ---------------------
reg [31:0]new_pc;


wire [31:0]instruction;
wire [31:0]sign_exted;
wire [31:0]rs_data;
wire [31:0]rt_data;
wire [31:0]regstb;
wire [31:0]rega_in;
wire [31:0]alu_out;
wire [31:0]readmem;
reg [31:0]writeback;
wire [31:0]writeback_comb;
wire [4:0]dest;
wire [31:0]new_jump_pc;
wire [31:0]imorsigex;
wire [0:0]zero_ext;
wire jr_ctrl;
wire rsneg;

// Control signals from decoder
wire [7:0] ctrol_bus;
wire [3:0] aluop;
wire [31:0] uc_data;
wire slt_mux;

// Unbundle control bus
wire jorf, ctrl, addorn, rori, instype, reoral, ref_w_ena, d_mem_wena;
assign {jorf, ctrl, addorn, rori, instype, reoral, ref_w_ena, d_mem_wena} = ctrol_bus;

// Comparator signals
reg equalrsrt;
reg rsmaior, rsmrt;
reg [31:0] np_jump;
wire [31:0] pc_jump;

// ALU outputs
wire alu_cout, alu_equal, alu_zero;
wire alu_overflow;
// ------------------------------------------------------------------------------
/*################################################################################
								Instruction FECH

Program Counter
Program Counter + 1
Instruction Memory

###################################################################################*/

// ************* Program Counter *************************************************
always @(posedge clock or negedge reset)
begin
	if(!reset)
		program_counter <= 32'd0;
	else
		program_counter <= np_jump;
end
// *******************************************************************************
// ************ Instruction Memory ***********************************************

instr_mem INST_MEM (
					.addr(program_counter), 
					.data(instruction)
					);

// ******************************************************************************
// ****************** Program Counter + 1 ***************************************
always @(program_counter)
begin
	new_pc = program_counter + 32'd1;
end
// ******************************************************************************

// ********************* Mux for Jump *******************************************
always @(jorf, pc_jump, new_pc)
begin
	np_jump = jorf ? pc_jump : new_pc;
end
// ******************************************************************************

/*################################################################################
								Instruction DECODE

Instruction Decoder Control
Jump Resolution Mux
Register File
Signal Extend

instruction 32 bits
     R-Type       |      I-Type       |     J-Type
6 opcode [31:26]  | 6 opcode [31:26]  | 6 opcode [31:26]
5 rs     [25:21]  | 5 rs     [25:21]  | 26 jump  [25:0]
5 rt     [20:16]  | 5 rt	 [20:16]  |
5 rd     [15:11]  | 16 imm   [15:0]   |
5 sa     [10:6]   |					  |
6 funct  [5:0]    |					  |

###################################################################################*/
// ************** Register File **************************************************
regfile #(.MEM_WIDTH(32)) REG_FILE (
				  .clk(clock), 
				  .w_data(writeback_comb), // mux to UC
				  .w_ena(ref_w_ena_final), 
				  .r1_data(rs_data), 
				  .r2_data(rt_data), 
				  .w_addr(dest),
				  .r1_addr(instruction[25:21]), 
				  .r2_addr(instruction[20:16])
				);
// *******************************************************************************
// ***************** Signal Extension ********************************************
assign sign_exted = (instruction[31:26] == 6'b001111) ? {instruction[15:0], 16'd0} : // LUI
                    (zero_ext ? {16'd0, instruction[15:0]} 
                              : { {16{instruction[15]}}, instruction[15:0] }); 
// *******************************************************************************
// ****************** Instruction Decoder unit ***********************************
decoder_mips INSTR_DEC (
						.opcode(instruction[31:26]),
						.funct(instruction[5:0]),
                        .sa(instruction[10:6]),
						.rt_code(instruction[20:16]),
						.equalrsrt(equalrsrt),
						.rsmaior(rsmaior),
						.rsmrt(rsmrt),
						.rsneg(rsneg),
						.outsaida(aluop),
						.ctrol(ctrol_bus),
						.rt(uc_data),
						.slt_mux(slt_mux),
						.zero_ext(zero_ext),
						.jr_ctrl(jr_ctrl),
                        .shift_imm(is_shift_special_imm),
                        .shift_var(is_shift_special_var),
                        .shamt_ext(shamt_ext),
                        .jal(jal)
						);
// *******************************************************************************
// ****************** JUMP RESOLUTION ********************************************
assign pc_jump = ctrl ? { {6'd0},instruction[25:0]} : (jr_ctrl ? rs_data : new_jump_pc);
// *******************************************************************************

/*################################################################################
							Instruction Execution

ALU
Control
Comparator
ADD
3 Muxs

###################################################################################*/

// ********************* Shift Detection *****************************************
// SPECIAL immediate shifts: SLL(000000), SRL(000010), SRA(000011)
// SPECIAL variable shifts: SLLV(000100), SRLV(000110), SRAV(000111)
wire is_shift_special_imm;
wire is_shift_special_var;
wire [31:0] shamt_ext;
// *******************************************************************************

// *************** MUX register B of ALU *****************************************
// ***************** RT or Sign_extended *****************************************
assign regstb = is_shift_special_imm ? shamt_ext :
                (is_shift_special_var ? rs_data :
                 (rori ? rt_data : sign_exted));
assign rega_in = (is_shift_special_imm || is_shift_special_var) ? rt_data : rs_data;
// *******************************************************************************

// ********************* ALU *****************************************************
alu #(.DATA_WIDTH(32)) ALU (
		  .rega(rega_in),
		  .regb(regstb),
		  .control(aluop),
		  .out_alu(alu_out),
		  .cout(alu_cout),
		  .equal(alu_equal),
		  .zero(alu_zero),
          .overflow(alu_overflow)
		);
// *******************************************************************************

// *************** Destination Resolution ****************************************
wire jal;
assign dest = jal ? 5'd31 : (instype ? instruction[20:16] : instruction[15:11]) ;
// *******************************************************************************

// ********************* PC Calculation and decision *****************************
assign new_jump_pc = addorn ? new_pc : (new_pc + sign_exted) ;
// *******************************************************************************

// ********************** Comparator *********************************************
// Separate comparator for branch decisions (works in parallel with decoder)
always @(rs_data, rt_data)
begin
	if ( rs_data == rt_data )
	equalrsrt = 1'b1;
	else
	equalrsrt = 1'b0;
end

assign rsneg = rs_data[31];

always @(rs_data, sign_exted)
begin
	if ( rs_data < sign_exted )
	rsmaior = 1'b0;
	else
	rsmaior = 1'b1;
end

always @(rs_data, rt_data)
begin
	if (rs_data < rt_data )
	rsmrt = 1'b1;
	else
	rsmrt = 1'b0;
end
// *******************************************************************************

// Control module removed - decoder_mips now provides all control signals directly via ctrol_bus

/*################################################################################
							Memory Stage

Data Memory

###################################################################################*/

// ******************* DATA Memory ***********************************************
data_mem DATA_MEM (
					.addr(alu_out),
					.w_data(rt_data),
					.r_data(readmem),
					.w_ena(d_mem_wena),
					.clk(clock)
					);
// *******************************************************************************

/*################################################################################
							Write Back Stage

Mux

###################################################################################*/

// ******************* Write Back Decision ***************************************
// Writeback Mux - SLT uses decoder output, otherwise ALU or Memory
assign writeback_comb = jal ? new_pc : (slt_mux ? uc_data : (reoral ? alu_out : readmem));

// Overflow trap gating for signed ADD/SUB/ADDI: disable writeback on overflow
wire signed_op_add_sub = (instruction[31:26] == 6'b000000) &&
                         ((instruction[5:0] == 6'b100000) || (instruction[5:0] == 6'b100010));
wire signed_op_addi    = (instruction[31:26] == 6'b001000);
wire ovf_trap_active   = (alu_overflow && (signed_op_add_sub || signed_op_addi));
wire ref_w_ena_final   = (ovf_trap_active ? 1'b0 : (ref_w_ena || jal));

always @(posedge clock or negedge reset)
begin
	if(!reset)
		writeback <= 32'd0;
	else
		writeback <= writeback_comb;
end
// *******************************************************************************
endmodule

