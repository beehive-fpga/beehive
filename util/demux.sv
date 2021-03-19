module demux #(
     parameter NUM_OUTPUTS = -1
    ,parameter NUM_LOG_OUTPUTS = $clog2(NUM_OUTPUTS)
    ,parameter INPUT_WIDTH = -1
)(
     input  logic   [NUM_LOG_OUTPUTS-1:0]               input_sel
    ,input  logic                    [INPUT_WIDTH-1:0]  data_input
    ,output logic   [NUM_OUTPUTS-1:0][INPUT_WIDTH-1:0]  data_outputs
);

    genvar i;
    generate
        for (i = 0; i < NUM_OUTPUTS; i = i + 1) begin
            always_comb begin
                data_outputs[i] = '0;
                if (input_sel == i) begin
                    data_outputs[i] = data_input;
                end
                else begin
                    data_outputs[i] = '0;
                end
            end
        end
    endgenerate
endmodule
