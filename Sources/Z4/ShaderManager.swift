
import Foundation

import Sokol

class ShaderManager {
    var bytecodeData: Data?
    
    func loadShaderBytecode(shaderName: String) {
        let filePath = "Sources/Z4/Shaders/\(shaderName).metallib"
        guard FileManager.default.fileExists(atPath: filePath) else {
            fatalError("Shader file \(filePath) not found.")
        }
        
        do {
            bytecodeData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            fatalError("Failed to load shader bytecode from \(filePath) - \(error)")
        }
    }

    func getSource(shaderName: String) -> String {
        let url = self.getShaderSourceUrl(shaderName: shaderName)
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            fatalError("Failed to get shader source string from \(url) - \(error)")
        }
    }

    private func getShaderSourceUrl(shaderName: String) -> URL {
        let filePath = "Sources/Z4/Shaders/\(shaderName).metal"
        guard FileManager.default.fileExists(atPath: filePath) else {
            fatalError("Shader file \(filePath) not found.")
        }
        return URL(fileURLWithPath: filePath)
    }
}
