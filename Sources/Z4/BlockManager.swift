
import HandmadeMath

struct BoxBounds {
    var corner1: HMM_Vec3
    var corner2: HMM_Vec3

    init(corner1: (x: Float, y: Float, z: Float),
         corner2: (x: Float, y: Float, z: Float)) {
        self.corner1 = HMM_Vec3(Elements: (corner1.x, corner1.y, corner1.z))
        self.corner2 = HMM_Vec3(Elements: (corner2.x, corner2.y, corner2.z))
    }

    init(corner1: HMM_Vec3, corner2: HMM_Vec3) {
        self.corner1 = corner1
        self.corner2 = corner2
    }

    func at(_ pos: HMM_Vec3) -> BoxBounds {
        let translation = pos - self.corner1
        return BoxBounds(corner1: pos,
                         corner2: self.corner2 + translation)
    }

    func minCorner() -> HMM_Vec3 {
        return HMM_Vec3(Elements: (min(self.corner1[0], self.corner2[0]),
                                   min(self.corner1[1], self.corner2[1]),
                                   min(self.corner1[2], self.corner2[2])))
    }

    func maxCorner() -> HMM_Vec3 {
        return HMM_Vec3(Elements: (max(self.corner1[0], self.corner2[0]),
                                   max(self.corner1[1], self.corner2[1]),
                                   max(self.corner1[2], self.corner2[2])))
    }
}

struct BoxInfo {
    var bounds: BoxBounds
    var textures: (front: String, back: String,
                   left: String, right: String,
                   top: String, bottom: String)

    func at(_ pos: HMM_Vec3) -> BoxInfo {
        return BoxInfo(bounds: self.bounds.at(pos), textures: self.textures)
    }
}

struct BlockInfo {
    var name: String
    var components: [BoxInfo]
}

class BlockManager {
    var blockInfoMap: [String:BlockInfo] = [:]

    init() {
        let grassInfo = BlockInfo(
          name: "grass",
          components: [
            BoxInfo(
              bounds: BoxBounds(corner1: (x: 0, y: 0, z: 0),
                                corner2: (x: 1, y: 1, z: 1)),
              textures: (front: "grassSide", back: "grassSide",
                         left: "grassSide", right: "grassSide",
                         top: "grassTop", bottom: "grassBottom"))
          ]
        )
        self.blockInfoMap[grassInfo.name] = grassInfo
    }

    func blockInfo(name: String) -> BlockInfo {
        return self.blockInfoMap[name]!
    }
}
