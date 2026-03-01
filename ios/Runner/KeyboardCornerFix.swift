import UIKit

/// Removes the rounded corners iOS 26 adds to the keyboard via UIDropShadowView.
final class KeyboardCornerFix {

    static let shared = KeyboardCornerFix()
    private init() {}

    func setup() {
        guard #available(iOS 26.0, *) else { return }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow() {
        removeDropShadow()
    }

    @objc private func keyboardDidShow() {
        removeDropShadow()
    }

    private func removeDropShadow() {
        guard #available(iOS 26.0, *) else { return }
        for window in UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows }) {
            traverseAndFix(view: window)
        }
    }

    private func traverseAndFix(view: UIView?) {
        guard let view = view else { return }
        if String(describing: type(of: view)).contains("UIDropShadowView") {
            view.backgroundColor = .clear
            view.isOpaque = false
            view.layer.cornerRadius = 0
            view.layer.maskedCorners = []
            view.clipsToBounds = false
        }
        for subview in view.subviews {
            traverseAndFix(view: subview)
        }
    }
}
