const std = @import("std");
const types = @import("types.zig");
const math = @import("math/operators.zig");
const utils = @import("utils.zig");

pub const std_options = struct {
    pub const log_level = .info;
};

// const test_string = "(begin (define r 10) (* pi (* r r)))";
const shorter_test_string = "(begin (define r (lambda (a b) (+ a b))) (define f (lambda (c d) (r c d))) (f 11 10))";
const Allocator = std.mem.Allocator;

pub const SyntaxErrors = error{UnexpectedTokenError};

pub const Interpreter = struct {
    const Self = @This();

    const keywords = [_][]const u8{ "begin", "define", "*", "+", "-", "if", ">", "<", "=", "lambda" };

    allocator: *Allocator,
    token_set: ?*types.ASTNode,
    parsed_string: ?std.ArrayList(std.ArrayList(u8)),
    env: types.Env,

    pub fn init(alloca: *Allocator) Interpreter {
        return Interpreter{ .allocator = alloca, .token_set = null, .parsed_string = null, .env = types.Env.init(alloca) };
    }

    fn storeParsedInput(self: *Self, input: std.ArrayList(std.ArrayList(u8))) !void {
        var stored_string = try std.ArrayList(std.ArrayList(u8)).initCapacity(self.allocator.*, input.items.len);
        for (input.items) |substring| {
            var raw_substring = try substring.clone();
            try stored_string.append(raw_substring);
        }
        self.parsed_string = stored_string;
    }

    pub fn parse(self: *Self, input_string: []const u8) !std.ArrayList(std.ArrayList(u8)) {
        var result_list = std.ArrayList(std.ArrayList(u8)).init(self.allocator.*);
        var string_buffer = std.ArrayList(u8).init(self.allocator.*);
        defer string_buffer.deinit();
        for (input_string) |character| {
            if (character == '(') {
                try finalizeWord(&string_buffer, &result_list);
                var opening_bracket = std.ArrayList(u8).init(self.allocator.*);
                try opening_bracket.append('(');
                try result_list.append(opening_bracket);

                continue;
            } else if (character == ')') {
                try finalizeWord(&string_buffer, &result_list);
                var closing_bracket = std.ArrayList(u8).init(self.allocator.*);
                try closing_bracket.append(')');
                try result_list.append(closing_bracket);

                continue;
            } else if (character == ' ') {
                try finalizeWord(&string_buffer, &result_list);
            } else {
                try string_buffer.append(character);
            }
        }
        try self.storeParsedInput(result_list);
        return result_list;
    }

    fn deinitAst(self: *Self, node: *types.ASTNode) void {
        switch (node.*) {
            .Expr => |expr| {
                std.log.debug("Processing Expression \n", .{});
                defer expr.deinit();
                for (expr.items) |*t| {
                    self.deinitAst(t);
                }
            },
            .Single => |*item| {
                switch (item.*) {
                    .String => |*string| {
                        if (self.env.find(string.items)) |value| {
                            var copy = value;
                            switch (copy.Single) {
                                .Function => |*f| {
                                    std.log.debug("Deiniting Function\n", .{});
                                    f.deinit();
                                },
                                else => {},
                            }
                        }
                        std.log.debug("Deiniting String: {s}\n", .{item.String.items});
                        string.deinit();
                    },
                    else => {},
                }
            },
        }
    }

    pub fn deinit(self: *Self) void {
        if (self.token_set) |*value| {
            defer self.allocator.destroy(value.*);
            self.deinitAst(value.*);
        }
        if (self.parsed_string) |string| {
            defer string.deinit();
            for (string.items) |sub_string| {
                sub_string.deinit();
            }
        }
        self.env.deinit();
    }

    fn finalizeWord(string_collector: *std.ArrayList(u8), outer_list: *std.ArrayList(std.ArrayList(u8))) !void {
        if (!std.mem.eql(u8, string_collector.items, "")) {
            try outer_list.append(try string_collector.clone());
            string_collector.clearRetainingCapacity();
        }
    }

    // Consumes the input string
    pub fn tokenize(self: *Self, parsed_input: *std.ArrayList(std.ArrayList(u8))) !*types.ASTNode {
        defer parsed_input.deinit();
        var token_set = try moveToHeap(self.allocator, try self._tokenize(parsed_input));
        self.token_set = token_set;
        return token_set;
    }

    fn _tokenize(self: *Self, parsed_input: *std.ArrayList(std.ArrayList(u8))) !types.ASTNode {
        var token: std.ArrayList(u8) = parsed_input.orderedRemove(0);
        if (std.mem.eql(u8, token.items, "(")) {
            std.log.debug("Open bracket encountered \n", .{});
            defer token.deinit();
            var local_node = types.ASTNode{ .Expr = std.ArrayList(types.ASTNode).init(self.allocator.*) };
            while (!std.mem.eql(u8, parsed_input.items[0].items, ")")) {
                std.log.debug("While loop iteration \n", .{});
                var item_to_add = try self._tokenize(parsed_input);
                try local_node.Expr.append(item_to_add);
            }
            var closing_bracket = parsed_input.orderedRemove(0);
            defer closing_bracket.deinit();
            return local_node;
        } else if (std.mem.eql(u8, token.items, ")")) {
            // TODO: This is definitely not unreachable but a Syntax Error
            return SyntaxErrors.UnexpectedTokenError;
        } else {
            var item = types.ASTNode{ .Single = try Interpreter.atomize(token) };
            std.log.debug("Single node item encountered \n", .{});
            return item;
        }
    }

    fn atomize(item: std.ArrayList(u8)) !types.Type {
        defer item.deinit();
        if (std.fmt.parseInt(i64, item.items, 10)) |value| {
            return types.Type{ .Number = value };
        } else |err| {
            _ = err catch {};
        }
        if (std.mem.eql(u8, item.items, "true")) {
            return types.Type{ .Bool = true };
        }
        if (std.mem.eql(u8, item.items, "false")) {
            return types.Type{ .Bool = false };
        }
        if (utils.findString(&keywords, item.items)) |index| {
            return types.Type{ .Keyword = keywords[index] };
        }
        return types.Type{ .String = try item.clone() };
    }

    pub fn _printAst(self: Self, node: types.ASTNode) void {
        switch (node) {
            .Expr => |expr| {
                std.log.debug("Processing Expression \n", .{});
                for (expr.items) |t| {
                    self._printAst(t);
                }
            },
            .Single => |item| {
                Interpreter.printAtom(item);
            },
        }
    }

    fn printAtom(atom: types.Type) void {
        switch (atom) {
            .Bool => |b| {
                std.log.info("Processing Bool Token: {}\n", .{b});
            },
            .Keyword => |k| {
                std.log.info("Processing Keyword Token: {s}\n", .{k});
            },
            .Number => |n| {
                std.log.info("Processing Number Token: {}\n", .{n});
            },
            .String => |s| {
                std.log.info("Processing String Token: {s}\n", .{s.items});
            },
            .Function => |_| {
                std.log.info("Processing Function\n", .{});
            },
        }
    }

    pub fn printAst(self: Self) void {
        self._printAst(self.token_set.?.*);
    }

    // TODO: Zig 0.11.0 doesn't support inferred errors on mutual recursion, need to revisit this
    // Issue tracker: https://github.com/ziglang/zig/issues/2971
    // pub fn processMathOperator(self: *Self, keyword: []const u8, expr: std.ArrayList(types.ASTNode)) !types.ASTNode {
    //     if (std.mem.eql(u8, keyword, "+")) {
    //         var accum = @as(i64, 0);
    //         for (expr.items[1..expr.items.len]) |*exp| {
    //             accum = math.add(accum, try self._eval(exp));
    //         }
    //         return types.ASTNode{ .Single = types.Type{ .Number = accum } };
    //     } else if (std.mem.eql(u8, keyword, "-")) {
    //         var accum = expr.items[1].Single.Number;
    //         for (expr.items[1..expr.items.len]) |*exp| {
    //             accum = math.substract(accum, try self._eval(exp));
    //         }
    //         return types.ASTNode{ .Single = types.Type{ .Number = accum } };
    //     } else {
    //         unreachable;
    //     }
    // }

    pub fn _eval(self: *Self, ast: *types.ASTNode, env: *types.Env) !types.ASTNode {
        switch (ast.*) {
            .Expr => |expr| {
                switch (expr.items[0].Single) {
                    .String => {
                        var function_token = try self._eval(&expr.items[0], env);
                        var function = function_token.Single.Function;
                        defer function.env.deinit();
                        for (function.parameter_names.items, 1..) |param, index| {
                            try function.env.env.put(param, try self._eval(&expr.items[index], env));
                        }

                        return try self._eval(function.body, &function.env);
                    },
                    .Keyword => |keyword| {
                        if (std.mem.eql(u8, keyword, "define")) {
                            var set_value = try self._eval(&expr.items[2], env);
                            try env.env.put(expr.items[1].Single.String.items, set_value);
                            return set_value;
                        } else if (std.mem.eql(u8, keyword, "begin")) {
                            for (expr.items[1 .. expr.items.len - 1]) |*exp| {
                                _ = try self._eval(exp, env);
                            }
                            var last = expr.getLast();
                            return self._eval(&last, env);
                        } else if (math.isMathOperator(keyword)) {
                            if (std.mem.eql(u8, keyword, "+")) {
                                var accum = @as(i64, 0);
                                for (expr.items[1..expr.items.len]) |*exp| {
                                    var calc = try self._eval(exp, env);
                                    accum = math.add(accum, calc);
                                }
                                return types.ASTNode{ .Single = types.Type{ .Number = accum } };
                            } else if (std.mem.eql(u8, keyword, "-")) {
                                var accum = expr.items[1].Single.Number;
                                for (expr.items[2..expr.items.len]) |*exp| {
                                    accum = math.substract(accum, try self._eval(exp, env));
                                }
                                return types.ASTNode{ .Single = types.Type{ .Number = accum } };
                            } else if (std.mem.eql(u8, keyword, ">")) {
                                var result = math.greater(try self._eval(&expr.items[1], env), try self._eval(&expr.items[2], env));
                                return types.ASTNode{ .Single = types.Type{ .Bool = result } };
                            } else if (std.mem.eql(u8, keyword, "<")) {
                                var result = math.less(try self._eval(&expr.items[1], env), try self._eval(&expr.items[2], env));
                                return types.ASTNode{ .Single = types.Type{ .Bool = result } };
                            } else if (std.mem.eql(u8, keyword, "=")) {
                                var result = math.equal(try self._eval(&expr.items[1], env), try self._eval(&expr.items[2], env));
                                return types.ASTNode{ .Single = types.Type{ .Bool = result } };
                            } else {
                                unreachable;
                            }
                        } else if (std.mem.eql(u8, keyword, "if")) {
                            var predicate = try self._eval(&expr.items[1], env);
                            if (predicate.Single.Bool == true) {
                                return try self._eval(&expr.items[2], env);
                            } else {
                                return try self._eval(&expr.items[3], env);
                            }
                        } else if (std.mem.eql(u8, keyword, "lambda")) {
                            var function_params = expr.items[1].Expr.items;
                            var params_list = std.ArrayList([]const u8).init(self.allocator.*);
                            for (function_params) |param| {
                                try params_list.append(param.Single.String.items);
                            }
                            return types.ASTNode{ .Single = types.Type{ .Function = types.Function.init(self.allocator, env, params_list, &expr.items[2]) } };
                        } else {
                            unreachable;
                        }
                    },
                    else => {
                        return SyntaxErrors.UnexpectedTokenError;
                    },
                }
            },
            .Single => |item| {
                switch (item) {
                    .String => |variable| {
                        return env.find(variable.items).?;
                    },
                    .Bool => |b| {
                        return types.ASTNode{ .Single = types.Type{ .Bool = b } };
                    },
                    .Keyword => |k| {
                        return types.ASTNode{ .Single = types.Type{ .Keyword = k } };
                    },
                    .Number => |n| {
                        return types.ASTNode{ .Single = types.Type{ .Number = n } };
                    },
                    else => {
                        return SyntaxErrors.UnexpectedTokenError;
                    },
                }
            },
        }
        unreachable;
    }

    pub fn eval(self: *Self, ast: *types.ASTNode) !types.ASTNode {
        return self._eval(ast, &self.env);
    }
};

pub fn moveToHeap(allocator: *Allocator, value: anytype) !*@TypeOf(value) {
    const T = @TypeOf(value);
    std.debug.assert(@typeInfo(T) != .Pointer);
    const ptr = try allocator.create(T);
    ptr.* = value;
    return ptr;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    var allocator = gpa.allocator();
    var interpreter = Interpreter.init(&allocator);
    defer interpreter.deinit();
    var parsed_string = try interpreter.parse(shorter_test_string);
    var ast = try interpreter.tokenize(&parsed_string);
    // interpreter.print_ast();
    var result = try interpreter.eval(ast);
    interpreter._printAst(result);
}
