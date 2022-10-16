import Foundation
import CoreGraphics
import Cocoa

let supported_image_file_types = [".tif", ".tiff"]
    
// support lazy loading of images from the sequence using reference counting
@available(macOS 10.15, *)
actor ImageSequence {

    init(dirname: String) {
        var image_files: [String] = []
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: dirname)
            contents.forEach { file in
                supported_image_file_types.forEach { type in
                    if file.hasSuffix(type) {
                        image_files.append("\(dirname)/\(file)")
                    } 
                }
            }
        } catch {
            Log.d("OH FUCK \(error)")
        }

        image_files.sort { (lhs: String, rhs: String) -> Bool in
            let lh = remove_path_and_suffix(fromString: lhs)
            let rh = remove_path_and_suffix(fromString: rhs)
            return lh < rh
        }

        self.filenames = image_files
    }
    
    let filenames: [String]

    private var images: [String: WeakRef<PixelatedImage>] = [:]

    func getImage(withName filename: String) -> PixelatedImage? {
        if let image = images[filename]?.value {
            return image
        }
        // lazy load it it's not present
        Log.d("Loading image from \(filename)")
        let imageURL = NSURL(fileURLWithPath: filename, isDirectory: false)
        do {
            let data = try Data(contentsOf: imageURL as URL)
            if let image = NSImage(data: data),
               let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
               let pixelatedImage = PixelatedImage(cgImage, filename: filename)
            {
                images[filename] = WeakRef(value: pixelatedImage)
                return pixelatedImage
            }
        } catch {
            Log.e("\(error)")
        }
        return nil
    }
}

class WeakRef<T> where T: AnyObject {

    private(set) weak var value: T?

    init(value: T?) {
        self.value = value
    }
}

// removes path and suffix from filename
func remove_path_and_suffix(fromString string: String) -> String {
    let imageURL = NSURL(fileURLWithPath: string, isDirectory: false) as URL
    let full_path = imageURL.deletingPathExtension().absoluteString
    let components = full_path.components(separatedBy: "/")
    return components[components.count-1]
}
