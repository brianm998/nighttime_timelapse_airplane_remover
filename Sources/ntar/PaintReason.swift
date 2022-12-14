import Foundation

// why we are or are not painting a group
enum PaintReason: Equatable, CaseIterable {
   case assumed                      // large groups are assumed to be airplanes
   case goodScore(Double)            // percent score
   case looksLikeALine(Double)       
   case inStreak(Int)           // size

   case badScore(Double)        // percent score
   case adjecentOverlap(Double) // overlap distance

   case smallNonLinear

   public var BasicColor: BasicColor {
        get {
            switch self {
            case .assumed:
                return .brightMagenta
            case .goodScore:
                return .yellow
            case .looksLikeALine:
                return .red
            case .inStreak:
                return .brightRed
            case .badScore:
                return .brightCyan
            case .adjecentOverlap:
                return .brightBlue
            case .smallNonLinear:
                return .cyan
            }
        }
   }

   public var name: String {
        get {
            switch self {
            case .assumed:           return "assumed"
            case .goodScore:         return "good score"
            case .looksLikeALine:    return "looks like a line"
            case .inStreak:          return "in a streak"
            case .badScore:          return "bad score"
            case .adjecentOverlap:   return "adjecent overlap"
            case .smallNonLinear:    return "small not linear"
            }
        }
   }

   public var description: String {
        get {
            switch self {
            case .assumed:
                return """
These outlier groups are painted over because they are larger than \(config.assumeAirplaneSize) pixels in size.
"""
            case .goodScore:
                return """
These outlier groups are painted over because of a good score analyzing the outliers in a single frame.
"""
            case .looksLikeALine:
                return """
These outlier groups are painted over because they look like a line based upon hough transform data.
"""
            case .badScore:
                return """
These outlier groups are not painted over because of a bad score analyzing the outliers in a single frame.
"""
            case .adjecentOverlap:
                return """
These outlier groups are not painted over because it overlaps with a similar outlier group in an adjecent frame.
"""
            case .inStreak:
                return """
These outlier groups were found to be in a streak across frames.
"""
            case .smallNonLinear:
                return """
These outlier groups were ignored for being too small and not linear enough.
"""
            }
        }
   }

   public var willPaint: Bool {
        get {
            switch self {
            case .assumed:           return true
            case .goodScore:         return true
            case .looksLikeALine:    return true
            case .inStreak:          return true
            case .badScore:          return false
            case .adjecentOverlap:   return false
            case .smallNonLinear:    return false
            }
        }
   }

   static var shouldPaintCases: [PaintReason] {
       return PaintReason.allCases.filter { $0.willPaint }
   }

   static var shouldNotPaintCases: [PaintReason] {
       return PaintReason.allCases.filter { !$0.willPaint }
   }

   static var allCases: [PaintReason] {
       return [.assumed, .looksLikeALine(0), .goodScore(0),
               .inStreak(0), .badScore(0), .adjecentOverlap(0), .smallNonLinear]
   }
                         
   // colors used to test paint to show why
   public var testPaintPixel: Pixel { self.BasicColor.pixel }
        
   public static func == (lhs: PaintReason, rhs: PaintReason) -> Bool {
      switch lhs {
      case .assumed:
          switch rhs {
          case .assumed:
              return true
          default:
              return false
          }
      case .looksLikeALine:
          switch rhs {
          case .looksLikeALine:
              return true
          default:
              return false
          }
      case .goodScore:
          switch rhs {
          case .goodScore:
              return true
          default:
              return false
          }
      case .inStreak:
          switch rhs {
          case .inStreak:
              return true
          default:
              return false
          }
      case .badScore:
          switch rhs {
          case .badScore:
              return true
          default:
              return false
          }
      case .adjecentOverlap:
          switch rhs {
          case .adjecentOverlap:
              return true
          default:
              return false
          }
      case .smallNonLinear:
          switch rhs {
          case .smallNonLinear:
              return true
          default:
              return false
          }
      }
   }    
}

