
import Foundation

import PNG
import Sokol

struct Uvs {
    var uBeg: Float
    var vBeg: Float
    var uEnd: Float
    var vEnd: Float
}

class TextureManager {
    let pathToTextureDir = "Sources/Z4Lib/Assets/Textures"
    let pathToAtlas = "Sources/Z4Lib/Assets/Generated/textureAtlas.png"

    var textureUvMap: [String: Uvs] = [:]

    var image: sg_image?
    var sampler: sg_sampler?

    func createTexture(pixels: [UInt32], width: Int, height: Int) {
        tracer.fnTrace1("width: \(width) height: \(height)")
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

    func getTextureUvs(textureName: String) -> Uvs {
        return self.textureUvMap[textureName]!
    }

    /// Read all the PNG files in the textures directory and combines them into a
    /// single texture atlas. Saves the atlas to a file and creates a (GPU) texture
    /// for it.
    func createTextureAtlas() {
        let fileManager = FileManager.default

        var pngFiles: [String] = []
        var textureWidth: Int = 0
        var textureHeight: Int = 0
        do {
            let textureFiles = try fileManager.contentsOfDirectory(atPath: self.pathToTextureDir)
            pngFiles = textureFiles.filter { $0.hasSuffix(".png") }

            for pngFile in pngFiles {
                // TODO: Do we need to decompress each time, or is there a lighter
                // way to do this?
                let pngImage: PNG.Image? = try .decompress(path: "\(self.pathToTextureDir)/\(pngFile)")
                if pngImage == nil {
                    fatalError("failed to open file '\(pngFile)'")
                }
                let pngWidth = pngImage!.size.x
                let pngHeight = pngImage!.size.y

                if textureWidth == 0 {
                    textureWidth = pngWidth
                    textureHeight = pngHeight
                } else {
                    if !((textureWidth == pngWidth) && (textureHeight == pngHeight)) {
                        fatalError("all textures must have the same dimensions")
                    }
                }
            }
        } catch {
            fatalError("\(error)")
        }

        let atlasWidth = textureWidth * pngFiles.count
        let atlasHeight = textureHeight
        tracer.fnTrace1(
          """
            Creating atlas with \(pngFiles.count) textures, with \
            width \(atlasWidth) and height \(atlasHeight)...
            """)
        var atlas = Array<PNG.RGBA<UInt8>>(repeating: PNG.RGBA<UInt8>(1),
                                           count: atlasWidth*atlasHeight)

        var xOffset = 0
        var yOffset = 0
        for pngFile in pngFiles {
            tracer.fnTrace2("Adding texture '\(pngFile)' to atlas...")
            var pngImage: PNG.Image? = nil
            do {
                pngImage = try .decompress(path: "\(self.pathToTextureDir)/\(pngFile)")
                if pngImage == nil {
                    fatalError("failed to open file '\(pngFile)'")
                }
            } catch {
                fatalError("\(error)")
            }
            let width = pngImage!.size.x
            let height = pngImage!.size.y

            let rgba = pngImage!.unpack(as: PNG.RGBA<UInt8>.self)
            for row in 0..<height {
                for column in 0..<width {
                    let atlasIdx = TextureManager.get2dIndex(
                      x: xOffset + column,
                      y: yOffset + row,
                      width: atlasWidth)
                    let rgbaIdx = TextureManager.get2dIndex(
                      x: column,
                      y: row,
                      width: width)
                    atlas[atlasIdx] = rgba[rgbaIdx]
                }
            }

            let textureName = String(pngFile.split(separator: ".").first!)
            self.textureUvMap[textureName] = Uvs(
              uBeg: Float(xOffset) / Float(atlasWidth),
              vBeg: Float(yOffset + height) / Float(atlasHeight),
              uEnd: Float(xOffset + width) / Float(atlasWidth),
              vEnd: Float(yOffset) / Float(atlasHeight))

            xOffset += width
            yOffset = 0
        }

        let atlasImage = PNG.Image(
          packing: atlas,
          size: (atlasWidth, atlasHeight),
          layout: .init(format: .rgb8(palette: [], fill: nil, key: nil)))
        do {
            try atlasImage.compress(path: pathToAtlas, level: 9)
        } catch {
            fatalError("\(error)")
        }

        self.createTexture(pixels: self.rgbaToUInt32Array(rgbaArray: atlas),
                           width: atlasWidth,
                           height: atlasHeight)
    }

    func loadTextureFromFile(textureName: String) {
        let path = self.getTexturePath(textureName: textureName)
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
        tracer.fnTrace2("""
                          textureName: '\(textureName)' \
                          width: \(pngImage!.size.x) height: \(pngImage!.size.y)
                          """)

        self.createTexture(pixels: self.rgbaToUInt32Array(rgbaArray: rgba),
                           width: pngImage!.size.x,
                           height: pngImage!.size.y)
    }

    private static func get2dIndex(x: Int, y: Int, width: Int) -> Int {
        return x + (y * width)
    }

    private func getTexturePath(textureName: String) -> String {
        return "\(pathToTextureDir)/\(textureName).png"
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
