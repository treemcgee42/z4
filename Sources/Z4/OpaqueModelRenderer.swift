
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

    struct Vertex {
        var position: HMM_Vec4
        var color: HMM_Vec4
    }

    init() {
        self.vertices = []
        self.indices = []
    }

    func createBuffers() {
        self.vertexBuffer = {
            self.vertices.withUnsafeBufferPointer { ubp in
                let range = sg_range(ptr: ubp.baseAddress, size: ubp.count * MemoryLayout<Vertex>.size)
                var desc = sg_buffer_desc()
                desc.data = range
                return sg_make_buffer(&desc)
            }
        }()
        self.indexBuffer = {
            self.indices.withUnsafeBufferPointer { ubp in
                let range = sg_range(ptr: ubp.baseAddress, size: ubp.count * MemoryLayout<Int16>.size)
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
        self.shader = {
            vertexShaderSource.withCString{ vs in
                fragmentShaderSource.withCString { fs in
                    var shaderDesc = sg_shader_desc()
                    shaderDesc.vs.source = vs
                    shaderDesc.vs.uniform_blocks.0.size = MemoryLayout<vs_params_t>.size
                    shaderDesc.fs.source = fs
                    return sg_make_shader(&shaderDesc)
                }
            }
        }()
    }

    func createBindings() {
        self.bindings = sg_bindings()
        self.bindings!.vertex_buffers.0 = self.vertexBuffer!
        self.bindings!.index_buffer = self.indexBuffer!
    }

    func createPipeline() {
        var pipelineDesc = sg_pipeline_desc()
        pipelineDesc.shader = self.shader!
        pipelineDesc.layout.buffers.0.stride = Int32(MemoryLayout<Vertex>.stride)
        pipelineDesc.layout.attrs.0.format = SG_VERTEXFORMAT_FLOAT4
        pipelineDesc.layout.attrs.1.format = SG_VERTEXFORMAT_FLOAT4
        pipelineDesc.index_type = SG_INDEXTYPE_UINT16
        pipelineDesc.depth.compare = SG_COMPAREFUNC_LESS_EQUAL
        pipelineDesc.depth.write_enabled = true
        pipelineDesc.cull_mode = SG_CULLMODE_BACK
        self.pipeline = sg_make_pipeline(&pipelineDesc)
    }

    func addBox(corner1: HMM_Vec3, corner2: HMM_Vec3) {
        let minCorner = HMM_Vec3(Elements: (min(corner1[0], corner2[0]),
                                            min(corner1[1], corner2[1]),
                                            min(corner1[2], corner2[2])))
        let maxCorner = HMM_Vec3(Elements: (max(corner1[0], corner2[0]),
                                            max(corner1[1], corner2[1]),
                                            max(corner1[2], corner2[2])))

        let startIndex = Int16(self.vertices.count)

        // --- Front face
        // (0,0,1)
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (minCorner[0], minCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 0, 1))))
        // (1,0,1) +1
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (maxCorner[0], minCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 0, 1))))
        // (0,1,1) +2
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (minCorner[0], maxCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 0, 1))))
        // (1,1,1) +3
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (maxCorner[0], maxCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 0, 1))))
        indices.append(startIndex)
        indices.append(startIndex + 2)
        indices.append(startIndex + 3)
        indices.append(startIndex)
        indices.append(startIndex + 3)
        indices.append(startIndex + 1)

        // --- Back face
        // (0,0,0) +4
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (minCorner[0], minCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 0, 1))))
        // (1,0,0) +5
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (maxCorner[0], minCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 0, 1))))
        // (0,1,0) +6
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (minCorner[0], maxCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 0, 1))))
        // (1,1,0) +7
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (maxCorner[0], maxCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 0, 1))))
        indices.append(startIndex + 4)
        indices.append(startIndex + 5)
        indices.append(startIndex + 7)
        indices.append(startIndex + 4)
        indices.append(startIndex + 7)
        indices.append(startIndex + 6)

        // --- Left face
        // (0,0,0) +8
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (minCorner[0], minCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 0, 1, 1))))
        // (0,1,0) +9
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (minCorner[0], maxCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 0, 1, 1))))
        // (0,0,1) +10
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (minCorner[0], minCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 0, 1, 1))))
        // (0,1,1) +11
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (minCorner[0], maxCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 0, 1, 1))))
        indices.append(startIndex + 10)
        indices.append(startIndex + 8)
        indices.append(startIndex + 9)
        indices.append(startIndex + 10)
        indices.append(startIndex + 9)
        indices.append(startIndex + 11)

        // --- Right face
        // (1,0,0) +12
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (maxCorner[0], minCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 1, 1))))
        // (1,1,0) +13
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (maxCorner[0], maxCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 1, 1))))
        // (1,0,1) +14
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (maxCorner[0], minCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 1, 1))))
        // (1,1,1) +15
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (maxCorner[0], maxCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (0, 1, 1, 1))))
        indices.append(startIndex + 14)
        indices.append(startIndex + 15)
        indices.append(startIndex + 13)
        indices.append(startIndex + 14)
        indices.append(startIndex + 13)
        indices.append(startIndex + 12)

        // --- Bottom face
        // (0,0,0) +16
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (minCorner[0], minCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 1, 0, 1))))
        // (1,0,0) +17
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (maxCorner[0], minCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 1, 0, 1))))
        // (0,0,1) +18
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (minCorner[0], minCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 1, 0, 1))))
        // (1,0,1) +19
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (maxCorner[0], minCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 1, 0, 1))))
        indices.append(startIndex + 18)
        indices.append(startIndex + 19)
        indices.append(startIndex + 17)
        indices.append(startIndex + 18)
        indices.append(startIndex + 17)
        indices.append(startIndex + 16)

        // --- Top face
        // (0,1,0) +20
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (minCorner[0], maxCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 1, 1))))
        // (1,1,0) +21
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (maxCorner[0], maxCorner[1], minCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 1, 1))))
        // (0,1,1) +22
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (minCorner[0], maxCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 1, 1))))
        // (1,1,1) +23
        self.vertices.append(
          Vertex.init(
            position: HMM_Vec4(Elements: (maxCorner[0], maxCorner[1], maxCorner[2], 1)),
            color: HMM_Vec4(Elements: (1, 0, 1, 1))))
        indices.append(startIndex + 22)
        indices.append(startIndex + 20)
        indices.append(startIndex + 21)
        indices.append(startIndex + 22)
        indices.append(startIndex + 21)
        indices.append(startIndex + 23)
    }
}
