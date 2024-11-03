
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

    struct Bounds {
        var min: Position
        var max: Position

        /**
         Initialize empty bounds around the provided point.
         */
        init(at: Position) {
            self.min = .init(x: 0, y: 0, z: 0)
            self.max = .init(x: 0, y: 0, z: 0)
        }

        /**
         Initialize the bounds between two points.

         The two points describe a rectangular prism. `min` is the component-wise
         minimum corner of this box, and `max` is the component-wise maximum.
         */
        init(min: Position, max: Position) {
            self.min = min
            self.max = max
        }

        /**
         Extend the current bounds as much as is necessary to fit the new bounds.
         */
        mutating func extendToFit(bounds: Bounds) {
            // Update the min position to be the smallest values of each axis
            min.x = Swift.min(min.x, bounds.min.x)
            min.y = Swift.min(min.y, bounds.min.y)
            min.z = Swift.min(min.z, bounds.min.z)

            // Update the max position to be the largest values of each axis
            max.x = Swift.max(max.x, bounds.max.x)
            max.y = Swift.max(max.y, bounds.max.y)
            max.z = Swift.max(max.z, bounds.max.z)
        }

        /**
         Checks if the vector lies withing the bounds.
         */
        func contains(_ v: Vec3f) -> Bool {
            return v.x >= Float(min.x) && v.x <= Float(max.x) &&
               v.y >= Float(min.y) && v.y <= Float(max.y) &&
               v.z >= Float(min.z) && v.z <= Float(max.z)
        }

        /**
         Check if integral point lies within bounds.
         */
        func contains(_ p: Position) -> Bool {
            return p.x >= min.x && p.x <= max.x &&
               p.y >= min.y && p.y <= max.y &&
               p.z >= min.z && p.z <= max.z
        }

        /**
         Check whether the given ray intersects with the bounds.

         - Returns: The intersection if there was one, `nil` ortherwise.
         */
        func intersect(with ray: Ray) -> Intersection? {
            // Calculate intersection along each axis
            let tMinX = (Float(min.x) - ray.origin.x) / ray.direction.x
            let tMaxX = (Float(max.x) - ray.origin.x) / ray.direction.x
            let tMinY = (Float(min.y) - ray.origin.y) / ray.direction.y
            let tMaxY = (Float(max.y) - ray.origin.y) / ray.direction.y
            let tMinZ = (Float(min.z) - ray.origin.z) / ray.direction.z
            let tMaxZ = (Float(max.z) - ray.origin.z) / ray.direction.z

            // Ensure tMin is the entry point and tMax is the exit point for each axis
            let (tEntryX, tExitX) = tMinX < tMaxX ? (tMinX, tMaxX) : (tMaxX, tMinX)
            let (tEntryY, tExitY) = tMinY < tMaxY ? (tMinY, tMaxY) : (tMaxY, tMinY)
            let (tEntryZ, tExitZ) = tMinZ < tMaxZ ? (tMinZ, tMaxZ) : (tMaxZ, tMinZ)

            // Calculate the largest tEntry and smallest tExit across all axes
            let tEntry = Swift.max(tEntryX, tEntryY, tEntryZ)
            let tExit = Swift.min(tExitX, tExitY, tExitZ)

            // If tEntry is less than or equal to tExit, there's an intersection within the bounds
            if tEntry <= tExit && tExit >= 0 {
                // Calculate the intersection point in world space
                let intersectionPoint = Vec3f(
                  x: ray.origin.x + tEntry * ray.direction.x,
                  y: ray.origin.y + tEntry * ray.direction.y,
                  z: ray.origin.z + tEntry * ray.direction.z
                )
                return .init(point: intersectionPoint, t: tEntry)
            }

            // No intersection with the bounds
            return nil
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

    /**
     Find the intersection between this chunk and a ray.

     - Parameter with: The ray to find the intersection with. The ray should be in
     "chunk space", i.e.  the space whose origin is the (component-wise) minimal
     corner of the chunk. The origin should be the intersection of the ray with
     the chunk.

     - Returns: The position of the first-intersected voxel if there was an
     intersection, `nil` otherwise.
     */
    func intersect(with r: Ray) -> Position? {
        let origin = r.origin
        let direction = r.direction + Vec3f.epsilon()

        // Initialize with voxel containing the origin
        var position = Position(x: Int(floor(r.origin.x)),
                                y: Int(floor(r.origin.y)),
                                z: Int(floor(r.origin.z)))

        // Check if the starting position is within bounds
        guard (0..<16).contains(position.x),
              (0..<16).contains(position.y),
              (0..<16).contains(position.z) else {
            return nil
        }

        let stepX = direction.x > 0 ? 1 : -1
        let stepY = direction.y > 0 ? 1 : -1
        let stepZ = direction.z > 0 ? 1 : -1

        let tDeltaX = abs(1.0 / direction.x)
        let tDeltaY = abs(1.0 / direction.y)
        let tDeltaZ = abs(1.0 / direction.z)

        var tMaxX = (Float(position.x + (stepX > 0 ? 1 : 0)) - origin.x) / direction.x
        var tMaxY = (Float(position.y + (stepY > 0 ? 1 : 0)) - origin.y) / direction.y
        var tMaxZ = (Float(position.z + (stepZ > 0 ? 1 : 0)) - origin.z) / direction.z

        // Traverse the voxels along the ray path
        while ((0..<16).contains(position.x) &&
                 (0..<16).contains(position.y) &&
                 (0..<16).contains(position.z)) {
            // Check if the current position contains a block (non-air block)
            let block = getBlock(at: position)
            if block.data != 0 {
                return position // Intersection found
            }

            // Step to the next voxel
            if tMaxX < tMaxY {
                if tMaxX < tMaxZ {
                    tMaxX += tDeltaX
                    position.x += stepX
                } else {
                    tMaxZ += tDeltaZ
                    position.z += stepZ
                }
            } else {
                if tMaxY < tMaxZ {
                    tMaxY += tDeltaY
                    position.y += stepY
                } else {
                    tMaxZ += tDeltaZ
                    position.z += stepZ
                }
            }
        }

        // No intersection found within bounds
        return nil
    }
}

class World {
    var chunks: [Chunk.Position:Chunk] = [:]
    var modified: Bool = false

    var worldBounds: Chunk.Bounds

    init() {
        self.worldBounds = .init(at: Chunk.Position(x: 0, y: 0, z: 0))
        self.addChunk(at: .init(x: 0, y: 0, z: 0), chunk: Chunk())
    }

    func addChunk(at p: Chunk.Position, chunk: Chunk) {
        self.chunks[p] = chunk
        self.worldBounds.extendToFit(bounds: .init(min: p, max: .init(x: p.x + 16, y: p.y + 16, z: p.z + 16)))
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

    func intersect(with: Ray) -> Chunk.Position? {
        tracer.fnTrace1("world intersection test with \(with)")
        // Find intersection with world bounds (self.worldBounds.contains(..))
        var origin = with.origin
        let direction = with.direction + Vec3f.epsilon()
        if !self.worldBounds.contains(origin) {
            if let intersection = self.worldBounds.intersect(with: with) {
                origin = intersection.point
            } else {
                return nil
            }
        }

        var intersectedChunks: [(chunkPosition: Chunk.Position, tEntry: Float)] = []

        // Step 1: Initialize position to the chunk containing the ray's origin
        var chunkPosition = Chunk.Position(
          x: Int(floor(origin.x / 16)) * 16,
          y: Int(floor(origin.y / 16)) * 16,
          z: Int(floor(origin.z / 16)) * 16
        )

        // Step 2: Determine the ray's step direction for chunk traversal
        let stepX = direction.x > 0 ? 16 : -16
        let stepY = direction.y > 0 ? 16 : -16
        let stepZ = direction.z > 0 ? 16 : -16

        // Step 3: Calculate tDelta values (distance to the next chunk boundary along each axis)
        let tDeltaX = abs(16.0 / direction.x)
        let tDeltaY = abs(16.0 / direction.y)
        let tDeltaZ = abs(16.0 / direction.z)

        // Calculate initial tMax values for the next chunk boundary
        var tMaxX = (Float(chunkPosition.x + (stepX > 0 ? 16 : 0)) - origin.x) / direction.x
        var tMaxY = (Float(chunkPosition.y + (stepY > 0 ? 16 : 0)) - origin.y) / direction.y
        var tMaxZ = (Float(chunkPosition.z + (stepZ > 0 ? 16 : 0)) - origin.z) / direction.z

        // Step 4: Traverse the chunks along the ray path
        var tEntry: Float = 0
        while true {
            // Record the current chunk and its entry t-value
            if self.chunks[chunkPosition] != nil {
                intersectedChunks.append((chunkPosition, tEntry))
            }

            // Move to the next chunk along the ray
            tEntry = min(tMaxX, tMaxY, tMaxZ)
            if tMaxX < tMaxY {
                if tMaxX < tMaxZ {
                    chunkPosition.x += stepX
                    tMaxX += tDeltaX
                } else {
                    chunkPosition.z += stepZ
                    tMaxZ += tDeltaZ
                }
            } else {
                if tMaxY < tMaxZ {
                    chunkPosition.y += stepY
                    tMaxY += tDeltaY
                } else {
                    chunkPosition.z += stepZ
                    tMaxZ += tDeltaZ
                }
            }

            // Optional: Exit condition if ray travels out of world bounds
            if !self.worldBounds.contains(chunkPosition) {
                break
            }
        }

        // Step 5: Sort intersected chunks by entry distance
        intersectedChunks.sort { $0.tEntry < $1.tEntry }

        // Step 6: Check for intersections in each chunk in sorted order
        for (chunkStart, t) in intersectedChunks {
            if let chunk = chunks[chunkStart] {
                // Transform ray origin to chunk space
                let intersectionPoint = Ray(origin: origin,
                                            direction: direction).at(t)
                let chunkStartF = Vec3f(x: Float(chunkStart.x),
                                        y: Float(chunkStart.y),
                                        z: Float(chunkStart.z))
                let localRay = Ray(
                  origin: intersectionPoint - chunkStartF,
                  direction: direction
                )

                // Call chunk intersection method
                if let localIntersection = chunk.intersect(with: localRay) {
                    // Convert local intersection to world coordinates and return
                    return Chunk.Position(
                      x: chunkStart.x + localIntersection.x,
                      y: chunkStart.y + localIntersection.y,
                      z: chunkStart.z + localIntersection.z
                    )
                }
            }
        }

        // No intersection found
        return nil
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

    let pickingState: PickingState

    init(pickingState: PickingState) {
        self.textureManager = TextureManager()
        self.textureManager.createTextureAtlas()
        self.blockManager = BlockManager()
        self.opaqueModelRenderer = OpaqueModelRenderer(
          blockManager: blockManager,
          textureManager: textureManager)
        self.shaderManager = ShaderManager()
        self.world = World()

        self.pickingState = pickingState

        self.pickingState.registerReactor { [weak self] to, changedPropertyId in
            if self == nil {
                return true
            }

            switch changedPropertyId {
            case to.clickRayId:
                let b = self!.world.intersect(with: to.clickRay)
                tracer.fnTrace1("world intersection results: \(b)")
            default:
                break
            }

            return false
        }
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
