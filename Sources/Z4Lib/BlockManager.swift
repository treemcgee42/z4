
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
    var components: [BoxInfo]
}

struct BlockId: Hashable {
    var data: UInt32

    /**
     Initialize with just the id and set additional data to 0.
     */
    init(id: UInt16) {
        self.init(id: id, additionalData: 0)
    }

    init(id: UInt16, additionalData: UInt16) {
        self.data = (UInt32(additionalData) << 16) | UInt32(id)
    }

    static func empty() -> BlockId {
        return BlockId(id: 0, additionalData: 0)
    }

    func id() -> UInt16 {
        // Extract the lower 16 bits.
        return UInt16(data & 0xFFFF)
    }

    func additionalData() -> UInt16 {
        // Extract the upper 16 bits
        return UInt16((data >> 16) & 0xFFFF)
    }

    mutating func setAdditionalData(_ newAdditionalData: UInt16) {
        // Clear the upper 16 bits and set the new additional data.
        self.data = (data & 0xFFFF) | (UInt32(newAdditionalData) << 16)
    }

    func hash(into hasher: inout Hasher) {
        // Hash only the `id` part.
        hasher.combine(self.id())
    }

    static func == (lhs: BlockId, rhs: BlockId) -> Bool {
        // Equality check based only on the `id` part.
        return lhs.id() == rhs.id()
    }
}

protocol Block {
    func tick(scene: Scene, position: Chunk.Position, blockId: BlockId)
}

class GrassBlock: Block {
    func tick(scene: Scene, position: Chunk.Position, blockId: BlockId) {}
}

class MovingGrassBlock: Block {
    struct AdditionalData {
        var tickCounter: UInt8
        var axisToMoveAlong: UInt8

        init(_ additionalData: UInt16) {
            self.tickCounter = (UInt8(additionalData >> 8) & 0xFF)
            self.axisToMoveAlong = UInt8(additionalData & 0xFF)
        }

        func pack() -> UInt16 {
            var packed: UInt16 = 0
            packed |= (UInt16(self.tickCounter) & 0xFF) << 8
            packed |= UInt16(self.axisToMoveAlong) & 0xFF
            return packed
        }
    }

    func tick(scene: Scene, position: Chunk.Position, blockId: BlockId) {
        var additionalData = AdditionalData(blockId.additionalData())
        additionalData.tickCounter += 1

        var newPosition = position
        if additionalData.tickCounter % 40 == 0 {
            newPosition = newPosition.down()
            additionalData.tickCounter = 0
        } else if additionalData.tickCounter % 20 == 0 {
            newPosition = newPosition.up()
        }

        let newBlockId = BlockId(id: blockId.id(), additionalData: additionalData.pack())
        scene.removeBlock(at: position)
        scene.addBlock(at: newPosition, blockId: newBlockId)
        scene.scheduleBlockToTick(at: newPosition)
    }
}

class BlockManager {
    var numBlocks: UInt16 = 0
    var blockIdMap: [String:BlockId] = [:]
    var blockInfoMap: [BlockId:BlockInfo] = [:]
    var blockClassMap: [BlockId:any Block] = [:]

    init() {
        let grassInfo = BlockInfo(
          components: [
            BoxInfo(
              bounds: BoxBounds(corner1: (x: 0, y: 0, z: 0),
                                corner2: (x: 1, y: 1, z: 1)),
              textures: (front: "grassSide", back: "grassSide",
                         left: "grassSide", right: "grassSide",
                         top: "grassTop", bottom: "grassBottom"))
          ]
        )
        self.registerBlock(name: "grass", info: grassInfo, cl: GrassBlock())
        self.registerBlock(name: "movingGrass", info: grassInfo, cl: MovingGrassBlock())
    }

    func tick(scene: Scene, position: Chunk.Position, blockId: BlockId) {
        let cl = self.blockClassMap[blockId]!
        cl.tick(scene: scene, position: position, blockId: blockId)
    }

    func registerBlock(name: String, info: BlockInfo, cl: any Block) {
        self.numBlocks += 1
        let blockId = BlockId(id: self.numBlocks, additionalData: 0)
        self.blockIdMap[name] = blockId
        self.blockInfoMap[blockId] = info
        self.blockClassMap[blockId] = cl
    }

    func blockInfo(blockId: BlockId) -> BlockInfo {
        guard let blockInfo = self.blockInfoMap[blockId] else {
            tracer.fnAssert(
              condition: false,
              message: "blockId (id=\(blockId.id())) not found in map")
            fatalError("")
        }
        return blockInfo
    }

    func blockId(name: String) -> BlockId {
        return self.blockIdMap[name]!
    }
}
