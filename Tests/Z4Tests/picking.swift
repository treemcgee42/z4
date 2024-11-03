import Testing
@testable import Z4Lib

@Test
func boundsIntersection() {
    let bounds = Chunk.Bounds(min: .init(x: 0, y: 0, z: 0),
                        max: .init(x: 16, y: 16, z: 16))
    let r = Ray(origin: .init(x: -20, y: 0.1, z: 0.1),
                direction: .init(x: 1, y: 0, z: 0))
    let intersectionPosition = bounds.intersect(with: r)
    #expect(intersectionPosition != nil)
    #expect(intersectionPosition!.point == Vec3f(x: 0, y: 0.1, z: 0.1))
}

@Test
func chunkIntersection() {
    let chunk = Chunk()
    let blockId = BlockId(id: 1, additionalData: 0)

    // Single direction, zero components in the ray direction.
    chunk.setBlock(at: .init(x: 15, y: 15, z: 15), blockId: blockId)
    let r = Ray(origin: .init(x: 0.2, y: 15.5, z: 15.8),
                direction: .init(x: 1, y: 0, z: 0))
    let intersectionPosition = chunk.intersect(with: r)
    #expect(intersectionPosition != nil)
}

@Test
func worldIntersection() {
    let world = World()

    for i in 1..<5 {
        let chunk = Chunk()
        world.addChunk(at: .init(x: 16*i, y: 0, z: 0), chunk: chunk)
    }
    let blockPosition = Chunk.Position(x: 79, y: 15, z: 15)
    world.addBlock(at: blockPosition, blockId: .init(id: 1))

    let r = Ray(origin: .init(x: -20, y: 15.5, z: 15.8),
                direction: .init(x: 1, y: 0, z: 0))
    let intersectionPosition = world.intersect(with: r)
    #expect(intersectionPosition != nil)
    #expect(intersectionPosition == blockPosition)
}

@Test
func unprojectOrthographic() {
    // Check that the origin is moved to the right place.
    // Look from: (0, 0, 10), look at: (0, 0, 0), up: (0, 1, 0)
    // Window size: (400, 200)
    // Ortho width: 8, ortho height: 4
    // Click at (100, 50) should be (-0.5, 0.5) in Metal NDC.
    // Scaled to frustum, that's (-2, 1).
    // So the origin should be the camera moved along the camera plane that much,
    // i.e. to (-2, 1, 10).
    do {
        let windowSize = Size<Int>(width: 400, height: 200)
        let point = Vec2f(x: 100, y: 50)
        let viewParams = Camera3d.ViewParams(lookFrom: Vec3f(x: 0, y: 0, z: 10).data,
                                             lookAt: Vec3f(x: 0, y: 0, z: 0).data,
                                             upDirection: Vec3f(x: 0, y: 1, z: 0).data)
        let r = Camera3d.unprojectOrthographic(point: point,
                                               viewParams: viewParams,
                                               orthoWidth: 8,
                                               orthoHeight: 4,
                                               windowSize: windowSize)
        #expect(r.origin == Vec3f(x: -2, y: 1, z: 10))
        #expect(Vec3f.normalize(r.direction) == Vec3f(x: 0, y: 0, z: -1))
    }


    let point = Vec2f(x: 400, y: 200) // center
    let viewParams = Camera3d.ViewParams(lookFrom: Vec3f(x: 2, y: 3, z: 10).data,
                                lookAt: Vec3f(x: 2, y: 3, z: 1).data,
                                upDirection: Vec3f(x: 0, y: 1, z: 0).data)
    let windowSize = Size<Int>(width: 800, height: 400)

    let r = Camera3d.unprojectOrthographic(point: point,
                                           viewParams: viewParams,
                                           orthoWidth: 7,
                                           orthoHeight: 8,
                                           windowSize: windowSize)
    #expect(r.contains(Vec3f(x: 2, y: 3, z: -20)) != nil)
}
