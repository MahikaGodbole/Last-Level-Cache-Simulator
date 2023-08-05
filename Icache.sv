import Grp8_Pkg :: *;
//Instruction Cache Block
module Instruction_Cache;
int Inst_HitCount = 0;
int Inst_MissCount = 0;
int Inst_ReadCount = 0;
real Inst_HitRatio;
logic [Instruction_SelectBits - 1 : 0] InstructionWays;

bit [Sets-1 : 0] [Instruction_CacheWays - 1 : 0] [Instruction_SelectBits - 1 : 0] LRU_I;
bit [Sets-1 : 0] [Data_CacheWays - 1 : 0] [Tag_Bits - 1 : 0] Tag_I;
MESI [Sets-1 : 0] [Data_CacheWays - 1 : 0] MESI_STATES_I;
initial 
begin
	Reset_I();
	ptr = $fopen("trace1(2).txt","r");
	if($test$plusargs("MODE"))
		Mode = 0;
	else
		Mode = 1;
	while(!$feof(ptr))
	begin
		ptr_t = $fscanf(ptr,"%h %h\n",n,Address);
		{Tag_Array,Index,Byte_Select} = Address;
		if(n == 4'd2)
			Read_L1Instruction(Index,Tag_Array,Mode);
		else if(n == 4'd8)
			Reset_I();
		else if(n == 4'd9)
			Print_Contents_States_I();
	end
	$fclose(ptr);

	Inst_HitRatio = (real'(Inst_HitCount)/(real'(Inst_HitCount) + real'(Inst_MissCount)));
	$display("*******************************************************Data_Cache_Statistics*******************************************************");
	$display("Number of L1 Icache Reads = %d,Number of L1 Icache Hits = %d,Number of L1 Icache Misses = %d, Icache Hit Ratio = %f",Inst_ReadCount,Inst_HitCount,Inst_MissCount,Inst_HitRatio);
	
end

//Task to Read Data from Instruction Cache 
task Read_L1Instruction(logic [Index_Bits -1:0] Index, logic [Tag_Bits -1 :0] Tag_Array, logic Mode);
	Inst_ReadCount = Inst_ReadCount + 1;
	Hit = 0;
	for(int i = 0; i < Instruction_CacheWays; i++)
	begin
		if(MESI_STATES_I[Index][i] != I)
			if(Tag_I[Index][i] == Tag_Array)
			begin
				InstructionWays = i;
				Hit = 1;
			end
	end
	
	if(Hit == 1)
	begin
		Inst_HitCount = Inst_HitCount + 1;
		LRU_Update_I(Index,InstructionWays);
		if(MESI_STATES_I[Index][InstructionWays] == E)
			MESI_STATES_I[Index][InstructionWays] = S;
		else
			MESI_STATES_I[Index][InstructionWays] = MESI_STATES_I[Index][InstructionWays];
	end
	else
	begin
		Inst_MissCount = Inst_MissCount + 1;
		Invalid = 0;
		for(int i = 0; i < Instruction_CacheWays; i++)
		begin	
			if(MESI_STATES_I[Index][i] == I)
			begin	
				InstructionWays = i;
				Invalid = 1;
			end
		end
		
		if(Invalid == 1)
		begin
			Tag_I[Index][InstructionWays] = Tag_Array;
			LRU_Update_I(Index,InstructionWays);
			LRU_Update_I(Index,InstructionWays);
			MESI_STATES_I[Index][InstructionWays] = E;
			if(Mode == 1)
				$display("Read from L2 %d'h%h",Address_Bits,Address);
		end
		else
		begin
			for(int i = 0; i < Instruction_CacheWays; i++)
			begin
				if(LRU_I[Index][i] == '0)
				begin
					if( Mode == 1 && ( MESI_STATES_I[Index][i] == M))
					begin
						$display(" Write M to L2 Cache %d'h%h", Address_Bits,Address);
					end
					InstructionWays = i;
				end
			end
			Tag_I[Index][InstructionWays] = Tag_Array;
			LRU_Update_I(Index,InstructionWays);
			LRU_Update_I(Index,InstructionWays);
			MESI_STATES_I[Index][InstructionWays] = E;
			if(Mode == 1)
				$display("Read from L2 %d'h%h",Address_Bits,Address);
		end
	end
endtask

//Task to Reset Instruction Cache
task Reset_I();
	Inst_HitCount = 0;
	Inst_MissCount = 0;
	Inst_ReadCount = 0;

	for(int i = 0; i <= Sets -1 ; i++)
	begin	
		for(int j = 0; j <= Instruction_CacheWays -1 ; j++)
		begin
			MESI_STATES_I[i][j]  = I;
		end
	end
endtask

//Task to Print Contents and States of Instruction Cache
task Print_Contents_States_I();
	$display("******Contents and States of the Instruction Cache*******");
	for(int i = 0; i < Sets; i++)
	begin
		for(int j = Instruction_CacheWays-1; j >= 0; j--)
		begin
			if(MESI_STATES_I[i][j] != I)
			begin
				if(!done)
				begin
					$display("|+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|");
					$display("|\t\t\tIndex = %d'h%h\t\t\t\t\t\t|", Index_Bits , i );
					$display("|+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|");
					$display("|\tWay No\t|  Tag_Address\t\t\t|      State\t\t|    LRU|       \t|");
					$display("|+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|");
					done = 1;
				end
				$display("|\t%3d\t|\t%2d'h%3h\t\t|  %s\t\t|\t%b\t|", (Instruction_CacheWays-1)-j,Tag_Bits,Tag_I[i][j],MESI_STATES_I[i][j],LRU_I[i][j]);
				$display("|+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|");
			end
		end
		done = 0;
	end
endtask

//Task to Update LRU based on Instruction
task automatic LRU_Update_I(logic [Index_Bits - 1: 0] Index, ref logic [Instruction_SelectBits -1 : 0] InstructionWays);
	logic [Instruction_SelectBits -1: 0] Sub_I;
	Sub_I = LRU_I[Index][InstructionWays];
	for(int i = 0; i < Instruction_CacheWays; i++)
	begin
		if(LRU_I[Index][i] > Sub_I)
			LRU_I[Index][i] = LRU_I[Index][i] - 1;
		else
			LRU_I[Index][i] = LRU_I[Index][i];
	end
	LRU_I[Index][InstructionWays] = '1;
endtask
endmodule