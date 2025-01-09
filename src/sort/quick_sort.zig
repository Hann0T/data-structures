const std = @import("std");

fn partition(input: []u32, low: usize, high: usize) usize {
    const pivot = input[high];

    var j = low;
    for (low..high) |i| {
        if (input[i] <= pivot) {
            const temp = input[i];
            input[i] = input[j];
            input[j] = temp;

            j += 1;
        }
    }

    input[high] = input[j];
    input[j] = pivot;

    return j;
}

fn sort(input: []u32, low: usize, high: usize) void {
    if (low >= high) return;

    const pivot_index = partition(input, low, high);

    sort(input, low, pivot_index - 1);
    sort(input, pivot_index + 1, high);
}

pub fn quick_sort(input: []u32) void {
    sort(input, 0, input.len - 1);
}

test "quick sort" {
    var arr = [_]u32{ 9, 3, 7, 4, 69, 420, 42 };

    quick_sort(&arr);

    const expected = [_]u32{ 3, 4, 7, 9, 42, 69, 420 };
    try std.testing.expectEqualSlices(u32, &expected, &arr);
}

test "quick sort 2" {
    var arr = [_]u32{ 420, 3, 69, 4, 7, 9, 42, 15 };

    quick_sort(&arr);

    const expected = [_]u32{ 3, 4, 7, 9, 15, 42, 69, 420 };
    try std.testing.expectEqualSlices(u32, &expected, &arr);
}
