const std = @import("std");
const main = @import("main.zig");

test "simple '+' expression works fine" {
    const shorter_test_string = "(begin (define r (+ 10 10)) (+ r 10))";

    var allocator = std.testing.allocator;
    var interpreter = main.Interpreter.init(&allocator);
    defer interpreter.deinit();
    var parsed_string = try interpreter.parse(shorter_test_string);
    var ast = try interpreter.tokenize(&parsed_string);
    var result = try interpreter.eval(ast);
    try std.testing.expect(result.Single.Number == 30);
}

test "simple '-' expression works fine" {
    const shorter_test_string = "(begin (define r (- 20 10)) (+ r 10))";

    var allocator = std.testing.allocator;
    var interpreter = main.Interpreter.init(&allocator);
    defer interpreter.deinit();
    var parsed_string = try interpreter.parse(shorter_test_string);
    var ast = try interpreter.tokenize(&parsed_string);
    var result = try interpreter.eval(ast);
    try std.testing.expect(result.Single.Number == 20);
}

test "simple '>' expression works fine" {
    const shorter_test_string = "(begin (define r (+ 20 10)) (> r 40))";

    var allocator = std.testing.allocator;
    var interpreter = main.Interpreter.init(&allocator);
    defer interpreter.deinit();
    var parsed_string = try interpreter.parse(shorter_test_string);
    var ast = try interpreter.tokenize(&parsed_string);
    var result = try interpreter.eval(ast);
    try std.testing.expect(result.Single.Bool == false);
}
