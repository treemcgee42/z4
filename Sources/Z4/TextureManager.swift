
import PNG
import Sokol

class TextureManager {
    var image: sg_image?
    var sampler: sg_sampler?

    func createTexture(pixels: [UInt32], width: Int, height: Int) {
        self.image = {
            var imageDesc = sg_image_desc()
            imageDesc.width = Int32(width)
            imageDesc.height = Int32(height)
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

    func createCheckerboardTexture() {
        let pixels: [UInt32] = [
          0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
          0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF,
          0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
          0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF,
        ]

        createTexture(pixels: pixels, width: 4, height: 4)
    }

    func getTextureUvs(textureName: String) -> (uMin: Float, vMin: Float, uMax: Float, vMax: Float) {
        return (uMin: 1, vMin: 1, uMax: 0, vMax: 0)
    }

    func loadTextureFromFile(textureName: String) {
        let path = "Sources/Z4/Assets/Textures/\(textureName).png"
        var pngImage: PNG.Image? = nil
        do {
            pngImage = try .decompress(path: path)
            if pngImage == nil {
                fatalError("failed to open file '\(path).png'")
            }
        } catch {
            fatalError("\(error)")
        }
        let rgba = pngImage!.unpack(as: PNG.RGBA<UInt8>.self)

        self.createTexture(pixels: self.rgbaToUInt32Array(rgbaArray: rgba),
                           width: pngImage!.size.x,
                           height: pngImage!.size.y)
    }

    private func rgbaToUInt32Array(rgbaArray: [PNG.RGBA<UInt8>]) -> [UInt32] {
        return rgbaArray.map { rgba in
            let r = UInt32(rgba.r)
            let g = UInt32(rgba.g) << 8
            let b = UInt32(rgba.b) << 16
            let a = UInt32(rgba.a) << 24
            return r | g | b | a
        }
    }
}
