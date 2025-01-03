const std = @import("std");

pub fn binary_search(haystack: []const i32, needle: i32) bool {
    var low: usize = 0;
    var high: usize = haystack.len;
    var should_run = true;

    while (should_run) {
        const mid: usize = low + (high - low) / 2;
        const value = haystack[mid];

        if (value == needle) {
            return true;
        } else if (needle > value) {
            low = mid + 1;
        } else {
            high = mid;
        }

        if (low >= high) {
            should_run = false;
        }
    }

    return false;
}

test "default test" {
    const arr = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    try std.testing.expectEqual(binary_search(&arr, 4), true);
    try std.testing.expectEqual(binary_search(&arr, 7), true);
    try std.testing.expectEqual(binary_search(&arr, 1), true);
    try std.testing.expectEqual(binary_search(&arr, 100), false);
}
