module ctrlBlock # (
	parameter FilterLength = 16,
	parameter DecimationK = 2
)
(
	input Rst_i,
	input Clk_i,
	
	input DataNd_i,
	
	output [3:0] DataAddrWr_o,
	output [3:0] DataAddr_o,
	output [3:0] CoeffAddr_o,
	output StartAcc_o,
	
	output DataValid_o
);

	reg [3:0] runNumber;
	reg [3:0] addrWr;
	reg [3:0] dataAddr;
	reg [3:0] coeffAddr;
	reg rdy;
	reg startAcc;
	
	always @ (posedge Clk_i or posedge Rst_i)
		if (Rst_i)
			begin
				runNumber <= 0;
				addrWr <= 0;
			end
		else if (DataNd_i)
			begin
				addrWr <= addrWr + 1;
				if (runNumber == DecimationK - 1)
					runNumber <= 0;
				else
					runNumber <= runNumber + 1;
			end
			
	parameter Idle = 0;
	parameter Work = 1;
	reg [3:0] state;
	always @ (posedge Rst_i or posedge Clk_i)
		if (Rst_i)
			begin
				state <= Idle;
				rdy <= 0;
				startAcc <= 0;
			end
		else
			case (state)
				Idle : begin
							coeffAddr <= 0;
							dataAddr <= addrWr;
							rdy <= 0;
							startAcc <= 0;
							if (DataNd_i && (runNumber == 0))
								begin
									startAcc <= 1;
									state <= Work;
								end
						end
				Work : begin
							startAcc <= 0;
							if (coeffAddr != FilterLength-1)
								begin
									dataAddr <= dataAddr - 1;
									coeffAddr <= coeffAddr + 1;
									if (coeffAddr != FilterLength-2)
										rdy <= 0;
									else
										rdy <= 1;
								end
							else
								begin
									rdy <= 0;
									if (DataNd_i && (runNumber == 0))
										begin
											state <= Work;
											dataAddr <= addrWr;
											coeffAddr <= 0;
											startAcc <= 1;
										end
									else
										state <= Idle;
								end
						end
				default : state <= Idle;
			endcase 
			
	reg [2:0] rdyShReg;
	always @ (posedge Rst_i or posedge Clk_i)
		if (Rst_i)
			rdyShReg <= 0;
		else
			rdyShReg <= {rdyShReg[1:0], rdy};
			
	reg [2:0] startAccShReg;
	always @ (posedge Rst_i or posedge Clk_i)
		if (Rst_i)
			startAccShReg <= 0;
		else
			startAccShReg <= {startAccShReg[1:0], startAcc};
			
	assign DataAddrWr_o = addrWr;
	assign DataAddr_o = dataAddr;
	assign CoeffAddr_o = coeffAddr;
	assign StartAcc_o = startAccShReg[1];
			
	assign DataValid_o = rdyShReg[2];

endmodule
