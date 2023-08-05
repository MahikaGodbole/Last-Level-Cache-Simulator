package Grp8_Pkg;
parameter Address_Bits = 32, Data_CacheWays = 8,  Instruction_CacheWays = 4, line_Size = 64, Sets = 2**14;
localparam Index_Bits = $clog2(Sets), Byte_Offsetbits = $clog2(line_Size), Data_SelectBits = $clog2(Data_CacheWays), Instruction_SelectBits = $clog2(Instruction_CacheWays);
localparam Tag_Bits = Address_Bits - (Byte_Offsetbits + Index_Bits);

typedef enum logic[1:0] { M  = 2'b00, E = 2'b01, S = 2'b10, I = 2'b11}MESI;

string Trace;
logic Mode, Hit, Invalid;
logic [3:0] n;
logic [Address_Bits - 1:0] Address;
logic [Index_Bits - 1 : 0] Index;
logic [Byte_Offsetbits - 1 : 0] Byte_Select;
logic [Tag_Bits - 1 : 0] Tag_Array;
logic [Data_SelectBits -1 : 0] Data_Ways;

int ptr, ptr_t, done;
endpackage
