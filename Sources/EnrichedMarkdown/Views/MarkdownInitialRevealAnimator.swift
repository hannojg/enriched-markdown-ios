import UIKit
import QuartzCore

/// Owns only the presentation mask. Text storage and its layout stay unchanged.
final class MarkdownInitialRevealAnimator {
    private enum State { case idle, waiting, revealing, finished }
    private weak var textView: UITextView?
    private let mask = CALayer()
    private var state = State.idle
    private var revealSize = CGSize.zero

    init(textView: UITextView) {
        self.textView = textView
    }

    func prepare() {
        guard state == .idle, let textView else { return }
        guard !UIAccessibility.isReduceMotionEnabled else {
            state = .finished
            return
        }
        state = .waiting
        textView.layer.mask = mask
    }

    func layout(content: NSAttributedString) {
        guard let textView else { return }
        if state == .revealing, textView.bounds.size != revealSize {
            finish()
            return
        }
        guard state == .waiting, textView.bounds.width > 0, textView.bounds.height > 0 else { return }
        let proposal = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        let fitted = textView.sizeThatFits(proposal)
        guard fitted.height <= textView.bounds.height + 0.5 else { return }
        let range = NSRange(location: 0, length: content.length)
        var rows: [(CGRect, NSRange)] = []
        TextLayoutHelpers.enumerateSegmentFrames(of: range, in: textView) { frame, range, _ in
            guard frame.height > 0 else { return }
            if let last = rows.last, abs(last.0.minY - frame.minY) < 0.5 {
                rows[rows.count - 1].0 = last.0.union(frame)
            } else {
                rows.append((frame, range))
            }
        }
        guard !rows.isEmpty else { return }
        state = .revealing
        revealSize = textView.bounds.size
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setCompletionBlock { [weak self] in self?.finish() }
        mask.frame = textView.bounds
        let width = textView.bounds.width
        let start = CACurrentMediaTime()
        var delay = 0.0
        for row in rows {
            let container = CALayer()
            container.frame = CGRect(x: 0, y: row.0.minY - 2, width: width, height: row.0.height + 4)
            container.masksToBounds = true
            let attributes = content.attributes(at: row.1.location, effectiveRange: nil)
            let style = attributes[.paragraphStyle] as? NSParagraphStyle
            if TextLayoutHelpers.paragraphIsRTL(style) {
                let transform = CGAffineTransform(scaleX: -1, y: 1)
                container.setAffineTransform(transform)
            }
            let gradient = CAGradientLayer()
            gradient.anchorPoint = .zero
            gradient.bounds = CGRect(x: 0, y: 0, width: width * 3, height: container.bounds.height)
            gradient.startPoint = CGPoint(x: 0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1, y: 0.5)
            gradient.colors = [UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor]
            gradient.locations = [0, 0.58, 0.65, 1]
            gradient.position = CGPoint(x: -width * 0.6, y: 0)
            container.addSublayer(gradient)
            mask.addSublayer(container)
            let seconds = Double(row.1.length) / 120
            let cappedDuration = min(seconds, 0.65)
            let duration = max(cappedDuration, 0.18)
            let animation = CABasicAnimation(keyPath: "position.x")
            animation.fromValue = -width * 2
            animation.toValue = -width * 0.6
            animation.beginTime = start + delay
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
            animation.fillMode = .backwards
            gradient.add(animation, forKey: "initialReveal")
            delay += duration * 0.7
        }
        CATransaction.commit()
    }

    func finish() {
        state = .finished
        if textView?.layer.mask === mask {
            textView?.layer.mask = nil
        }
        mask.sublayers = nil
    }
}
