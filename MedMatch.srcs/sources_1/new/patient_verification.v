
module patient_verification(
    input clk,
    input reset,
    input scan_valid,
    input [31:0] scanned_patient_id,
    input [31:0] registered_patient_id,
    output reg patient_verified,
    output reg patient_rejected
);

always @(posedge clk) begin
    if (reset) begin
        patient_verified <= 1'b0;
        patient_rejected <= 1'b0;
    end
    else if (scan_valid) begin
        if (scanned_patient_id == registered_patient_id) begin
            patient_verified <= 1'b1;
            patient_rejected <= 1'b0;
        end
        else begin
            patient_verified <= 1'b0;
            patient_rejected <= 1'b1;
        end
    end
end

endmodule
