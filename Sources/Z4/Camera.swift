import Foundation

import HandmadeMath
import Imgui

/// A 3D perspective camera.
///
/// Assumes right-handed coordinate system and column-major matrices.
class Camera3dPerspective {
    let windowState: WindowState

    var fov: Measurement<UnitAngle>
    var aspectRatio: Float {
        return Float(windowState.windowSize.width) / Float(windowState.windowSize.height)
    }
    var near: Float
    var far: Float
    var lookFrom: HMM_Vec3
    var lookAt: HMM_Vec3
    var upDirection: HMM_Vec3

    var projectionMatrix: HMM_Mat4
    var viewMatrix: HMM_Mat4
    var viewProjectionMatrix: HMM_Mat4 {
        return HMM_MulM4(self.projectionMatrix, self.viewMatrix)
    }

    init(fov: Measurement<UnitAngle>, near: Float, far: Float,
         lookFrom: HMM_Vec3, lookAt: HMM_Vec3, upDirection: HMM_Vec3,
         windowState: WindowState) {
        self.fov = fov
        self.near = near
        self.far = far
        self.lookFrom = lookFrom
        self.lookAt = lookAt
        self.upDirection = upDirection
        self.windowState = windowState

        self.viewMatrix = Camera3dPerspective.computeViewMatrix(
          lookFrom: lookFrom,
          lookAt: lookAt,
          upDirection: upDirection)
        self.projectionMatrix = Camera3dPerspective.computeProjectionMatrix(
          fov: fov,
          aspectRatio: Float(windowState.windowSize.width) / Float(windowState.windowSize.height),
          near: near,
          far: far)

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

    static func computeProjectionMatrix(
      fov: Measurement<UnitAngle>,
      aspectRatio: Float,
      near: Float,
      far: Float
    ) -> HMM_Mat4 {
        return HMM_Perspective_RH_ZO(
          Float(fov.converted(to: .radians).value), aspectRatio, near, far)
    }

    static func computeViewMatrix(
      lookFrom: HMM_Vec3,
      lookAt: HMM_Vec3,
      upDirection: HMM_Vec3
    ) -> HMM_Mat4 {
        return HMM_LookAt_RH(lookFrom, lookAt, upDirection)
    }

    func recomputeProjectionMatrix() {
        self.projectionMatrix = Camera3dPerspective.computeProjectionMatrix(
          fov: self.fov, aspectRatio: self.aspectRatio, near: self.near, far: self.far)
    }

    func recomputeViewMatrix() {
        self.viewMatrix = Camera3dPerspective.computeViewMatrix(
          lookFrom: self.lookFrom, lookAt: self.lookAt, upDirection: self.upDirection)
    }

    func imguiDebugWindow() {
        var fov = Float(self.fov.converted(to: .degrees).value)
        var near = self.near
        var far = self.far
        var lookFrom: [Float] = [self.lookFrom[0], self.lookFrom[1], self.lookFrom[2]]
        var lookAt: [Float] = [self.lookAt[0], self.lookAt[1], self.lookAt[2]]
        var upDirection: [Float] = [self.upDirection[0], self.upDirection[1], self.upDirection[2]]

        if ImGui.CollapsingHeader("Camera") {
            ImGui.SeparatorText("Perspective")
            ImGui.InputFloat("fov (degrees)", &fov, 1, 179, "%.3f")
            ImGui.InputFloat("near", &near, 0.001, 1, "%.3f")
            ImGui.InputFloat("far", &far, 1, 100000, "%.3f")

            ImGui.SeparatorText("View")
            ImGui.InputFloat3("look from", &lookFrom);
            ImGui.InputFloat3("look at", &lookAt);
            ImGui.InputFloat3("up direction", &upDirection);

            self.fov = Measurement(value: Double(fov), unit: UnitAngle.degrees)
            self.near = near
            self.far = far
            self.recomputeProjectionMatrix()
            self.lookFrom = HMM_Vec3(Elements: (lookFrom[0], lookFrom[1], lookFrom[2]))
            self.lookAt = HMM_Vec3(Elements: (lookAt[0], lookAt[1], lookAt[2]))
            self.upDirection = HMM_Vec3(Elements: (upDirection[0], upDirection[1], upDirection[2]))
            self.recomputeViewMatrix()
        }
    }
}
