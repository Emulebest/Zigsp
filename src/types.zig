const std = @import("std");

pub const Type = union(enum) { String: std.ArrayList(u8), Number: i64, Bool: bool, Keyword: []const u8 };
pub const ASTNode = union(enum) {
    Expr: std.ArrayList(ASTNode),
    Single: Type,
};
