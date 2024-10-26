
import Sokol

class TextureManager {
    var image: sg_image?
    var sampler: sg_sampler?

    func createTexture() {
        let pixels: [UInt32] = [
          0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
          0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF,
          0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
          0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF,
        ]

        self.image = {
            var imageDesc = sg_image_desc()
            imageDesc.width = 4
            imageDesc.height = 4
            return pixels.withUnsafeBufferPointer { ubp in
                let range = sg_range(ptr: ubp.baseAddress, size: ubp.count * MemoryLayout<UInt32>.size)
                imageDesc.data.subimage.0.0 = range
                return sg_make_image(&imageDesc)
            }
        }()

        self.sampler = {
            var samplerDesc = sg_sampler_desc()
            samplerDesc.min_filter = SG_FILTER_NEAREST
            samplerDesc.mag_filter = SG_FILTER_NEAREST
            return sg_make_sampler(&samplerDesc)
        }()
    }

    func getTextureUvs(textureName: String) -> (uMin: Float, vMin: Float, uMax: Float, vMax: Float) {
        return (uMin: 0, vMin: 0, uMax: 1, vMax: 1)
    }
}
