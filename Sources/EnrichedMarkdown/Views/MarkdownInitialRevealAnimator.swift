import UIKit
import QuartzCore

/// Owns only the presentation mask. Text storage and its layout stay unchanged.
final class MarkdownInitialRevealAnimator {
    private enum State { case idle, waiting, revealing, finished }
    private weak var textView: UITextView?
    private let mask = CALayer()
    private var state = State.idle
    private var revealSize = CGSize.zero
    private weak var sequence: MarkdownRevealSequence?
    private var index = 0
    private var generation = 0
    private var content: NSAttributedString?

    init(textView: UITextView) {
        self.textView = textView
    }

    func prepare(_ reveal: MarkdownInitialReveal) {
        detach()
        guard let textView else { return }
        state = .waiting
        sequence = reveal.sequence
        index = reveal.index
        textView.layer.mask = mask
        reveal.sequence.register(self, at: index)
    }

    func layout(content: NSAttributedString) {
        guard state == .waiting || state == .revealing else { return }
        self.content = content
        if let textView, state == .revealing, textView.bounds.size != revealSize {
            finish()
            return
        }
        sequence?.startNext()
    }

    func start() {
        guard state == .waiting, let textView, let content else { return }
        guard !UIAccessibility.isReduceMotionEnabled, content.length > 0 else {
            finish()
            return
        }
        guard textView.bounds.width > 0, textView.bounds.height > 0 else { return }
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
        guard !rows.isEmpty else {
            finish()
            return
        }
        state = .revealing
        revealSize = textView.bounds.size
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let generation = self.generation
        CATransaction.setCompletionBlock { [weak self] in
            guard let self, self.generation == generation else { return }
            self.finish()
        }
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

    func detach() {
        sequence?.remove(self, at: index)
        sequence = nil
        generation += 1
        finish()
        content = nil
        state = .idle
    }

    func finish() {
        guard state != .finished else { return }
        state = .finished
        content = nil
        if textView?.layer.mask === mask {
            textView?.layer.mask = nil
        }
        mask.sublayers = nil
        sequence?.complete(self, at: index)
    }
}
