`timescale 1ns / 1ps

module ds3231_i2c #(
    parameter CLK_FREQ = 100000000,
    parameter I2C_FREQ = 100000
)(
    input clk,
    input reset,
    input start,
    inout wire scl,
    inout wire sda,
    output reg busy,
    output reg done,
    output reg ack_error,
    output reg [7:0] seconds_bcd,
    output reg [7:0] minutes_bcd,
    output reg [7:0] hours_bcd,
    output reg [7:0] day_bcd,
    output reg [7:0] date_bcd,
    output reg [7:0] month_bcd,
    output reg [7:0] year_bcd
);

localparam HALF_PERIOD = CLK_FREQ / (2 * I2C_FREQ);

localparam IDLE = 0;
localparam START_A = 1;
localparam START_B = 2;
localparam TX_SETUP = 3;
localparam TX_HIGH = 4;
localparam TX_LOW = 5;
localparam TX_ACK_SETUP = 6;
localparam TX_ACK_HIGH = 7;
localparam TX_ACK_LOW = 8;
localparam RESTART_A = 9;
localparam RESTART_B = 10;
localparam RESTART_C = 11;
localparam RESTART_D = 12;
localparam RX_SETUP = 13;
localparam RX_HIGH = 14;
localparam RX_LOW = 15;
localparam RX_FINAL_LOW = 16;
localparam RX_ACK_SETUP = 17;
localparam RX_ACK_HIGH = 18;
localparam RX_ACK_LOW = 19;
localparam STOP_SETUP = 20;
localparam STOP_HIGH = 21;
localparam STOP_RELEASE = 22;

reg [4:0] state;
reg [31:0] divider;
reg [7:0] tx_byte;
reg [7:0] rx_shift;
reg [2:0] bit_index;
reg [2:0] byte_index;
reg [1:0] tx_phase;
reg scl_drive_low;
reg sda_drive_low;
reg start_d;
reg start_pending;

wire sda_in;

assign sda = sda_drive_low ? 1'b0 : 1'bz;
assign scl = scl_drive_low ? 1'b0 : 1'bz;

assign sda_in = sda;

always @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
        divider <= 0;
        tx_byte <= 0;
        rx_shift <= 0;
        bit_index <= 0;
        byte_index <= 0;
        tx_phase <= 0;
        scl_drive_low <= 0;
        sda_drive_low <= 0;
        start_d <= 0;
        start_pending <= 0;
        busy <= 0;
        done <= 0;
        ack_error <= 0;
        seconds_bcd <= 0;
        minutes_bcd <= 0;
        hours_bcd <= 0;
        day_bcd <= 0;
        date_bcd <= 0;
        month_bcd <= 0;
        year_bcd <= 0;
    end
    else begin
        done <= 0;
        start_d <= start;

        if (start && !start_d)
            start_pending <= 1;

        if (divider >= HALF_PERIOD - 1) begin
            divider <= 0;

            case (state)

                IDLE: begin
                    scl_drive_low <= 0;
                    sda_drive_low <= 0;
                    busy <= 0;

                    if (start_pending) begin
                        start_pending <= 0;
                        busy <= 1;
                        ack_error <= 0;
                        tx_phase <= 0;
                        tx_byte <= 8'hD0;
                        bit_index <= 0;
                        state <= START_A;
                    end
                end

                START_A: begin
                    scl_drive_low <= 0;
                    sda_drive_low <= 1;
                    state <= START_B;
                end

                START_B: begin
                    scl_drive_low <= 1;
                    sda_drive_low <= 1;
                    state <= TX_SETUP;
                end

                TX_SETUP: begin
                    scl_drive_low <= 1;
                    sda_drive_low <= ~tx_byte[7];
                    state <= TX_HIGH;
                end

                TX_HIGH: begin
                    scl_drive_low <= 0;
                    state <= TX_LOW;
                end

                TX_LOW: begin
                    scl_drive_low <= 1;

                    if (bit_index == 7) begin
                        state <= TX_ACK_SETUP;
                    end
                    else begin
                        bit_index <= bit_index + 1;
                        tx_byte <= {tx_byte[6:0], 1'b0};
                        state <= TX_SETUP;
                    end
                end

                TX_ACK_SETUP: begin
                    scl_drive_low <= 1;
                    sda_drive_low <= 0;
                    state <= TX_ACK_HIGH;
                end

                TX_ACK_HIGH: begin
                    scl_drive_low <= 0;

                    if (sda_in != 1'b0) begin
                        ack_error <= 1;
                        state <= STOP_SETUP;
                    end
                    else begin
                        state <= TX_ACK_LOW;
                    end
                end

                TX_ACK_LOW: begin
                    scl_drive_low <= 1;

                    if (tx_phase == 0) begin
                        tx_phase <= 1;
                        tx_byte <= 8'h00;
                        bit_index <= 0;
                        state <= TX_SETUP;
                    end
                    else if (tx_phase == 1) begin
                        tx_phase <= 2;
                        state <= RESTART_A;
                    end
                    else begin
                        byte_index <= 0;
                        bit_index <= 0;
                        rx_shift <= 0;
                        state <= RX_SETUP;
                    end
                end

                RESTART_A: begin
                    scl_drive_low <= 1;
                    sda_drive_low <= 0;
                    state <= RESTART_B;
                end

                RESTART_B: begin
                    scl_drive_low <= 0;
                    sda_drive_low <= 0;
                    state <= RESTART_C;
                end

                RESTART_C: begin
                    scl_drive_low <= 0;
                    sda_drive_low <= 1;
                    tx_byte <= 8'hD1;
                    state <= RESTART_D;
                end

                RESTART_D: begin
                    scl_drive_low <= 1;
                    sda_drive_low <= 1;
                    bit_index <= 0;
                    state <= TX_SETUP;
                end

                RX_SETUP: begin
                    scl_drive_low <= 1;
                    sda_drive_low <= 0;
                    state <= RX_HIGH;
                end

                RX_HIGH: begin
                    scl_drive_low <= 0;
                    rx_shift <= {rx_shift[6:0], sda_in};

                    if (bit_index == 7)
                        state <= RX_FINAL_LOW;
                    else
                        state <= RX_LOW;
                end

                RX_LOW: begin
                    scl_drive_low <= 1;
                    bit_index <= bit_index + 1;
                    state <= RX_SETUP;
                end

                RX_FINAL_LOW: begin
                    scl_drive_low <= 1;

                    case (byte_index)
                        0: seconds_bcd <= rx_shift;
                        1: minutes_bcd <= rx_shift;
                        2: hours_bcd <= rx_shift;
                        3: day_bcd <= rx_shift;
                        4: date_bcd <= rx_shift;
                        5: month_bcd <= rx_shift;
                        6: year_bcd <= rx_shift;
                    endcase

                    state <= RX_ACK_SETUP;
                end

                RX_ACK_SETUP: begin
                    scl_drive_low <= 1;
                    sda_drive_low <= (byte_index == 6) ? 0 : 1;
                    state <= RX_ACK_HIGH;
                end

                RX_ACK_HIGH: begin
                    scl_drive_low <= 0;
                    state <= RX_ACK_LOW;
                end

                RX_ACK_LOW: begin
                    scl_drive_low <= 1;

                    if (byte_index == 6) begin
                        state <= STOP_SETUP;
                    end
                    else begin
                        byte_index <= byte_index + 1;
                        bit_index <= 0;
                        rx_shift <= 0;
                        state <= RX_SETUP;
                    end
                end

                STOP_SETUP: begin
                    scl_drive_low <= 1;
                    sda_drive_low <= 1;
                    state <= STOP_HIGH;
                end

                STOP_HIGH: begin
                    scl_drive_low <= 0;
                    sda_drive_low <= 1;
                    state <= STOP_RELEASE;
                end

                STOP_RELEASE: begin
                    scl_drive_low <= 0;
                    sda_drive_low <= 0;
                    busy <= 0;
                    done <= 1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                    scl_drive_low <= 0;
                    sda_drive_low <= 0;
                    busy <= 0;
                end

            endcase
        end
        else begin
            divider <= divider + 1;
        end
    end
end

endmodule