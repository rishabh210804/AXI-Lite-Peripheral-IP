// ============================================================================
// Module Name: axi_peripheral
// Description: AXI4-Lite Slave Peripheral IP with Register Map & Interrupts
// ============================================================================

module axi_peripheral #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)(
    // --- Clock and Reset ---
    input  wire                  s_axi_aclk,
    input  wire                  s_axi_aresetn,

    // --- Write Address Channel (AW) ---
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire [2:0]            s_axi_awprot,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,

    // --- Write Data Channel (W) ---
    input  wire [DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,

    // --- Write Response Channel (B) ---
    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,

    // --- Read Address Channel (AR) ---
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire [2:0]            s_axi_arprot,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,

    // --- Read Data Channel (R) ---
    output reg  [DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready,

    // --- External Interrupt Signal ---
    output wire                  irq_out
);

    // AXI Response Codes
    localparam RESP_OKAY   = 2'b00;
    localparam RESP_DECERR = 2'b11;

    // Internal Registers
    reg [DATA_WIDTH-1:0] ctrl_reg;      // Address 0x00
    reg [DATA_WIDTH-1:0] status_reg;    // Address 0x04
    reg [DATA_WIDTH-1:0] data_in_reg;   // Address 0x08
    reg [DATA_WIDTH-1:0] data_out_reg;  // Address 0x0C

    // Internal Latch Variables
    reg [ADDR_WIDTH-1:0] axi_awaddr_latched;
    reg [ADDR_WIDTH-1:0] axi_araddr_latched;

    // Peripheral Processing Logic (Bitwise Inversion Example)
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            data_out_reg <= 32'h0;
            status_reg   <= 32'h0;
        end else begin
            if (ctrl_reg[0]) begin
                data_out_reg  <= ~data_in_reg;
                status_reg[0] <= 1'b0;        // Busy = 0
                status_reg[2] <= 1'b1;        // Interrupt Pending = 1
            end else begin
                status_reg[0] <= 1'b0;
                status_reg[2] <= 1'b0;
            end
        end
    end

    // Active-High Interrupt Line
    assign irq_out = ctrl_reg[1] & status_reg[2];

    // --- Write Channel Logic (AW, W, B) ---
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready       <= 1'b0;
            s_axi_wready        <= 1'b0;
            s_axi_bvalid        <= 1'b0;
            s_axi_bresp         <= RESP_OKAY;
            axi_awaddr_latched  <= 4'b0000;
            ctrl_reg            <= 32'h0;
            data_in_reg         <= 32'h0;
        end else begin
            if (!s_axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                s_axi_awready       <= 1'b1;
                s_axi_wready        <= 1'b1;
                axi_awaddr_latched  <= s_axi_awaddr;
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end

            if (s_axi_awready && s_axi_wready && s_axi_awvalid && s_axi_wvalid) begin
                s_axi_bvalid <= 1'b1;
                case (axi_awaddr_latched)
                    4'h0: ctrl_reg    <= s_axi_wdata;
                    4'h8: data_in_reg <= s_axi_wdata;
                    default: s_axi_bresp <= RESP_DECERR;
                endcase
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                s_axi_bresp  <= RESP_OKAY;
            end
        end
    end

    // --- Read Channel Logic (AR, R) ---
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready      <= 1'b0;
            s_axi_rvalid       <= 1'b0;
            s_axi_rresp        <= RESP_OKAY;
            s_axi_rdata        <= 32'h0;
            axi_araddr_latched <= 4'b0000;
        end else begin
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready      <= 1'b1;
                axi_araddr_latched <= s_axi_araddr;
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_arready && s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                case (axi_araddr_latched)
                    4'h0: begin s_axi_rdata <= ctrl_reg;      s_axi_rresp <= RESP_OKAY; end
                    4'h4: begin s_axi_rdata <= status_reg;    s_axi_rresp <= RESP_OKAY; end
                    4'h8: begin s_axi_rdata <= data_in_reg;   s_axi_rresp <= RESP_OKAY; end
                    4'hC: begin s_axi_rdata <= data_out_reg;  s_axi_rresp <= RESP_OKAY; end
                    default: begin
                        s_axi_rdata <= 32'hDEADBEEF;
                        s_axi_rresp <= RESP_DECERR;
                    end
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule