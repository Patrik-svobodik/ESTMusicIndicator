//
//  MusicIndicatorView.swift
//  MusicIndicator
//
//  Created by Aufree on 12/6/15.
//  Copyright © 2015 The EST Group. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

public class MusicIndicatorView: UIView {

    /**
     A boolean value that controls whether the receiver is hidden
     when the state is set to `.stopped`.
     
     If the value of this property is `true` (the default),
     the receiver sets its `hidden` property of (`UIView`) to `true`
     when receiver’s state is `.stopped`.
     If the value is `false`, the receiver is shown even when it's stopped.
     
     Note that by setting state `.playing` or `.paused`
     the receiver will be shown automatically.
     */
    
    open var hidesWhenStopped: Bool = true {
        didSet {
            if state == .stopped {
                isHidden = hidesWhenStopped
            }
        }
    }
    
    /**
     The current state of the receiver.
     
     You can control the receiver's appearance and behavior by setting this property.
     
     - `.stopped`:
     - If hidesWhenStopped is `true`, the receiver becomes hidden.
     - If hidesWhenStopped is `false`, the receiver shows idle bars (same as `.paused`).
     - `.playing`: The receiver shows oscillatory animated bars.
     - `.paused`: The receiver shows idle bars.
     
     The initial value is `.stopped`.
     */
    public var state: MusicIndicatorViewState = .stopped {
        didSet {
            if state == .stopped {
                stopAnimating()
                if hidesWhenStopped {
                    isHidden = true
                }
            } else {
                state == .playing ? startAnimating() : stopAnimating()
                isHidden = false
            }
        }
    }
    
    private var hasInstalledConstraints = false
    private lazy var contentView = MusicIndicatorContentView()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        layer.masksToBounds = true
        addSubview(contentView)
        prepareLayoutPriorities()
        setNeedsUpdateConstraints()
        // Observe app's state
        for name in [UIApplication.willEnterForegroundNotification,
                     UIApplication.didEnterBackgroundNotification] {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [weak self] notification in
                self?.handleApplicationStateChanged(notification)
            }
        }
    }
    
    private func prepareLayoutPriorities() {
        // Custom views should set default values for both orientations on creation,
        // based on their content, typically to NSLayoutPriorityDefaultLow or NSLayoutPriorityDefaultHigh.
        setContentHuggingPriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.horizontal)
        setContentHuggingPriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.vertical)
        
        setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.horizontal)
        setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.vertical)
    }

    // MARK: Auto Layout
    
    override open var intrinsicContentSize : CGSize { contentView.intrinsicContentSize }
    
    override open func updateConstraints() {
        if !hasInstalledConstraints {
            addConstraint(NSLayoutConstraint(item: self,
                                        attribute: .centerX,
                                        relatedBy: .equal,
                                        toItem: contentView,
                                        attribute: .centerX,
                                        multiplier: 1.0,
                                        constant: 0.0))
            
            addConstraint(NSLayoutConstraint(item: self,
                                        attribute: .centerY,
                                        relatedBy: .equal,
                                        toItem: contentView,
                                        attribute: .centerY,
                                        multiplier: 1.0,
                                        constant: 0.0))
            
            hasInstalledConstraints = true
        }
        super.updateConstraints()
    }
    
    open override var forFirstBaselineLayout: UIView { contentView }
    
    // MARK: Frame-Based Layout
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize { intrinsicContentSize }
    
    // MARK: Helpers
    
    private func startAnimating() {
        guard !contentView.isOscillating() else { return }
        
        contentView.stopDecay()
        contentView.startOscillation()
    }
    
    private func stopAnimating() {
        guard contentView.isOscillating() else { return }
        
        contentView.stopOscillation()
        contentView.startDecay()
    }
    
    // MARK: Notification
    private func handleApplicationStateChanged(_ sender: Notification) {
        switch sender.name {
        case UIApplication.willEnterForegroundNotification:
            guard state == .playing else { break }
            startAnimating()
        case UIApplication.didEnterBackgroundNotification:
            stopAnimating()
        default:
            break
        }
    }
}