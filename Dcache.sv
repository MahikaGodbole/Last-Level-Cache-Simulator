
/************************************/
//Name:	L1SplitCache.sv				 //																	    
//									 //																													
// Subject:	ECE 585					 //													                        																															    
// Guide  : Yuchen Huang			 //																            
// Date   : March 16, 2023			 //																					
// Team	  :	Harsha Vardhan Abburi,   //
//			Mahika Satish Godbole,   //
//			Vamsi Krishna Masetty,   //
//          Venkata Ramana Molabanti //																														
// Term   : Winter 2023				 //
//									 //
/************************************/

import Grp8_Pkg :: * ;  
module L1_SplitCache;
Data_Cache CD();
Instruction_Cache CI();
endmodule

module Data_Cache;
int HitCount = 0;
int MissCount = 0;
int ReadCount = 0;
int WriteCount  = 0;
real HitRatio;
logic [Data_SelectBits -1 : 0] Data_Ways;

bit [Sets-1 : 0] [Data_CacheWays - 1 : 0] [Data_SelectBits - 1 : 0] LRU;
bit [Sets-1 : 0] [Data_CacheWays - 1 : 0] [Tag_Bits - 1 : 0] TAG;
MESI [Sets-1 : 0] [Data_CacheWays- 1 : 0] MESI_STATES;
initial 
begin
	Reset();
	ptr = $fopen("trace1(2).txt","r");
	if($test$plusargs("MODE"))
		Mode = 0;
	else
		Mode = 1;
	while(!$feof(ptr))
	begin
		ptr_t = $fscanf(ptr,"%h %h\n",n,Address);
		{Tag_Array,Index,Byte_Select} = Address;
		if(n == 4'd0)
			ReadData_L1(Index,Tag_Array,Mode);
		else if(n == 4'd1)
			WriteData_L1(Index,Tag_Array,Mode);
		else if(n == 4'd3)
			Invalid_CommandL2(Index,Tag_Array,Mode);
		else if(n == 4'd4)
			DatafromL2(Index,Tag_Array,Mode);
		else if(n == 4'd8)
			Reset();
		else if(n == 4'd9)
			Print_Contents_States();
	end
	$fclose(ptr);
	HitRatio = (real'(HitCount)/(real'(HitCount) + real'(MissCount)));
	$display("*******************************************************Data_Cache_Statistics*******************************************************");
	$display("Number of L1 Cache Reads = %d, Number of L1 Cache Writes = %d, Number of L1 Cache Hits = %d, Number of L1 Cache Misses = %d, Number of L1 Cache Hit Ratio = %f",ReadCount,WriteCount,HitCount,MissCount,HitRatio);
		
end

//Task to Read Data from Cache
task ReadData_L1 (logic [Index_Bits -1:0] Index, logic [Tag_Bits -1 :0] Tag_Array, logic M);
	ReadCount = ReadCount + 1;
	
	Hit = 0;
	for(int i = 0; i < Data_CacheWays; i++)
	begin
		if(MESI_STATES[Index][i] != I)
			if(TAG[Index][i] == Tag_Array)
			begin
				Data_Ways = i;
				Hit = 1;
			end
	end
	
	if(Hit == 1)
	begin
		HitCount = HitCount + 1;
		LRU_Update(Index,Data_Ways);
		if(MESI_STATES[Index][Data_Ways] == E)
			MESI_STATES[Index][Data_Ways] = S;
		else
			MESI_STATES[Index][Data_Ways] = MESI_STATES[Index][Data_Ways] ;
	end
	else
	begin
		MissCount = MissCount + 1;
		Invalid = 0;
		for(int i = 0; i < Data_CacheWays; i++)
		begin	
			if(MESI_STATES[Index][i] == I)
			begin	
				Data_Ways = i;
				Invalid = 1;
			end
		end
		if(Invalid == 1)
		begin
			TAG[Index][Data_Ways] = Tag_Array;
			LRU_Update(Index,Data_Ways);
			MESI_STATES[Index][Data_Ways] = E;
			if(Mode==1)
				$display("Read from L2 %d'h%h",Address_Bits,Address);
		end
		else
		begin
			for(int i = 0; i < Data_CacheWays; i++)
			begin
				if(LRU[Index][i] == '0)
				begin
					if( Mode == 1 && ( MESI_STATES[Index][i] == M))
					begin
						$display(" Write to L2 %d'h%h", Address_Bits,Address);
					end
					Data_Ways = i;
				end
			end
			TAG[Index][Data_Ways] = Tag_Array;
			LRU_Update(Index,Data_Ways);
			MESI_STATES[Index][Data_Ways] = E;
			if(Mode == 1)
				$display("Read from L2 %d'h%h",Address_Bits,Address);
		end
	end
endtask

//Task to Write Data to Cache
task WriteData_L1(logic [Index_Bits -1:0] Index, logic [Tag_Bits -1 :0] Tag_Array, logic Mode);
	WriteCount = WriteCount + 1;
	Hit = 0;
	for(int i = 0; i < Data_CacheWays; i++)
	begin
		if(MESI_STATES[Index][i] != I)
			if(TAG[Index][i] == Tag_Array)
			begin
				Data_Ways = i;
				Hit = 1;
			end
	end
	if(Hit == 1)
	begin
		HitCount = HitCount + 1;
		LRU_Update(Index,Data_Ways);
		if(MESI_STATES[Index][Data_Ways] == E)
			MESI_STATES[Index][Data_Ways] = M;
		else if(MESI_STATES[Index][Data_Ways] == S)
		begin
			MESI_STATES[Index][Data_Ways] = E;
			if(Mode == 1)
				$display("Write to L2 %d'h%h",Address_Bits,Address);
		end
	end
	else
	begin
		MissCount = MissCount + 1;
		Invalid = 0;
		for(int i = 0; i < Data_CacheWays; i++)
		begin	
			if(MESI_STATES[Index][i] == I)
			begin	
				Data_Ways = i;
				Invalid = 1;
			end
		end
		
		if(Invalid == 1)
		begin
			TAG[Index][Data_Ways] = Tag_Array;
			LRU_Update(Index,Data_Ways);
			MESI_STATES[Index][Data_Ways] = E;  
			if(Mode == 1)
				$display("Read for Ownership from L2 %d'h%h",Address_Bits,Address);
		end
		else
		begin
			for(int i = 0; i < Data_CacheWays; i++)
			begin
				if(LRU[Index][i] == '0)
				begin
					if( Mode == 1 && ( MESI_STATES[Index][i] == M))
					begin
						$display(" Write to L2 Cache %d'h%h", Address_Bits,Address);
					end
					Data_Ways = i;
				end
			end
			TAG[Index][Data_Ways] = Tag_Array;
			LRU_Update(Index,Data_Ways);
			MESI_STATES[Index][Data_Ways] = M;  
			if(Mode == 1)
				$display("Read for Ownership from L2 %d'h%h",Address_Bits,Address);
		end
	end				
endtask


//Task to Invalidate command from L2
task Invalid_CommandL2(logic [Index_Bits -1:0] Index, logic [Tag_Bits -1 :0] Tag_Array, logic Mode);
	Hit = 0;
	for(int i = 0; i < Data_CacheWays; i++)
	begin
		if(MESI_STATES[Index][i] != I)
			if(TAG[Index][i] == Tag_Array)
			begin
				Data_Ways = i;
				Hit = 1;
			end
	end
	
	if(Hit == 1)
	begin
		if(Mode == 1 && (MESI_STATES[Index][Data_Ways] == M))
		begin
			$display("Return data to L2 %d'h%h",Address_Bits,Address);
		end
		MESI_STATES[Index][Data_Ways] = I;
	end
endtask


//Task to Read Data from L2
task DatafromL2(logic [Index_Bits -1:0] Index, logic [Tag_Bits -1 :0] Tag_Array, logic Mode);
	Hit = 0;
	for(int i = 0; i < Data_CacheWays; i++)
	begin
		if(MESI_STATES[Index][i] != I)
			if(TAG[Index][i] == Tag_Array)
			begin
				Data_Ways = i;
				Hit = 1;
			end
	end
	
	if(Hit == 1)
	begin
		if(MESI_STATES[Index][Data_Ways] == E)
		begin
			MESI_STATES[Index][Data_Ways] = S;
			LRU_Update(Index,Data_Ways);
		end
		else if(MESI_STATES[Index][Data_Ways] == M)
		begin
			MESI_STATES[Index][Data_Ways] = I;
			if(Mode == 1)
				$display("Return data to L2 %d'h%h",Address_Bits,Address);
		end
		
	end
endtask

//Task to Reset all the States
task Reset();
	HitCount = 0;
	MissCount = 0;
	ReadCount = 0;
	WriteCount  = 0;
	for(int i = 0; i <= Sets -1 ; i++)
	begin	
		for(int j = 0; j <= Data_CacheWays -1 ; j++)
		begin
			MESI_STATES[i][j]  = I;
		end
	end
endtask

//Task to print the Contents and States of the Cache
task Print_Contents_States();
	$display("******Contents and States of the Data Cache*******");
	for(int i = 0; i < Sets; i++)
	begin
		for(int j = Data_CacheWays-1; j >= 0; j--)
		begin
			if(MESI_STATES[i][j] != I)
			begin
				if(!done)
				begin
					$display("|+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|");
					$display("|\t\t\tIndex = %d'h%h\t\t\t\t\t\t|", Index_Bits , i );
					$display("|+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|");
					$display("|\tWay No\t|  Tag_Address\t\t\t|  CACHE State\t\t|    LRU  \t|");
					$display("|+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|");				
					done = 1;
				end
				$display("|\t%3d\t|\t%2d'h%3h\t\t|  %s\t\t|\t%b\t|", (Data_CacheWays-1)- j,Tag_Bits,TAG[i][j],MESI_STATES[i][j],LRU[i][j]);
				$display("|+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|");
			end
		end
		done = 0;
	end

endtask

//Task to update LRU based on the Instruction 
task automatic LRU_Update(logic [Index_Bits - 1: 0] Index, ref logic [Data_SelectBits -1 : 0] Data_Ways);
	logic [Data_SelectBits -1: 0] Sub;
	Sub = LRU[Index][Data_Ways];
	for(int i = 0; i < Data_CacheWays; i++)
	begin
		if(LRU[Index][i] > Sub)
			LRU[Index][i] = LRU[Index][i] - 1;
		else
			LRU[Index][i] = LRU[Index][i];
	end
	LRU[Index][Data_Ways] = '1;
endtask
endmodule