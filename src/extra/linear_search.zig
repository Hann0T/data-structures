const std = @import("std");

pub fn linear_search(haystack: []const i32, needle: i32) bool {
    for (haystack) |item| {
        if (item == needle) {
            return true;
        }
    }

    return false;
}

test "default test" {
    const arr = [_]i32{ 1, 2, 3, 4, 5 };
    try std.testing.expectEqual(linear_search(&arr, 2), true);
    try std.testing.expectEqual(linear_search(&arr, 20), false);
}
