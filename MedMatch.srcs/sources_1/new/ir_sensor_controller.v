module ir_sensor_controller(
    input clk,
    input reset,
    input ir_sensor_input,
    input access_granted,
    output reg medicine_removed
);

always @(posedge clk) begin
    if (reset) begin
        medicine_removed <= 1'b0;
    end
    else if (access_granted && !ir_sensor_input) begin
        medicine_removed <= 1'b1;
    end
    else if (ir_sensor_input) begin
        medicine_removed <= 1'b0;
    end
end

endmodule