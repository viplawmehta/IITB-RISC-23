module main(
input clk,
output done
);
reg [15:0]r0;
reg [15:0]r1;
reg [15:0]r2;
reg [15:0]r3;
reg [15:0]r4;
reg [15:0]r5;
reg [15:0]r6;
reg [15:0]r7;
reg ins_mem_read;
reg[15:0]ins_mem_access_addr;
wire[15:0]ins_mem_read_data;

instr_memory  i1(clk,ins_mem_access_addr,ins_mem_read,ins_mem_read_data);
//fetch stage


always @(posedge clk) begin  
           if (ins_mem_read)  
                ins_mem_access_addr <= r0;  
      end
		
always @(posedge clk) begin  
          // if (ins_mem_read)
                ins_mem_read <= 1'b1;  
      end
		
		

// decode stage
	
	always @(posedge clk) begin 
		case (r0[15:11]) //r type instruction
			4'b0001:begin
						case(r0[2:0])
						000: begin //ADA:
								end
						001: begin //ADC:
						
								end
						010: begin //ADZ:
						
								end
						011: begin //AWC:
						
								end
						100: begin //ACA:
						
								end
						101: begin //ACC:
						
								end
						110: begin //ACZ:
						
								end
						111: begin //ACW:
						
								end
				endcase
		end

		4'b0000:begin //ADI:
		end
		4'b0010:begin //
						case(r0[2:0])
							000: begin //NDU:
							
									end
							010: begin //NDC:
							
									end
							001: begin //NDZ:
							
									end
							100: begin //NCU:
							
									end
							110: begin //NCC:
							
									end
							101: begin //NCZ:
							
									end
					
					endcase
		end
		4'b0011:begin //LLI:
		end
		4'b0100:begin //LW:
		end
		4'b0101:begin //SW:
		end
		4'b0110:begin //LM:
		end
		4'b0111:begin //SM:
		end
		4'b1000:begin //BEQ:BLT:
		end
		4'b1100:begin //JAL:
		end
		4'b1101:begin //JLR:
		end
		4'b1101:begin //JRI:
		end
	endcase
	end
//next stage
endmodule