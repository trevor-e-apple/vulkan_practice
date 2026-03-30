const std = @import("std");
const print = std.debug.print;

pub fn rot(txt: []u8, key: u8) void {
    for (txt, 0..txt.len) |c, i| {
        if (std.ascii.isLower(c)) {
            txt[i] = (c - 'a' + key) % 26 + 'a';
        } else if (std.ascii.isUpper(c)) {
            txt[i] = (c - 'A' + key) % 26 + 'A';
        }
    }
}

pub fn main() !void {
    const key = 3;
    var txt = "The five boxing wizards jump quickly".*;

    print("Original:  {s}\n", .{txt});
    rot(&txt, key);
    print("Encrypted: {s}\n", .{txt});
    rot(&txt, 26 - key);
    print("Decrypted: {s}\n", .{txt});
}
