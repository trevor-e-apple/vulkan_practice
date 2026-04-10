const builtin = @import("builtin");
const sdl3 = @import("sdl3");
const std = @import("std");
const vk = @import("vulkan");

const fps = 60;
const screen_width = 640;
const screen_height = 480;

pub fn main() !void {
    if (builtin.mode == .Debug) {
        std.debug.print("Debug mode!", .{});
    }
    const parent_allocator: std.mem.Allocator = allocator: switch (builtin.mode) {
        .Debug => {
            var debug_allocator = std.heap.DebugAllocator(.{}).init;
            break :allocator debug_allocator.allocator();
        },
        else => break :allocator std.heap.page_allocator,
    };

    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit();

    defer sdl3.shutdown();

    // Initialize SDL with subsystems you need here.
    const init_flags = sdl3.InitFlags{ .video = true };
    try sdl3.init(init_flags);
    defer sdl3.quit(init_flags);

    // Initial window setup
    const window = result: {
        const flags = sdl3.video.Window.Flags{ .vulkan = true };
        const window = try sdl3.video.Window.init("Hello SDL3", screen_width, screen_height, flags);
        break :result window;
    };
    defer window.deinit();

    // graphics setup?
    switch (builtin.target.os.tag) {
        .macos => {
            // TODO
        },
        else => {
            const vkb = vk.BaseWrapper.load(@as(vk.PfnGetInstanceProcAddr, @ptrCast(try sdl3.vulkan.getVkGetInstanceProcAddr())));
            const instance_extensions = try sdl3.vulkan.getInstanceExtensions();
            std.debug.print("{any}\n", .{instance_extensions});

            if (builtin.mode == .Debug) {
                const validation_layers: []const [*:0]const u8 = &.{"VL_LAYER_KHRONOS_validation"};
                const available_layers = try vkb.enumerateInstanceLayerPropertiesAlloc(arena.allocator());
                for (validation_layers) |required_layer| {
                    const has_layer: bool = layer_scan: for (available_layers) |layer| {
                        if (std.mem.startsWith(
                            u8,
                            &layer.layer_name,
                            required_layer[0..(std.mem.len(required_layer) - 1)],
                        )) {
                            break :layer_scan true;
                        }
                    } else {
                        break :layer_scan false;
                    };
                    if (!has_layer) {
                        std.debug.print("Missing required layer", .{});
                        return;
                    }
                }
            }

            const app_info: vk.ApplicationInfo = .{
                .p_application_name = "Hello Triangle",
                .application_version = @bitCast(vk.makeApiVersion(0, 1, 0, 0)),
                .p_engine_name = "No Engine",
                .engine_version = @bitCast(vk.makeApiVersion(0, 1, 0, 0)),
                .api_version = @bitCast(vk.API_VERSION_1_4),
            };
            const create_instance_info: vk.InstanceCreateInfo = .{
                .p_application_info = &app_info,
                .enabled_extension_count = @intCast(instance_extensions.len),
                .pp_enabled_extension_names = instance_extensions.ptr,
            };
            _ = try vkb.createInstance(&create_instance_info, null);
        },
    }

    // // vk.PfnEnumerateInstanceExtensionProperties;
    // const instance: vk.Instance  = vk.PfnCreateInstance;

    // Useful for limiting the FPS and getting the delta time
    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = fps } };

    var quit = false;
    while (!quit) {
        // Delay to limit the FPS, returned delta time not needed.
        const dt = fps_capper.delay();
        _ = dt;

        // Update logic
        const surface = try window.getSurface();
        try surface.fillRect(null, surface.mapRgb(128, 30, 255));
        try window.updateSurface();

        // Event logic
        while (sdl3.events.poll()) |event|
            switch (event) {
                .quit => quit = true,
                .terminating => quit = true,
                else => {},
            };

        _ = arena.reset(.retain_capacity);
    }
}
