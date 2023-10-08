const std = @import("std");
const utils = @import("./utils.zig");
const Allocator = std.mem.Allocator;

pub const Type = union(enum) { String: std.ArrayList(u8), Number: i64, Bool: bool, Keyword: []const u8, Function: Function };
pub const ASTNode = union(enum) {
    Expr: std.ArrayList(ASTNode),
    Single: Type,
};

pub const Function = struct {
    const Self = @This();
    parameter_names: std.ArrayList([]const u8),
    env: Env,
    body: *ASTNode,

    pub fn init(alloca: *Allocator, env: *Env, params: std.ArrayList([]const u8), body: *ASTNode) Function {
        return Function{ .env = Env.initWithEnv(alloca, env), .parameter_names = params, .body = body };
    }

    pub fn deinit(self: *Self) void {
        self.env.deinit();
        self.parameter_names.deinit();
    }
};

pub const Env = struct {
    const Self = @This();
    outer_env: ?*Env,
    env: std.StringArrayHashMap(ASTNode),

    pub fn init(alloca: *Allocator) Env {
        return Env{ .env = std.StringArrayHashMap(ASTNode).init(alloca.*), .outer_env = null };
    }

    pub fn initWithEnv(alloca: *Allocator, env: *Env) Env {
        return Env{ .env = std.StringArrayHashMap(ASTNode).init(alloca.*), .outer_env = env };
    }

    pub fn find(self: *Self, variable: []const u8) ?ASTNode {
        if (self.env.get(variable)) |node| {
            return node;
        } else if (self.outer_env) |outer| {
            return outer.*.find(variable);
        } else {
            return null;
        }
    }

    pub fn deinit(self: *Env) void {
        self.env.deinit();
    }
};
