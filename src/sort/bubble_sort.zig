const std = @import("std");

pub fn bubble_sort(input: []i32) void {
    var high: usize = input.len - 1;

    while (high > 1) : (high -= 1) {
        std.debug.print("with high: {d} input: {any}\n", .{ high, input });

        for (0..high) |index| {
            if (input[index] > input[index + 1]) {
                const temp = input[index];
                input[index] = input[index + 1];
                input[index + 1] = temp;
            }
        }
    }
}

pub fn sort(input: []i32) void {
    for (0..input.len - 1) |i| {
        if (input[i] > input[i + 1]) {
            const temp = input[i];
            input[i] = input[i + 1];
            input[i + 1] = temp;
        }
    }
}

pub fn recursive_bubble_sort(input: []i32) void {
    var high = input.len;
    while (high > 1) : (high -= 1) {
        std.debug.print("recursive with high: {d} input: {any}\n", .{ high, input });
        sort(input[0..high]);
    }
}

test "Bubble sort" {
    var arr = [_]i32{ 1, 3, 5, 7, 4, 2 };
    const expected = [_]i32{ 1, 2, 3, 4, 5, 7 };
    bubble_sort(&arr);

    try std.testing.expectEqualSlices(i32, &expected, &arr);
}

test "Recursive bubble sort" {
    var arr = [_]i32{ 10, 2, 1, 5, 7, 4, 3 };
    const expected = [_]i32{ 1, 2, 3, 4, 5, 7, 10 };
    recursive_bubble_sort(&arr);

    try std.testing.expectEqualSlices(i32, &expected, &arr);
}
