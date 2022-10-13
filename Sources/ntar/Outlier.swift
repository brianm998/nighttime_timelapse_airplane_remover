import Foundation

public class Outlier: Hashable, Equatable {
    let x: UInt16
    let y: UInt16
    let amount: UInt32
    var tag: String?
    
    public init(x: UInt16, y: UInt16, amount: UInt32) {
        self.x = x
        self.y = y
        self.amount = amount
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }

    public static func == (lhs: Outlier, rhs: Outlier) -> Bool {
        return
            lhs.x == rhs.x &&
            lhs.y == rhs.y
    }    
}
