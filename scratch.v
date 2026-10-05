assign foo = a ? (b | c) : (b ^ c);

always @(*) begin
    if (a) begin
        foo = b | c;
    end 
    else begin
        foo = b ^ c;
    end
end

always_comb begin
    if (a) begin
        foo = b | c;
    end
    else begin
        foo = b ^ c;
    end
end

always @(posedge clk) begin
    if (a) begin
        foo_r <= b | c;
    end
    else begin
        foo_r <= b ^ c;
    end
end

always_ff @(posedge clk) begin
    if (a) begin
        foo_r <= b | c;
    end
    else begin
        foo_r <= b ^ c;
    end
end

reg [1:0] b;
reg c;
wire [1:0] a;
wire clr

always @(posedge clk) begin
    if (clr) begin
        b <= 0;
        c <= 0;
    end
    else begin
        b <= a;
        c <= &b ^ c;
    end
end

logic [1:0] a, b;
logic c, clr;

always_ff (posedge clk) begin
    if (clr) begin
        b <= 0;
        c <= 0;
    end
    else begin
        b <= a;
        c <= &b ^ c;
    end
end

reg [1:0] Q;
wire [1:0] A;

always @(posedge clk) begin
    Q[0] <= ~|A;
    Q[1] <= &A;
end

logic [1:0] A, Q;

always_ff (posedge clk) begin
    Q[0] <= ~|A;
    Q[1] <= &A;
end

reg [3:0] acc;
wire [3:0] sum, in;
wire clear, overflow;

always @(posedge clk) begin
    if (clear) begin
        acc <= 0;
    end
    else begin
        acc <= sum;
    end
end

assign {overflow, sum} = acc + in;


logic [3:0] acc, in, sum;
logic clear, overflow;

always_ff @(posedge clk) begin
    if (clear) begin
        acc <= 0;
    end
    else begin
        acc <= sum;
    end
end

assign {overflow, sum} = acc + in;