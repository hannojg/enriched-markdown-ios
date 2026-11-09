import Foundation

/// Reveals immutable Markdown blocks in ascending order, starting at index zero.
/// Own one sequence per message and create a new sequence when replacing that message.
/// Access the sequence on the main thread, together with its text views.
public final class MarkdownRevealSequence {
    private var entries: [Int: MarkdownInitialRevealAnimator] = [:]
    private var nextIndex = 0
    private var isAdvancing = false
    private var isCancelled = false

    public init() {}

    /// Removes all reveal masks and prevents this sequence from starting more animations.
    public func cancel() {
        isCancelled = true
        let animators = Array(entries.values)
        entries.removeAll()
        for animator in animators {
            animator.finish()
        }
    }

    func register(_ animator: MarkdownInitialRevealAnimator, at index: Int) {
        precondition(index >= 0, "Markdown reveal indices must start at zero.")
        guard !isCancelled, index >= nextIndex else {
            animator.finish()
            return
        }
        if let previous = entries[index], previous !== animator {
            entries.removeValue(forKey: index)
            previous.finish()
        }
        entries[index] = animator
    }

    func remove(_ animator: MarkdownInitialRevealAnimator, at index: Int) {
        guard entries[index] === animator else { return }
        entries.removeValue(forKey: index)
    }

    func complete(_ animator: MarkdownInitialRevealAnimator, at index: Int) {
        guard entries[index] === animator, index == nextIndex else { return }
        entries.removeValue(forKey: index)
        nextIndex += 1
        startNext()
    }

    func startNext() {
        guard !isAdvancing else { return }
        isAdvancing = true
        defer { isAdvancing = false }
        while let animator = entries[nextIndex] {
            let index = nextIndex
            animator.start()
            if nextIndex == index { break }
        }
    }
}
