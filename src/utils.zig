const std = @import("std");

pub fn findString(arr: []const []const u8, target: []const u8) ?usize {
    for (arr, 0..) |element, index| {
        if (std.mem.eql(u8, element, target)) {
            return index;
        }
    }
    return null;
}
