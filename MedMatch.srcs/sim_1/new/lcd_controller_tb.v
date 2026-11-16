`timescale 1ns / 1ps

module lcd_controller_tb;

reg clk;
reg reset;
reg access_granted;
reg access_rejected;
reg [2:0] rejection_reason;

wire lcd_rs;
wire lcd_en;
wire [3:0] lcd_data;

integer enable_count;
integer errors;

lcd_controller #(
    .CLK_FREQ(1000000)
) DUT(
    .clk(clk),
    .reset(reset),
    .access_granted(access_granted),
    .access_rejected(access_rejected),
    .rejection_reason(rejection_reason),
    .lcd_rs(lcd_rs),
    .lcd_en(lcd_en),
    .lcd_data(lcd_data)
);

always #500 clk = ~clk;

always @(posedge lcd_en)
    enable_count = enable_count + 1;

initial begin
    clk = 0;
    reset = 1;
    access_granted = 0;
    access_rejected = 0;
    rejection_reason = 0;
    enable_count = 0;
    errors = 0;

    #50000;
    reset = 0;

    #1000000;
    access_granted = 1;

    #40000000;
    access_granted = 0;
    access_rejected = 1;
    rejection_reason = 3'b100;

    #40000000;

    if (enable_count > 10)
        $display("TEST 1 PASSED: LCD enable activity detected");
    else begin
        $display("TEST 1 FAILED: Insufficient LCD activity");
        errors = errors + 1;
    end

    if ((^lcd_data) !== 1'bx)
        $display("TEST 2 PASSED: LCD data output is valid");
    else begin
        $display("TEST 2 FAILED: LCD data contains unknown values");
        errors = errors + 1;
    end

    if (errors == 0)
        $display("LCD INTERFACE TESTS PASSED");
    else
        $display("LCD TESTS COMPLETED WITH %0d ERRORS", errors);

    $finish;
end

initial begin
    #100000000;
    $display("TEST FAILED: Simulation timeout");
    $finish;
end

endmodule