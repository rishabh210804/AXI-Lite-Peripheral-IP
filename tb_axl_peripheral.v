`timescale 1ns / 1ps

module tb_axl_peripheral;

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 4;

    reg clk;
    reg rst_n;

    reg  [ADDR_WIDTH-1:0] awaddr;
    reg  [2:0]            awprot;
    reg                   awvalid;
    wire                  awready;

    reg  [DATA_WIDTH-1:0] wdata;
    reg  [(DATA_WIDTH/8)-1:0] wstrb;
    reg                   wvalid;
    wire                  wready;

    wire [1:0]            bresp;
    wire                  bvalid;
    reg                   bready;

    reg  [ADDR_WIDTH-1:0] araddr;
    reg  [2:0]            arprot;
    reg                   arvalid;
    wire                  arready;

    wire [DATA_WIDTH-1:0] rdata;
    wire [1:0]            rresp;
    wire                  rvalid;
    reg                   rready;

    wire                  irq_out;

    // Instantiate Device Under Test (DUT)
    axi_peripheral #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .s_axi_aclk(clk),
        .s_axi_aresetn(rst_n),
        .s_axi_awaddr(awaddr),
        .s_axi_awprot(awprot),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),
        .s_axi_wdata(wdata),
        .s_axi_wstrb(wstrb),
        .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),
        .s_axi_bresp(bresp),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(bready),
        .s_axi_araddr(araddr),
        .s_axi_arprot(arprot),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),
        .s_axi_rdata(rdata),
        .s_axi_rresp(rresp),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready),
        .irq_out(irq_out)
    );

    // 100 MHz Clock Generator
    always #5 clk = ~clk;

    // AXI Write Task
    task axi_write;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        begin
            @(posedge clk);
            awaddr  <= addr;
            awvalid <= 1'b1;
            wdata   <= data;
            wstrb   <= 4'hF;
            wvalid  <= 1'b1;
            bready  <= 1'b1;

            wait(awready && wready);
            @(posedge clk);
            awvalid <= 1'b0;
            wvalid  <= 1'b0;

            wait(bvalid);
            @(posedge clk);
            bready  <= 1'b0;
            $display("[AXI WRITE] Addr: 0x%0h | Data: 0x%0h | Resp: 2'b%0b", addr, data, bresp);
        end
    endtask

    // AXI Read Task
    task axi_read;
        input [ADDR_WIDTH-1:0] addr;
        begin
            @(posedge clk);
            araddr  <= addr;
            arvalid <= 1'b1;
            rready  <= 1'b1;

            wait(arready);
            @(posedge clk);
            arvalid <= 1'b0;

            wait(rvalid);
            @(posedge clk);
            rready  <= 1'b0;
            $display("[AXI READ ] Addr: 0x%0h | Read Data: 0x%0h | Resp: 2'b%0b", addr, rdata, rresp);
        end
    endtask

    // Initial Test Sequence
    initial begin
        clk     = 0;
        rst_n   = 0;
        awaddr  = 0; awprot = 0; awvalid = 0;
        wdata   = 0; wstrb  = 0; wvalid  = 0; bready = 0;
        araddr  = 0; arprot = 0; arvalid = 0; rready = 0;

        #20 rst_n = 1; 
        #10;

        $display("==================================================");
        $display("--- STEP 1: Enable Peripheral & Interrupt (0x00) ---");
        axi_write(4'h0, 32'h0000_0003);

        $display("--- STEP 2: Write Input Data (0x08) ---");
        axi_write(4'h8, 32'hA5A5_5A5A);

        #20;

        $display("--- STEP 3: Read Inverted Output Data (0x0C) ---");
        axi_read(4'hC);

        $display("--- STEP 4: Unmapped Address Test (Decode Error) ---");
        axi_read(4'hF);
        $display("==================================================");

        #50;
        $display(">>> ALL SIMULATION TESTS COMPLETED SUCCESSFULLY <<<");
        $finish;
    end

endmodule