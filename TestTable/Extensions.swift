//
//  Extensions.swift
//  TestTable
//
//  Created by Denis Karpenko on 2019-07-11.
//  Copyright © 2019 Denis Karpenko. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    @discardableResult
    func pinToSuperview(_ insets: UIEdgeInsets = UIEdgeInsets.zero, excludingEdges: Set<NSLayoutConstraint.Attribute>? = nil) -> [NSLayoutConstraint] {
        guard let superview = self.superview else {
            fatalError("Superview is required before pinning to it")
        }

        self.translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint] = [
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: superview, attribute: .leading, multiplier: 1.0, constant: insets.left),
            NSLayoutConstraint(item: superview, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: insets.right),
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: superview, attribute: .top, multiplier: 1.0, constant: insets.top),
            NSLayoutConstraint(item: superview, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: insets.bottom),
        ]
        if let excludingEdges = excludingEdges { constraints.removeAll { excludingEdges.contains($0.firstAttribute) } }
        superview.addConstraints(constraints)

        return constraints
    }

    @discardableResult
    func pinHeight(_ height: CGFloat) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: height)
        self.addConstraint(heightConstraint)
        return heightConstraint
    }

    @discardableResult
    func pinWidth(_ width: CGFloat) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: width)
        self.addConstraint(widthConstraint)
        return widthConstraint
    }

    @discardableResult
    func pinSize(_ size: CGSize) -> [NSLayoutConstraint] {
        return [self.pinWidth(size.width), self.pinHeight(size.height)]
    }

    static func separatorView() -> UIView {
        let view = UIView()
        view.backgroundColor = .gray
        let height = 1 / UIScreen.main.scale
        view.pinHeight(height)
        return view
    }
}

extension UIEdgeInsets {
    /// Creates an `UIEdgeInsets` with the inset value applied to all (top, bottom, right, left)
    /// - Parameter inset: Inset to be applied in all the edges.
    public init(inset: CGFloat) {
        self.init(top: inset, left: inset, bottom: inset, right: inset)
    }

    /// Creates an `UIEdgeInsets` with the vertical value applied to top and bottom, horizontal value applied to left and right
    /// - Parameter vertical: vertical value to be applied to top and bottom
    /// - Parameter horizontal: horizontal value to be applied to left and right
    public init(vertical: CGFloat = 0, horizontal: CGFloat = 0) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}

public struct Disposable {
    fileprivate var identifier: String
}

public final class Observable<T> {

    public var value: T {
        didSet {
            self.observers.forEach { $0.block(value) }
        }
    }

    private var observers: [(identifier: String, block: ((T) -> Void))] = []

    public init(value: T) {
        self.value = value
    }

    @discardableResult
    public func startObserving(autoBlock: Bool = true, block: @escaping (T) -> Void) -> Disposable {
        let identifier = NSUUID().uuidString

        self.observers.append((identifier, block))
        if autoBlock { block(value) }

        return Disposable(identifier: identifier)
    }

    public func dispose(_ disposable: Disposable) {
        let index = self.observers.index { $0.identifier == disposable.identifier }

        guard let unwrappedIndex = index else { return }
        self.observers.remove(at: unwrappedIndex)
    }
}

class ClosureSleeve {
    let closure: ()->()

    init (_ closure: @escaping ()->()) {
        self.closure = closure
    }

    @objc func invoke () {
        closure()
    }
}

extension UIControl {
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping ()->()) {
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
        objc_setAssociatedObject(self, "[\(arc4random())]", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

extension UIColor {
    func getImage(size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image(actions: { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        })
    }
}
