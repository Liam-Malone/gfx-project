const std = @import("std");
const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;

const xml = @import("xml.zig");
const stdout = std.io.getStdOut().writer();

const wl_tags = enum {
    protocol, // root --> file level
    interface, // struct -> toplevel
    event, // struct -> within interface
    request, // method -> within interface
    arg, // method/event argument
    errors, // error results
};

const Arg = struct {
    name: []const u8,
    summary: []const u8,
    type: Type,

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
            return std.meta.stringToEnum(Arg.Type, s) orelse {
                return error.UnknownType;
            };
        }
        pub fn to_zig_type_string(self: Type) ?[]const u8 {
            return switch (self) {
                .fd => "wl_msg.FileDescriptor", // fd will be sent through cmsg, not main send
                .int => "i32",
                .fixed => "f32",
                .array => "[]const u8",
                .string => "[:0]const u8",
                .uint, .object, .new_id => "u32",
            };
        }
    };
};

const Generator = struct {
    arena: std.heap.ArenaAllocator,
};

// for each interface:
// add docstring (description) above interface
// go through requests -> adding docstring above, then each arg as it's encountered
// take events too
//

pub fn gen_protocol(allocator: Allocator, writer: anytype, root: *xml.Element) !void {
    // ------------------------ BEGIN PROTOCOL ------------------------
    _ = allocator;
    var interface_iter = root.findChildrenByTag("interface");
    while (interface_iter.next()) |interface| {
        const interface_description = interface.findChildByTag("description").?;
        _ = interface_description;
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

        // TODO: Edge-case handling for newlines in description
        if (interface.findChildByTag("description")) |description| {
            if (description.getAttribute("summary")) |summary| {
                try writer.print(
                    \\
                    \\/// {s}
                    \\
                , .{summary});
            }
        } else {
            try writer.writeAll("\n");
        }
        // ------------------------ BEGIN INTERFACE ------------------------
        try writer.print(
            \\pub const {s} = struct {{
            \\    id: u32,
            \\    version: u32 = {s},
            \\
        ,
            .{
                snakeToPascal(name),
                interface_version,
            },
        );
        var idx: usize = 0;
        var request_iter = interface.findChildrenByTag("request");
        while (request_iter.next()) |req| : (idx += 1) {
            const req_name = req.getAttribute("name").?;
            try write_req_params(writer, req, idx);
            if (req.findChildByTag("description")) |description| {
                if (description.getAttribute("summary")) |summary| {
                    try writer.print(
                        \\
                        \\    /// {s}
                        \\
                    , .{summary});
                }
            } else {
                try writer.writeAll("\n");
            }
            try writer.print(
                \\    pub fn {s}(self: *const {s}, writer: anytype, params: {s}_params) !void {{
                \\        log.debug("    Sending {s}::{s} {{any}}", .{{ params }});
                \\        try wl_msg.write(writer, @TypeOf(params), params, self.id);
                \\    }}
                \\
            , .{
                req_name,
                snakeToPascal(name),
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
                const base_name = ev.getAttribute("name").?;
                const ev_name = if (std.mem.eql(u8, base_name, "error")) "err" else base_name;

                // `Event.` prefix added for disambiguation
                try writer.print(
                    \\    {s}: Event.{s},
                    \\
                , .{ ev_name, snakeToPascal(base_name) });
            }

            // Declare Types
            event_iter = interface.findChildrenByTag("event"); // reset
            while (event_iter.next()) |ev| {
                const ev_name = ev.getAttribute("name").?;

                try writer.print(
                    \\
                    \\        pub const {s} = struct {{
                , .{snakeToPascal(ev_name)});

                var ev_arg_iter = ev.findChildrenByTag("arg");
                while (ev_arg_iter.next()) |ev_arg| {
                    const arg_name = ev_arg.getAttribute("name").?;
                    try writer.print("\n             {s}", .{arg_name});
                    const arg_t_opt = ev_arg.getAttribute("type");
                    if (arg_t_opt) |arg_t|
                        try writer.print(": {s},", .{(try Arg.Type.from_string(arg_t)).to_zig_type_string().?})
                    else
                        try writer.print(",", .{});
                }
                try writer.print("        }};", .{});
            }
            // TODO: Parse function generation
            event_iter = interface.findChildrenByTag("event"); // reset
            try writer.print(
                \\        pub fn parse(op: u32, data: []const u8) !Event {{
                \\            return switch (op) {{
                \\
            , .{});
            while (event_iter.next()) |ev| : (idx += 1) {
                const base_name = ev.getAttribute("name").?;
                const ev_name = if (std.mem.eql(u8, base_name, "error")) "err" else base_name;
                try writer.print(
                    \\                {d} => .{{ .{s} = try wl_msg.parse_data(Event.{s}, data) }},
                    \\
                , .{ idx, ev_name, snakeToPascal(base_name) });
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
        const arg_type: Arg.Type = try Arg.Type.from_string(arg.getAttribute("type").?);

        if (arg.getAttribute("summary")) |summary| {
            try writer.print(
                \\        /// {s}
                \\
            , .{summary});
        }
        if (arg_type == .new_id and arg_interface_opt == null) {
            try writer.print(
                \\        {s}_interface: [:0]const u8,
                \\        {s}_interface_version: u32,
                \\
            , .{ arg_name, arg_name });
        }
        try writer.print("        {s}: {s},\n", .{ arg_name, arg_type.to_zig_type_string().? });
    }
    try writer.print(
        \\    }};
        \\
    , .{});
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
    var scope_name: []u8 = try allocator.dupe(u8, xml_filename[start_idx..end_idx]);
    for (scope_name, 0..) |char, idx| {
        if (char == '-') {
            scope_name[idx] = '_';
        }
    }

    try writer.print(
        \\// This file is auto-generated by Zig-Wayland-Generator
        \\//
        \\// These bindings are *NOT* libwayland bindings. These bindings are for
        \\// interacting directly with the wayland socket.
        \\//
        \\// These bindings are somewhat incomplete. I hacked this together in 
        \\// one night, so I only made sure features I would immediately use are 
        \\// present and included.
        \\//
        \\// TODO: Put a useful message in here when this thing is ready.
        \\
        \\const std = @import("std");
        \\const log = std.log.scoped(.{s});
        \\
        \\const wl_msg = @import("wl_msg"); // It's assumed that the user provides this module
        \\
    , .{scope_name});
    try gen_protocol(allocator, writer, spec.root);

    // defer spec.deinit();
    // var gen: Generator = .init(allocator, spec.root) catch |err| {
    //     std.log.err("Failed to init generator with err: {s}", .{@errorName(err)});
    // };
    // defer gen.deinit();
    // gen.render(writer) catch |err| {
    //     std.log.err("Failed to render with err: {s}", .{@errorName(err)});
    // };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var args = std.process.argsWithAllocator(allocator) catch |err| switch (err) {
        error.OutOfMemory => @panic("OOM"),
    };
    const prog_name = args.next() orelse "wayland-zig-generator";

    var xml_opt: ?[]const u8 = null;
    var out_opt: ?[]const u8 = null;
    var debug = false;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            help_msg(prog_name) catch |err| {
                std.log.err("Failed to write to stdout with err: {s}", .{@errorName(err)});
            };
            std.process.exit(1);
        } else if (std.mem.eql(u8, arg, "--debug")) {
            try stdout.print("[debug mode]\n", .{});
            debug = true;
        } else if (xml_opt == null) {
            xml_opt = arg;
        } else if (out_opt == null) {
            out_opt = arg;
        } else {
            try help_msg(prog_name);
        }
    }

    const xml_file = xml_opt orelse {
        help_msg(prog_name) catch |err| {
            std.log.err("Failed to write to stdout with err: {s}", .{@errorName(err)});
        };
        std.process.exit(1);
    };

    const out_file = out_opt orelse {
        help_msg(prog_name) catch |err| {
            std.log.err("Failed to write to stdout with err: {s}", .{@errorName(err)});
        };
        std.process.exit(1);
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

    cwd.writeFile(.{
        .sub_path = out_file,
        .data = formatted,
    }) catch |err| {
        std.log.err("failed to write to output file '{s}' ({s})", .{ out_file, @errorName(err) });
        std.process.exit(1);
    };
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
            try printWithUpperFirstChar(writer, elem);
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
