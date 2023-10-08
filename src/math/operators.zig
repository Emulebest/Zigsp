const std = @import("std");
const types = @import("../types.zig");
const utils = @import("../utils.zig");

const math_operators = [_][]const u8{ "*", "+", "-", ">", "<", "=" };

pub fn isMathOperator(keyword: []const u8) bool {
    if (utils.findString(&math_operators, keyword)) |_| {
        return true;
    } else {
        return false;
    }
}

pub fn add(accum: i64, node: types.ASTNode) i64 {
    switch (node) {
        .Expr => {
            unreachable;
        },
        .Single => |val| {
            switch (val) {
                .Number => |num| {
                    return accum + num;
                },
                else => unreachable,
            }
        },
    }
}

pub fn substract(accum: i64, node: types.ASTNode) i64 {
    switch (node) {
        .Expr => {
            unreachable;
        },
        .Single => |val| {
            switch (val) {
                .Number => |num| {
                    return accum - num;
                },
                else => unreachable,
            }
        },
    }
}

pub fn greater(operand_a: types.ASTNode, operand_b: types.ASTNode) bool {
    if (operand_a.Single.Number > operand_b.Single.Number) {
        return true;
    }
    return false;
}

pub fn less(operand_a: types.ASTNode, operand_b: types.ASTNode) bool {
    if (operand_a.Single.Number < operand_b.Single.Number) {
        return true;
    }
    return false;
}

pub fn equal(operand_a: types.ASTNode, operand_b: types.ASTNode) bool {
    if (operand_a.Single.Number == operand_b.Single.Number) {
        return true;
    }
    return false;
}
