module schedule_controller(
    input clk,
    input reset,
    input check_enable,
    input [4:0] current_hour,
    input [5:0] current_minute,
    input [4:0] scheduled_hour,
    input [5:0] scheduled_minute,
    output reg time_valid,
    output reg early_dose,
    output reg late_dose
);

always @(posedge clk) begin
    if (reset) begin
        time_valid <= 1'b0;
        early_dose <= 1'b0;
        late_dose <= 1'b0;
    end
    else if (check_enable) begin
        if ((current_hour == scheduled_hour) &&
            (current_minute == scheduled_minute)) begin
            time_valid <= 1'b1;
            early_dose <= 1'b0;
            late_dose <= 1'b0;
        end
        else if ((current_hour < scheduled_hour) ||
                ((current_hour == scheduled_hour) &&
                 (current_minute < scheduled_minute))) begin
            time_valid <= 1'b0;
            early_dose <= 1'b1;
            late_dose <= 1'b0;
        end
        else begin
            time_valid <= 1'b0;
            early_dose <= 1'b0;
            late_dose <= 1'b1;
        end
    end
end

endmodule