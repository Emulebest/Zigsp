pub const State = struct {
    const Self = @This();

    current_symbol: u32 = 0,
    initial_string: []const u8
};