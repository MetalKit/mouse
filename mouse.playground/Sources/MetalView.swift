
import MetalKit

public class MetalView: MTKView, NSWindowDelegate {
    
    var queue: MTLCommandQueue! = nil
    var cps: MTLComputePipelineState! = nil
    var mouseBuffer: MTLBuffer!
    var outBuffer: MTLBuffer!
    var pos = float2()
    
    override public func mouseDown(with event: NSEvent) {
        let position = convertToLayer(convert(event.locationInWindow, from: nil))
        let scale = Float(layer!.contentsScale)
        pos.x = Float(position.x) * scale
        // fix Cocoa's lower-left origin by flipping it upside down
        pos.y = Float(bounds.height - position.y) * scale
        let data = outBuffer.contents().bindMemory(to: float2.self, capacity: 1)
        Swift.print("\(data[0].x) \(data[1].x)")
    }
    
    func update() {
        let bufferPointer = mouseBuffer.contents()
        memcpy(bufferPointer, &pos, MemoryLayout<float2>.size)
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override public init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        queue = device!.makeCommandQueue()
        let path = Bundle.main.path(forResource: "Shaders", ofType: "metal")
        do {
            let input = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
            let library = try device!.makeLibrary(source: input, options: nil)
            let kernel = library.makeFunction(name: "compute")!
            cps = try device!.makeComputePipelineState(function: kernel)
        } catch let e {
            Swift.print("\(e)")
        }
        mouseBuffer = device!.makeBuffer(length: MemoryLayout<float2>.size, options: [])
        let bytes = [Float](repeating: 0, count: 2)
        outBuffer = device?.makeBuffer(bytes: bytes, length: 2 * MemoryLayout<float2>.size, options: [])
    }
    
    override public func draw(_ dirtyRect: NSRect) {
        if let drawable = currentDrawable {
            let commandBuffer = queue.makeCommandBuffer()
            let commandEncoder = commandBuffer.makeComputeCommandEncoder()
            commandEncoder.setComputePipelineState(cps)
            commandEncoder.setTexture(drawable.texture, at: 0)
            commandEncoder.setBuffer(mouseBuffer, offset: 0, at: 1)
            commandEncoder.setBuffer(outBuffer, offset: 0, at: 2)
            update()
            let threadGroupCount = MTLSizeMake(1, 1, 1)
            let threadGroups = MTLSizeMake(drawable.texture.width / threadGroupCount.width, drawable.texture.height / threadGroupCount.height, 1)
            commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
