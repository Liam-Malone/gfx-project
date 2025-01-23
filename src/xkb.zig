const std = @import("std");
const input = @import("input.zig");
const Key = input.Key;

const Arena = @import("Arena.zig");

const log = std.log.scoped(.xkb_keymap);

pub const Keycodes = struct {
    name: []const u8,
    min: u32,
    max: u32,
    map: KeycodeMap,

    const KeycodeMap = std.AutoHashMap(u32, []const u8);
    // TODO: Handle parsing of 'indicator' and 'alias' lines
    pub fn init(arena: *Arena, data: []const u8) !Keycodes {
        const alloc = arena.allocator();
        var result: Keycodes = .{
            .name = undefined,
            .min = undefined,
            .max = undefined,
            .map = .init(alloc),
        };

        var line_iter = std.mem.splitScalar(u8, data, '\n');
        while (line_iter.next()) |line| {
            if (line[0] == 'x') { // name line
                var word_iter = std.mem.splitScalar(u8, line, ' ');
                _ = word_iter.next();
                const name_opt = word_iter.next();
                if (name_opt) |name| {
                    result.name = name[1 .. name.len - 1];
                }
                continue;
            } else if (line[0] == '}') { // done
            } else {
                var word_iter = std.mem.splitScalar(u8, line, '=');
                while (word_iter.next()) |word| {
                    // first char is a tab
                    if (std.mem.eql(u8, word[1 .. word.len - 1], "minimum")) {
                        const min_str = word_iter.next().?;
                        result.min = try std.fmt.parseInt(u32, min_str[1 .. min_str.len - 1], 10);
                    } else if (std.mem.eql(u8, word[1 .. word.len - 1], "maximum")) {
                        const max_str = word_iter.next().?;
                        result.max = try std.fmt.parseInt(u32, max_str[1 .. max_str.len - 1], 10);
                    } else if (line[1] == '<') {
                        var key_end_idx = word.len - 1;
                        for (word, 0..) |char, idx| {
                            if (char == '>') key_end_idx = idx + 1;
                        }
                        const key_name = word[1..key_end_idx];
                        const key_code_str = word_iter.next().?;
                        const key_code = try std.fmt.parseInt(u32, key_code_str[1 .. key_code_str.len - 1], 10);

                        try result.map.put(key_code - result.min, key_name);
                    }
                }
            }
        }

        return result;
    }

    pub fn get(self: *const Keycodes, keycode: u32) ?[]const u8 {
        return if (keycode < self.max and keycode > self.min)
            self.map.get(keycode)
        else
            null;
    }
};

pub const Symbols = struct {
    name: []const u8,
    map: SymbolMap,
    modmap: SymbolMap,

    const SymbolMap = std.StringHashMap([]const u8);
    pub fn init(arena: *Arena, data: []const u8) !Symbols {
        var result: Symbols = .{
            .name = undefined,
            .map = .init(arena.allocator()),
            .modmap = undefined,
        };

        var line_iter = std.mem.splitScalar(u8, data, '\n');
        var cur_key: []const u8 = undefined;
        while (line_iter.next()) |line| {
            if (line.len < 1 or line[0] == '}') {
                // done
            } else if (line[0] == 'x') {
                // Start of block
                var iter = std.mem.splitScalar(u8, line, ' ');
                _ = iter.next();
                const name = iter.next().?;
                result.name = name[1 .. name.len - 1];
            } else {
                var segment_iter = std.mem.splitScalar(u8, line, '\t');
                while (segment_iter.next()) |segment| {
                    if (segment.len < 1 or segment[0] == '}') {
                        // Do nothing
                    } else if (std.mem.eql(u8, "key", segment[0..3])) {
                        var angle_idx: usize = 0;
                        for (segment[0..], 0..) |char, idx| {
                            if (char == '>') {
                                angle_idx = idx + 1;
                                break;
                            }
                        }
                        cur_key = segment[4..angle_idx];
                    } else if (segment[0] == '[') {
                        var start: usize = 0;
                        var end: usize = 0;
                        for (segment, 0..) |char, idx| {
                            if (start == 0 and !(char == ' ' or char == '[')) {
                                start = idx;
                            } else if (start != 0 and (char == ',' or char == ' ')) {
                                end = idx;
                                break;
                            }
                        }

                        try result.map.put(cur_key, segment[start..end]);
                    } else if (segment[0] == 's') {
                        var bracket_count: usize = 0;
                        var start: usize = 0;
                        var end: usize = 0;
                        for (segment, 0..) |char, idx| {
                            if (bracket_count < 2 and char == '[') {
                                bracket_count += 1;
                            } else if (start == 0 and char != ' ') {
                                start = idx;
                            } else if (start != 0 and (char == ' ' or char == ',')) {
                                end = idx;
                                break;
                            }
                        }

                        try result.map.put(cur_key, segment[start..end]);
                    }
                }
            }
        }

        return result;
    }

    pub fn get(self: *const Symbols, key: []const u8) ?[]const u8 {
        return self.map.get(key);
    }
};

pub const Keymap = struct {
    keycodes: Keycodes,
    symbols: Symbols,

    pub fn init(arena: *Arena, data: []const u8) !Keymap {
        var start: usize = 0;
        var end: usize = 0;

        for (data, 0..) |char, idx| {
            if (start == 0) {
                if (std.mem.eql(u8, "xkb_keycodes", data[idx .. idx + 12])) {
                    start = idx;
                }
            } else {
                if (char == '}') {
                    end = idx + 1;
                    break;
                }
            }
        }

        const keycodes: Keycodes = try .init(arena, data[start..end]);

        start = 0;
        end = 0;
        var brace_balance: usize = 0;
        for (data, 0..) |char, idx| {
            if (char == '{') brace_balance += 1;
            if (char == '}') brace_balance -= 1;

            if (start == 0)
                if (std.mem.eql(u8, "xkb_symbols", data[idx .. idx + 11])) {
                    start = idx;
                };
            if (start != 0 and brace_balance == 0) {
                end = idx + 1;
                break;
            }
        }
        const symbols: Symbols = try .init(arena, data[start..end]);

        return .{
            .keycodes = keycodes,
            .symbols = symbols,
        };
    }
    pub fn deinit(keymap: *Keymap) void {
        keymap.keycodes.deinit();
        keymap.symbols.denit();
    }
    pub fn get_key(keymap: *const Keymap, keycode: u32) input.Key {
        log.debug("Querying Keymap with code :: {d}", .{keycode});
        const symbol_opt = keymap.keycodes.get(keycode);
        const key_opt = if (symbol_opt) |sym| keymap.symbols.get(sym).? else null;
        const result = if (key_opt) |key| std.meta.stringToEnum(input.Key, key) orelse .invalid else .invalid;
        return result;
    }
};
