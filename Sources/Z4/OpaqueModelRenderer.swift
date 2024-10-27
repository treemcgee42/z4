
import HandmadeMath
import Sokol

class OpaqueModelRenderer {
    var vertexBuffer: sg_buffer?
    var indexBuffer: sg_buffer?
    var shader: sg_shader?
    var bindings: sg_bindings?
    var pipeline: sg_pipeline?

    var vertices: [Vertex]
    var indices: [Int16]
    let textureManager: TextureManager

    struct Vertex {
        var position: HMM_Vec4
        var color: HMM_Vec4
        var uv: HMM_Vec2
    }

    init(textureManager: TextureManager) {
        self.vertices = []
        self.indices = []
        self.textureManager = textureManager
    }

    func createBuffers() {
        self.vertexBuffer = {
            self.vertices.withUnsafeBufferPointer { ubp in
                let range = sg_range(ptr: ubp.baseAddress, size: ubp.count * MemoryLayout<Vertex>.stride)
                var desc = sg_buffer_desc()
                desc.data = range
                return sg_make_buffer(&desc)
            }
        }()
        self.indexBuffer = {
            self.indices.withUnsafeBufferPointer { ubp in
                let range = sg_range(ptr: ubp.baseAddress, size: ubp.count * MemoryLayout<Int16>.stride)
                var desc = sg_buffer_desc()
                desc.type = SG_BUFFERTYPE_INDEXBUFFER
                desc.data = range
                return sg_make_buffer(&desc)
            }
        }()
    }

    func createShaders(shaderManager: ShaderManager) {
        let vertexShaderSource = shaderManager.getSource(shaderName: "opaqueModelVs")
        let fragmentShaderSource = shaderManager.getSource(shaderName: "opaqueModelFs")
        let fragmentShaderEntry = "fs_main"
        self.shader = {
            vertexShaderSource.withCString{ vs in
                fragmentShaderSource.withCString { fs in
                    fragmentShaderEntry.withCString { fsEntry in
                        var shaderDesc = sg_shader_desc()

                        shaderDesc.vs.source = vs
                        shaderDesc.vs.uniform_blocks.0.size = MemoryLayout<vs_params_t>.size

                        shaderDesc.fs.source = fs
                        shaderDesc.fs.images.0.used = true
                        shaderDesc.fs.samplers.0.used = true
                        shaderDesc.fs.image_sampler_pairs.0.used = true
                        shaderDesc.fs.image_sampler_pairs.0.image_slot = 0
                        shaderDesc.fs.image_sampler_pairs.0.sampler_slot = 0
                        shaderDesc.fs.entry = fsEntry
                        return sg_make_shader(&shaderDesc)
                    }
                }
            }
        }()
    }

    func createBindings() {
        self.bindings = sg_bindings()
        self.bindings!.vertex_buffers.0 = self.vertexBuffer!
        self.bindings!.index_buffer = self.indexBuffer!
        self.bindings!.fs.images.0 = self.textureManager.image!
        self.bindings!.fs.samplers.0 = self.textureManager.sampler!
    }

    func createPipeline() {
        var pipelineDesc = sg_pipeline_desc()
        pipelineDesc.shader = self.shader!
        pipelineDesc.layout.buffers.0.stride = Int32(MemoryLayout<Vertex>.stride)
        pipelineDesc.layout.attrs.0.format = SG_VERTEXFORMAT_FLOAT4
        pipelineDesc.layout.attrs.1.format = SG_VERTEXFORMAT_FLOAT4
        pipelineDesc.layout.attrs.2.format = SG_VERTEXFORMAT_FLOAT2
        pipelineDesc.index_type = SG_INDEXTYPE_UINT16
        pipelineDesc.depth.compare = SG_COMPAREFUNC_LESS_EQUAL
        pipelineDesc.depth.write_enabled = true
        pipelineDesc.cull_mode = SG_CULLMODE_BACK
        self.pipeline = sg_make_pipeline(&pipelineDesc)
    }

    func addBox(corner1: HMM_Vec3, corner2: HMM_Vec3,
                textures: (bottom: String, top: String, left: String, right: String,
                           front: String, back: String)) {
        let minCorner = HMM_Vec3(Elements: (min(corner1[0], corner2[0]),
                                            min(corner1[1], corner2[1]),
                                            min(corner1[2], corner2[2])))
        let maxCorner = HMM_Vec3(Elements: (max(corner1[0], corner2[0]),
                                            max(corner1[1], corner2[1]),
                                            max(corner1[2], corner2[2])))

        let startIndex = Int16(self.vertices.count)

        // --- Front face
        let frontFaceUvs = self.textureManager.getTextureUvs(textureName: textures.front)
        // (0,0,1)
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (minCorner[0], minCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 0, 1)),
            uv: HMM_Vec2(Elements: (frontFaceUvs.uBeg, frontFaceUvs.vBeg))))
        // (1,0,1) +1
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (maxCorner[0], minCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 0, 1)),
            uv: HMM_Vec2(Elements: (frontFaceUvs.uEnd, frontFaceUvs.vBeg))))
        // (0,1,1) +2
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (minCorner[0], maxCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 0, 1)),
            uv: HMM_Vec2(Elements: (frontFaceUvs.uBeg, frontFaceUvs.vEnd))))
        // (1,1,1) +3
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (maxCorner[0], maxCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 0, 1)),
            uv: HMM_Vec2(Elements: (frontFaceUvs.uEnd, frontFaceUvs.vEnd))))
        indices.append(startIndex)
        indices.append(startIndex + 2)
        indices.append(startIndex + 3)
        indices.append(startIndex)
        indices.append(startIndex + 3)
        indices.append(startIndex + 1)

        // --- Back face
        let backFaceUvs = self.textureManager.getTextureUvs(textureName: textures.back)
        // (0,0,0) +4
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (minCorner[0], minCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 0, 1)),
            uv: HMM_Vec2(Elements: (backFaceUvs.uBeg, backFaceUvs.vBeg))))
        // (1,0,0) +5
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (maxCorner[0], minCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 0, 1)),
            uv: HMM_Vec2(Elements: (backFaceUvs.uEnd, backFaceUvs.vBeg))))
        // (0,1,0) +6
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (minCorner[0], maxCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 0, 1)),
            uv: HMM_Vec2(Elements: (backFaceUvs.uBeg, backFaceUvs.vEnd))))
        // (1,1,0) +7
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (maxCorner[0], maxCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 0, 1)),
            uv: HMM_Vec2(Elements: (backFaceUvs.uEnd, backFaceUvs.vEnd))))
        indices.append(startIndex + 4)
        indices.append(startIndex + 5)
        indices.append(startIndex + 7)
        indices.append(startIndex + 4)
        indices.append(startIndex + 7)
        indices.append(startIndex + 6)

        // --- Left face
        let leftFaceUvs = self.textureManager.getTextureUvs(textureName: textures.left)
        // (0,0,0) +8
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (minCorner[0], minCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 0, 1, 1)),
            uv: HMM_Vec2(Elements: (leftFaceUvs.uBeg, leftFaceUvs.vBeg))))
        // (0,1,0) +9
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (minCorner[0], maxCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 0, 1, 1)),
            uv: HMM_Vec2(Elements: (leftFaceUvs.uBeg, leftFaceUvs.vEnd))))
        // (0,0,1) +10
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (minCorner[0], minCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 0, 1, 1)),
            uv: HMM_Vec2(Elements: (leftFaceUvs.uEnd, leftFaceUvs.vBeg))))
        // (0,1,1) +11
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (minCorner[0], maxCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 0, 1, 1)),
            uv: HMM_Vec2(Elements: (leftFaceUvs.uEnd, leftFaceUvs.vEnd))))
        indices.append(startIndex + 10)
        indices.append(startIndex + 8)
        indices.append(startIndex + 9)
        indices.append(startIndex + 10)
        indices.append(startIndex + 9)
        indices.append(startIndex + 11)

        // --- Right face
        let rightFaceUvs = self.textureManager.getTextureUvs(textureName: textures.right)
        // (1,0,0) +12
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (maxCorner[0], minCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 1, 1)),
            uv: HMM_Vec2(Elements: (rightFaceUvs.uBeg, rightFaceUvs.vBeg))))
        // (1,1,0) +13
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (maxCorner[0], maxCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 1, 1)),
            uv: HMM_Vec2(Elements: (rightFaceUvs.uEnd, rightFaceUvs.vBeg))))
        // (1,0,1) +14
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (maxCorner[0], minCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 1, 1)),
            uv: HMM_Vec2(Elements: (rightFaceUvs.uBeg, rightFaceUvs.vEnd))))
        // (1,1,1) +15
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (maxCorner[0], maxCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 1, 1)),
            uv: HMM_Vec2(Elements: (rightFaceUvs.uEnd, rightFaceUvs.vEnd))))
        indices.append(startIndex + 14)
        indices.append(startIndex + 15)
        indices.append(startIndex + 13)
        indices.append(startIndex + 14)
        indices.append(startIndex + 13)
        indices.append(startIndex + 12)

        // --- Bottom face
        let bottomFaceUvs = self.textureManager.getTextureUvs(textureName: textures.bottom)
        // (0,0,0) +16
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (minCorner[0], minCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 1, 0, 1)),
            uv: HMM_Vec2(Elements: (bottomFaceUvs.uBeg, bottomFaceUvs.vBeg))))
        // (1,0,0) +17
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (maxCorner[0], minCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 1, 0, 1)),
            uv: HMM_Vec2(Elements: (bottomFaceUvs.uEnd, bottomFaceUvs.vBeg))))
        // (0,0,1) +18
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (minCorner[0], minCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 1, 0, 1)),
            uv: HMM_Vec2(Elements: (bottomFaceUvs.uBeg, bottomFaceUvs.vEnd))))
        // (1,0,1) +19
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (maxCorner[0], minCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 1, 0, 1)),
            uv: HMM_Vec2(Elements: (bottomFaceUvs.uEnd, bottomFaceUvs.vEnd))))
        indices.append(startIndex + 18)
        indices.append(startIndex + 19)
        indices.append(startIndex + 17)
        indices.append(startIndex + 18)
        indices.append(startIndex + 17)
        indices.append(startIndex + 16)

        // --- Top face
        let topFaceUvs = self.textureManager.getTextureUvs(textureName: textures.top)
        // (0,1,0) +20
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (minCorner[0], maxCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 1, 1)),
            uv: HMM_Vec2(Elements: (topFaceUvs.uBeg, topFaceUvs.vBeg))))
        // (1,1,0) +21
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (maxCorner[0], maxCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 1, 1)),
            uv: HMM_Vec2(Elements: (topFaceUvs.uEnd, topFaceUvs.vBeg))))
        // (0,1,1) +22
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (minCorner[0], maxCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 1, 1)),
            uv: HMM_Vec2(Elements: (topFaceUvs.uBeg, topFaceUvs.vEnd))))
        // (1,1,1) +23
        self.vertices.append(
          Vertex(
            position: HMM_Vec4(Elements: (maxCorner[0], maxCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 1, 1)),
            uv: HMM_Vec2(Elements: (topFaceUvs.uEnd, topFaceUvs.vEnd))))
        indices.append(startIndex + 22)
        indices.append(startIndex + 20)
        indices.append(startIndex + 21)
        indices.append(startIndex + 22)
        indices.append(startIndex + 21)
        indices.append(startIndex + 23)
    }
}
