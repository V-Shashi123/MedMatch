`timescale 1ns / 1ps

module mfrc522_spi_tb;

reg clk;
reg reset;
reg start;
reg read_mode;
reg [5:0] reg_addr;
reg [7:0] write_data;
reg miso;

wire [7:0] read_data;
wire busy;
wire done;
wire sck;
wire mosi;
wire cs_n;

integer clock_count;
integer errors;

mfrc522_spi #(
    .CLK_FREQ(100),
    .SPI_FREQ(10)
) DUT(
    .clk(clk),
    .reset(reset),
    .start(start),
    .read_mode(read_mode),
    .reg_addr(reg_addr),
    .write_data(write_data),
    .miso(miso),
    .read_data(read_data),
    .busy(busy),
    .done(done),
    .sck(sck),
    .mosi(mosi),
    .cs_n(cs_n)
);

always #5 clk = ~clk;

always @(posedge sck) begin
    if (!cs_n)
        clock_count = clock_count + 1;
end

initial begin
    clk = 0;
    reset = 1;
    start = 0;
    read_mode = 0;
    reg_addr = 6'h02;
    write_data = 8'hA5;
    miso = 1;
    clock_count = 0;
    errors = 0;

    #20;
    reset = 0;

    #10;
    start = 1;
    #10;
    start = 0;

    wait(done);
    #10;

    if (clock_count == 16)
        $display("TEST 1 PASSED: Exactly 16 SPI clock pulses");
    else begin
        $display("TEST 1 FAILED: Incorrect SPI clock count = %0d", clock_count);
        errors = errors + 1;
    end

    if (cs_n && !busy)
        $display("TEST 2 PASSED: Chip select released after transaction");
    else begin
        $display("TEST 2 FAILED: Chip select or busy signal incorrect");
        errors = errors + 1;
    end

    if (read_data == 8'hFF)
        $display("TEST 3 PASSED: SPI data reception working");
    else begin
        $display("TEST 3 FAILED: Received data = %h", read_data);
        errors = errors + 1;
    end

    if (errors == 0)
        $display("ALL SPI TESTS PASSED");
    else
        $display("SPI TESTING COMPLETED WITH %0d ERRORS", errors);

    $finish;
end

initial begin
    #10000;
    $display("TEST FAILED: Simulation timeout");
    $finish;
end

endmodule