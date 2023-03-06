module MESI(
input clk, rst,
input PrRd, PrWr, BusRd, BusRdx, Flush, BusUpgr							// PrRd = Processor Read, PrWr = Processor Write, BusRd = Bus Read, BusRdx = Bus Read Exclusive, Flush = Write cache line back, BusUpgr = BusUpgrade/ Invalidate
);

logic mesi_initial_cpu_req, mesi_initial_snooping, mesi_cpu_next, mesi_snoop_next; 

typedef enum bit[1:0] {M, E, S, I} transition_state;


 
if(tag_hit) 
begin
	if (cmd inside{cpu_cmd}) 
	begin: CPU_REQ
			case(mesi_intial_cpu_req)
				
				M:
				begin
					if(PrRd)
					begin
						mesi_cpu_next = M;
					end
					
					else if (PrWr)
					begin
						mesi_cpu_next = M;
					end
				end
				
				
				E:
				begin
					if (PrRd)
					begin
						mesi_cpu_next = E;
					end
					
					else if (PrWr)
					begin
						mesi_cpu_next = M;
					end
				end	
					
				S:
				begin
					if (PrRd)
					begin
						mesi_cpu_next = S;
					end
					
					else if (PrWr, BusUpgr)
					begin
						mesi_cpu_next = M;
	
	end
















end
