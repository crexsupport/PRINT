import CoreGraphics

extension CGPoint {
    @inline(__always) func distance(to p: CGPoint) -> CGFloat {
        hypot(x - p.x, y - p.y)
    }
    /// Returns a point that is `alpha`-weighted between self and `p`
    @inline(__always) func lerp(to p: CGPoint, alpha: CGFloat) -> CGPoint {
        CGPoint(x: x + (p.x - x) * alpha,
                y: y + (p.y - y) * alpha)
    }
}