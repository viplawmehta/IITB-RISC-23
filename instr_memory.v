 module instr_memory  
 (  
		input clk,  
      input[15:0]ins_mem_access_addr,  
      input ins_mem_read,  
      output[15:0]ins_mem_read_data  
 );  
 
      reg [15:0] ram [255:0];  

initial
begin
ram[0] = {15'b000000000000000};
ram[1] = {15'b000000000000001};
ram[2] = {15'b000000000000011};
end 
	//and more
      assign ins_mem_read_data = (ins_mem_read==1'b1) ? ram[ins_mem_access_addr]: 16'd0;   
 endmodule 
 
 
 