import Foundation

import HandmadeMath
import Imgui

/// A 3D perspective camera.
///
/// Assumes right-handed coordinate system and column-major matrices.
class Camera3d {
    let inputState: InputState
    let pickingState: PickingState
    let windowState: WindowState

    var projectionKind: ProjectionKind

    var aspectRatio: Float {
        return Float(windowWidth) / Float(windowHeight)
    }
    var windowWidth: Int {
        return windowState.windowSize.width
    }
    var windowHeight: Int {
        return windowState.windowSize.height
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
        var near: Float
        var far: Float
    }

    struct OrthographicParams {
        var width: Float
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
         inputState: InputState, pickingState: PickingState, windowState: WindowState) {
        self.perspectiveParams = perspective
        self.orthographicParams = orthographic
        self.projectionKind = projectionKind
        self.viewParams = view
        self.inputState = inputState
        self.pickingState = pickingState
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

        self.inputState.registerReactor { [weak self] to, changedPropertyId in
            if self == nil {
                return true
            }

            switch changedPropertyId {
            case to.leftMouseButtonClickId:
                let p = to.leftMouseButtonClick
                self!.pickingState.clickRay = self!.unproject(point: p)
            default:
                break
            }

            return false
        }
    }

    static func unprojectOrthographic(
      point: Vec2f,
      viewParams: ViewParams,
      orthoWidth: Float,
      orthoHeight: Float,
      windowSize: Size<Int>) -> Ray {
        // Vector from lookFrom to lookAt
        let camDirection = Vec3f(viewParams.lookAt) - Vec3f(viewParams.lookFrom)

        // In window coordinates, Y is down.
        // In Metal, NDC is (-1, -1, 0) to (1, 1, 1), Y is up.
        let ndc = Vec3f(x: 2 * point.x / Float(windowSize.width) - 1,
                        y: 1 - 2 * point.y / Float(windowSize.height),
                        z: 0)

        let coordsScaledToFrustum = Vec2f(x: ndc.x * orthoWidth / 2,
                                          y: ndc.y * orthoHeight / 2)

        let camRight = Vec3f.normalize(Vec3f.crossProduct(camDirection, Vec3f(viewParams.upDirection)))
        let camUp = Vec3f.normalize(Vec3f.crossProduct(camRight, camDirection))

        let origin = (Vec3f(viewParams.lookFrom) +
                        (coordsScaledToFrustum.x * camRight ) +
                        (coordsScaledToFrustum.y * camUp))
        let direction = camDirection

        return Ray(origin: origin, direction: direction)
    }

    func unproject(point: Vec2f) -> Ray {
        return Self.unprojectOrthographic(point: point,
                                          viewParams: self.viewParams,
                                          orthoWidth: self.orthographicParams.width,
                                          orthoHeight: self.orthographicParams.width / self.aspectRatio,
                                          windowSize: self.windowState.windowSize)
    }

    func windowSizeReactor() {
        self.recomputeProjectionMatrix()
    }

    static func computeOrthographicProjectionMatrix(
      left: Float, right: Float,
      bottom: Float, top: Float,
      near: Float, far: Float) -> HMM_Mat4 {
        return HMM_Orthographic_RH_ZO(left, right,
                                      bottom, top,
                                      near, far)
    }

    static func computePerspectiveProjectionMatrix(
      fovRadians: Float, aspectRatio: Float, near: Float, far: Float) -> HMM_Mat4 {
        return HMM_Perspective_RH_ZO(fovRadians, aspectRatio, near, far)
    }

    static func computeViewMatrix(_ p: ViewParams) -> HMM_Mat4 {
        return HMM_LookAt_RH(p.lookFrom, p.lookAt, p.upDirection)
    }

    func recomputeProjectionMatrix() {
        switch self.projectionKind {
        case .orthographic:
            let left = -self.orthographicParams.width / 2
            let right = self.orthographicParams.width / 2
            let orthoHeight = self.orthographicParams.width / self.aspectRatio
            let bottom = -orthoHeight / 2
            let top = orthoHeight / 2

            self.projectionMatrix = Camera3d.computeOrthographicProjectionMatrix(
              left: left, right: right,
              bottom: bottom, top: top,
              near: self.orthographicParams.near, far: self.orthographicParams.far)
        case .perspective:
            let fovRadians = self.perspectiveParams.fov.converted(to: .radians).value
            self.projectionMatrix = Camera3d.computePerspectiveProjectionMatrix(
              fovRadians: Float(fovRadians), aspectRatio: self.aspectRatio,
              near: self.perspectiveParams.near, far: self.perspectiveParams.far)
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
                ImGui.InputFloat("width", &p.width, 1, 1000, "%.1f")
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
