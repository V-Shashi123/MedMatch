module servo_controller #(
    parameter CLK_FREQ = 100000000
)(
    input clk,
    input reset,
    input access_granted,
    output reg servo_pwm
);

reg [20:0] counter;
reg [20:0] pulse_width;

localparam PERIOD = CLK_FREQ / 50;

always @(*) begin
    if (access_granted)
        pulse_width = CLK_FREQ / 1000 * 2;
    else
        pulse_width = CLK_FREQ / 1000;
end

always @(posedge clk) begin
    if (reset) begin
        counter <= 0;
        servo_pwm <= 0;
    end
    else begin
        if (counter >= PERIOD - 1)
            counter <= 0;
        else
            counter <= counter + 1;

        servo_pwm <= (counter < pulse_width);
    end
end

endmodule