pub const std = @import("std");
// OneLonelyCoder Array pattern matcher

// Match pattern of dices
// Equal size of pattern and dice set is required
// `[0-9]` and exact digit
// `?` any digit
// ????? - any 5 digits
// NNNNN - any 5 repeating digits
// `N` - any digit
// `NN` -
pub fn patternMatch(data: []u8, pattern: []const u8) bool {
    var index: usize = 0;
    var last_matched: u8 = 0;
    var last_matched_used: bool = false;
    while (index < data.len) {
        switch (pattern[index]) {
            '1','2','3','4','5','6' => {
                if (data[index] != pattern[index] - '0') {
                    return false;
                }
            },
            'N' => {
                if (!last_matched_used) {
                    last_matched = data[index];
                    last_matched_used = true;
                } else {
                    if (last_matched != data[index]) {
                        return false;
                    }
                }
            },
            '?' => {},
            else => unreachable,
        }

        index += 1;
    }

    return true;
}

test "Pattern matching" {
    var arr = [_]u8{ 1, 1, 1, 1, 6 };
    // same 5
    try std.testing.expectEqual(patternMatch(&arr, "NNNNN"), false);
    // same 4`
    try std.testing.expectEqual(patternMatch(&arr, "NNNN?"), true);
    // same 3
    try std.testing.expectEqual(patternMatch(&arr, "?NNN?"), true);
    // straight
    try std.testing.expectEqual(patternMatch(&arr, "12345") or patternMatch(&arr, "23456"), false);
}

test "Match straight" {
    var arr = [_]u8 { 1,2,3,4,5 };

    try std.testing.expectEqual(patternMatch(&arr, "12345") or patternMatch(&arr, "23456"), true);
}