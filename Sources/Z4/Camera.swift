import Foundation

import HandmadeMath
import Imgui

/// A 3D perspective camera.
///
/// Assumes right-handed coordinate system and column-major matrices.
class Camera3d {
    let windowState: WindowState

    var projectionKind: ProjectionKind

    var aspectRatio: Float {
        return Float(windowState.windowSize.width) / Float(windowState.windowSize.height)
    }
    var viewParams: ViewParams
    var orthographicParams: OrthographicParams
    var perspectiveParams: PerspectiveParams

    var projectionMatrix: HMM_Mat4!
    var viewMatrix: HMM_Mat4!
    var viewProjectionMatrix: HMM_Mat4 {
        return HMM_MulM4(self.projectionMatrix, self.viewMatrix)
    }

    enum ProjectionKind {
        case perspective
        case orthographic
    }

    struct PerspectiveParams {
        var fov: Measurement<UnitAngle>
        var aspectRatio: Float
        var near: Float
        var far: Float
    }

    struct OrthographicParams {
        var left: Float
        var right: Float
        var bottom: Float
        var top: Float
        var near: Float
        var far: Float
    }

    struct ViewParams {
        var lookFrom: HMM_Vec3
        var lookAt: HMM_Vec3
        var upDirection: HMM_Vec3
    }

    init(perspective: PerspectiveParams, orthographic: OrthographicParams,
         projectionKind: ProjectionKind,
         view: ViewParams,
         windowState: WindowState) {
        self.perspectiveParams = perspective
        self.orthographicParams = orthographic
        self.projectionKind = projectionKind
        self.viewParams = view
        self.windowState = windowState

        self.recomputeViewMatrix()
        self.recomputeProjectionMatrix()

        windowState.registerReactor { [weak self] to, changedPropertyId in
            if self == nil {
                return true
            }

            switch changedPropertyId {
            case to.windowSizeId:
                self?.windowSizeReactor()
            default:
                break
            }

            return false
        }
    }

    func windowSizeReactor() {
        self.recomputeProjectionMatrix()
    }

    static func computeOrthographicProjectionMatrix(_ p: OrthographicParams) -> HMM_Mat4 {
        return HMM_Orthographic_RH_ZO(p.left, p.right,
                                      p.bottom, p.top,
                                      p.near, p.far)
    }

    static func computePerspectiveProjectionMatrix(_ p: PerspectiveParams) -> HMM_Mat4 {
        return HMM_Perspective_RH_ZO(
          Float(p.fov.converted(to: .radians).value),
          p.aspectRatio,
          p.near,
          p.far)
    }

    static func computeViewMatrix(_ p: ViewParams) -> HMM_Mat4 {
        return HMM_LookAt_RH(p.lookFrom, p.lookAt, p.upDirection)
    }

    func recomputeProjectionMatrix() {
        switch self.projectionKind {
        case .orthographic:
            let width = self.orthographicParams.right - self.orthographicParams.left
            let height = width / self.aspectRatio
            self.orthographicParams.top = height + self.orthographicParams.bottom

            self.projectionMatrix = Camera3d.computeOrthographicProjectionMatrix(
              self.orthographicParams)
        case .perspective:
            self.perspectiveParams.aspectRatio = self.aspectRatio
            self.projectionMatrix = Camera3d.computePerspectiveProjectionMatrix(
              self.perspectiveParams)
        }
    }

    func recomputeViewMatrix() {
        self.viewMatrix = Camera3d.computeViewMatrix(self.viewParams)
    }

    func imguiDebugWindow() {
        if ImGui.CollapsingHeader("Camera") {
            ImGui.SeparatorText("Projection")

            // Projection kind selector
            let perspectiveProjectionKind: Int32 = 0
            let orthographicProjectionKind: Int32 = 1
            var projectionKind: Int32 = {
                switch self.projectionKind {
                case .perspective:
                    return perspectiveProjectionKind
                case .orthographic:
                    return orthographicProjectionKind
                }
            }()
            ImGui.RadioButton("perspective", &projectionKind, perspectiveProjectionKind)
            ImGui.SameLine()
            ImGui.RadioButton("orthographic", &projectionKind, orthographicProjectionKind)

            // Projection options
            switch projectionKind {
            case perspectiveProjectionKind:
                self.projectionKind = .perspective
                var p = self.perspectiveParams
                var fovDeg = Float(p.fov.converted(to: .degrees).value)
                ImGui.InputFloat("fov (degrees)", &fovDeg, 1, 179, "%.3f")
                ImGui.InputFloat("near", &p.near, 0.001, 1, "%.3f")
                ImGui.InputFloat("far", &p.far, 1, 100000, "%.3f")
                p.fov = Measurement(value: Double(fovDeg), unit: UnitAngle.degrees)
                self.perspectiveParams = p
                self.recomputeProjectionMatrix()
            case orthographicProjectionKind:
                self.projectionKind = .orthographic
                var p = self.orthographicParams
                ImGui.InputFloat("left", &p.left, -1000, 1000, "%.1f")
                ImGui.InputFloat("right", &p.right, -1000, 1000, "%.1f")
                ImGui.InputFloat("bottom", &p.bottom, -1000, 1000, "%.1f")
                ImGui.InputFloat("top", &p.top, -1000, 1000, "%.1f")
                ImGui.InputFloat("near", &p.near, 0.001, 1, "%.3f")
                ImGui.InputFloat("far", &p.far, 1, 100000, "%.3f")
                self.orthographicParams = p
                self.recomputeProjectionMatrix()
            default:
                fatalError("unexpected projection option \(projectionKind)")
            }

            // View options
            var p = self.viewParams
            var lookFrom: [Float] = [p.lookFrom[0], p.lookFrom[1], p.lookFrom[2]]
            var lookAt: [Float] = [p.lookAt[0], p.lookAt[1], p.lookAt[2]]
            var upDirection: [Float] = [p.upDirection[0], p.upDirection[1], p.upDirection[2]]
            ImGui.SeparatorText("View")
            ImGui.InputFloat3("look from", &lookFrom);
            ImGui.InputFloat3("look at", &lookAt);
            ImGui.InputFloat3("up direction", &upDirection);
            p.lookFrom = HMM_Vec3(Elements: (lookFrom[0], lookFrom[1], lookFrom[2]))
            p.lookAt = HMM_Vec3(Elements: (lookAt[0], lookAt[1], lookAt[2]))
            p.upDirection = HMM_Vec3(Elements: (upDirection[0], upDirection[1], upDirection[2]))
            self.viewParams = p
            self.recomputeViewMatrix()
        }
    }
}
