hb_to_apb (
  // AHB Interface signals
  
  // Global signals
  input HCLK, 
  input HRESETn,
  
  //Address and Control inputs
  input HSELAPBif,
  input [31:0] HADDR,
  input [1:0] HTRANS,
  input HWRITE,
  //input HREADYin, // from APB slave
  output reg HREADYout, // TO AHB Master
  output [1:0] HRESP,
  
  //Write and Read Data Buses
  input [31:0] HWDATA ,
  output reg [31:0] HRDATA ,
  
  // APB Interface signals
  output reg PENABLE,
  output reg PSEL,
  output reg [31:0] PADDR,
  output reg PWRITE,
  output reg [31:0] PWDATA,
  input [31:0] PRDATA
);
  // Bridge FSM States
  parameter IDLE 	= 3'd0,
  			WWAIT	= 3'D1,
  			READ	= 3'D2,
  			WRITE  	= 3'D3,
  			WRITEP	= 3'D4,
  			WENABLEP= 3'D5,
  			WENABLE	= 3'D6,
  			RENABLE	= 3'D7;
  
  reg [2:0] state, nstate;
  reg valid, Hwrite;
  reg [31:0] TEMP_HADDR, TEMP_HWDATA;
  // AHB Slave bus interface
  // This block determines valid transfer detection and storing the address and control registers
  always @(*)
    begin
      if (HSELAPBif	== 1'b1 & HTRANS[1]==1'B1)
        valid = 1'b1;
      else
        valid = 1'b0;
    end
  
  // The below block correspons to the state machine transistion
  always @(posedge HCLK,negedge HRESETn)
    begin
      if (~HRESETn) begin
        state <= IDLE;
      end
      else begin
        state <= nstate;
      end
    end
  // Combinational logic for the state transistion and output signals
  always @(*) begin
    case(state)
      IDLE 	:	begin
        PSEL 		= 1'b0;
        PENABLE		= 1'B0;
        HREADYout	= 1'B1;
        if (valid == 1'b0)
          nstate <= IDLE;
        else if (valid == 1'b1 && HWRITE == 1'b0)
          nstate <= READ;
        else
          nstate <= WWAIT;
      end
      READ	:	begin
        PSEL 	= 1'B1;
        PADDR	= HADDR;
        PWRITE	= 1'B0;
        PENABLE = 1'B0;
        HREADYout = 1'b0;
        nstate = RENABLE;
      end
      RENABLE	:	begin
        PENABLE = 1'B1;
        HRDATA  = PRDATA;
        HREADYout  = 1'B1;
        if (valid == 1'b1 & HWRITE == 1'b0)
          nstate = READ;
        else if (valid == 1'b1 & HWRITE == 1'B1)
          nstate = WWAIT;
        else
          nstate = IDLE;
      end
      WWAIT		:	begin
        PSEL	= 1'b1;
        TEMP_HADDR = HADDR;
        Hwrite	= HWRITE;
        if (valid == 1'b0)
          nstate = WRITE;
        else 
          nstate = WRITEP;
      end
      WRITE		:	begin
        PSEL	=	1'b1;
        PADDR	=	TEMP_HADDR;
        PWDATA  = 	HWDATA;
        PWRITE	= 1'B1;
        HREADYout=1'B0;
        if (valid == 1'b0)
          nstate = WENABLE;
        else 
          nstate = WENABLEP;
      end
      WRITEP	:	begin
        PSEL	=	1'B1;
        PADDR	= TEMP_HADDR;
        PWDATA	=	HWDATA;
        PWRITE = 1'B1;
        HREADYout	= 1'b0;
        TEMP_HADDR	=	HADDR;
        Hwrite	= HWRITE;
        nstate = WENABLEP;
      end
      WENABLE	:	begin
        PENABLE	= 1'b1;
        HREADYout = 1'B1;
        if (valid == 1'b1 & HWRITE == 1'b0)
          nstate = READ;
        else if (valid == 1'b1 & HWRITE == 1'B1)
          nstate = WWAIT;
        else
          nstate = IDLE;
      end
      WENABLEP	:	begin
        PENABLE = 1'B1;
        HREADYout  = 1'B1;
        if (valid == 1'b0 && Hwrite == 1'B1)
          nstate = WRITE;
        else if (valid== 1'b1 && Hwrite == 1'b1)
          nstate = WRITEP;
        else 
          nstate = READ;
      end
    endcase
  end
  assign HRESP = 2'B0;
endmodule
  
