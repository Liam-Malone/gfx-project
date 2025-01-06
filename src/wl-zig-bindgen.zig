const std = @import("std");
const Allocator = std.mem.Allocator;
const Arena = @import("Arena.zig");

const xml = @import("xml.zig");
const stdout = std.io.getStdOut().writer();

const Type = enum {
    int,
    uint,
    fixed,
    string,
    object,
    new_id,
    array,
    fd,

    pub fn from_string(s: []const u8) !Type {
        return std.meta.stringToEnum(Type, s) orelse {
            return error.UnknownType;
        };
    }
    pub fn to_zig_type_string(self: Type) ?[]const u8 {
        return switch (self) {
            .fd => "std.posix.fd_t", // fd will be sent through cmsg, not main send
            .int => "i32",
            .fixed => "f32",
            .array => "[]const u8",
            .string => "[:0]const u8",
            .uint, .object, .new_id => "u32",
        };
    }
};

// for each interface:
// add docstring (description) above interface
// go through requests -> adding docstring above, then each arg as it's encountered
// take events too
//

pub fn gen_protocol(writer: anytype, root: *xml.Element) !void {
    // ------------------------ BEGIN PROTOCOL ------------------------
    var interface_iter = root.findChildrenByTag("interface");
    while (interface_iter.next()) |interface| {
        const interface_name = interface.getAttribute("name").?;
        const interface_version = interface.getAttribute("version").?;
        const underscore_idx = blk: {
            for (interface_name, 0..) |char, idx| {
                if (char == '_')
                    break :blk idx + 1;
            }
            break :blk 0;
        };
        const name = interface_name[underscore_idx..];

        if (interface.findChildByTag("description")) |description| {
            if (description.getAttribute("summary")) |summary| {
                try writer.print(
                    \\
                    \\///{s}
                    \\
                , .{IgnoreNewline{ .str = summary }});
            }
        } else {
            try writer.writeAll("\n");
        }
        // ------------------------ BEGIN INTERFACE ------------------------
        try writer.print(
            \\pub const {s} = struct {{
            \\    pub const name: [:0]const u8 = "{s}";
            \\
            \\    version: u32 = {s},
            \\    id: u32,
            \\
        ,
            .{
                snakeToPascal(name),
                interface_name,
                interface_version,
            },
        );

        var enum_iter = interface.findChildrenByTag("enum");
        while (enum_iter.next()) |enum_type| {
            const enum_name = enum_type.getAttribute("name").?;
            if (enum_type.findChildByTag("description")) |description|
                if (description.getAttribute("summary")) |summary| {
                    try writer.print(
                        \\
                        \\    ///{s}
                        \\
                    , .{IgnoreNewline{ .str = summary }});
                } else {
                    try writer.print("\n", .{});
                };

            var enum_field_iter = enum_type.findChildrenByTag("entry");
            if (enum_type.getAttribute("bitfield")) |_| {
                // bitfield
                try writer.print("    pub const {s} = packed struct(u32) {{\n", .{snakeToPascal(enum_name)});
                var idx: u8 = 0;
                while (enum_field_iter.next()) |bit_entry| : (idx += 1) {
                    if (bit_entry.getAttribute("summary")) |summary| {
                        try writer.print(
                            \\
                            \\        ///{s}
                            \\
                        , .{IgnoreNewline{ .str = summary }});
                    } else {
                        try writer.print("\n", .{});
                    }
                    const entry_name = bit_entry.getAttribute("name").?;
                    try writer.print("        @\"{s}\": bool = false,", .{entry_name});
                }

                while (idx < 32) : (idx += 1) {
                    try writer.print("        __reserved_bit_{d}: bool = false,", .{idx});
                }
            } else {
                try writer.print("    pub const {s} = enum (u32) {{\n", .{snakeToPascal(enum_name)});
                while (enum_field_iter.next()) |enum_entry| {
                    if (enum_entry.getAttribute("summary")) |summary| {
                        try writer.print(
                            \\
                            \\        ///{s}
                            \\
                        , .{IgnoreNewline{ .str = summary }});
                    } else {
                        try writer.print("\n", .{});
                    }
                    const entry_name = enum_entry.getAttribute("name").?;
                    const entry_value = enum_entry.getAttribute("value").?;
                    try writer.print("        @\"{s}\" = {s},", .{ entry_name, entry_value });
                }
            }
            try writer.print("\n    }};", .{});
        }

        var idx: usize = 0;
        var request_iter = interface.findChildrenByTag("request");
        while (request_iter.next()) |req| : (idx += 1) {
            const req_name = req.getAttribute("name").?;
            try write_req_params(writer, req, idx);
            if (req.findChildByTag("description")) |description| {
                if (description.getAttribute("summary")) |summary| {
                    try writer.print(
                        \\
                        \\    ///{s}
                        \\
                    , .{IgnoreNewline{ .str = summary }});
                }
            } else {
                try writer.writeAll("\n");
            }
            try writer.print(
                \\    pub fn {s}(self: *const {s}, writer: anytype, params: {s}_params) !void {{
                \\        try wl_msg.write(writer, @TypeOf(params), params, self.id);
                \\    }}
                \\
            , .{
                req_name,
                snakeToPascal(name),
                req_name,
            });
        }

        idx = 0;
        if (interface.findChildByTag("event")) |_| {
            var event_iter = interface.findChildrenByTag("event");
            try writer.print("pub const Event = union (enum) {{\n", .{});
            // Declare fields
            while (event_iter.next()) |ev| {
                const ev_name = ev.getAttribute("name").?;
                // const ev_name = if (std.mem.eql(u8, base_name, "error")) "err" else base_name;

                // `Event.` prefix added for disambiguation
                try writer.print(
                    \\    @"{s}": Event.@"{s}",
                    \\
                , .{ ev_name, snakeToPascal(ev_name) });
            }

            // Declare Types
            event_iter = interface.findChildrenByTag("event"); // reset
            while (event_iter.next()) |ev| {
                const ev_name = ev.getAttribute("name").?;

                if (ev.findChildByTag("description")) |description|
                    if (description.getAttribute("summary")) |summary|
                        try writer.print(
                            \\
                            \\
                            \\        ///{s}
                        , .{IgnoreNewline{ .str = summary }});
                try writer.print(
                    \\
                    \\        pub const {s} = struct {{
                , .{snakeToPascal(ev_name)});

                var ev_arg_iter = ev.findChildrenByTag("arg");
                while (ev_arg_iter.next()) |ev_arg| {
                    const arg_name = ev_arg.getAttribute("name").?;
                    try writer.print("\n             {s}", .{arg_name});
                    const arg_t_opt = ev_arg.getAttribute("type");
                    const arg_enum_t_opt = ev_arg.getAttribute("enum");
                    if (arg_enum_t_opt) |arg_enum_t| {
                        if (std.mem.eql(u8, "wl_", arg_enum_t[0..3]))
                            try writer.print(": {s},", .{snakeToPascal(arg_enum_t[3..])})
                        else
                            try writer.print(": {s}.{s},", .{ snakeToPascal(name), snakeToPascal(arg_enum_t) });
                    } else if (arg_t_opt) |arg_t|
                        try writer.print(": {s},", .{(try Type.from_string(arg_t)).to_zig_type_string().?})
                    else
                        try writer.print(",", .{});
                }
                try writer.print("        }};", .{});
            }

            event_iter = interface.findChildrenByTag("event"); // reset
            try writer.print(
                \\
                \\        pub fn parse(op: u32, data: []const u8) !Event {{
                \\            return switch (op) {{
                \\
            , .{});
            while (event_iter.next()) |ev| : (idx += 1) {
                const ev_name = ev.getAttribute("name").?;

                // const ev_name = if (std.mem.eql(u8, base_name, "error")) "err" else base_name;
                try writer.print(
                    \\                {d} => .{{ .@"{s}" = try wl_msg.parse_data(Event.@"{s}", data) }},
                    \\
                , .{ idx, ev_name, snakeToPascal(ev_name) });
            }
            try writer.print(
                \\                else => {{
                \\                    log.warn("Unknown {s} event: {{d}}", .{{op}});
                \\                    return error.UnknownEvent;
                \\                }},
                \\
            , .{name});
            try writer.print("\n            }};\n", .{});
            try writer.print("\n        }}\n", .{});
            try writer.print("    }};\n", .{});
        }
        idx = 0;

        // ------------------------  END INTERFACE  ------------------------
        try writer.print("\n}};\n", .{});
    }
    // ------------------------  END PROTOCOL  ------------------------
}

fn write_req_params(writer: anytype, req: *xml.Element, idx: usize) !void {
    try writer.print(
        \\
        \\    pub const {s}_params = struct {{
        \\        pub const op = {d};
        \\
    ,
        .{
            req.getAttribute("name").?,
            idx,
        },
    );
    var arg_iter = req.findChildrenByTag("arg");
    while (arg_iter.next()) |arg| {
        const arg_interface_opt = arg.getAttribute("interface");
        const arg_name = arg.getAttribute("name").?;
        const arg_type: Type = try Type.from_string(arg.getAttribute("type").?);
        const arg_enum_type = arg.getAttribute("enum");

        if (arg.getAttribute("summary")) |summary| {
            try writer.print(
                \\        ///{s}
                \\
            , .{IgnoreNewline{ .str = summary }});
        }
        if (arg_type == .new_id and arg_interface_opt == null) {
            try writer.print(
                \\        {s}_interface: [:0]const u8,
                \\        {s}_interface_version: u32,
                \\
            , .{ arg_name, arg_name });
        }
        try writer.print("        {s}: ", .{arg_name});
        if (arg_enum_type) |enum_type| {
            try writer.print("{s},\n", .{snakeToPascal(enum_to_str(enum_type))});
        } else {
            try writer.print("{s},\n", .{arg_type.to_zig_type_string().?});
        }
    }
    try writer.print(
        \\    }};
        \\
    , .{});
}

fn enum_to_str(enum_str: []const u8) []const u8 {
    const upper_idx = blk: {
        for (enum_str, 0..) |char, idx| {
            if (char == '.')
                break :blk idx + 1;
        }
        break :blk 0;
    };
    const underscore_idx = if (upper_idx == 0) 0 else blk: {
        for (enum_str, 0..) |char, idx| {
            if (char == '_')
                break :blk idx + 1;
        }
        break :blk 0;
    };
    var name = @constCast(enum_str[underscore_idx..]);
    name[0] = std.ascii.toUpper(name[0]);
    name[upper_idx - underscore_idx] = std.ascii.toUpper(name[upper_idx - underscore_idx]);
    return name;
}

pub fn generate(allocator: Allocator, xml_filename: []const u8, spec_xml: []const u8, writer: anytype) !void {
    const spec = try xml.parse(allocator, spec_xml);
    defer spec.deinit();

    var start_idx: usize = 0;
    var end_idx: usize = xml_filename.len - 1;

    for (xml_filename, 0..) |char, idx| {
        if (char == '/') start_idx = idx + 1;
        if (char == '.') end_idx = idx;
    }
    const scope_name = xml_filename[start_idx..end_idx];
    try writer.print(
        \\// WARNING: This file is auto-generated by wl-zig-bindgen.
        \\//          It is recommended that you do NOT edit this file.
        \\//
        \\// TODO: Put a useful message in here when this thing is ready.
        \\//
        \\
        \\const std = @import("std");
        \\const log = std.log.scoped(.@"{s}");
        \\
        \\const wl_msg = @import("wl_msg"); // It's assumed that the user provides this module
        \\
    , .{scope_name});

    try gen_protocol(writer, spec.root);
}

pub fn main() !void {
    var arena = Arena.init(.default);
    defer arena.release();
    const allocator = arena.allocator();

    var args = std.process.argsWithAllocator(allocator) catch |err| switch (err) {
        error.OutOfMemory => @panic("OOM"),
    };
    const prog_name = args.next() orelse "wl-zig-bindgen";

    var xml_opts = std.ArrayList([]const u8).init(arena.allocator());
    var file_outs = std.ArrayList(?[]const u8).init(arena.allocator());
    var file_in = true;
    var debug = false;
    var out_pref_opt: ?[]const u8 = null;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            help_msg(prog_name) catch |err| {
                std.log.err("Failed to write to stdout with err: {s}", .{@errorName(err)});
            };
            std.process.exit(1);
        } else if (std.mem.eql(u8, arg, "--out")) {
            file_in = false;
        } else if (std.mem.eql(u8, arg, "--debug")) {
            try stdout.print("[debug mode]\n", .{});
            debug = true;
        } else if (std.mem.eql(u8, arg, "--prefix") or std.mem.eql(u8, arg, "-p")) {
            out_pref_opt = args.next() orelse blk: {
                help_msg(prog_name) catch |err| {
                    std.log.err("Failed to write to stdout with err: {s}", .{@errorName(err)});
                };
                break :blk null;
            };
        } else {
            if (file_in) try xml_opts.append(arg) else try file_outs.append(arg);
        }
    }

    while (file_outs.items.len < xml_opts.items.len) {
        try file_outs.append(null);
    }

    for (xml_opts.items, 0..) |xml_file, i| {
        const out_file = if (file_outs.items[i]) |out| out else blk: {
            var start: usize = 0;
            var end: usize = xml_file.len - 1;
            for (xml_file, 0..) |char, idx| {
                if (char == '/') start = idx + 1;
                if (char == '.') end = idx;
            }

            const file_ext = ".zig";
            var buf = arena.push(u8, (end - start) + file_ext.len);
            @memcpy(buf[0 .. end - start], xml_file[start..end]);
            @memcpy(buf[end - start ..], file_ext);
            break :blk buf;
        };

        const cwd = std.fs.cwd();
        const xml_src = cwd.readFileAlloc(allocator, xml_file, std.math.maxInt(usize)) catch |err| {
            std.log.err("Failed to open input file '{s}' with err: {s}", .{ xml_file, @errorName(err) });
            std.process.exit(1);
        };

        var out_buf = std.ArrayList(u8).init(allocator);
        generate(allocator, xml_file, xml_src, out_buf.writer()) catch |err| {
            std.log.err("XML parse err: {s}", .{@errorName(err)});
        };
        out_buf.append(0) catch @panic("oom");
        const src = out_buf.items[0 .. out_buf.items.len - 1 :0];
        const tree = std.zig.Ast.parse(allocator, src, .zig) catch |err| switch (err) {
            error.OutOfMemory => @panic("oom"),
        };

        const formatted = if (tree.errors.len > 0) blk: {
            std.log.err("generated invalid zig code", .{});

            reportParseErrors(tree) catch |err| {
                std.log.err("failed to dump ast errors: {s}", .{@errorName(err)});
                std.process.exit(1);
            };

            if (debug) {
                break :blk src;
            }
            std.process.exit(1);
        } else tree.render(allocator) catch |err| switch (err) {
            error.OutOfMemory => @panic("oom"),
        };

        if (tree.errors.len > 0 and debug) {
            try stdout.writeAll(src);
        }

        if (std.fs.path.dirname(out_file)) |dir| {
            cwd.makePath(dir) catch |err| {
                std.log.err("failed to create output directory '{s}' ({s})", .{ dir, @errorName(err) });
                std.process.exit(1);
            };
        }

        const out_path = if (out_pref_opt) |out_prefix|
            try std.mem.join(arena.allocator(), "/", &[_][]const u8{ out_prefix, out_file })
        else
            out_file;

        cwd.writeFile(.{
            .sub_path = out_path,
            .data = formatted,
        }) catch |err| {
            std.log.err("failed to write to output file '{s}' ({s})", .{ out_file, @errorName(err) });
            std.process.exit(1);
        };
    }
}

fn help_msg(prog_name: []const u8) !void {
    try stdout.print(
        \\\ Utility tool to generate Zig bindings from Wayland protocol XML specifications
        \\\
        \\\ Usage: {s} [options] <xml source> <zig output path>
        \\\ -h --help    Show this message and exit
        \\\
    , .{prog_name});
}

fn reportParseErrors(tree: std.zig.Ast) !void {
    const stderr = std.io.getStdErr().writer();

    for (tree.errors) |err| {
        const loc = tree.tokenLocation(0, err.token);
        try stderr.print("(wayland-zig error):{d}:{d}: error: ", .{ loc.line + 1, loc.column + 1 });
        try tree.renderError(err, stderr);
        try stderr.print("\n{s}\n", .{tree.source[loc.line_start..loc.line_end]});
        for (0..loc.column) |_| {
            try stderr.writeAll(" ");
        }
        try stderr.writeAll("^\n");
    }
}

const IgnoreNewline = struct {
    str: []const u8,

    pub fn format(
        self: *const IgnoreNewline,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        var it = std.mem.splitScalar(u8, self.str, '\n');
        while (it.next()) |substr| {
            if (substr.len > 0) {
                // first non-space character
                const start_idx = blk: {
                    for (substr, 0..) |char, idx| {
                        if (char != ' ' and char != '\t')
                            break :blk idx;
                    }
                    break :blk 0;
                };
                try writer.print(" {s}", .{substr[start_idx..]});
            }
        }
    }
};
// Taken from Sphaerophoria -- https://github.com/sphaerophoria/sphwayland-client
//-------------------------------------------------------------------------------
const SnakeToPascal = struct {
    name: []const u8,

    pub fn format(
        self: *const SnakeToPascal,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        var it = std.mem.splitScalar(u8, self.name, '_');
        while (it.next()) |elem| {
            var it_dot = std.mem.splitScalar(u8, elem, '.');
            var idx: u32 = 0;
            while (it_dot.next()) |inner| : (idx += 1) {
                if (idx > 0) try writer.print(".", .{});
                try printWithUpperFirstChar(writer, inner);
            }
            // try printWithUpperFirstChar(writer, elem);
        }
    }
};
fn printWithUpperFirstChar(writer: anytype, s: []const u8) !void {
    switch (s.len) {
        0 => return,
        1 => try writer.writeByte(std.ascii.toUpper(s[0])),
        else => {
            const first_char = std.ascii.toUpper(s[0]);
            try writer.print("{c}{s}", .{ first_char, s[1..] });
        },
    }
}

fn snakeToPascal(s: []const u8) SnakeToPascal {
    return .{ .name = s };
}
//-------------------------------------------------------------------------------
