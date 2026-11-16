module mfrc522_spi #(
    parameter CLK_FREQ = 100000000,
    parameter SPI_FREQ = 1000000
)(
    input clk,
    input reset,
    input start,
    input read_mode,
    input [5:0] reg_addr,
    input [7:0] write_data,
    input miso,
    output reg [7:0] read_data,
    output reg busy,
    output reg done,
    output reg sck,
    output reg mosi,
    output reg cs_n
);

localparam HALF_PERIOD = CLK_FREQ / (2 * SPI_FREQ);

reg [15:0] tx_shift;
reg [7:0] rx_shift;
reg [3:0] bit_count;
reg [31:0] divider;
reg phase;

always @(posedge clk) begin
    if (reset) begin
        tx_shift <= 0;
        rx_shift <= 0;
        read_data <= 0;
        bit_count <= 0;
        divider <= 0;
        phase <= 0;
        busy <= 0;
        done <= 0;
        sck <= 0;
        mosi <= 0;
        cs_n <= 1;
    end
    else begin
        done <= 0;

        if (!busy) begin
            if (start) begin
                tx_shift <= {
                    read_mode,
                    reg_addr,
                    1'b0,
                    (read_mode ? 8'h00 : write_data)
                };
                rx_shift <= 0;
                bit_count <= 0;
                divider <= 0;
                phase <= 0;
                sck <= 0;
                mosi <= read_mode;
                cs_n <= 0;
                busy <= 1;
            end
        end
        else begin
            if (divider == HALF_PERIOD - 1) begin
                divider <= 0;

                if (!phase) begin
                    sck <= 1;
                    phase <= 1;

                    if (bit_count >= 8)
                        rx_shift <= {rx_shift[6:0], miso};
                end
                else begin
                    sck <= 0;
                    phase <= 0;

                    if (bit_count == 15) begin
                        read_data <= {rx_shift[6:0], miso};
                        cs_n <= 1;
                        busy <= 0;
                        done <= 1;
                        mosi <= 0;
                    end
                    else begin
                        bit_count <= bit_count + 1'b1;
                        tx_shift <= {tx_shift[14:0], 1'b0};
                        mosi <= tx_shift[14];
                    end
                end
            end
            else begin
                divider <= divider + 1'b1;
            end
        end
    end
end

endmodule