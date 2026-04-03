const std = @import("std");
const ArenaAllocator = std.heap.ArenaAllocator;

pub fn build(b: *std.Build) !void {
    var arena = ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var cwd_buffer: [256]u8 = undefined;
    const cwd = try std.process.getCwd(&cwd_buffer);

    var env_variables = try std.process.getEnvMap(arena.allocator());
    defer env_variables.deinit();

    const vulkan_sdk_path = result: {
        if (env_variables.hash_map.get("VULKAN_SDK")) |vulkan_sdk_path| {
            std.debug.print("VULKAN_SDK: {s}\n", .{vulkan_sdk_path});
            const relative_path = try std.fs.path.relative(arena.allocator(), cwd, vulkan_sdk_path);
            std.debug.print("relative_path: {s}\n", .{relative_path});
            break :result relative_path;
        } else {
            std.debug.print("VULKAN_SDK path not found\n", .{});
            return;
        }
    };

    const relative_to_vk_xml: []const u8 = "share/vulkan/registry/vk.xml";
    const vk_xml_path = try std.fs.path.join(arena.allocator(), &[_][]const u8{ vulkan_sdk_path, relative_to_vk_xml });
    std.debug.print("vk_xml_path: {s}", .{vk_xml_path});
    const vulkan = b.dependency("vulkan", .{ .registry = b.path(vk_xml_path) });

    const sdl3 = b.dependency("sdl3", .{
        .target = target,
        .optimize = optimize,
        // Lib options.
        .ext_image = false,
        .ext_net = false,
        .ext_ttf = false,
        .log_message_stack_size = 1024,
        .main = false,
        .renderer_debug_text_stack_size = 1024,

        // Options passed directly to https://github.com/castholm/SDL (SDL3 C Bindings):
        // .c_sdl_preferred_linkage = .static,
        // .c_sdl_strip = false,
        // .c_sdl_sanitize_c = .off,
        // .c_sdl_lto = .none,
        // .c_sdl_emscripten_pthreads = false,
        // .c_sdl_install_build_config_h = false,

        // Options if `ext_image` is enabled:
        // .image_enable_bmp = true,
        // .image_enable_gif = true,
        // .image_enable_jpg = true,
        // .image_enable_lbm = true,
        // .image_enable_pcx = true,
        // .image_enable_png = true,
        // .image_enable_pnm = true,
        // .image_enable_qoi = true,
        // .image_enable_svg = true,
        // .image_enable_tga = true,
        // .image_enable_xcf = true,
        // .image_enable_xpm = true,
        // .image_enable_xv = true,
    });

    var root_module = b.createModule(.{
        .root_source_file = b.path("hello_world.zig"),
        .target = target,
    });
    root_module.addImport("sdl3", sdl3.module("sdl3"));
    root_module.addImport("vulkan", vulkan.module("vulkan-zig"));

    const exe = b.addExecutable(.{
        .name = "hello",
        .root_module = root_module,
    });

    b.installArtifact(exe);

    _ = arena.reset(ArenaAllocator.ResetMode.retain_capacity);
}
