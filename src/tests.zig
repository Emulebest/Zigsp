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

test "simple '*' expression works fine" {
    const shorter_test_string = "(begin (define r (* 2 5)) (+ r 10))";

    var allocator = std.testing.allocator;
    var interpreter = main.Interpreter.init(&allocator);
    defer interpreter.deinit();
    var parsed_string = try interpreter.parse(shorter_test_string);
    var ast = try interpreter.tokenize(&parsed_string);
    var result = try interpreter.eval(ast);
    try std.testing.expect(result.Single.Number == 20);
}

test "simple '/' expression works fine" {
    const shorter_test_string = "(begin (define r 10) (/ r 2))";

    var allocator = std.testing.allocator;
    var interpreter = main.Interpreter.init(&allocator);
    defer interpreter.deinit();
    var parsed_string = try interpreter.parse(shorter_test_string);
    var ast = try interpreter.tokenize(&parsed_string);
    var result = try interpreter.eval(ast);
    try std.testing.expect(result.Single.Number == 5);
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

test "if expression test" {
    const shorter_test_string = "(begin (define r (if (> 10 15) 10 15)) (+ r 4))";

    var allocator = std.testing.allocator;
    var interpreter = main.Interpreter.init(&allocator);
    defer interpreter.deinit();
    var parsed_string = try interpreter.parse(shorter_test_string);
    var ast = try interpreter.tokenize(&parsed_string);
    var result = try interpreter.eval(ast);
    try std.testing.expect(result.Single.Number == 19);
}

test "lambda expression test" {
    const shorter_test_string = "(begin (define r (lambda (a b) (+ a b))) (r 10 5))";

    var allocator = std.testing.allocator;
    var interpreter = main.Interpreter.init(&allocator);
    defer interpreter.deinit();
    var parsed_string = try interpreter.parse(shorter_test_string);
    var ast = try interpreter.tokenize(&parsed_string);
    var result = try interpreter.eval(ast);
    try std.testing.expect(result.Single.Number == 15);
}
