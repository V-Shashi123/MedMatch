module dose_tracker(
    input clk,
    input reset,
    input new_schedule,
    input dose_accepted,
    output reg dose_already_taken
);

always @(posedge clk) begin
    if (reset) begin
        dose_already_taken <= 1'b0;
    end
    else if (new_schedule) begin
        dose_already_taken <= 1'b0;
    end
    else if (dose_accepted) begin
        dose_already_taken <= 1'b1;
    end
end

endmodule