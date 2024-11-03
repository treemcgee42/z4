
import HandmadeMath

struct Size<T: Equatable>: Equatable {
    var width: T
    var height: T
}

struct Intersection {
    var point: Vec3f
    var t: Float
}

struct Ray {
    var origin: Vec3f
    var direction: Vec3f

    func at(_ t: Float) -> Vec3f {
        return self.origin + t * self.direction
    }

    func contains(_ p: Vec3f) -> Float? {
        let diff = p - self.origin

        var t: Float = 0
        if !direction.x.isEqual(to: 0) {
            t = diff.x / direction.x
        } else if !direction.y.isEqual(to: 0) {
            t = diff.y / direction.y
        } else if !direction.z.isEqual(to: 0) {
            t = diff.z / direction.z
        } else {
            fatalError("")
        }

        if (t * direction == diff) {
            return t
        }
        return nil
    }
}

struct Vec2f: CustomStringConvertible {
    var x: Float
    var y: Float

    var description: String {
        return "Vec2f(\(self.x), \(self.y))"
    }
}

struct Vec3f: CustomStringConvertible {
    var data: HMM_Vec3

    var x: Float {
        get { return data[0] }
        set { data[0] = newValue }
    }
    var y: Float {
        get { return data[1] }
        set { data[1] = newValue }
    }
    var z: Float {
        get { return data[2] }
        set { data[2] = newValue }
    }

    var description: String {
        return "Vec3f(\(self.x), \(self.y), \(self.z))"
    }

    init(x: Float, y: Float, z: Float) {
        self.data = HMM_Vec3(Elements: (x, y, z))
    }

    init(_ data: HMM_Vec3) {
        self.data = data
    }

    static func epsilon() -> Self {
        return .init(x: Float.ulpOfOne, y: Float.ulpOfOne, z: Float.ulpOfOne)
    }

    static func crossProduct(_ left: Vec3f, _ right: Vec3f) -> Vec3f {
        return .init(HMM_Cross(left.data, right.data))
    }

    static func normalize(_ v: Self) -> Self {
        let norm = (v.x * v.x + v.y * v.y + v.z * v.z).squareRoot()
        return .init(x: v.x / norm,
                     y: v.y / norm,
                     z: v.z / norm)
    }

    static func + (left: Self, right: Self) -> Self {
        return .init(HMM_AddV3(left.data, right.data))
    }

    static func - (left: Self, right: Self) -> Self {
        return .init(HMM_SubV3(left.data, right.data))
    }

    static func * (left: Float, right: Self) -> Self {
        return .init(HMM_MulV3F(right.data, left))
    }

    static func == (left: Self, right: Self) -> Bool {
        return left.x.isEqual(to: right.x) &&
          left.y.isEqual(to: right.y) &&
          left.z.isEqual(to: right.z)
    }
}
