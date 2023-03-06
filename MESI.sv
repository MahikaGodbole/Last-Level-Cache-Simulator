module MESI(
input clk, rst,
input PrRd, PrWr, BusRd, BusRdx, Flush, BusUpgr							// PrRd = Processor Read, PrWr = Processor Write, BusRd = Bus Read, BusRdx = Bus Read Exclusive, Flush = Write cache line back, BusUpgr = BusUpgrade/ Invalidate
);

logic mesi_initial_cpu_req, mesi_initial_snooping; 

typedef enum bit[1:0] {M, E, S, I} transition_state;


 
if(tag_hit) 
begin
	if (cmd inside{cpu_cmd}) 
	begin: CPU_REQ
		
	
	
	
	end
















end
