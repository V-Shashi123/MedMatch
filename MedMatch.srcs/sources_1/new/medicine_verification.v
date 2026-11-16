module medicine_verification(
    input clk,
    input reset,
    input verify_enable,
    input [15:0] scanned_medicine_id,
    input [15:0] prescribed_medicine_id,
    output reg medicine_valid,
    output reg medicine_invalid
);

always @(posedge clk) begin
    if (reset) begin
        medicine_valid <= 1'b0;
        medicine_invalid <= 1'b0;
    end
    else if (verify_enable) begin
        if (scanned_medicine_id == prescribed_medicine_id) begin
            medicine_valid <= 1'b1;
            medicine_invalid <= 1'b0;
        end
        else begin
            medicine_valid <= 1'b0;
            medicine_invalid <= 1'b1;
        end
    end
end

endmodule