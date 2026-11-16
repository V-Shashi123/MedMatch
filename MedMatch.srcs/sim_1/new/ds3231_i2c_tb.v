`timescale 1ns / 1ps

module ds3231_i2c_tb;

reg clk;
reg reset;
reg start;

tri1 scl;
tri1 sda;

wire busy;
wire done;
wire ack_error;

wire [7:0] seconds_bcd;
wire [7:0] minutes_bcd;
wire [7:0] hours_bcd;
wire [7:0] day_bcd;
wire [7:0] date_bcd;
wire [7:0] month_bcd;
wire [7:0] year_bcd;

integer errors;

ds3231_i2c #(
    .CLK_FREQ(100),
    .I2C_FREQ(10)
) DUT (
    .clk(clk),
    .reset(reset),
    .start(start),
    .scl(scl),
    .sda(sda),
    .busy(busy),
    .done(done),
    .ack_error(ack_error),
    .seconds_bcd(seconds_bcd),
    .minutes_bcd(minutes_bcd),
    .hours_bcd(hours_bcd),
    .day_bcd(day_bcd),
    .date_bcd(date_bcd),
    .month_bcd(month_bcd),
    .year_bcd(year_bcd)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    reset = 1;
    start = 0;
    errors = 0;

    #30;
    reset = 0;

    #30;
    start = 1;

    #20;
    start = 0;

    wait(done);

    #1;

    if (ack_error) begin
        $display("TEST 1 PASSED: Missing RTC acknowledgement detected");
    end
    else begin
        $display("TEST 1 FAILED: Expected acknowledgement error");
        errors = errors + 1;
    end

    if (!busy) begin
        $display("TEST 2 PASSED: Controller exited busy state");
    end
    else begin
        $display("TEST 2 FAILED: Controller remained busy");
        errors = errors + 1;
    end

    if (done) begin
        $display("TEST 3 PASSED: STOP operation completed");
    end
    else begin
        $display("TEST 3 FAILED: STOP operation did not complete");
        errors = errors + 1;
    end

    if (errors == 0)
        $display("ALL RTC NACK TESTS PASSED");
    else
        $display("RTC TEST COMPLETED WITH %0d ERRORS", errors);

    $finish;
end

initial begin
    #1000000;

    if (!done) begin
        $display("TEST FAILED: Simulation timeout");
        $finish;
    end
end

endmodule