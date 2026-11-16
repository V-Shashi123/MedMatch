module alert_controller(
    input access_granted,
    input access_rejected,
    output reg green_led,
    output reg red_led,
    output reg buzzer
);

always @(*) begin
    if (access_granted) begin
        green_led = 1'b1;
        red_led = 1'b0;
        buzzer = 1'b0;
    end
    else if (access_rejected) begin
        green_led = 1'b0;
        red_led = 1'b1;
        buzzer = 1'b1;
    end
    else begin
        green_led = 1'b0;
        red_led = 1'b0;
        buzzer = 1'b0;
    end
end

endmodule