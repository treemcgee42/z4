
import HandmadeMath

class Chunk {
    var blocks: [BlockId]

    struct Position: Hashable {
        var x: Int
        var y: Int
        var z: Int

        func up() -> Position {
            tracer.fnAssert(condition: self.y < 15, message: "")
            return Position(x: self.x, y: self.y + 1, z: self.z)
        }

        func down() -> Position {
            tracer.fnAssert(condition: self.y > 0, message: "")
            return Position(x: self.x, y: self.y - 1, z: self.z)
        }
    }

    init() {
        self.blocks = Array<BlockId>(
          repeating: BlockId(id: 0, additionalData: 0),
          count: 16*16*16)
    }

    func getBlock(at p: Position) -> BlockId {
        guard (0..<16).contains(p.x),
              (0..<16).contains(p.y),
              (0..<16).contains(p.z) else {
            fatalError("Position out of chunk bounds.")
        }

        let index = p.x + (p.y * 16) + (p.z * 16 * 16)
        return blocks[index]
    }

    func setBlock(at: Position, blockId: BlockId) {
        guard (0..<16).contains(at.x),
              (0..<16).contains(at.y),
              (0..<16).contains(at.z) else {
            fatalError("Position out of chunk bounds.")
        }

        let index = at.x + (at.y * 16) + (at.z * 16 * 16)
        blocks[index] = blockId
    }
}

class World {
    var chunks: [Chunk.Position:Chunk] = [:]
    var modified: Bool = false

    init() {
        chunks[Chunk.Position(x: 0, y: 0, z: 0)] = Chunk()
    }

    private func chunkPosition(
      enclosing p: Chunk.Position
    ) -> (chunkStart: Chunk.Position, positionWithinChunk: Chunk.Position) {
        // Calculate the chunk's starting position in world coordinates
        let chunkX = Int(floor(Float(p.x) / 16)) * 16
        let chunkY = Int(floor(Float(p.y) / 16)) * 16
        let chunkZ = Int(floor(Float(p.z) / 16)) * 16
        let chunkStart = Chunk.Position(x: chunkX, y: chunkY, z: chunkZ)

        // Calculate the position within the chunk (local coordinates from 0 to 15)
        let positionWithinX = p.x - chunkX
        let positionWithinY = p.y - chunkY
        let positionWithinZ = p.z - chunkZ
        let positionWithinChunk = Chunk.Position(
          x: positionWithinX,
          y: positionWithinY,
          z: positionWithinZ)

        return (chunkStart, positionWithinChunk)
    }

    func getBlock(at p: Chunk.Position) -> BlockId {
        let chunkPosition = self.chunkPosition(enclosing: p)
        let chunk = self.chunks[chunkPosition.chunkStart]!
        return chunk.getBlock(at: chunkPosition.positionWithinChunk)
    }

    func addBlock(at p: Chunk.Position, blockId: BlockId) {
        let chunkPosition = self.chunkPosition(enclosing: p)

        let chunk = self.chunks[chunkPosition.chunkStart]!
        chunk.setBlock(at: chunkPosition.positionWithinChunk, blockId: blockId)
        self.modified = true
    }
}

class Scene {
    var ticksPerSecond = 20
    var tickInterval = 0.05
    var tickAccumulator: Double = 0
    var elapsedTicks = 0

    let textureManager: TextureManager
    let blockManager: BlockManager
    let opaqueModelRenderer: OpaqueModelRenderer
    let shaderManager: ShaderManager
    let world: World

    var scheduledBlocksToTick: [Chunk.Position] = []

    init() {
        self.textureManager = TextureManager()
        self.textureManager.createTextureAtlas()
        self.blockManager = BlockManager()
        self.opaqueModelRenderer = OpaqueModelRenderer(
          blockManager: blockManager,
          textureManager: textureManager)
        self.shaderManager = ShaderManager()
        self.world = World()
    }

    func tick() {
        let blocks = self.scheduledBlocksToTick
        self.scheduledBlocksToTick = []

        for blockPosition in blocks {
            let blockId = self.world.getBlock(at: blockPosition)
            self.blockManager.tick(scene: self, position: blockPosition, blockId: blockId)
        }

        self.elapsedTicks += 1
    }

    func tick(deltaTime: Double) {
        self.tickAccumulator += deltaTime
        while self.tickAccumulator > self.tickInterval {
            self.tick()
            self.tickAccumulator -= tickInterval
        }
    }

    func frame(deltaTime: Double) {
        self.tick(deltaTime: deltaTime)
        if world.modified {
            self.createRenderBuffers()
            world.modified = false
        }
    }

    func addBlock(at: Chunk.Position, blockId: BlockId) {
        self.world.addBlock(at: at, blockId: blockId)
    }

    func removeBlock(at: Chunk.Position) {
        self.addBlock(at: at, blockId: BlockId.empty())
    }

    func scheduleBlockToTick(at: Chunk.Position) {
        self.scheduledBlocksToTick.append(at)
    }

    func createRenderBuffers() {
        for (chunkStart, chunk) in world.chunks {
            for i in 0..<16 {
                for j in 0..<16 {
                    for k in 0..<16 {
                        let blockId = chunk.getBlock(at: Chunk.Position(x: i, y: j, z: k))
                        if blockId.data != 0 {
                            self.opaqueModelRenderer.addBlock(
                              blockId: blockId,
                              at: HMM_Vec3(Elements: (Float(chunkStart.x + i),
                                                      Float(chunkStart.y + j),
                                                      Float(chunkStart.z + k))))
                        }
                    }
                }
            }
        }
        self.opaqueModelRenderer.createBuffers()
        self.opaqueModelRenderer.vertices = []
        self.opaqueModelRenderer.indices = []
        self.opaqueModelRenderer.createBindings()
    }

    func createRenderResources() {
        self.createRenderBuffers()
        self.opaqueModelRenderer.createShaders(shaderManager: shaderManager)
        self.opaqueModelRenderer.createPipeline()
    }
}
