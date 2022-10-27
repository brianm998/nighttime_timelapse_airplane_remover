import Foundation
import CoreGraphics
import Cocoa

@available(macOS 10.15, *) 
class PixelatedImage {
    let width: Int
    let height: Int

    let raw_image_data: Data
    
    let bitsPerPixel: Int
    let bytesPerRow: Int
    let bitsPerComponent: Int
    let bytesPerPixel: Int
    let bitmapInfo: CGBitmapInfo

    convenience init?(fromFile filename: String) throws {
        Log.d("Loading image from \(filename)")
        let imageURL = NSURL(fileURLWithPath: filename, isDirectory: false)

        let data = try Data(contentsOf: imageURL as URL)
        if let image = NSImage(data: data),
           let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        {
            self.init(cgImage)
        } else {
            return nil
        }
    }
    
    init?(_ image: CGImage) {
        assert(image.colorSpace?.model == .rgb)
        self.width = image.width
        self.height = image.height
        self.bitsPerPixel = image.bitsPerPixel
        self.bytesPerRow = image.bytesPerRow
        self.bitsPerComponent = image.bitsPerComponent
        self.bytesPerPixel = self.bitsPerPixel / 8
        self.bitmapInfo = image.bitmapInfo

        if let data = image.dataProvider?.data as? Data {
            self.raw_image_data = data
        } else {
            Log.e("DOH")
            return nil
        }
    }

    func read(_ closure: (UnsafeBufferPointer<UInt16>) -> Void) {
        raw_image_data.withUnsafeBytes { unsafeRawPointer in 
            let typedPointer: UnsafeBufferPointer<UInt16> = unsafeRawPointer.bindMemory(to: UInt16.self)
            closure(typedPointer)
        }        
    }
    
    func readPixel(atX x: Int, andY y: Int) -> Pixel {
        let offset = (y * width*3) + (x * 3)
        let pixel = raw_image_data.withUnsafeBytes { unsafeRawPointer -> Pixel in 
            let typedPointer: UnsafeBufferPointer<UInt16> = unsafeRawPointer.bindMemory(to: UInt16.self)
            var pixel = Pixel()
            pixel.red = typedPointer[offset]
            pixel.green = typedPointer[offset+1]
            pixel.blue = typedPointer[offset+2]
            return pixel
        }
        return pixel
    }

    // write out the given image data as a 16 bit tiff file to the given filename
    // used when modifying the invariant original image data, and saying the edits to a file
    func writeTIFFEncoding(ofData image_data: Data, toFilename image_filename: String) {
        // create a CGImage from the data we just changed
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let dataProvider = CGDataProvider(data: image_data as CFData),
           let new_image =  CGImage(width: width,
                                    height: height,
                                    bitsPerComponent: bitsPerComponent,
                                    bitsPerPixel: bytesPerPixel*8,
                                    bytesPerRow: width*bytesPerPixel,
                                    space: colorSpace,
                                    bitmapInfo: bitmapInfo,
                                    provider: dataProvider,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: .defaultIntent)
        {
            // save it
            //Log.d("new_image \(new_image)")
            do {
                let context = CIContext()
                let fileURL = NSURL(fileURLWithPath: image_filename, isDirectory: false) as URL
                let options: [CIImageRepresentationOption: CGFloat] = [:]
                if let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) {
                    let imgFormat = CIFormat.RGBA16

                    try context.writeTIFFRepresentation(
                        of: CIImage(cgImage: new_image),
                        to: fileURL,
                        format: imgFormat,
                        colorSpace: colorSpace,
                        options: options
                    )
                    Log.i("image written to \(image_filename)")
                } else {
                    Log.d("FUCK")
                }
            } catch {
                Log.e(error)
            }
        }
    }
}

