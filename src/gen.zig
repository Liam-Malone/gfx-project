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
                .int => "i32",
                .array => "[]const u8",
                .string => "[:0]const u8",
                .fd => "void",
                .uint, .object, .new_id => "u32",
                else => null,
            };
        }
    };
};

const RequestEvent = struct {
    name: []const u8,
    description: []const u8,
    arguments: []Arg,
};

const Interface = struct {
    name: []const u8,
    description: []const u8,
    events: []RequestEvent,
    requests: []RequestEvent,
};

const Generator = struct {
    arena: std.heap.ArenaAllocator,
};

// for each interface:
// add docstring (description) above interface
// go through requests -> adding docstring above, then each arg as it's encountered
// take events too
//

pub fn walk_print(allocator: Allocator, writer: anytype, root: *xml.Element) !void {
    var interface_iter = root.findChildrenByTag("interface");
    while (interface_iter.next()) |interface| {
        try stdout.print("{s}: name = {s}, version = {s}\n", .{ interface.tag, interface.getAttribute("name").?, interface.getAttribute("version").? });
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
        var name = try allocator.dupe(u8, interface_name[underscore_idx..]);
        name[0] = std.ascii.toUpper(name[0]);
        try stdout.print(
            \\pub const {s} = struct {{
            \\    name: []const u8,
            \\    version: u32 = {s},
            \\
        ,
            .{
                name,
                interface_version,
            },
        );
        try writer.print(
            \\pub const {s} = struct {{
            \\    name: []const u8,
            \\    version: u32 = {s},
            \\
        ,
            .{
                name,
                interface_version,
            },
        );
        var req_idx: usize = 0;
        var request_iter = interface.findChildrenByTag("request");
        while (request_iter.next()) |req| : (req_idx += 1) {
            try write_req_params(writer, req, req_idx);
            try stdout.print(
                \\    pub fn {s}(self: *const {s}, writer: anytype, params: {s}_params) !void {{
                \\        log.info("Sending {s}::{s} {{any}}", .{{ params }});
                \\        wl_msg.write(writer, params, self.id);
                \\    }}
                \\
            , .{
                req.getAttribute("name").?,
                name,
                req.getAttribute("name").?,
                name,
                req.getAttribute("name").?,
            });
            try writer.print(
                \\    pub fn {s}(self: *const {s}, writer: anytype, params: {s}_params) !void {{
                \\        log.info("Sending {s}::{s} {{any}}", .{{ params }});
                \\        wl_msg.write(writer, params, self.id);
                \\    }}
                \\
            , .{
                req.getAttribute("name").?,
                name,
                req.getAttribute("name").?,
                name,
                req.getAttribute("name").?,
            });
        }
        try stdout.print("}};\n\x00", .{});
        try writer.print("}};\n\x00", .{});
    }
}

fn write_req_params(writer: anytype, req: *xml.Element, idx: usize) !void {
    // try stdout.print("    >> {s}: name = {s}\n", .{ req.tag, req.getAttribute("name").? });

    try stdout.print(
        \\    pub const {s}_params = struct {{
        \\        pub const op = {d};
        \\
    ,
        .{
            req.getAttribute("name").?,
            idx,
        },
    );
    try writer.print(
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
        const arg_name = arg.getAttribute("name").?;
        const arg_type = arg.getAttribute("type").?;
        const arg_interface_opt = arg.getAttribute("interface");

        if (arg_interface_opt) |arg_interface| {
            std.log.warn("unsure how to handle interfaces in args as of now :: interface: {s}", .{arg_interface});
        }

        try stdout.print("        {s}: {s},\n", .{ arg_name, (try Arg.Type.from_string(arg_type)).to_zig_type_string().? });
        try writer.print("        {s}: {s},\n", .{ arg_name, (try Arg.Type.from_string(arg_type)).to_zig_type_string().? });
    }
    try stdout.print(
        \\    }};
        \\
    , .{});
    try writer.print(
        \\    }};
        \\
    , .{});
}

pub fn generate(allocator: Allocator, xml_filename: []const u8, spec_xml: []const u8, writer: anytype) !void {
    const spec = try xml.parse(allocator, spec_xml);
    defer spec.deinit();
    try stdout.print("{s}\n", .{xml_filename});
    const start_idx = blk: {
        var idx: usize = xml_filename.len - 1;
        while (idx < 0) {
            if (xml_filename[idx] == '/') {
                idx += 1;
                break :blk idx;
            }
            idx -= 1;
        }
        break :blk idx;
    };
    const end_idx = blk: {
        var idx: usize = xml_filename.len - 1;
        while (idx < 0) {
            if (xml_filename[idx] == '.' or xml_filename[idx] == '.') {
                idx += 1;
                break :blk idx;
            }
            idx -= 1;
        }
        break :blk idx;
    };

    try stdout.print("root:\n{s} = {s}\nattrib count: {d}\n\n", .{ spec.root.attributes[0].name, spec.root.attributes[0].value, spec.root.attributes.len });
    try stdout.print(
        \\// THIS FILE IS AUTO-GENERATED BY Zig-Wayland-Generator
        \\// If there are any issues... uhh well, there's nowhere to report yet, this isn't a released tool/program, I'm the only user unless someone else has copied the code out of my repo...
        \\const std = @import("std");
        \\const wl_msg = @import("wl_msg");
        \\const log = std.log.scoped(.{s});
        \\
    , .{xml_filename[start_idx..end_idx]});
    try writer.print(
        \\// THIS FILE IS AUTO-GENERATED BY Zig-Wayland-Generator
        \\// If there are any issues... uhh well, there's nowhere to report yet, this isn't a released tool/program, I'm the only user unless someone else has copied the code out of my repo...
        \\const std = @import("std");
        \\const wl_msg = @import("wl_msg");
        \\const log = std.log.scoped(.{s});
        \\
    , .{xml_filename[start_idx..end_idx]});
    try walk_print(allocator, writer, spec.root);

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
