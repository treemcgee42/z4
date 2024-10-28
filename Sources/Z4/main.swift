import Metal
import simd

import Glfw
import HandmadeMath
import Imgui
import Sokol

struct vs_params_t {
    var mvp: HMM_Mat4
}

@MainActor
func main() {
    print("hello, world!")

    let mtlDevice = MTLCreateSystemDefaultDevice()!

    let windowingSystem = WindowingSystem(title: "Hello Triangle", width: 640, height: 480, mtlDevice: mtlDevice)

    var sokolDesc = sg_desc()
    sokolDesc.environment = windowingSystem.environment()
    sokolDesc.logger.func = slog_func
    sg_setup(&sokolDesc)

    var sokolImguiDesc = simgui_desc_t()
    sokolImguiDesc.logger.func = slog_func
    simgui_setup(&sokolImguiDesc)

    ImGui_ImplGlfw_InitForOther(windowingSystem.window, false);

    stm_setup();

    let windowSize = windowingSystem.windowSize()
    let camera = Camera3dPerspective(
      fov: Measurement(value: 60, unit: UnitAngle.degrees), aspectRatio: Float(windowSize.width)/Float(windowSize.height), near: 0.01, far: 1000.0,
      lookFrom: HMM_Vec3(Elements: (0.0, 1.5, 6.0)), lookAt: HMM_Vec3(Elements: (0.0, 0.0, 0.0)), upDirection: HMM_Vec3(Elements: (0.0, 1.0, 0.0)))

    let scene = Scene()
    let grassBlockId = scene.blockManager.blockId(name: "grass")
    let movingGrassBlockId = scene.blockManager.blockId(name: "movingGrass")
    scene.addBlock(at: Chunk.Position(x: 0, y: 0, z: 0), blockId: grassBlockId)
    scene.addBlock(at: Chunk.Position(x: 1, y: 1, z: 1), blockId: movingGrassBlockId)
    scene.scheduleBlockToTick(at: Chunk.Position(x: 1, y: 1, z: 1))
    scene.createRenderResources()

    var lastTime: UInt64 = 0
    while (glfwWindowShouldClose(windowingSystem.window) == 0) {
        let deltaTimeSec = stm_sec(stm_laptime(&lastTime))

        scene.frame(deltaTime: deltaTimeSec)

        var pass = sg_pass()
        pass.swapchain = windowingSystem.swapchain()

        var sokolImguiFrameDesc = simgui_frame_desc_t()
        sokolImguiFrameDesc.width = Int32(pass.swapchain.width)
        sokolImguiFrameDesc.height = Int32(pass.swapchain.height)
        sokolImguiFrameDesc.delta_time = deltaTimeSec
        sokolImguiFrameDesc.dpi_scale = windowingSystem.dpiScale()
        simgui_new_frame(&sokolImguiFrameDesc);

        withVaList([], { vaList in
                           ImGui.TextV("Hello", vaList); })
        camera.imguiDebugWindow()

        // ImGui.ShowDemoWindow();

        sg_begin_pass(&pass)
        sg_apply_pipeline(scene.opaqueModelRenderer.pipeline!);
        sg_apply_bindings(&scene.opaqueModelRenderer.bindings!);
        var vs_params = vs_params_t(mvp: camera.viewProjectionMatrix)
        withUnsafeBytes(of: &vs_params) { buffer in
            var range = sg_range(ptr: buffer.baseAddress, size: buffer.count)
            sg_apply_uniforms(SG_SHADERSTAGE_VS, 0, &range)
        }
        sg_draw(0, Int32(scene.opaqueModelRenderer.indexBufferNumIndices), 1);
        simgui_render();
        sg_end_pass();
        sg_commit();
        glfwSwapBuffers(windowingSystem.window);
        glfwPollEvents();
    }

    ImGui_ImplGlfw_Shutdown()
    simgui_shutdown();
    sg_shutdown();
    glfwTerminate();
}

main()
