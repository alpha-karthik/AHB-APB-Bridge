t clk ;
  bit resetn ;
  
  //AHB Master Signals
  bit hselapbif;
  bit [31:0] haddr;
  bit [1:0] htrans;
  bit hwrite;
  wire hready;
  wire [1:0] hresp;
  bit [31:0] hwdata;
  wire [31:0] hrdata;
  
  // APB Slave signasl
  wire penable;
  wire psel;
  wire [31:0] paddr;
  wire pwrite;
  wire [31:0] pwdata;
  bit [31:0] prdata;
  
  // APB Interface
  task write_transfer_apb;
    @(penable)  begin
      if (pwrite)
        prdata <= pwdata;
      else
        prdata <= $random;
      
    end
  endtask
  always #5 clk = ~clk;
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
  end
  
  //AHB Write transfer
  task write_transfer_ahb;
    @(posedge clk) begin
      hselapbif <= 1'b1;
      htrans <= 2'b10;
      haddr <= 32'b10;
      hwrite <= 1'b1;
	end
    @(posedge clk) begin
      hwdata <= 32'd7;
      hselapbif <= 1'b0;
    end
  
  endtask
    
  
  
  // AHB-to-APB Bridge
  ahb_to_apb hp (clk,resetn, hselapbif, haddr,htrans, hwrite, hready, hresp, hwdata, hrdata, penable, psel, paddr, pwrite, pwdata, prdata);
  
  initial begin
    $monitor("Received_data = %0d ", prdata);
    #0 clk = 1'b0;
    #0 resetn = 1'b1;
    #1 resetn = 1'b0;
    @(posedge clk) resetn = 1'b1;
    fork 
      write_transfer_apb;
      write_transfer_ahb;
    join
    #100 $finish;
  end
  
endmodule

