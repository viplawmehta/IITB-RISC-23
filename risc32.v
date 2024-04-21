
module risc32 (clk, reset);
input clk, reset;

//INSTRUCTIONS
parameter ADD = 4'b0000, NDU = 4'b0010, ADI = 4'b0001, LHI = 4'b0011,
		  LW  = 4'b0100, SW  = 4'b0101, LM  = 4'b0110, SM  = 4'b0111,
		  LA  = 4'b1010, SA  = 4'b1011, BEQ = 4'b1100, JAL = 4'b1000, 
		  JLR = 4'b1001, JRI = 4'b1101;


//CONTROL SIGNALS
reg SM_FLAG, LM_FLAG, LOAD_FLAG;											// Flags
reg IF_ID_STALL,ID_RR_STALL,RR_EX_STALL,EX_MEM_STALL,MEM_WB_STALL;			
reg IF_ID_TKN_BRNCH, ID_RR_TKN_BRNCH, RR_EX_TKN_BRNCH, EX_MEM_TKN_BRNCH, MEM_WB_TKN_BRNCH, HALT_FLAG;
reg IF_ID_TEMP,ID_RR_TEMP,RR_EX_TEMP,EX_MEM_TEMP,MEM_WB_TEMP;
reg EX_MEM_Z, MEM_WB_Z, EX_MEM_COUT,EX_MEM_TMP, MEM_WB_TMP;
reg [15:0] IF_ID_IR, ID_RR_IR, RR_EX_IR, EX_MEM_IR, MEM_WB_IR;				// Pipeline stage
reg [15:0] IF_ID_NPCLAT, ID_RR_NPCLAT, RR_EX_NPCLAT, EX_MEM_NPCLAT, MEM_WB_NPCLAT;		
reg [15:0] IF_ID_MPCLAT, ID_RR_MPCLAT, RR_EX_MPCLAT, EX_MEM_R7LAT;
reg [15:0] EX_MEM_CB, EX_MEM_ALULAT, MEM_WB_ALULAT, MEM_WB_LMD;
reg [15:0] MEM_WB_LMDA, MEM_WB_LMDB, MEM_WB_LMDC, MEM_WB_LMDD;
reg [15:0] MEM_WB_LMDE, MEM_WB_LMDF, MEM_WB_LMDG, MEM_WB_LMDH;
reg [15:0] ID_RR_Imm,RR_EX_Imm;
reg [15:0] EX_MEM_B,RR_EX_A,RR_EX_B, EX_MEM_A;
reg [7:0]  ID_RR_T2, RR_EX_T2, EX_MEM_T2,MEM_WB_T2;

// INSTRUCTION MEMORY, DATA MEMORY, REGISTER ARRAY
reg [15:0] IMEM [0:63];
reg [15:0] DMEM [0:63];
reg [15:0] REGR [0:7];


always @ (posedge reset)
begin
	IF_ID_IR <=16'bx;
	ID_RR_IR <=16'bx;
	RR_EX_IR <=16'bx;
	EX_MEM_IR <=16'bx;
	MEM_WB_IR <=16'bx;
	 
	EX_MEM_CB <=16'b0;
	EX_MEM_ALULAT <=16'b0;
	MEM_WB_ALULAT <=16'b0;
	MEM_WB_LMD <=16'b0;
	 
	MEM_WB_LMDA <=16'b0;
	MEM_WB_LMDB <=16'b0;
	MEM_WB_LMDC <=16'b0;
	MEM_WB_LMDD <=16'b0;
	 
	MEM_WB_LMDE <=16'b0;
	MEM_WB_LMDF <=16'b0;
	MEM_WB_LMDG <=16'b0;
	MEM_WB_LMDH <=16'b0;
	 
	ID_RR_Imm <=16'b0;
	RR_EX_Imm <=16'b0;
	  
	EX_MEM_B <=16'b0;
	RR_EX_A <=16'b0;
	RR_EX_B <=16'b0;
	EX_MEM_A <=16'b0;
	  
	ID_RR_T2 <=8'b0;
	RR_EX_T2 <=8'b0;
	EX_MEM_T2 <=8'b0;
	MEM_WB_T2 <=8'b0;
	  
	SM_FLAG <=1'b0;
	LM_FLAG <=1'b0;
	LOAD_FLAG <=1'b0;
	HALT_FLAG <=1'b0;
	  
	IF_ID_STALL <=1'b0;
	ID_RR_STALL <=1'b0;
	RR_EX_STALL <=1'b0;
	EX_MEM_STALL <=1'b0;
	MEM_WB_STALL <=1'b0;

	IF_ID_TKN_BRNCH <=1'b0;
	ID_RR_TKN_BRNCH <=1'b0;
	RR_EX_TKN_BRNCH <=1'b0;
	EX_MEM_TKN_BRNCH <=1'b0;
	MEM_WB_TKN_BRNCH <=1'b0;
	  
	IF_ID_TEMP <=1'b0;
	ID_RR_TEMP <=1'b0;
	RR_EX_TEMP <=1'b0;
	EX_MEM_TEMP <=1'b0;
	MEM_WB_TEMP <=1'b0;
	  
	EX_MEM_Z <=1'b0;
	MEM_WB_Z <=1'b0;
	EX_MEM_COUT <=1'b0;
	  
	IF_ID_NPCLAT <=16'b0;
	ID_RR_NPCLAT <=16'b0;
	RR_EX_NPCLAT <=16'b0;
	EX_MEM_NPCLAT <=16'b0;
	MEM_WB_NPCLAT <=16'b0;
	  
	IF_ID_MPCLAT <=16'b0;
	ID_RR_MPCLAT <=16'b0;
	RR_EX_MPCLAT <=16'b0;
 end


// IF STAGE

always @ (posedge clk)
begin
	IF_ID_TEMP <= 1'b0;

	if (RR_EX_IR[15:12] == SM)
		SM_FLAG <= 1'b1;
	else
		SM_FLAG <= 0;


	if (ID_RR_IR[15:12] == LM)
	begin
		if (((((RR_EX_IR[15:12]==ADD) || (RR_EX_IR[15:12]==NDU)) && (RR_EX_IR[5:3]==3'b111)) // jump or instruction writing in R7 folowwed by 3 LM instr
			||(((RR_EX_IR[15:12]==LW) || (RR_EX_IR[15:12]==LHI)) && (RR_EX_IR[11:9]==3'b111))
			||((RR_EX_IR[15:12]==ADI) && (RR_EX_IR[8:6]==3'b111))
			||((RR_EX_IR[15:12]==BEQ) && (RR_EX_A==RR_EX_B))
			||((RR_EX_IR[15:12]==JAL) || (RR_EX_IR[15:12]==JLR))
			||(((RR_EX_IR[15:12]==ADD) || (RR_EX_IR[15:12]==NDU)) && (RR_EX_IR[5:3]==3'b111) && (EX_MEM_COUT==1'b1))
			||(((RR_EX_IR[15:12]==ADD) || (RR_EX_IR[15:12]==NDU)) && (RR_EX_IR[5:3]==3'b111) && (EX_MEM_Z==1'b1)))
			||
			((((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[5:3]==3'b111))
			||(((EX_MEM_IR[15:12]==LW) || (EX_MEM_IR[15:12]==LHI)) && (EX_MEM_IR[11:9]==3'b111))
			||((EX_MEM_IR[15:12]==ADI) && (EX_MEM_IR[8:6]==3'b111))
			||((EX_MEM_IR[15:12]==BEQ) && (EX_MEM_Z==1'b1))
			||((EX_MEM_IR[15:12]==JAL) || (EX_MEM_IR[15:12]==JLR))
			||(((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[5:3]==3'b111) && (EX_MEM_STALL==1'b1))
			||(((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[5:3]==3'b111) && (EX_MEM_STALL==1'b1)))
			||
			((((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[5:3]==3'b111))
			||(((MEM_WB_IR[15:12]==LW) || (MEM_WB_IR[15:12]==LHI)) && (MEM_WB_IR[11:9]==3'b111))
			||((MEM_WB_IR[15:12]==ADI) && (MEM_WB_IR[8:6]==3'b111))
			||((MEM_WB_IR[15:12]==BEQ) && (MEM_WB_Z==1'b1))
			||((MEM_WB_IR[15:12]==JAL) || (MEM_WB_IR[15:12]==JLR))
			||(((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[5:3]==3'b111) && (MEM_WB_STALL==1'b1))
			||(((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[5:3]==3'b111) && (MEM_WB_STALL==1'b1)))
			||(ID_RR_STALL==1'b1))

		begin
			LM_FLAG<=1'b0;
		end
		else
			LM_FLAG <= 1'b1;
	end

	if ((SM_FLAG == 0) && (LM_FLAG == 0) && (LOAD_FLAG == 0) && (HALT_FLAG==0))
	begin
	if (((RR_EX_IR[15:12] == LW) && (((ID_RR_IR[15:12] == ADD) || (ID_RR_IR[15:12] == NDU) || 
		(ID_RR_IR[15:12] == BEQ)) && ((RR_EX_IR[11:9] == ID_RR_IR[11:9]) || (RR_EX_IR[11:9] == ID_RR_IR[8:6]))))

		|| ((RR_EX_IR[15:12] == LW) && ((ID_RR_IR[15:12] == ADI) && (RR_EX_IR[11:9] == ID_RR_IR[11:9])))

		|| ((RR_EX_IR[15:12] == LW) && (((ID_RR_IR[15:12] == LW) || (ID_RR_IR[15:12] == SW)) && (RR_EX_IR[11:9] == ID_RR_IR[8:6])))

		|| ((RR_EX_IR[15:12] == LW) && (((ID_RR_IR[15:12] == LM) || (ID_RR_IR[15:12] == SM)) && (RR_EX_IR[11:9] == ID_RR_IR[11:9])))

		|| ((RR_EX_IR[15:12] == LW) && ((ID_RR_IR[15:12] == JLR) && (RR_EX_IR[11:9] == ID_RR_IR[8:6]))))
	begin
		if (((((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[5:3]==3'b111))
		||(((EX_MEM_IR[15:12]==LW) || (EX_MEM_IR[15:12]==LHI)) && (EX_MEM_IR[11:9]==3'b111))
		||((EX_MEM_IR[15:12]==ADI) && (EX_MEM_IR[8:6]==3'b111))
		||((EX_MEM_IR[15:12]==BEQ) && (EX_MEM_Z==1'b1))	
		||((EX_MEM_IR[15:12]==JAL) || (EX_MEM_IR[15:12]==JLR))) || (RR_EX_IR[11:9]==3'b111) || (RR_EX_STALL==1'b1))

	begin
		LOAD_FLAG <= 1'b0;
	end

	else
	begin
		LOAD_FLAG<=1'b1;
	end
end

IF_ID_STALL <= 1'b0;

if ((((EX_MEM_IR[15:12] == BEQ) && (EX_MEM_Z == 1)) || (EX_MEM_IR[15:12] == JAL)) && (EX_MEM_STALL == 0))
begin
IF_ID_IR <= IMEM[EX_MEM_CB];
IF_ID_TKN_BRNCH <= 1'b1;
IF_ID_NPCLAT <= EX_MEM_CB + 16'b0000000000000001;
IF_ID_MPCLAT <= EX_MEM_CB;
end

else if ((EX_MEM_IR[15:12] == JLR) && (EX_MEM_STALL == 0))
begin
IF_ID_IR <= IMEM[EX_MEM_A];
IF_ID_TKN_BRNCH <= 1'b1;
IF_ID_NPCLAT <= EX_MEM_A + 16'b0000000000000001;
IF_ID_MPCLAT <= EX_MEM_A;
end

else if (((EX_MEM_IR[15:12] == ADD) && (EX_MEM_IR[5:3] == 3'b111) && (EX_MEM_STALL==0))||
			((EX_MEM_IR[15:12] == ADI) && (EX_MEM_IR[8:6] == 3'b111) && (EX_MEM_STALL==0))||
			((EX_MEM_IR[15:12] == NDU) && (EX_MEM_IR[5:3] == 3'b111) && (EX_MEM_STALL==0))||
			((EX_MEM_IR[15:12] == LHI) && (EX_MEM_IR[11:9] == 3'b111) && (EX_MEM_STALL==0)))
begin
IF_ID_IR <= IMEM[EX_MEM_ALULAT];
IF_ID_NPCLAT <= EX_MEM_ALULAT + 16'b0000000000000001;
IF_ID_MPCLAT <= EX_MEM_ALULAT;
IF_ID_TKN_BRNCH <= 1;
end

else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == 3'b111))
begin
IF_ID_IR <= IMEM[MEM_WB_LMD];
IF_ID_NPCLAT <= MEM_WB_LMD + 16'b0000000000000001;
IF_ID_MPCLAT <= MEM_WB_LMD;
IF_ID_TKN_BRNCH <= 1;
end
else if ((RR_EX_IR[15:12]==LM) && (EX_MEM_IR[15:12]==LM) && (RR_EX_STALL==1'b1) && (EX_MEM_STALL==1'b1) && (RR_EX_T2[7]==1'b1) && (EX_MEM_T2[7]==1'b1) )
begin
IF_ID_IR <= IMEM[REGR[7]];
IF_ID_MPCLAT <= REGR[7];
IF_ID_NPCLAT <= REGR[7] + 16'b0000000000000001;
IF_ID_TKN_BRNCH <= 1;
end

else
begin
IF_ID_IR <= IMEM[IF_ID_NPCLAT];
IF_ID_MPCLAT <= IF_ID_NPCLAT;
IF_ID_TKN_BRNCH <= 0;
IF_ID_NPCLAT <= IF_ID_NPCLAT + 16'b0000000000000001;
end
end
end

//******************************________ID STAGE_______**************************************

always @(posedge clk)
begin

if (((EX_MEM_IR[15:12]==BEQ && EX_MEM_Z==1)||(EX_MEM_IR[15:12]==ADD && EX_MEM_IR[5:3]==3'b111)||
    (EX_MEM_IR[15:12]==ADI && EX_MEM_IR[8:6]==3'b111)||
	 (EX_MEM_IR[15:12]==NDU && EX_MEM_IR[5:3]==3'b111)||
	 (EX_MEM_IR[15:12]==LHI && EX_MEM_IR[11:9]==3'b111)||
	 (EX_MEM_IR[15:12]==LW && EX_MEM_IR[11:9]==3'b111)||
	 (MEM_WB_IR[15:12]==LW && MEM_WB_IR[11:9]==3'b111)||
	 (EX_MEM_IR[15:12]==JAL || EX_MEM_IR[15:12]==JLR || (RR_EX_IR[15:12]==LM && RR_EX_T2[7]==1'b1))) && (ID_RR_TKN_BRNCH == 0))
begin
ID_RR_STALL <= 1'b1;
end

else
begin
ID_RR_STALL<=IF_ID_STALL;
end

if ((SM_FLAG == 0) && (LM_FLAG == 0) && (LOAD_FLAG == 0) && (HALT_FLAG==0))
begin

ID_RR_IR<= IF_ID_IR;
ID_RR_NPCLAT<=IF_ID_NPCLAT;
ID_RR_MPCLAT<=IF_ID_MPCLAT;
ID_RR_TEMP<=IF_ID_TEMP;
ID_RR_TKN_BRNCH <= IF_ID_TKN_BRNCH;


if ((IF_ID_IR[15:12]==ADI) || (IF_ID_IR[15:12]==LW)||
    (IF_ID_IR[15:12]==SW) || (IF_ID_IR[15:12]==BEQ))
begin
ID_RR_Imm<={{10{IF_ID_IR[5]}},{IF_ID_IR[5:0]}};
end

if ((IF_ID_IR[15:12]==LHI) || (IF_ID_IR[15:12]==JAL))
begin
ID_RR_Imm<={{7{IF_ID_IR[8]}},{IF_ID_IR[8:0]}};
end

if ((IF_ID_IR[15:12]==SM) || (IF_ID_IR[15:12]==LM))
begin
ID_RR_T2<=IF_ID_IR[7:0];
end
end
end

//RR STAGE
always @ (posedge clk)
begin
if (((EX_MEM_IR[15:12]==BEQ && EX_MEM_Z==1)&& EX_MEM_STALL ==0)||((EX_MEM_IR[15:12]==ADD && EX_MEM_IR[5:3]==3'b111)&& EX_MEM_STALL ==0)||
    ((EX_MEM_IR[15:12]==ADI && EX_MEM_IR[8:6]==3'b111)&& EX_MEM_STALL ==0)||
	 ((EX_MEM_IR[15:12]==NDU && EX_MEM_IR[5:3]==3'b111)&& EX_MEM_STALL ==0)||
	 ((EX_MEM_IR[15:12]==LHI && EX_MEM_IR[11:9]==3'b111)&& EX_MEM_STALL ==0)||
	 ((EX_MEM_IR[15:12]==LW && EX_MEM_IR[11:9]==3'b111)&& EX_MEM_STALL ==0)||
	 (((EX_MEM_IR[15:12]==JAL || EX_MEM_IR[15:12]==JLR) && EX_MEM_STALL ==0) || (RR_EX_IR[15:12]==LM && RR_EX_T2[7]==1'b1) || (MEM_WB_IR[15:12]==LM && MEM_WB_STALL==1'b0) ))
begin
RR_EX_STALL <= 1'b1;
end

else
begin
RR_EX_STALL<=ID_RR_STALL;
end

if ((SM_FLAG == 0) && (LM_FLAG == 0) && (LOAD_FLAG == 0) && (HALT_FLAG==0))
begin
RR_EX_Imm <= ID_RR_Imm;
RR_EX_NPCLAT <= ID_RR_NPCLAT;
RR_EX_MPCLAT <= ID_RR_MPCLAT;
RR_EX_TEMP <= ID_RR_TEMP;
RR_EX_IR <= ID_RR_IR;
RR_EX_T2 <= ID_RR_T2;
RR_EX_TKN_BRNCH <= ID_RR_TKN_BRNCH;

if ((((ID_RR_IR[15:12] == ADD)||(ID_RR_IR[15:12] == NDU)) && (ID_RR_IR[1:0] == 2'b00))
	|| (((ID_RR_IR[15:12] == ADD)||(ID_RR_IR[15:12] == NDU)) && (ID_RR_IR[1:0] == 2'b10))
	|| (((ID_RR_IR[15:12] == ADD)||(ID_RR_IR[15:12] == NDU)) && (ID_RR_IR[1:0] == 2'b01))
	|| (ID_RR_IR[15:12] == SW) || (ID_RR_IR[15:12] == BEQ))
begin
RR_EX_B <= REGR[ID_RR_IR[11:9]];
RR_EX_A <= REGR[ID_RR_IR[8:6]];
end

if ((ID_RR_IR[15:12] == ADI) || (ID_RR_IR[15:12] == LM) || (ID_RR_IR[15:12] == SM))
begin
RR_EX_A <= REGR[ID_RR_IR[11:9]];
end

if ((ID_RR_IR[15:12] == LW) || (ID_RR_IR[15:12] == JLR))
begin
RR_EX_A <= REGR[ID_RR_IR[8:6]];
end

end
end

//EX STAGE
always @(posedge clk)
begin

if ((EX_MEM_IR[15:12]==BEQ && EX_MEM_Z==1)||(EX_MEM_IR[15:12]==ADD && EX_MEM_IR[5:3]==3'b111)||
    (EX_MEM_IR[15:12]==ADI && EX_MEM_IR[8:6]==3'b111)||
	 (EX_MEM_IR[15:12]==NDU && EX_MEM_IR[5:3]==3'b111)||
	 (EX_MEM_IR[15:12]==LHI && EX_MEM_IR[11:9]==3'b111)||
	 (EX_MEM_IR[15:12]==LW && EX_MEM_IR[11:9]==3'b111)||
	 (EX_MEM_IR[15:12]==JAL || EX_MEM_IR[15:12]==JLR) || (MEM_WB_IR[15:12]==LM && MEM_WB_STALL==1'b0))
begin
EX_MEM_STALL <= 1'b1;
end

else
begin
EX_MEM_STALL<=RR_EX_STALL;
end

if (((((SM_FLAG == 0) && (LM_FLAG == 0) && (HALT_FLAG==0)) || ((LM_FLAG == 1) && (RR_EX_IR[15:12] == LM) && (RR_EX_STALL==1'b0 || RR_EX_TKN_BRNCH == 1'b1))) && (LOAD_FLAG == 0))
    || (EX_MEM_IR[15:12]==LW && RR_EX_IR[15:12]==LM && EX_MEM_IR[11:9]!=3'b111 && EX_MEM_IR[11:9]==RR_EX_IR[11:9]))
begin

EX_MEM_NPCLAT <= RR_EX_NPCLAT;
EX_MEM_TEMP <= RR_EX_TEMP;
EX_MEM_IR <= RR_EX_IR;
EX_MEM_T2 <= RR_EX_T2;
EX_MEM_A <= RR_EX_A; // done changes for LM followed by LM follwed by dependent
EX_MEM_B <= RR_EX_B;
EX_MEM_TKN_BRNCH <= RR_EX_TKN_BRNCH;


if (RR_EX_IR[15:12] == SM)
EX_MEM_R7LAT <= REGR[7];

//Execute stage for JLR instruction

if (RR_EX_IR[15:12] == JLR)
begin
if(((((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b00) && (EX_MEM_IR[5:3] == RR_EX_IR[8:6]) && (EX_MEM_IR[5:3] != 3'b111))
|| (((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b01) && (EX_MEM_STALL == 0)&& (EX_MEM_IR[5:3] == RR_EX_IR[8:6]) && (EX_MEM_IR[5:3] != 3'b111))
|| (((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b10) && (EX_MEM_STALL == 0)&& (EX_MEM_IR[5:3] == RR_EX_IR[8:6]) && (EX_MEM_IR[5:3] != 3'b111))
|| ((EX_MEM_IR[15:12] == ADI) && (EX_MEM_IR[8:6] == RR_EX_IR[8:6]) && (EX_MEM_IR[8:6] != 3'b111))
|| ((EX_MEM_IR[15:12] == LHI) && (EX_MEM_IR[11:9] == RR_EX_IR[8:6]) && (EX_MEM_IR[11:9] != 3'b111))) && (EX_MEM_STALL==1'b0))
	begin
	EX_MEM_A <= EX_MEM_ALULAT;
	end
else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == RR_EX_IR[8:6]) && (MEM_WB_IR[11:9] != 3'b111))
	begin
	EX_MEM_A <= MEM_WB_LMD;
	end

else if(((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == RR_EX_IR[8:6]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == RR_EX_IR[8:6]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == RR_EX_IR[8:6]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == RR_EX_IR[8:6]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == RR_EX_IR[8:6]) && (MEM_WB_IR[11:9] != 3'b111))) && (MEM_WB_STALL==1'b0))
	begin
	EX_MEM_A <= MEM_WB_ALULAT;
	end

else
	begin
	EX_MEM_A <= RR_EX_A;
	end
end


//Execute Stage for ADI INSTRUCTION
if (RR_EX_IR[15:12] == ADI && ((RR_EX_STALL == 0) || (RR_EX_TKN_BRNCH == 1)))
begin
if(((((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b00) && (EX_MEM_IR[5:3] == RR_EX_IR[11:9]) && (EX_MEM_IR[5:3] != 3'b111))
|| (((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b01) && (EX_MEM_STALL == 0)&& (EX_MEM_IR[5:3] == RR_EX_IR[11:9]) && (EX_MEM_IR[5:3] != 3'b111))
|| (((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b10) && (EX_MEM_STALL == 0)&& (EX_MEM_IR[5:3] == RR_EX_IR[11:9]) && (EX_MEM_IR[5:3] != 3'b111))
|| ((EX_MEM_IR[15:12] == ADI) && (EX_MEM_IR[8:6] == RR_EX_IR[11:9]) && (EX_MEM_IR[8:6] != 3'b111))
|| ((EX_MEM_IR[15:12] == LHI) && (EX_MEM_IR[11:9] == RR_EX_IR[11:9]) && (EX_MEM_IR[11:9] != 3'b111))) && (EX_MEM_STALL==1'b0))
	begin
	{EX_MEM_COUT, EX_MEM_ALULAT} <= EX_MEM_ALULAT + RR_EX_Imm;
	EX_MEM_Z <= ((EX_MEM_ALULAT + RR_EX_Imm) == 0);
	end
else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == RR_EX_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111) && (MEM_WB_STALL==1'b0))
	begin
	{EX_MEM_COUT, EX_MEM_ALULAT} <= MEM_WB_LMD + RR_EX_Imm;
	EX_MEM_Z <= ((MEM_WB_LMD + RR_EX_Imm) == 0);
	end

else if(((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == RR_EX_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == RR_EX_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == RR_EX_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == RR_EX_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == RR_EX_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111))) && (MEM_WB_STALL==1'b0))
	begin
	{EX_MEM_COUT, EX_MEM_ALULAT} <= MEM_WB_ALULAT + RR_EX_Imm;
	EX_MEM_Z <= ((MEM_WB_ALULAT + RR_EX_Imm) == 0);
	end

else
	begin
	{EX_MEM_COUT, EX_MEM_ALULAT} <= RR_EX_A + RR_EX_Imm;
	EX_MEM_Z <= ((RR_EX_A + RR_EX_Imm) == 0);
	end
end

//Execute Stage for LHI INSTRUCTION
if (RR_EX_IR[15:12] == LHI)
	EX_MEM_ALULAT <= RR_EX_Imm << 7; //seven bit left shift

	//Execute Stage for JAL INSTRUCTION
if (RR_EX_IR[15:12] == JAL)
	EX_MEM_CB <= RR_EX_MPCLAT + RR_EX_Imm;

//Execute Stage for BEQ INSTRUCTION
if (RR_EX_IR[15:12] == BEQ && ((RR_EX_STALL == 0) || (RR_EX_TKN_BRNCH == 1)))
begin
if ((((((((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b00))||
    (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b10) &&(EX_MEM_STALL==1'b0))||
	 (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b01) &&(EX_MEM_STALL==1'b0)))&&
      ((EX_MEM_IR[5:3]==RR_EX_IR[11:9]) || (EX_MEM_IR[5:3]==RR_EX_IR[8:6])) && (EX_MEM_IR[5:3]!=3'b111)) && (EX_MEM_STALL==1'b0))
||
(((EX_MEM_IR[15:12]==LHI) && ((EX_MEM_IR[11:9]==RR_EX_IR[11:9]) || (EX_MEM_IR[11:9]==RR_EX_IR[8:6])) && (EX_MEM_IR[11:9]!=3'b111)) && (EX_MEM_STALL==1'b0))
||
(((EX_MEM_IR[15:12]==ADI) && ((EX_MEM_IR[8:6]==RR_EX_IR[11:9]) || (EX_MEM_IR[8:6]==RR_EX_IR[8:6])) && (EX_MEM_IR[8:6]!=3'b111)) && (EX_MEM_STALL==1'b0))
&&
(((((((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b00))||
    (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b10) &&(MEM_WB_STALL==1'b0))||
	 (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b01) &&(MEM_WB_STALL==1'b0)))&&
      ((MEM_WB_IR[5:3]==RR_EX_IR[11:9]) || (MEM_WB_IR[5:3]==RR_EX_IR[8:6])) && (MEM_WB_IR[5:3]!=3'b111)) && (MEM_WB_STALL==1'b0))
||
((MEM_WB_IR[15:12]==LHI) && ((MEM_WB_IR[11:9]==RR_EX_IR[11:9]) || (MEM_WB_IR[11:9]==RR_EX_IR[8:6])) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))
||
((MEM_WB_IR[15:12]==ADI) && ((MEM_WB_IR[8:6]==RR_EX_IR[11:9]) || (MEM_WB_IR[8:6]==RR_EX_IR[8:6])) && (MEM_WB_IR[8:6]!=3'b111) && (MEM_WB_STALL==1'b0)))))
begin
	EX_MEM_Z <= ((MEM_WB_ALULAT - EX_MEM_ALULAT) == 0);
	EX_MEM_CB <= RR_EX_MPCLAT + RR_EX_Imm;
end
else if(((((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b00) && (EX_MEM_IR[5:3] == RR_EX_IR[11:9]) && (EX_MEM_IR[5:3] != 3'b111))
|| (((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b01) && (EX_MEM_STALL == 0)&& (EX_MEM_IR[5:3] == RR_EX_IR[11:9]) && (EX_MEM_IR[5:3] != 3'b111))
|| (((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b10) && (EX_MEM_STALL == 0)&& (EX_MEM_IR[5:3] == RR_EX_IR[11:9]) && (EX_MEM_IR[5:3] != 3'b111))
|| ((EX_MEM_IR[15:12] == ADI) && (EX_MEM_IR[8:6] == RR_EX_IR[11:9]) && (EX_MEM_IR[8:6] != 3'b111))
|| ((EX_MEM_IR[15:12] == LHI) && (EX_MEM_IR[11:9] == RR_EX_IR[11:9]) && (EX_MEM_IR[11:9] != 3'b111))) && (EX_MEM_STALL==1'b0))
	begin
	EX_MEM_Z <= ((RR_EX_A - EX_MEM_ALULAT) == 0);
	EX_MEM_CB <= RR_EX_MPCLAT + RR_EX_Imm;
	end
else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == RR_EX_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111) && (MEM_WB_STALL==1'b0))
	begin
	EX_MEM_Z <= ((RR_EX_A - MEM_WB_LMD) == 0);
	EX_MEM_CB <= RR_EX_MPCLAT + RR_EX_Imm;
	end
	
else if(((((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b00) && (EX_MEM_IR[5:3] == RR_EX_IR[8:6]) && (EX_MEM_IR[5:3] != 3'b111))
|| (((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b01) && (EX_MEM_STALL == 0)&& (EX_MEM_IR[5:3] == RR_EX_IR[8:6]) && (EX_MEM_IR[5:3] != 3'b111))
|| (((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b10) && (EX_MEM_STALL == 0)&& (EX_MEM_IR[5:3] == RR_EX_IR[8:6]) && (EX_MEM_IR[5:3] != 3'b111))
|| ((EX_MEM_IR[15:12] == ADI) && (EX_MEM_IR[8:6] == RR_EX_IR[8:6]) && (EX_MEM_IR[8:6] != 3'b111))
|| ((EX_MEM_IR[15:12] == LHI) && (EX_MEM_IR[11:9] == RR_EX_IR[8:6]) && (EX_MEM_IR[11:9] != 3'b111))) && (EX_MEM_STALL==1'b0))
	begin
	EX_MEM_Z <= ((EX_MEM_ALULAT - RR_EX_B) == 0);
	EX_MEM_CB <= RR_EX_MPCLAT + RR_EX_Imm;
	end
else if (((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == RR_EX_IR[8:6]) && (MEM_WB_IR[11:9] != 3'b111)) && (MEM_WB_STALL==1'b0))
	begin
	EX_MEM_Z <= ((MEM_WB_LMD - RR_EX_B) == 0);
	EX_MEM_CB <= RR_EX_MPCLAT + RR_EX_Imm;
	end

else if(((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == RR_EX_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == RR_EX_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == RR_EX_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == RR_EX_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == RR_EX_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111))) && (MEM_WB_STALL==1'b0))
	begin
	EX_MEM_Z <= ((RR_EX_A - MEM_WB_ALULAT) == 0);
	EX_MEM_CB <= RR_EX_MPCLAT + RR_EX_Imm;
	end

else if(((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == RR_EX_IR[8:6]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == RR_EX_IR[8:6]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == RR_EX_IR[8:6]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == RR_EX_IR[8:6]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == RR_EX_IR[8:6]) && (MEM_WB_IR[11:9] != 3'b111))) && (MEM_WB_STALL==1'b0))
	begin
	EX_MEM_Z <= ((MEM_WB_ALULAT - RR_EX_B) == 0);
	EX_MEM_CB <= RR_EX_MPCLAT + RR_EX_Imm;
	end

else
	begin
	EX_MEM_Z <= ((RR_EX_A - RR_EX_B) == 0);
	EX_MEM_CB <= RR_EX_MPCLAT + RR_EX_Imm;
	end
end

//Execute Stage for LW AND SW INSTRUCTION

if ((RR_EX_IR[15:12] == LW) || (RR_EX_IR[15:12] == SW))
begin
if(((((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b00) && (EX_MEM_IR[5:3] == RR_EX_IR[8:6]) && (EX_MEM_IR[5:3] != 3'b111))
|| (((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b01) && (EX_MEM_STALL == 0)&& (EX_MEM_IR[5:3] == RR_EX_IR[8:6]) && (EX_MEM_IR[5:3] != 3'b111))
|| (((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && (EX_MEM_IR[1:0] == 2'b10) && (EX_MEM_STALL == 0)&& (EX_MEM_IR[5:3] == RR_EX_IR[8:6]) && (EX_MEM_IR[5:3] != 3'b111))
|| ((EX_MEM_IR[15:12] == ADI) && (EX_MEM_IR[8:6] == RR_EX_IR[8:6]) && (EX_MEM_IR[8:6] != 3'b111))
|| ((EX_MEM_IR[15:12] == LHI) && (EX_MEM_IR[11:9] == RR_EX_IR[8:6]) && (EX_MEM_IR[11:9] != 3'b111))) && (EX_MEM_STALL==1'b0))

	EX_MEM_ALULAT <= EX_MEM_ALULAT + RR_EX_Imm;
	
else if (((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == RR_EX_IR[8:6]) && (MEM_WB_IR[11:9] != 3'b111)) && (MEM_WB_STALL==1'b0))

	EX_MEM_ALULAT <= MEM_WB_LMD + RR_EX_Imm;

else if(((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == RR_EX_IR[8:6]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == RR_EX_IR[8:6]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == RR_EX_IR[8:6]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == RR_EX_IR[8:6]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == RR_EX_IR[8:6]) && (MEM_WB_IR[11:9] != 3'b111))) && (MEM_WB_STALL==1'b0))

	EX_MEM_ALULAT <= MEM_WB_ALULAT + RR_EX_Imm;	
else
	EX_MEM_ALULAT <= RR_EX_A + RR_EX_Imm;
end

// EXECUTE STAGE FOR ADD NDU

if ((((RR_EX_IR[15:12]==ADD) || (RR_EX_IR[15:12]==NDU)) && (RR_EX_IR[1:0]==2'b00)) && ((RR_EX_STALL == 0) || (RR_EX_TKN_BRNCH == 1))) // for ADD and NDU
begin
if ((((((((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b00))||
    (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b10) &&(EX_MEM_STALL==1'b0))||
	 (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b01) &&(EX_MEM_STALL==1'b0)))&&
      ((EX_MEM_IR[5:3]==RR_EX_IR[11:9]) || (EX_MEM_IR[5:3]==RR_EX_IR[8:6])) && (EX_MEM_IR[5:3]!=3'b111)) && (EX_MEM_STALL==1'b0))
||
(((EX_MEM_IR[15:12]==LHI) && ((EX_MEM_IR[11:9]==RR_EX_IR[11:9]) || (EX_MEM_IR[11:9]==RR_EX_IR[8:6])) && (EX_MEM_IR[11:9]!=3'b111)) && (EX_MEM_STALL==1'b0))
||
(((EX_MEM_IR[15:12]==ADI) && ((EX_MEM_IR[8:6]==RR_EX_IR[11:9]) || (EX_MEM_IR[8:6]==RR_EX_IR[8:6])) && (EX_MEM_IR[8:6]!=3'b111)) && (EX_MEM_STALL==1'b0))
&&
(((((((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b00))||
    (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b10) &&(MEM_WB_STALL==1'b0))||
	 (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b01) &&(MEM_WB_STALL==1'b0)))&&
      ((MEM_WB_IR[5:3]==RR_EX_IR[11:9]) || (MEM_WB_IR[5:3]==RR_EX_IR[8:6])) && (MEM_WB_IR[5:3]!=3'b111)) && (MEM_WB_STALL==1'b0))
||
((MEM_WB_IR[15:12]==LHI) && ((MEM_WB_IR[11:9]==RR_EX_IR[11:9]) || (MEM_WB_IR[11:9]==RR_EX_IR[8:6])) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))
||
((MEM_WB_IR[15:12]==ADI) && ((MEM_WB_IR[8:6]==RR_EX_IR[11:9]) || (MEM_WB_IR[8:6]==RR_EX_IR[8:6])) && (MEM_WB_IR[8:6]!=3'b111) && (MEM_WB_STALL==1'b0)))))
begin
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+MEM_WB_ALULAT;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+MEM_WB_ALULAT)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & MEM_WB_ALULAT);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & MEM_WB_ALULAT)==16'b0);
	  end
endcase
end

else if ((((((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b00))||
    (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b10) &&(EX_MEM_STALL==1'b0))||
	 (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b01) &&(EX_MEM_STALL==1'b0)))&&
      (EX_MEM_IR[5:3]==RR_EX_IR[11:9]) && (EX_MEM_IR[5:3]!=3'b111)) && (EX_MEM_STALL==1'b0)) // mem stage=ADD,AND,ADZ,ADC,NDZ,NDC with Ra=Rc
begin
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_A)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_A)==16'b0);
	  end
endcase
end

else if ((((((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b00))||
    (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b10) &&(EX_MEM_STALL==1'b0))||
	 (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b01) &&(EX_MEM_STALL==1'b0)))&&
      (EX_MEM_IR[5:3]==RR_EX_IR[8:6]) && (EX_MEM_IR[5:3]!=3'b111)) && (EX_MEM_STALL==1'b0)) // mem stage=ADD,AND,ADZ,ADC,NDZ,NDC with Rb=Rc
begin
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_B)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_B)==16'b0);
	  end
endcase
end

else if(((EX_MEM_IR[15:12]==LHI) && (EX_MEM_IR[11:9]==RR_EX_IR[11:9]) && (EX_MEM_IR[11:9]!=3'b111)) && (EX_MEM_STALL==1'b0))
begin  // mem stage=LHI 
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_B)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_A)==16'b0);
	  end
endcase
end

else if(((EX_MEM_IR[15:12]==LHI) && (EX_MEM_IR[11:9]==RR_EX_IR[8:6]) && (EX_MEM_IR[11:9]!=3'b111)) && (EX_MEM_STALL==1'b0))
begin // // mem stage=LHI
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_A)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_B)==16'b0);
	  end
endcase
end

else if(((EX_MEM_IR[15:12]==ADI) && (EX_MEM_IR[8:6]==RR_EX_IR[11:9]) && (EX_MEM_IR[8:6]!=3'b111)) && (EX_MEM_STALL==1'b0))
begin  // mem stage=ADI
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_A)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_A)==16'b0);
	  end
endcase
end

else if(((EX_MEM_IR[15:12]==ADI) && (EX_MEM_IR[8:6]==RR_EX_IR[8:6]) && (EX_MEM_IR[8:6]!=3'b111)) && (EX_MEM_STALL==1'b0))
begin // // mem stage=ADI 
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_B)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_B)==16'b0);
	  end
endcase
end


//else
//begin // if no dependencies
//case(RR_EX_IR[15:12])
//ADD: begin
//     {EX_MEM_COUT,EX_MEM_ALULAT}<= RR_EX_A+RR_EX_B;
//	  EX_MEM_Z<= (RR_EX_A+RR_EX_B==16'b0);
//	  end
//NDU: begin
//     EX_MEM_ALULAT<= ~(RR_EX_A & RR_EX_B);
//	  EX_MEM_COUT<= EX_MEM_COUT;
//	  EX_MEM_Z<= (~(RR_EX_A & RR_EX_B)==16'b0);
//	  end
//endcase
//end



else if ((((((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b00))||
    (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b10) &&(MEM_WB_STALL==1'b0))||
	 (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b01) &&(MEM_WB_STALL==1'b0)))&&
      (MEM_WB_IR[5:3]==RR_EX_IR[11:9]) && (MEM_WB_IR[5:3]!=3'b111)) && (MEM_WB_STALL==1'b0))  // WB stage=ADD,AND,ADZ,ADC,NDZ,NDC with Ra=Rc 
begin
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_A)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_A)==16'b0);
	  end
endcase
end

else if ((((((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b00))||
    (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b10) &&(MEM_WB_STALL==1'b0))||
	 (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b01) &&(MEM_WB_STALL==1'b0)))&&
      (MEM_WB_IR[5:3]==RR_EX_IR[8:6]) && (MEM_WB_IR[5:3]!=3'b111)) && (MEM_WB_STALL==1'b0)) // WB stage=ADD,AND,ADZ,ADC,NDZ,NDC with Rb=Rc
begin
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_B)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_B)==16'b0);
	  end
endcase
end

else if((MEM_WB_IR[15:12]==LW) && (MEM_WB_IR[11:9]==RR_EX_IR[11:9]) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))  
begin // WB stage=LW  Ra=Ra
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_LMD+RR_EX_A;
	  EX_MEM_Z<= ((MEM_WB_LMD+RR_EX_A)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(MEM_WB_LMD & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_LMD & RR_EX_A)==16'b0);
	  end
endcase
end

else if((MEM_WB_IR[15:12]==LW) && (MEM_WB_IR[11:9]==RR_EX_IR[8:6]) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0)) 
begin // WB stage=LW  Rb=Ra
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_LMD+RR_EX_B;
	  EX_MEM_Z<= ((MEM_WB_LMD+RR_EX_B)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(MEM_WB_LMD & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_LMD & RR_EX_B)==16'b0);
	  end
endcase
end



else if((MEM_WB_IR[15:12]==LHI) && (MEM_WB_IR[11:9]==RR_EX_IR[11:9]) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))
begin  // WB stage=LHI
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_A)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_A)==16'b0);
	  end
endcase
end


else if((MEM_WB_IR[15:12]==LHI) && (MEM_WB_IR[11:9]==RR_EX_IR[8:6]) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))
begin  // WB stage=LHI
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_B)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_B)==16'b0);
	  end
endcase
end

else if((MEM_WB_IR[15:12]==ADI) && (MEM_WB_IR[8:6]==RR_EX_IR[11:9]) && (MEM_WB_IR[8:6]!=3'b111) && (MEM_WB_STALL==1'b0))
begin  // WB stage=ADI
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_A)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_A)==16'b0);
	  end
endcase
end


else if((MEM_WB_IR[15:12]==ADI) && (MEM_WB_IR[8:6]==RR_EX_IR[8:6]) && (MEM_WB_IR[8:6]!=3'b111) &&(MEM_WB_STALL==1'b0))
begin  // WB stage=ADI 
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_B)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_B)==16'b0);
	  end
endcase
end


else
begin // if no dependencies
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= RR_EX_A+RR_EX_B;
	  EX_MEM_Z<= ((RR_EX_A+RR_EX_B)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(RR_EX_A & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(RR_EX_A & RR_EX_B)==16'b0);
	  end
endcase
end
end

// EXECUTE STAGE ADC NDC

if ((((RR_EX_IR[15:12]==ADD) || (RR_EX_IR[15:12]==NDU)) && (RR_EX_IR[1:0]==2'b10)) && ((RR_EX_STALL == 0) || (RR_EX_TKN_BRNCH == 1)))
begin // for ADC and NDC
if ((((((((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b00))||
    (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b10) &&(EX_MEM_STALL==1'b0))||
	 (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b01) &&(EX_MEM_STALL==1'b0)))&&
      ((EX_MEM_IR[5:3]==RR_EX_IR[11:9]) || (EX_MEM_IR[5:3]==RR_EX_IR[8:6])) && (EX_MEM_IR[5:3]!=3'b111)) && (EX_MEM_STALL==1'b0))
||
(((EX_MEM_IR[15:12]==LHI) && ((EX_MEM_IR[11:9]==RR_EX_IR[11:9]) || (EX_MEM_IR[11:9]==RR_EX_IR[8:6])) && (EX_MEM_IR[11:9]!=3'b111)) && (EX_MEM_STALL==1'b0))
||
(((EX_MEM_IR[15:12]==ADI) && ((EX_MEM_IR[8:6]==RR_EX_IR[11:9]) || (EX_MEM_IR[8:6]==RR_EX_IR[8:6])) && (EX_MEM_IR[8:6]!=3'b111)) && (EX_MEM_STALL==1'b0))
&&
(((((((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b00))||
    (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b10) &&(MEM_WB_STALL==1'b0))||
	 (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b01) &&(MEM_WB_STALL==1'b0)))&&
      ((MEM_WB_IR[5:3]==RR_EX_IR[11:9]) || (MEM_WB_IR[5:3]==RR_EX_IR[8:6])) && (MEM_WB_IR[5:3]!=3'b111)) && (MEM_WB_STALL==1'b0))
||
((MEM_WB_IR[15:12]==LHI) && ((MEM_WB_IR[11:9]==RR_EX_IR[11:9]) || (MEM_WB_IR[11:9]==RR_EX_IR[8:6])) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))
||
((MEM_WB_IR[15:12]==ADI) && ((MEM_WB_IR[8:6]==RR_EX_IR[11:9]) || (MEM_WB_IR[8:6]==RR_EX_IR[8:6])) && (MEM_WB_IR[8:6]!=3'b111) && (MEM_WB_STALL==1'b0)))))
begin
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+MEM_WB_ALULAT;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+MEM_WB_ALULAT)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & MEM_WB_ALULAT);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & MEM_WB_ALULAT)==16'b0);
	  end
endcase
end
else if ((((((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b00))||
    (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b10) &&(EX_MEM_STALL==1'b0))||
	 (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b01) &&(EX_MEM_STALL==1'b0)))&&
      (EX_MEM_IR[5:3]==RR_EX_IR[11:9]) && (EX_MEM_IR[5:3]!=3'b111)) && (EX_MEM_STALL==1'b0)) // mem stage=ADD,AND,ADZ,ADC,NDZ,NDC with Ra=Rc
begin
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end
	
else if ((((((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b00))||
    (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b10) &&(EX_MEM_STALL==1'b0))||
	 (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b01) &&(EX_MEM_STALL==1'b0)))&&
      (EX_MEM_IR[5:3]==RR_EX_IR[8:6]) && (EX_MEM_IR[5:3]!=3'b111)) && (EX_MEM_STALL==1'b0)) // mem stage=ADD,AND,ADZ,ADC,NDZ,NDC with Rb=Rc
begin
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((EX_MEM_IR[15:12]==LHI) && (EX_MEM_IR[11:9]==RR_EX_IR[11:9]) && (EX_MEM_IR[11:9]!=3'b111) && (EX_MEM_STALL==1'b0))
begin  // mem stage=LHI 
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	 
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end
	
else if((EX_MEM_IR[15:12]==LHI) && (EX_MEM_IR[11:9]==RR_EX_IR[8:6]) && (EX_MEM_IR[11:9]!=3'b111) && (EX_MEM_STALL==1'b0))
begin  // mem stage=LHI 
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	 
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((EX_MEM_IR[15:12]==ADI) && (EX_MEM_IR[8:6]==RR_EX_IR[11:9]) && (EX_MEM_IR[8:6]!=3'b111) && (EX_MEM_STALL==1'b0))
begin  // mem stage=ADI
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	 
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end
	
else if((EX_MEM_IR[15:12]==ADI) && (EX_MEM_IR[8:6]==RR_EX_IR[8:6]) && (EX_MEM_IR[8:6]!=3'b111) && (EX_MEM_STALL==1'b0))
begin  // mem stage=ADI
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	 
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end


//else
//begin // if no dependencies
//case(RR_EX_IR[15:12])
//ADD: begin
//     if(EX_MEM_COUT==1'b1)
//	  begin
//     {EX_MEM_COUT,EX_MEM_ALULAT}<= RR_EX_A+RR_EX_B;
//	  EX_MEM_Z<= (RR_EX_A+RR_EX_B==16'b0);
//	  end
//	  else
//	  begin
//	  EX_MEM_STALL<=1'b1;
//	  end
//	  end
//NDU: begin
//     if(EX_MEM_COUT==1'b1)
//	  begin
//     EX_MEM_ALULAT<= ~(RR_EX_A & RR_EX_B);
//	  EX_MEM_COUT<= EX_MEM_COUT;
//	  EX_MEM_Z<= (~(RR_EX_A & RR_EX_B)==16'b0);
//	  end
//	  else
//	  begin
//	  EX_MEM_STALL<=1'b1;
//	  end
//	  end
//endcase
//end



else if ((((((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b00))||
    (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b10) &&(MEM_WB_STALL==1'b0))||
	 (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b01) &&(MEM_WB_STALL==1'b0)))&&
      (MEM_WB_IR[5:3]==RR_EX_IR[11:9]) && (MEM_WB_IR[5:3]!=3'b111)) && (MEM_WB_STALL==1'b0))  // WB stage=ADD,AND,ADZ,ADC,NDZ,NDC with Ra=Rc 
begin
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if ((((((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b00))||
    (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b10) &&(MEM_WB_STALL==1'b0))||
	 (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b01) &&(MEM_WB_STALL==1'b0)))&&
      (MEM_WB_IR[5:3]==RR_EX_IR[8:6]) && (MEM_WB_IR[5:3]!=3'b111)) && (MEM_WB_STALL==1'b0)) // WB stage=ADD,AND,ADZ,ADC,NDZ,NDC with Rb=Rc 
begin
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((MEM_WB_IR[15:12]==LW) && (MEM_WB_IR[11:9]==RR_EX_IR[11:9]) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))  
begin // WB stage=LW  Ra=Ra
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_LMD+RR_EX_A;
	  EX_MEM_Z<= ((MEM_WB_LMD+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	 
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_LMD & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_LMD & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((MEM_WB_IR[15:12]==LW) && (MEM_WB_IR[11:9]==RR_EX_IR[8:6]) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))  
begin // WB stage=LW  Ra=Rb
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_LMD+RR_EX_B;
	  EX_MEM_Z<= ((MEM_WB_LMD+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	 
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_LMD & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_LMD & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

	

else if((MEM_WB_IR[15:12]==LHI) && (MEM_WB_IR[11:9]==RR_EX_IR[11:9]) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))
begin  // WB stage=LHI 
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	  
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((MEM_WB_IR[15:12]==LHI) && (MEM_WB_IR[11:9]==RR_EX_IR[8:6]) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))
begin  // WB stage=LHI
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	  
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((MEM_WB_IR[15:12]==ADI) && (MEM_WB_IR[8:6]==RR_EX_IR[11:9]) && (MEM_WB_IR[8:6]!=3'b111) && (MEM_WB_STALL==1'b0))
begin  // WB stage=ADI 
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	  
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((MEM_WB_IR[15:12]==ADI) && (MEM_WB_IR[8:6]==RR_EX_IR[8:6]) && (MEM_WB_IR[8:6]!=3'b111) && (MEM_WB_STALL==1'b0))
begin  // WB stage=ADI
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	  
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end



else
begin // if no dependencies
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= RR_EX_A+RR_EX_B;
	  EX_MEM_Z<= ((RR_EX_A+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
NDU: begin
     if(EX_MEM_COUT==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(RR_EX_A & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(RR_EX_A & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end
end	

//EXECUTE STAGE ADZ NDZ

if ((((RR_EX_IR[15:12]==ADD) || (RR_EX_IR[15:12]==NDU)) && (RR_EX_IR[1:0]==2'b01)) && ((RR_EX_STALL == 0) || (RR_EX_TKN_BRNCH == 1)))
begin // for ADZ and NDZ
if ((((((((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b00))||
    (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b10) &&(EX_MEM_STALL==1'b0))||
	 (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b01) &&(EX_MEM_STALL==1'b0)))&&
      ((EX_MEM_IR[5:3]==RR_EX_IR[11:9]) || (EX_MEM_IR[5:3]==RR_EX_IR[8:6])) && (EX_MEM_IR[5:3]!=3'b111)) && (EX_MEM_STALL==1'b0))
||
(((EX_MEM_IR[15:12]==LHI) && ((EX_MEM_IR[11:9]==RR_EX_IR[11:9]) || (EX_MEM_IR[11:9]==RR_EX_IR[8:6])) && (EX_MEM_IR[11:9]!=3'b111)) && (EX_MEM_STALL==1'b0))
||
(((EX_MEM_IR[15:12]==ADI) && ((EX_MEM_IR[8:6]==RR_EX_IR[11:9]) || (EX_MEM_IR[8:6]==RR_EX_IR[8:6])) && (EX_MEM_IR[8:6]!=3'b111)) && (EX_MEM_STALL==1'b0))
&&
(((((((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b00))||
    (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b10) &&(MEM_WB_STALL==1'b0))||
	 (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b01) &&(MEM_WB_STALL==1'b0)))&&
      ((MEM_WB_IR[5:3]==RR_EX_IR[11:9]) || (MEM_WB_IR[5:3]==RR_EX_IR[8:6])) && (MEM_WB_IR[5:3]!=3'b111)) && (MEM_WB_STALL==1'b0))
||
((MEM_WB_IR[15:12]==LHI) && ((MEM_WB_IR[11:9]==RR_EX_IR[11:9]) || (MEM_WB_IR[11:9]==RR_EX_IR[8:6])) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))
||
((MEM_WB_IR[15:12]==ADI) && ((MEM_WB_IR[8:6]==RR_EX_IR[11:9]) || (MEM_WB_IR[8:6]==RR_EX_IR[8:6])) && (MEM_WB_IR[8:6]!=3'b111) && (MEM_WB_STALL==1'b0)))))
begin
case(RR_EX_IR[15:12])
ADD: begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+MEM_WB_ALULAT;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+MEM_WB_ALULAT)==16'b0);
	  end
NDU: begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & MEM_WB_ALULAT);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & MEM_WB_ALULAT)==16'b0);
	  end
endcase
end
else if ((((((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b00))||
    (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b10) &&(EX_MEM_STALL==1'b0))||
	 (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b01) &&(EX_MEM_STALL==1'b0)))&&
      (EX_MEM_IR[5:3]==RR_EX_IR[11:9]) && (EX_MEM_IR[5:3]!=3'b111)) && (EX_MEM_STALL==1'b0)) // mem stage=ADD,AND,ADZ,ADC,NDZ,NDC with Ra=Rc
begin
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end
	
else if ((((((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b00))||
    (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b10) &&(EX_MEM_STALL==1'b0))||
	 (((EX_MEM_IR[15:12]==ADD) || (EX_MEM_IR[15:12]==NDU)) && (EX_MEM_IR[1:0]==2'b01) &&(EX_MEM_STALL==1'b0)))&&
      (EX_MEM_IR[5:3]==RR_EX_IR[8:6]) && (EX_MEM_IR[5:3]!=3'b111)) && (EX_MEM_STALL==1'b0))// mem stage=ADD,AND,ADZ,ADC,NDZ,NDC with Rb=Rc
begin
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((EX_MEM_IR[15:12]==LHI) && (EX_MEM_IR[11:9]==RR_EX_IR[11:9]) && (EX_MEM_IR[11:9]!=3'b111) && (EX_MEM_STALL==1'b0))
begin  // mem stage=LHI 
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	 
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end
	
else if((EX_MEM_IR[15:12]==LHI) && (EX_MEM_IR[11:9]==RR_EX_IR[8:6]) && (EX_MEM_IR[11:9]!=3'b111) && (EX_MEM_STALL==1'b0))
begin  // mem stage=LHI 
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	 
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((EX_MEM_IR[15:12]==ADI) && (EX_MEM_IR[8:6]==RR_EX_IR[11:9]) && (EX_MEM_IR[8:6]!=3'b111) && (EX_MEM_STALL==1'b0))
begin  // mem stage=ADI
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	 
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end
	
else if((EX_MEM_IR[15:12]==ADI) && (EX_MEM_IR[8:6]==RR_EX_IR[8:6]) && (EX_MEM_IR[8:6]!=3'b111) && (EX_MEM_STALL==1'b0))
begin  // mem stage=ADI
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= EX_MEM_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((EX_MEM_ALULAT+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	 
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(EX_MEM_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(EX_MEM_ALULAT & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end


//else
//begin // if no dependencies
//case(RR_EX_IR[15:12])
//ADD: begin
//     if(EX_MEM_Z==1'b1)
//	  begin
//     {EX_MEM_COUT,EX_MEM_ALULAT}<= RR_EX_A+RR_EX_B;
//	  EX_MEM_Z<= (RR_EX_A+RR_EX_B==16'b0);
//	  end
//	  else
//	  begin
//	  EX_MEM_STALL<=1'b1;
//	  end
//	  end
//NDU: begin
//     if(EX_MEM_Z==1'b1)
//	  begin
//     EX_MEM_ALULAT<= ~(RR_EX_A & RR_EX_B);
//	  EX_MEM_COUT<= EX_MEM_COUT;
//	  EX_MEM_Z<= (~(RR_EX_A & RR_EX_B)==16'b0);
//	  end
//	  else
//	  begin
//	  EX_MEM_STALL<=1'b1;
//	  end
//	  end
//endcase
//end



else if ((((((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b00))||
    (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b10) &&(MEM_WB_STALL==1'b0))||
	 (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b01) &&(MEM_WB_STALL==1'b0)))&&
      (MEM_WB_IR[5:3]==RR_EX_IR[11:9]) && (MEM_WB_IR[5:3]!=3'b111)) && (MEM_WB_STALL==1'b0)) // WB stage=ADD,AND,ADZ,ADC,NDZ,NDC with Ra=Rc 
begin
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if ((((((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b00))||
    (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b10) &&(MEM_WB_STALL==1'b0))||
	 (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b01) &&(MEM_WB_STALL==1'b0)))&&
      (MEM_WB_IR[5:3]==RR_EX_IR[8:6]) && (MEM_WB_IR[5:3]!=3'b111)) && (MEM_WB_STALL==1'b0)) // WB stage=ADD,AND,ADZ,ADC,NDZ,NDC with Rb=Rc 
begin
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((MEM_WB_IR[15:12]==LW) && (MEM_WB_IR[11:9]==RR_EX_IR[11:9]) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))  
begin // WB stage=LW  Ra=Ra
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_LMD+RR_EX_A;
	  EX_MEM_Z<= ((MEM_WB_LMD+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	 
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_LMD & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_LMD & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((MEM_WB_IR[15:12]==LW) && (MEM_WB_IR[11:9]==RR_EX_IR[8:6]) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))  
begin // WB stage=LW  Ra=Rb
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_LMD+RR_EX_B;
	  EX_MEM_Z<= ((MEM_WB_LMD+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	 
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_LMD & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_LMD & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

	

else if((MEM_WB_IR[15:12]==LHI) && (MEM_WB_IR[11:9]==RR_EX_IR[11:9]) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))
begin  // WB stage=LHI 
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	  
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((MEM_WB_IR[15:12]==LHI) && (MEM_WB_IR[11:9]==RR_EX_IR[8:6]) && (MEM_WB_IR[11:9]!=3'b111) && (MEM_WB_STALL==1'b0))
begin  // WB stage=LHI
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	  
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((MEM_WB_IR[15:12]==ADI) && (MEM_WB_IR[8:6]==RR_EX_IR[11:9]) && (MEM_WB_IR[8:6]!=3'b111) && (MEM_WB_STALL==1'b0))
begin  // WB stage=ADI 
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_A;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	  
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_A);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_A)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end

else if((MEM_WB_IR[15:12]==ADI) && (MEM_WB_IR[8:6]==RR_EX_IR[8:6]) && (MEM_WB_IR[8:6]!=3'b111) && (MEM_WB_STALL==1'b0))
begin  // WB stage=ADI
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= MEM_WB_ALULAT+RR_EX_B;
	  EX_MEM_Z<= ((MEM_WB_ALULAT+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
	  
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(MEM_WB_ALULAT & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(MEM_WB_ALULAT & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end



else
begin // if no dependencies
case(RR_EX_IR[15:12])
ADD: begin
     if(EX_MEM_Z==1'b1)
	  begin
     {EX_MEM_COUT,EX_MEM_ALULAT}<= RR_EX_A+RR_EX_B;
	  EX_MEM_Z<= ((RR_EX_A+RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
NDU: begin
     if(EX_MEM_Z==1'b1)
	  begin
     EX_MEM_ALULAT<= ~(RR_EX_A & RR_EX_B);
	  EX_MEM_COUT<= EX_MEM_COUT;
	  EX_MEM_Z<= (~(RR_EX_A & RR_EX_B)==16'b0);
	  EX_MEM_TMP <= 1'b0;
	  end
	  else
	  begin
	  EX_MEM_STALL<=1'b1;
	  EX_MEM_TMP <= 1'b1;
	  end
	  end
endcase
end	
end

end

else
begin
EX_MEM_TMP <= 0;
end
//EX_MEM_NPCLAT <= RR_EX_NPCLAT;
//EX_MEM_TEMP <= RR_EX_TEMP;
//EX_MEM_IR <= RR_EX_IR;
//EX_MEM_T2 <= RR_EX_T2;
////EX_MEM_A <= RR_EX_A;
//EX_MEM_B <= RR_EX_B;
//end

end  // execute stage end

//******************************________MEM STAGE_______**************************************
//MEM STAGE
always @(posedge clk)
begin
MEM_WB_TKN_BRNCH <= EX_MEM_TKN_BRNCH;
if (((EX_MEM_STALL==1'b0) || (EX_MEM_TKN_BRNCH == 1))
|| ((((EX_MEM_IR[15:12] == ADD) || (EX_MEM_IR[15:12] == NDU)) && ((EX_MEM_IR[1:0] == 2'b01) || (EX_MEM_IR[1:0] == 2'b10))) && (EX_MEM_TMP == 1'b1))
 && (HALT_FLAG==0))
begin

if(MEM_WB_IR[15:12]==LM && MEM_WB_STALL==1'b0) // setting done for LM followed by LM followed by dependent instruction
begin
EX_MEM_STALL<=1'b1;
end
else
begin
MEM_WB_STALL<=EX_MEM_STALL;
end
MEM_WB_TMP <= EX_MEM_TMP;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~SETTING OF PROGRAM COUNTER IN R7~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



if ((((EX_MEM_IR[15:12] == BEQ) && (EX_MEM_Z == 1)) || (EX_MEM_IR[15:12] == JAL)) && (EX_MEM_STALL == 0))
begin
REGR[7] <= EX_MEM_CB;
end

else if ((EX_MEM_IR[15:12] == JLR) && (EX_MEM_STALL == 0))
begin
REGR[7] <= EX_MEM_A;
end

else if (((EX_MEM_IR[15:12] == ADD) && (EX_MEM_IR[5:3] == 3'b111) && (EX_MEM_IR[1:0] == 2'b00) && (EX_MEM_STALL==0))||
			((EX_MEM_IR[15:12] == ADD) && (EX_MEM_IR[5:3] == 3'b111) && (EX_MEM_IR[1:0] == 2'b01) && (EX_MEM_TMP == 1'b0) && (EX_MEM_STALL==0))||
			((EX_MEM_IR[15:12] == ADD) && (EX_MEM_IR[5:3] == 3'b111) && (EX_MEM_IR[1:0] == 2'b10) && (EX_MEM_TMP == 1'b0) && (EX_MEM_STALL==0))||
			((EX_MEM_IR[15:12] == ADI) && (EX_MEM_IR[8:6] == 3'b111) && (EX_MEM_STALL==0))||
			((EX_MEM_IR[15:12] == NDU) && (EX_MEM_IR[5:3] == 3'b111) && (EX_MEM_STALL==0))||
			((EX_MEM_IR[15:12] == LHI) && (EX_MEM_IR[11:9] == 3'b111) && (EX_MEM_STALL==0)))
begin
REGR[7] <= EX_MEM_ALULAT;
end

else if ((EX_MEM_IR[15:12] == LW) && (EX_MEM_IR[11:9] == 3'b111))
begin
REGR[7] <= DMEM[EX_MEM_ALULAT];
end

else if (EX_MEM_IR === 16'hxxxx)
begin
REGR[7] <= REGR[7];
end

else
begin
REGR[7] <= EX_MEM_NPCLAT;
end
//<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>//


//if ((EX_MEM_IR[15:12] == LW) && (RR_EX_IR[15:12] == ADD) && ((EX_MEM_IR[11:9] == RR_EX_IR[11:9]) || (EX_MEM_IR[11:9] == RR_EX_IR[8:6])))
//LOAD_FLAG <= 0;

if(((EX_MEM_IR[15:12] == LW) && (((RR_EX_IR[15:12] == ADD) || (RR_EX_IR[15:12] == NDU) || 
(RR_EX_IR[15:12] == BEQ)) && ((EX_MEM_IR[11:9] == RR_EX_IR[11:9]) || (EX_MEM_IR[11:9] == RR_EX_IR[8:6])))) 
|| ((EX_MEM_IR[15:12] == LW) && ((RR_EX_IR[15:12] == ADI) && (EX_MEM_IR[11:9] == RR_EX_IR[11:9])))
|| ((EX_MEM_IR[15:12] == LW) && (((RR_EX_IR[15:12] == LW) || (RR_EX_IR[15:12] == SW)) && (EX_MEM_IR[11:9] == RR_EX_IR[8:6])))
|| ((EX_MEM_IR[15:12] == LW) && ((RR_EX_IR[15:12] == JLR) && (EX_MEM_IR[11:9] == RR_EX_IR[8:6])))
|| ((EX_MEM_IR[15:12] == LW) && (((RR_EX_IR[15:12] == LM) || (RR_EX_IR[15:12] == SM)) && (EX_MEM_IR[11:9] == RR_EX_IR[11:9]))))
begin
LOAD_FLAG <= 0;
end

MEM_WB_IR<=EX_MEM_IR;
MEM_WB_NPCLAT<=EX_MEM_NPCLAT;
MEM_WB_ALULAT<=EX_MEM_ALULAT;
//MEM_WB_STALL<=EX_MEM_STALL;
MEM_WB_T2<=EX_MEM_T2;

if(EX_MEM_IR[15:12]==LW)
begin
MEM_WB_LMD <= DMEM[EX_MEM_ALULAT];
end

if(EX_MEM_IR[15:12]==SW)
begin
if (((((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b00))||
    (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b10) &&(MEM_WB_STALL==1'b0))||
	 (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0]==2'b01) &&(MEM_WB_STALL==1'b0)))&&
      (MEM_WB_IR[5:3]==EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3]!=3'b111))  // WB stage=ADD,AND,ADZ,ADC,NDZ,NDC with Rb=Rc 
begin
DMEM[EX_MEM_ALULAT] <= MEM_WB_ALULAT;
end

else if((MEM_WB_IR[15:12]==LW) && (MEM_WB_IR[11:9]==EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9]!=3'b111))  
begin // WB stage=LW  Ra=Ra
DMEM[EX_MEM_ALULAT]<= MEM_WB_LMD;
end

else if((MEM_WB_IR[15:12]==LHI) && (MEM_WB_IR[11:9]==EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9]!=3'b111))
begin  // WB stage=LHI 
DMEM[EX_MEM_ALULAT]<= MEM_WB_ALULAT;
end

else if((MEM_WB_IR[15:12]==ADI) && (MEM_WB_IR[8:6]==EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6]!=3'b111))
begin  // WB stage=ADI 
DMEM[EX_MEM_ALULAT]<= MEM_WB_ALULAT;
end

else
begin
DMEM[EX_MEM_ALULAT]<= EX_MEM_B;
end
end

if (EX_MEM_IR[15:12]==LM)
begin

case (EX_MEM_T2[7:0])

8'b00000000: begin //0
          MEM_WB_T2<=EX_MEM_T2;
			 end

8'b00000001: begin //1
          MEM_WB_T2<=EX_MEM_T2;
			 
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 end
			 
			 
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 end
			 end
			 
			 
8'b00000010: begin //2
          MEM_WB_T2<=EX_MEM_T2;  
          if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 end
			 
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 end
			 end
			 
8'b00000011: begin //3
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b00000100: begin //4
			 MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 end
			 
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 end
			 end
			 
8'b00000101: begin //5
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 

8'b00000110: begin //6
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b00000111: begin //7
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b00001000: begin //8
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 end
			 
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 end
			 end
			 
8'b00001001: begin //9
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 

8'b00001010: begin //10
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end

8'b00001011: begin //11
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b00001100: begin //12
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b00001101: begin //13
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end

8'b00001110: begin //14
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end

8'b00001111: begin //15
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 

8'b00010000: begin //16
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 end
			 
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 end
			 end
			 
8'b00010001: begin //17
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b00010010: begin //18
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b00010011: begin //19
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b00010100: begin //20
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end

8'b00010101: begin //21
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b00010110: begin //22
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b00010111: begin //23
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b00011000: begin //24
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end

8'b00011001: begin //25
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b00011010: begin //26
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b00011011: begin //27
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b00011100: begin //28
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end

8'b00011101: begin //29
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end	
	
8'b00011110: begin //30
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end

8'b00011111: begin //31
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end

8'b00100000: begin //32
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 end
			 
			 
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 end
			 end	
	
8'b00100001: begin //33
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
				
8'b00100010: begin //34
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			
8'b00100011: begin //35
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b00100100: begin //36
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			
8'b00100101: begin //37
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b00100110: begin //38
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			
8'b00100111: begin //39
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			
8'b00101000: begin //40
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end	
			
8'b00101001: begin //41
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			
8'b00101010: begin //42
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			
8'b00101011: begin //43
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			
8'b00101100: begin //44
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
8'b00101101: begin //45
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end	
			 
8'b00101110: begin //46
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b00101111: begin //47
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b00110000: begin //48
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b00110001: begin //49
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b00110010: begin //50
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b00110011: begin //51
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b00110100: begin //52
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b00110101: begin //53
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b00110110: begin //54
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b00110111: begin //55
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b00111000: begin //56
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b00111001: begin //57
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b00111010: begin //58
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b00111011: begin //59
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b00111100: begin //60
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
			 
8'b00111101: begin //61
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b00111110: begin //62
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b00111111: begin //63
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b01000000: begin //64
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 end
			 
			 
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 end
			 end
			 
8'b01000001: begin //65
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b01000010: begin //66
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b01000011: begin //67
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b01000100: begin //68
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b01000101: begin //69
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b01000110: begin //70
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b01000111: begin //71
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01001000: begin //72
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b01001001: begin //73
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b01001010: begin //74
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b01001011: begin //75
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01001100: begin //76
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b01001101: begin //77
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01001110: begin //78
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01001111: begin //79
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01010000: begin //80
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b01010001: begin //81
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b01010010: begin //82
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b01010011: begin //83
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01010100: begin //84
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b01010101: begin //85
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01010110: begin //86
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01010111: begin //87
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01011000: begin //88
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b01011001: begin //89
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01011010: begin //90
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01011011: begin //91
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01011100: begin //92
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01011101: begin //93
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01011110: begin //94
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01011111: begin //95
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			
8'b01100000: begin //96
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end	
	
8'b01100001: begin //97
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			
8'b01100010: begin //98
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			
8'b01100011: begin //99
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			
8'b01100100: begin //100
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b01100101: begin //101
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01100110: begin //102
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01100111: begin //103
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01101000: begin //104
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b01101001: begin //105
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01101010: begin //106
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01101011: begin //107
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01101100: begin //108
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01101101: begin //109
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01101110: begin //110
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01101111: begin //111
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b01110000: begin //112
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b01110001: begin //113
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01110010: begin //114
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01110011: begin //115
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01110100: begin //116
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01110101: begin //117
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01110110: begin //118
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01110111: begin //119
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b01111000: begin //120
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b01111001: begin //121
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01111010: begin //122
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01111011: begin //123
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b01111100: begin //124
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b01111101: begin //125
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b01111110: begin //126
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b01111111: begin //127
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 end
			 end
			 
8'b10000000: begin //128
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 REGR[7]<= DMEM[MEM_WB_ALULAT];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 REGR[7]<= DMEM[MEM_WB_LMD];
			 end
			 
			 
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 REGR[7]<= DMEM[EX_MEM_A];
			 end
			 end
			 
8'b10000001: begin //129
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b10000010: begin //130
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b10000011: begin //131
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b10000100: begin //132
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b10000101: begin //133
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b10000110: begin //134
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end
			 
8'b10000111: begin //135
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10001000: begin //136
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b10001001: begin //137
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b10001010: begin //138
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b10001011: begin //139
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10001100: begin //140
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b10001101: begin //141
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10001110: begin //142
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end  
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10001111: begin //143
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10010000: begin //144
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b10010001: begin //145
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b10010010: begin //146
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b10010011: begin //147
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10010100: begin //148
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b10010101: begin //149
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<= DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<= DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10010110: begin //150
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10010111: begin //151
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10011000: begin //152
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b10011001: begin //153
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10011010: begin //154
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10011011: begin //155
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10011100: begin //156
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10011101: begin //157
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10011110: begin //158
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10011111: begin //159
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b10100000: begin //160
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 REGR[7]<= DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b10100001: begin //161
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b10100010: begin //162
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b10100011: begin //163
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10100100: begin //164
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b10100101: begin //165
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10100110: begin //166
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10100111: begin //167
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10101000: begin //168
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b10101001: begin //169
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10101010: begin //170
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10101011: begin //171
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10101100: begin //172
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10101101: begin //173
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10101110: begin //174
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10101111: begin //175
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b10110000: begin //176
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b10110001: begin //177
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10110010: begin //178
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10110011: begin //179
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10110100: begin //180
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10110101: begin //181
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10110110: begin //182
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10110111: begin //183
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b10111000: begin //184
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b10111001: begin //185
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10111010: begin //186
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10111011: begin //187
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b10111100: begin //188
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b10111101: begin //189
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b10111110: begin //190
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7] <= DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b10111111: begin //191
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 end
			 end
			 
8'b11000000: begin //192
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 end
			 end
			 
8'b11000001: begin //193
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b11000010: begin //194
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b11000011: begin //195
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11000100: begin //196
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b11000101: begin //197
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11000110: begin //198
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11000111: begin //199
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11001000: begin //200
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b11001001: begin //201
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11001010: begin //202
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11001011: begin //203
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11001100: begin //204
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11001101: begin //205
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11001110: begin //206
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11001111: begin //207
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11010000: begin //208
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b11010001: begin //209
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11010010: begin //210
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11010011: begin //211
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11010100: begin //212
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11010101: begin //213
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11010110: begin //214
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11010111: begin //215
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11011000: begin //216
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11011001: begin //217
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7] <= DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11011010: begin //218
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11011011: begin //219
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11011100: begin //220
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11011101: begin //221
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11011110: begin //222
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11011111: begin //223
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 end
			 end
			 
8'b11100000: begin //224
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 end
			 end	
			 
8'b11100001: begin //225
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11100010: begin //226
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11100011: begin //227
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11100100: begin //228
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11100101: begin //229
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11100110: begin //230
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11100111: begin //231
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11101000: begin //232
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11101001: begin //233
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11101010: begin //234
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11101011: begin //235
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11101100: begin //236
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11101101: begin //237
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11101110: begin //238
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11101111: begin //239
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 end
			 end
			 
8'b11110000: begin //240
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 end
			 end
			 
8'b11110001: begin //241
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11110010: begin //242
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11110011: begin //243
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end

8'b11110100: begin //244
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11110101: begin //245
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11110110: begin //246
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11110111: begin //247
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 end
			 end
			 
8'b11111000: begin //248
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 end
			 end
			 
8'b11111001: begin //249
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11111010: begin //250
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11111011: begin //251
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 end
			 end
			 
8'b11111100: begin //252
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 end
			 end
			 
8'b11111101: begin //253
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 end
			 end
			 
8'b11111110: begin //254
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 end
			 end
			 
8'b11111111: begin //255
          MEM_WB_T2<=EX_MEM_T2;
			 if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
          || ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
          || ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
			 begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_ALULAT];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_ALULAT+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_ALULAT+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_ALULAT+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_ALULAT+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_ALULAT+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_ALULAT+16'b0000000000000110)];
			 MEM_WB_LMDH<=DMEM[(MEM_WB_ALULAT+16'b0000000000000111)];
			 REGR[7]<=DMEM[(MEM_WB_ALULAT+16'b0000000000000111)];
			 end
			 
			 else if ((MEM_WB_IR[15:12] == LW) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
		    begin
			 MEM_WB_LMDA<=DMEM[MEM_WB_LMD];
			 MEM_WB_LMDB<=DMEM[(MEM_WB_LMD+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(MEM_WB_LMD+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(MEM_WB_LMD+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(MEM_WB_LMD+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(MEM_WB_LMD+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(MEM_WB_LMD+16'b0000000000000110)];
			 MEM_WB_LMDH<=DMEM[(MEM_WB_LMD+16'b0000000000000111)];
			 REGR[7]<=DMEM[(MEM_WB_LMD+16'b0000000000000111)];
			 end
			 else
			 begin
			 MEM_WB_LMDA<=DMEM[EX_MEM_A];
			 MEM_WB_LMDB<=DMEM[(EX_MEM_A+16'b0000000000000001)];
			 MEM_WB_LMDC<=DMEM[(EX_MEM_A+16'b0000000000000010)];
			 MEM_WB_LMDD<=DMEM[(EX_MEM_A+16'b0000000000000011)];
			 MEM_WB_LMDE<=DMEM[(EX_MEM_A+16'b0000000000000100)];
			 MEM_WB_LMDF<=DMEM[(EX_MEM_A+16'b0000000000000101)];
			 MEM_WB_LMDG<=DMEM[(EX_MEM_A+16'b0000000000000110)];
			 MEM_WB_LMDH<=DMEM[(EX_MEM_A+16'b0000000000000111)];
			 REGR[7]<=DMEM[(EX_MEM_A+16'b0000000000000111)];
			 end
			 end

			 
endcase
end //lm end

if (EX_MEM_IR[15:12]==SM)
begin
case (EX_MEM_T2[7:0])
	8'b00000000: begin//0
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
	8'b00000001: begin//1
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00000010: begin//2
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00000011: begin//3
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00000100: begin//4
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00000101: begin//5
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00000110: begin//6
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00000111: begin//7
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00001000: begin//8
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00001001: begin//9
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00001010: begin//10
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00001011: begin//11
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00001100: begin//12
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00001101: begin//13
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00001110: begin//14
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00001111: begin//15
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00010000: begin//16
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00010001: begin//17
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00010010: begin//18
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00010011: begin//19
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00010100: begin//20
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00010101: begin//21
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00010110: begin//22
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00010111: begin//23
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00011000: begin//24
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00011001: begin//25
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00011010: begin//26
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00011011: begin//27
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00011100: begin//28
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00011101: begin//29
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00011110: begin//30
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00011111: begin//31
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[4];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00100000: begin//32
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00100001: begin//33
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00100010: begin//34
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00100011: begin//35
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00100100: begin//36
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00100101: begin//37
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00100110: begin//38
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00100111: begin//39
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00101000: begin//40
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00101001: begin//41
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00101010: begin//42
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00101011: begin//43
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00101100: begin//44
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00101101: begin//45
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00101110: begin//46
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00101111: begin//47
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00110000: begin//48
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[4];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00110001: begin//49
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00110010: begin//50
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00110011: begin//51
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00110100: begin//52
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00110101: begin//53
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00110110: begin//54
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00110111: begin//55
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00111000: begin//56
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00111001: begin//57
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00111010: begin//58
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00111011: begin//59
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00111100: begin//60
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00111101: begin//61
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00111110: begin//62
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b00111111: begin//63
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[4];
					DMEM[EX_MEM_A + 16'b101] <= REGR[5];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01000000: begin//64
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01000001: begin//65
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01000010: begin//66
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01000011: begin//67
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01000100: begin//68
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01000101: begin//69
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01000110: begin//70
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01000111: begin//71
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01001000: begin//72
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01001001: begin//73
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01001010: begin//74
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01001011: begin//75
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01001100: begin//76
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01001101: begin//77
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01001110: begin//78
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01001111: begin//79
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01010000: begin//80
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[4];
					DMEM[EX_MEM_A + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01010001: begin//81
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01010010: begin//82
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01010011: begin//83
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01010100: begin//84
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01010101: begin//85
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01010110: begin//86
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01010111: begin//87
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01011000: begin//88
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01011001: begin//89
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01011010: begin//90
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01011011: begin//91
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01011100: begin//92
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01011101: begin//93
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01011110: begin//94
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01011111: begin//95
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[4];
					DMEM[EX_MEM_A + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01100000: begin//96
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[5];
					DMEM[EX_MEM_A + 16'b1] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01100001: begin//97
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01100010: begin//98
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01100011: begin//99
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01100100: begin//100
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01100101: begin//101
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01100110: begin//102
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01100111: begin//103
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01101000: begin//104
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01101001: begin//105
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01101010: begin//106
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01101011: begin//107
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01101100: begin//108
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01101101: begin//109
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01101110: begin//110
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01101111: begin//111
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01110000: begin//112
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[4];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01110001: begin//113
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01110010: begin//114
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01110011: begin//115
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01110100: begin//116
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01110101: begin//117
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01110110: begin//118
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01110111: begin//119
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01111000: begin//120
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01111001: begin//121
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01111010: begin//122
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01111011: begin//123
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01111100: begin//124
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01111101: begin//125
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01111110: begin//126
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b01111111: begin//127
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b110] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b110] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[4];
					DMEM[EX_MEM_A + 16'b101] <= REGR[5];
					DMEM[EX_MEM_A + 16'b110] <= REGR[6];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10000000: begin//128
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10000001: begin//129
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10000010: begin//130
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10000011: begin//131
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10000100: begin//132
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10000101: begin//133
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10000110: begin//134
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10000111: begin//135
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10001000: begin//136
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10001001: begin//137
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10001010: begin//138
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10001011: begin//139
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10001100: begin//140
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10001101: begin//141
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10001110: begin//142
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10001111: begin//143
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10010000: begin//144
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[4];
					DMEM[EX_MEM_A + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10010001: begin//145
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10010010: begin//146
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10010011: begin//147
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10010100: begin//148
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10010101: begin//149
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10010110: begin//150
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10010111: begin//151
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10011000: begin//152
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10011001: begin//153
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10011010: begin//154
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10011011: begin//155
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10011100: begin//156
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10011101: begin//157
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10011110: begin//158
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10011111: begin//159
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[4];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10100000: begin//160
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[5];
					DMEM[EX_MEM_A + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10100001: begin//161
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10100010: begin//162
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10100011: begin//163
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10100100: begin//164
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10100101: begin//165
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10100110: begin//166
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10100111: begin//167
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10101000: begin//168
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10101001: begin//169
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10101010: begin//170
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10101011: begin//171
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10101100: begin//172
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10101101: begin//173
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10101110: begin//174
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10101111: begin//175
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10110000: begin//176
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[4];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10110001: begin//177
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10110010: begin//178
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10110011: begin//179
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10110100: begin//180
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10110101: begin//181
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10110110: begin//182
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10110111: begin//183
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10111000: begin//184
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10111001: begin//185
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10111010: begin//186
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10111011: begin//187
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= EX_MEM_R7LAT; //REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= EX_MEM_R7LAT; //REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= EX_MEM_R7LAT; //REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10111100: begin//188
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10111101: begin//189
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10111110: begin//190
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b10111111: begin//191
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[4];
					DMEM[EX_MEM_A + 16'b101] <= REGR[5];
					DMEM[EX_MEM_A + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11000000: begin//192
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[6];
					DMEM[EX_MEM_A + 16'b1] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11000001: begin//193
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[6];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11000010: begin//194
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[6];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11000011: begin//195
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11000100: begin//196
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[6];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11000101: begin//197
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11000110: begin//198
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11000111: begin//199
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11001000: begin//200
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[6];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11001001: begin//201
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11001010: begin//202
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11001011: begin//203
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11001100: begin//204
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11001101: begin//205
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11001110: begin//206
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11001111: begin//207
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11010000: begin//208
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[4];
					DMEM[EX_MEM_A + 16'b1] <= REGR[6];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11010001: begin//209
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11010010: begin//210
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11010011: begin//211
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11010100: begin//212
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11010101: begin//213
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11010110: begin//214
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11010111: begin//215
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11011000: begin//216
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11011001: begin//217
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11011010: begin//218
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11011011: begin//219
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11011100: begin//220
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11011101: begin//221
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11011110: begin//222
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11011111: begin//223
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[4];
					DMEM[EX_MEM_A + 16'b101] <= REGR[6];
					DMEM[EX_MEM_A + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11100000: begin//224
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[5];
					DMEM[EX_MEM_A + 16'b1] <= REGR[6];
					DMEM[EX_MEM_A + 16'b10] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11100001: begin//225
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11100010: begin//226
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11100011: begin//227
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11100100: begin//228
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11100101: begin//229
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11100110: begin//230
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11100111: begin//231
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11101000: begin//232
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11101001: begin//233
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11101010: begin//234
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11101011: begin//235
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11101100: begin//236
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11101101: begin//237
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11101110: begin//238
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11101111: begin//239
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[6];
					DMEM[EX_MEM_A + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11110000: begin//240
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[4];
					DMEM[EX_MEM_A + 16'b1] <= REGR[5];
					DMEM[EX_MEM_A + 16'b10] <= REGR[6];
					DMEM[EX_MEM_A + 16'b11] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11110001: begin//241
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11110010: begin//242
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11110011: begin//243
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11110100: begin//244
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11110101: begin//245
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11110110: begin//246
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11110111: begin//247
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[6];
					DMEM[EX_MEM_A + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11111000: begin//248
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[3];
					DMEM[EX_MEM_A + 16'b1] <= REGR[4];
					DMEM[EX_MEM_A + 16'b10] <= REGR[5];
					DMEM[EX_MEM_A + 16'b11] <= REGR[6];
					DMEM[EX_MEM_A + 16'b100] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11111001: begin//249
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11111010: begin//250
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11111011: begin//251
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[6];
					DMEM[EX_MEM_A + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11111100: begin//252
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[2];
					DMEM[EX_MEM_A + 16'b1] <= REGR[3];
					DMEM[EX_MEM_A + 16'b10] <= REGR[4];
					DMEM[EX_MEM_A + 16'b11] <= REGR[5];
					DMEM[EX_MEM_A + 16'b100] <= REGR[6];
					DMEM[EX_MEM_A + 16'b101] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11111101: begin//253
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[6];
					DMEM[EX_MEM_A + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11111110: begin//254
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[1];
					DMEM[EX_MEM_A + 16'b1] <= REGR[2];
					DMEM[EX_MEM_A + 16'b10] <= REGR[3];
					DMEM[EX_MEM_A + 16'b11] <= REGR[4];
					DMEM[EX_MEM_A + 16'b100] <= REGR[5];
					DMEM[EX_MEM_A + 16'b101] <= REGR[6];
					DMEM[EX_MEM_A + 16'b110] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
	8'b11111111: begin//255
					if((((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| (((MEM_WB_IR[15:12] == ADD) || (MEM_WB_IR[15:12] == NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_STALL == 0)&& (MEM_WB_IR[5:3] == EX_MEM_IR[11:9]) && (MEM_WB_IR[5:3] != 3'b111))
|| ((MEM_WB_IR[15:12] == ADI) && (MEM_WB_IR[8:6] == EX_MEM_IR[11:9]) && (MEM_WB_IR[8:6] != 3'b111))
|| ((MEM_WB_IR[15:12] == LHI) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]) && (MEM_WB_IR[11:9] != 3'b111)))
					begin
					DMEM[MEM_WB_ALULAT] <= REGR[0];
					DMEM[MEM_WB_ALULAT + 16'b1] <= REGR[1];
					DMEM[MEM_WB_ALULAT + 16'b10] <= REGR[2];
					DMEM[MEM_WB_ALULAT + 16'b11] <= REGR[3];
					DMEM[MEM_WB_ALULAT + 16'b100] <= REGR[4];
					DMEM[MEM_WB_ALULAT + 16'b101] <= REGR[5];
					DMEM[MEM_WB_ALULAT + 16'b110] <= REGR[6];
					DMEM[MEM_WB_ALULAT + 16'b111] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else if ((MEM_WB_IR[15:12] == LW) && (EX_MEM_IR[15:12] == SM) && (MEM_WB_IR[11:9] == EX_MEM_IR[11:9]))
					begin
					DMEM[MEM_WB_LMD] <= REGR[0];
					DMEM[MEM_WB_LMD + 16'b1] <= REGR[1];
					DMEM[MEM_WB_LMD + 16'b10] <= REGR[2];
					DMEM[MEM_WB_LMD + 16'b11] <= REGR[3];
					DMEM[MEM_WB_LMD + 16'b100] <= REGR[4];
					DMEM[MEM_WB_LMD + 16'b101] <= REGR[5];
					DMEM[MEM_WB_LMD + 16'b110] <= REGR[6];
					DMEM[MEM_WB_LMD + 16'b111] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					else
					begin
					DMEM[EX_MEM_A] <= REGR[0];
					DMEM[EX_MEM_A + 16'b1] <= REGR[1];
					DMEM[EX_MEM_A + 16'b10] <= REGR[2];
					DMEM[EX_MEM_A + 16'b11] <= REGR[3];
					DMEM[EX_MEM_A + 16'b100] <= REGR[4];
					DMEM[EX_MEM_A + 16'b101] <= REGR[5];
					DMEM[EX_MEM_A + 16'b110] <= REGR[6];
					DMEM[EX_MEM_A + 16'b111] <= REGR[7];
					SM_FLAG <= 1'b0;
					//LM_FLAG <= 1'b0;
					end
					end
endcase
end	//sm end
end // stall flag end
else
begin
MEM_WB_IR<=EX_MEM_IR;
MEM_WB_NPCLAT<=EX_MEM_NPCLAT;
MEM_WB_ALULAT<=EX_MEM_ALULAT;
MEM_WB_STALL<=EX_MEM_STALL;
MEM_WB_T2<=EX_MEM_T2;
end
end// MEM stage end

//******************************________WB STAGE_______**************************************
//WB STAGE
always @(posedge clk)
begin

if (((MEM_WB_STALL==1'b0) || (MEM_WB_TKN_BRNCH == 1))  && (HALT_FLAG==0)) 
begin

if(MEM_WB_IR[15:12]==LM && MEM_WB_STALL==1'b0) // setting done for LM followed by LM followed by dependent instruction
begin
MEM_WB_STALL<=1'b1;
end
//else
//begin
//MEM_WB_STALL<=MEM_WB_STALL;
//end


if (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0] == 2'b00) && (MEM_WB_IR[5:3] != 3'b111))
begin
REGR[MEM_WB_IR[5:3]]<=MEM_WB_ALULAT;
end

if (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0] == 2'b10) && (MEM_WB_IR[5:3] != 3'b111))
begin
if (MEM_WB_TMP == 1'b0)
REGR[MEM_WB_IR[5:3]]<=MEM_WB_ALULAT;
end

if (((MEM_WB_IR[15:12]==ADD) || (MEM_WB_IR[15:12]==NDU)) && (MEM_WB_IR[1:0] == 2'b01) && (MEM_WB_IR[5:3] != 3'b111))
begin
if (MEM_WB_TMP == 1'b0)
REGR[MEM_WB_IR[5:3]]<=MEM_WB_ALULAT;
end

if ((MEM_WB_IR[15:12]==ADI) && (MEM_WB_IR[8:6] != 3'b111))
begin
REGR[MEM_WB_IR[8:6]]<=MEM_WB_ALULAT;
end

if ((MEM_WB_IR[15:12]==LHI) && (MEM_WB_IR[11:9] != 3'b111))
begin
REGR[MEM_WB_IR[11:9]]<=MEM_WB_ALULAT;
end

if ((MEM_WB_IR[15:12]==LW) && (MEM_WB_IR[11:9] != 3'b111))
begin
REGR[MEM_WB_IR[11:9]]<=MEM_WB_LMD;
end

if (((MEM_WB_IR[15:12]==JAL) || (MEM_WB_IR[15:12]==JLR)) && (MEM_WB_IR[11:9] != 3'b111))
begin
REGR[MEM_WB_IR[11:9]]<=MEM_WB_NPCLAT;
end

if (((MEM_WB_IR[15:12]==JAL) || (MEM_WB_IR[15:12]==JLR)) && (MEM_WB_IR[11:9] == 3'b111))
begin
HALT_FLAG<=1'b1;
$display("This is an invalid instruction");
end

if(MEM_WB_IR[15:12]==LM)
begin
case (MEM_WB_T2[7:0])

8'b00000000: begin //0
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 end

8'b00000001: begin //1
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 end
			 
8'b00000010: begin //2
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 end
			 
8'b00000011: begin //3
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 end
			 
8'b00000100: begin //4
			 LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[2]<=MEM_WB_LMDA;
			 end
			 
8'b00000101: begin //5
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 end
			 

8'b00000110: begin //6
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 end
			 
8'b00000111: begin //7
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 end
			 
8'b00001000: begin //8
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[3]<=MEM_WB_LMDA;
			 end
			 
8'b00001001: begin //9
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 end
			 

8'b00001010: begin //10
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 end

8'b00001011: begin //11
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 end
			 
8'b00001100: begin //12
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 end
			 
8'b00001101: begin //13
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 end

8'b00001110: begin //14
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 end

8'b00001111: begin //15
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 end
			 

8'b00010000: begin //16
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[4]<=MEM_WB_LMDA;
			 end
			 
8'b00010001: begin //17
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 end
			 
8'b00010010: begin //18
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 end
			 
8'b00010011: begin //19
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 end
			 
8'b00010100: begin //20
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[2]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 end

8'b00010101: begin //21
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 end
			 
8'b00010110: begin //22
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 end
			 
8'b00010111: begin //23
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 end
			 
8'b00011000: begin //24
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[3]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 end

8'b00011001: begin //25
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 end
			 
8'b00011010: begin //26
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 end
			 
8'b00011011: begin //27
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 end
			 
8'b00011100: begin //28
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 end

8'b00011101: begin //29
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 end	
	
8'b00011110: begin //30
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 end

8'b00011111: begin //31
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 REGR[4]<=MEM_WB_LMDE;
			 end

8'b00100000: begin //32
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[5]<=MEM_WB_LMDA;
			 end	
	
8'b00100001: begin //33
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 end
				
8'b00100010: begin //34
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 end
			
8'b00100011: begin //35
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 end	
			 
			 
8'b00100100: begin //36
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[2]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 end
			
8'b00100101: begin //37
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 end
			 
8'b00100110: begin //38
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 end
			
8'b00100111: begin //39
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 end
			 
			
8'b00101000: begin //40
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[3]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 end	
			
8'b00101001: begin //41
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 end
			
8'b00101010: begin //42
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 end
			
8'b00101011: begin //43
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 end
			
8'b00101100: begin //44
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 end
8'b00101101: begin //45
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 end	
			 
8'b00101110: begin //46
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 end
			 
8'b00101111: begin //47
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 end
			 
8'b00110000: begin //48
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[4]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 end
			 
8'b00110001: begin //49
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 end
			 
8'b00110010: begin //50
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 end
			 
8'b00110011: begin //51
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 end
			 
8'b00110100: begin //52
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[2]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 end
			 
8'b00110101: begin //53
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 end
			 
8'b00110110: begin //54
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 end
			 
8'b00110111: begin //55
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 end
			 
8'b00111000: begin //56
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[3]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 end
			 
8'b00111001: begin //57
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 end
			 
8'b00111010: begin //58
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
          end
			 
8'b00111011: begin //59
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 end
			 
8'b00111100: begin //60
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 end
			 
			 
8'b00111101: begin //61
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 end
			 
8'b00111110: begin //62
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
          end
			 
8'b00111111: begin //63
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 REGR[6]<=MEM_WB_LMDF;
			 end
			 
8'b01000000: begin //64
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[6]<=MEM_WB_LMDA;
			 end
			 
8'b01000001: begin //65
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[6]<=MEM_WB_LMDB;
			 end
			 
8'b01000010: begin //66
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[6]<=MEM_WB_LMDB;
			 end
			 
8'b01000011: begin //67
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end
			 
8'b01000100: begin //68
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[2]<=MEM_WB_LMDA;
			 REGR[6]<=MEM_WB_LMDB;
			 end
			 
8'b01000101: begin //69
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end
			 
8'b01000110: begin //70
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end
			 
8'b01000111: begin //71
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01001000: begin //72
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[3]<=MEM_WB_LMDA;
			 REGR[6]<=MEM_WB_LMDB;
			 end
			 
8'b01001001: begin //73
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end
			 
8'b01001010: begin //74
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end
			 
8'b01001011: begin //75
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01001100: begin //76
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end
			 
8'b01001101: begin //77
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01001110: begin //78
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01001111: begin //79
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01010000: begin //80
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[4]<=MEM_WB_LMDA;
			 REGR[6]<=MEM_WB_LMDB;
			 end
			 
8'b01010001: begin //81
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end
			 
8'b01010010: begin //82
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end
			 
8'b01010011: begin //83
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01010100: begin //84
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[2]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end
			 
8'b01010101: begin //85
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01010110: begin //86
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01010111: begin //87
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01011000: begin //88
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[3]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end
			 
8'b01011001: begin //89
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01011010: begin //90
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01011011: begin //91
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01011100: begin //92
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01011101: begin //93
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01011110: begin //94
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01011111: begin //95
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 REGR[4]<=MEM_WB_LMDE;
			 REGR[6]<=MEM_WB_LMDF;
			 end
			
8'b01100000: begin //96
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[5]<=MEM_WB_LMDA;
			 REGR[6]<=MEM_WB_LMDB;
			 end	
	
8'b01100001: begin //97
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end	
			
8'b01100010: begin //98
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end
			
8'b01100011: begin //99
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			
8'b01100100: begin //100
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[2]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end	
			 
8'b01100101: begin //101
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01100110: begin //102
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01100111: begin //103
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01101000: begin //104
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
			 REGR[3]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end
			 
8'b01101001: begin //105
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01101010: begin //106
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01101011: begin //107
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01101100: begin //108
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01101101: begin //109
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01101110: begin //110
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01101111: begin //111
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 REGR[6]<=MEM_WB_LMDF;
			 end
			 
8'b01110000: begin //112
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[4]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			 end
			 
8'b01110001: begin //113
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01110010: begin //114
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01110011: begin //115
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01110100: begin //116
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01110101: begin //117
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01110110: begin //118
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01110111: begin //119
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 REGR[6]<=MEM_WB_LMDF;
			 end
			 
8'b01111000: begin //120
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[3]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			 end
			 
8'b01111001: begin //121
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01111010: begin //122
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01111011: begin //123
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 REGR[6]<=MEM_WB_LMDF;
			 end
			 
8'b01111100: begin //124
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			 end
			 
8'b01111101: begin //125
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 REGR[6]<=MEM_WB_LMDF;
			 end
			 
8'b01111110: begin //126
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 REGR[6]<=MEM_WB_LMDF;
			 end
			 
8'b01111111: begin //127
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 REGR[4]<=MEM_WB_LMDE;
			 REGR[5]<=MEM_WB_LMDF;
			 REGR[6]<=MEM_WB_LMDG;
			 end
			 
8'b10000000: begin //128
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
         // REGR[7]<=MEM_WB_LMDA;
			 end
			 
8'b10000001: begin //129
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 //REGR[7]<=MEM_WB_LMDB;
			 end
			 
8'b10000010: begin //130
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 //REGR[7]<=MEM_WB_LMDB;
			 end
			 
8'b10000011: begin //131
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end
			 
8'b10000100: begin //132
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 //REGR[7]<=MEM_WB_LMDB;
			 end
			 
8'b10000101: begin //133
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end
			 
8'b10000110: begin //134
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 //REGR[7]<=MEM_WB_LMDC;
			 end
			 
8'b10000111: begin //135
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 //REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10001000: begin //136
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[3]<=MEM_WB_LMDA;
			 //REGR[7]<=MEM_WB_LMDB;
			 end
			 
8'b10001001: begin //137
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b10001010: begin //138
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b10001011: begin //139
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 //REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10001100: begin //140
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b10001101: begin //141
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10001110: begin //142
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10001111: begin //143
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10010000: begin //144
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[4]<=MEM_WB_LMDA;
			// REGR[7]<=MEM_WB_LMDB;
          end
			 
8'b10010001: begin //145
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b10010010: begin //146
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 //REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b10010011: begin //147
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10010100: begin //148
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b10010101: begin //149
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 //REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10010110: begin //150
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10010111: begin //151
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10011000: begin //152
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[3]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b10011001: begin //153
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10011010: begin //154
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10011011: begin //155
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10011100: begin //156
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10011101: begin //157
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10011110: begin //158
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 //REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10011111: begin //159
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 REGR[4]<=MEM_WB_LMDE;
			// REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b10100000: begin //160
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[5]<=MEM_WB_LMDA;
			// REGR[7]<=MEM_WB_LMDB;
			 end
			 
8'b10100001: begin //161
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b10100010: begin //162
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end
			 
8'b10100011: begin //163
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10100100: begin //164
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b10100101: begin //165
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10100110: begin //166
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10100111: begin //167
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10101000: begin //168
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[3]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b10101001: begin //169
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10101010: begin //170
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10101011: begin //171
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10101100: begin //172
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10101101: begin //173
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10101110: begin //174
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10101111: begin //175
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			// REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b10110000: begin //176
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[4]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b10110001: begin //177
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10110010: begin //178
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			//REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10110011: begin //179
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10110100: begin //180
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10110101: begin //181
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10110110: begin //182
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10110111: begin //183
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			// REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b10111000: begin //184
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[3]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b10111001: begin //185
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10111010: begin //186
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10111011: begin //187
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			// REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b10111100: begin //188
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b10111101: begin //189
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			// REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b10111110: begin //190
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			// REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b10111111: begin //191
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 REGR[4]<=MEM_WB_LMDE;
			 REGR[5]<=MEM_WB_LMDF;
			// REGR[7]<=MEM_WB_LMDG;
			 end
			 
8'b11000000: begin //192
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[6]<=MEM_WB_LMDA;
			// REGR[7]<=MEM_WB_LMDB;
			 end
			 
8'b11000001: begin //193
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[6]<=MEM_WB_LMDB;
			// REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b11000010: begin //194
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[6]<=MEM_WB_LMDB;
		//	 REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b11000011: begin //195
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
		//	 REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11000100: begin //196
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[6]<=MEM_WB_LMDB;
		//	 REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b11000101: begin //197
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
		//	 REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11000110: begin //198
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11000111: begin //199
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11001000: begin //200
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[3]<=MEM_WB_LMDA;
			 REGR[6]<=MEM_WB_LMDB;
		//	 REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b11001001: begin //201
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11001010: begin //202
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11001011: begin //203
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11001100: begin //204
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11001101: begin //205
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11001110: begin //206
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11001111: begin //207
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
			// REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11010000: begin //208
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[4]<=MEM_WB_LMDA;
			 REGR[6]<=MEM_WB_LMDB;
		//	 REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b11010001: begin //209
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
		//	 REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11010010: begin //210
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11010011: begin //211
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11010100: begin //212
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
		//	 REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11010101: begin //213
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11010110: begin //214
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11010111: begin //215
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11011000: begin //216
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[3]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
		//	 REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11011001: begin //217
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11011010: begin //218
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11011011: begin //219
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11011100: begin //220
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11011101: begin //221
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11011110: begin //222
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11011111: begin //223
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 REGR[4]<=MEM_WB_LMDE;
			 REGR[6]<=MEM_WB_LMDF;
		//	 REGR[7]<=MEM_WB_LMDG;
			 end
			 
8'b11100000: begin //224
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[5]<=MEM_WB_LMDA;
			 REGR[6]<=MEM_WB_LMDB;
		//	 REGR[7]<=MEM_WB_LMDC;
			 end	
			 
8'b11100001: begin //225
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
		//	 REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11100010: begin //226
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
		//	 REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11100011: begin //227
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11100100: begin //228
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
			// REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11100101: begin //229
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
			// REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11100110: begin //230
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11100111: begin //231
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11101000: begin //232
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[3]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
		//	 REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11101001: begin //233
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11101010: begin //234
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11101011: begin //235
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11101100: begin //236
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11101101: begin //237
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11101110: begin //238
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11101111: begin //239
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 REGR[6]<=MEM_WB_LMDF;
		//	 REGR[7]<=MEM_WB_LMDG;
			 end
			 
8'b11110000: begin //240
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[4]<=MEM_WB_LMDA;
			 REGR[5]<=MEM_WB_LMDB;
			 REGR[6]<=MEM_WB_LMDC;
		//	 REGR[7]<=MEM_WB_LMDD;
			 end
			 
8'b11110001: begin //241
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11110010: begin //242
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11110011: begin //243
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end

8'b11110100: begin //244
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11110101: begin //245
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11110110: begin //246
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11110111: begin //247
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 REGR[6]<=MEM_WB_LMDF;
		//	 REGR[7]<=MEM_WB_LMDG;
			 end
			 
8'b11111000: begin //248
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[3]<=MEM_WB_LMDA;
			 REGR[4]<=MEM_WB_LMDB;
			 REGR[5]<=MEM_WB_LMDC;
			 REGR[6]<=MEM_WB_LMDD;
		//	 REGR[7]<=MEM_WB_LMDE;
			 end
			 
8'b11111001: begin //249
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11111010: begin //250
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11111011: begin //251
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 REGR[6]<=MEM_WB_LMDF;
		//	 REGR[7]<=MEM_WB_LMDG;
			 end
			 
8'b11111100: begin //252
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[2]<=MEM_WB_LMDA;
			 REGR[3]<=MEM_WB_LMDB;
			 REGR[4]<=MEM_WB_LMDC;
			 REGR[5]<=MEM_WB_LMDD;
			 REGR[6]<=MEM_WB_LMDE;
		//	 REGR[7]<=MEM_WB_LMDF;
			 end
			 
8'b11111101: begin //253
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 REGR[6]<=MEM_WB_LMDF;
		//	 REGR[7]<=MEM_WB_LMDG;
			 end
			 
8'b11111110: begin //254
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[1]<=MEM_WB_LMDA;
			 REGR[2]<=MEM_WB_LMDB;
			 REGR[3]<=MEM_WB_LMDC;
			 REGR[4]<=MEM_WB_LMDD;
			 REGR[5]<=MEM_WB_LMDE;
			 REGR[6]<=MEM_WB_LMDF;
		//	 REGR[7]<=MEM_WB_LMDG;
			 end
			 
8'b11111111: begin //255
          LM_FLAG<=1'b0;
			 SM_FLAG<=1'b0;
          REGR[0]<=MEM_WB_LMDA;
			 REGR[1]<=MEM_WB_LMDB;
			 REGR[2]<=MEM_WB_LMDC;
			 REGR[3]<=MEM_WB_LMDD;
			 REGR[4]<=MEM_WB_LMDE;
			 REGR[5]<=MEM_WB_LMDF;
			 REGR[6]<=MEM_WB_LMDG;
		//	 REGR[7]<=MEM_WB_LMDH;
			 end
			 
endcase
end
end
end





endmodule
