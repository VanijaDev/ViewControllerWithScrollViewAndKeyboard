//  Created by ChikabuZ on 09.06.16.
//  Copyright © 2016 Buddy Healthcare Ltd Oy. All rights reserved.

import UIKit

class ViewControllerWithScrollViewAndKeyboard: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate
{
    
    let BOTTOM_MARGIN: CGFloat = 10.0
    
    var bottomMargin: CGFloat {
        return BOTTOM_MARGIN
    }
    
    var bottomViewFrame: CGRect? {
        return self.scrollView?.frame
    }
    
    var activeTextInputFrame: CGRect?
    
    var scrollView: UIScrollView?
    {
        for subview in self.view.subviews
        {
            if let scrollView = subview as? UIScrollView {
                return scrollView
            }
        }
        return nil
    }
    
    var bottomBarHeight: CGFloat {
        get {
            if let rootViewControllerView = UIApplication.shared.windows.first?.rootViewController?.view, let scrollView = scrollView {
                let newFrame = view.convert(scrollView.frame, to: rootViewControllerView)
                let result = rootViewControllerView.frame.height - newFrame.height - newFrame.origin.y
                return result
            }
            return 0
        }
    }
    
    var originalContentOffsetY: CGFloat = 0
    var originalContentInsetBottom: CGFloat = 0
    var originalScrollIndicatorInsetsBottom: CGFloat = 0
    
    var keyboardHeight: CGFloat = 0
    var isKeyboardVisible: Bool = false
    
    lazy var textFields: [UITextField] =
        {
            if let scrollV = scrollView {
                let container = scrollV.subviews[0]
                
                var tmpTextFields = [UITextField]()
                for view in container.subviews {
                    if view is UITextField {
                        tmpTextFields.append(view as! UITextField)
                    }
                }
                return tmpTextFields
            }
            
            return []
    }()
    
    func bottomTextFieldReturnAction() {
    }
    
    //MARK: -
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        originalContentInsetBottom = scrollView?.contentInset.bottom ?? 0
        originalScrollIndicatorInsetsBottom = scrollView?.scrollIndicatorInsets.bottom ?? 0
        
        setReturnKeys(inputs: textFields)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        
        
        registerForKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        unregisterFromKeyboardNotifications()
    }
    
    //MARK: - Keyboard actions
    fileprivate func registerForKeyboardNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    fileprivate func unregisterFromKeyboardNotifications()
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc fileprivate func handleKeyboardNotification(_ notification: Notification) {
        guard notification.name == NSNotification.Name.UIKeyboardWillShow || notification.name == NSNotification.Name.UIKeyboardWillHide else {
            return
        }
        
        let userInfo = notification.userInfo
        
        keyboardHeight = (userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height ?? 220
        let animationOptionRawValue = userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? UInt ?? UIViewAnimationOptions().rawValue
        let keyboardAnimationOption = UIViewAnimationOptions(rawValue: animationOptionRawValue)
        let keyboardAnimationDuration = (userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        
        isKeyboardVisible = notification.name == NSNotification.Name.UIKeyboardWillShow
        
        UIView.animate(withDuration: keyboardAnimationDuration, delay: 0, options: keyboardAnimationOption, animations: {
            
            self.updateScrollViewContentSize()
            self.scrollToActiveTextInput()
            
        }) { (completed) in
            self.updateScrollViewContentSize()
        }
    }
    
    func scrollToActiveTextInput(animated: Bool = false) {
        guard let scrollView = scrollView, let activeTextInputFrame = activeTextInputFrame else
        {
            print("activeTextInputFrame is nil"); return
        }
        
        if isKeyboardVisible {
            
            //            originalContentOffsetY = scrollView.contentOffset.y
            
            let delta = activeTextInputFrame.origin.y + activeTextInputFrame.height + bottomMargin + keyboardHeight - bottomBarHeight - scrollView.frame.height
            
            if delta > 0 {
                scrollView.contentOffset.y = delta
            }
        } else {
            //            scrollView.contentOffset.y = originalContentOffsetY
        }
    }
    
    func updateScrollViewContentSize() {
        guard let scrollView = scrollView, let bottomViewFrame = bottomViewFrame else {
            print("scrollView not found")
            return
        }
        if isKeyboardVisible {
            let delta = bottomViewFrame.origin.y + bottomViewFrame.height + keyboardHeight - bottomBarHeight + bottomMargin - scrollView.contentSize.height
            scrollView.contentInset.bottom = delta
            scrollView.scrollIndicatorInsets.bottom = keyboardHeight - bottomBarHeight
        } else {
            scrollView.contentInset.bottom = originalContentInsetBottom
            scrollView.scrollIndicatorInsets.bottom = originalScrollIndicatorInsetsBottom
        }
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    //MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        activeTextInputFrame = textField.frame
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if let currentIndex = textFields.index(of: textField) {
            if currentIndex + 1 < textFields.count {
                let newTextField = textFields[currentIndex + 1]
                newTextField.becomeFirstResponder()
                //                textFieldDidBeginEditing(newTextField)
            } else {
                bottomTextFieldReturnAction()
            }
        }
        
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Workaround for the jumping text bug
        textField.resignFirstResponder()
        textField.layoutIfNeeded()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIButton {
            return false
        }
        if touch.view is UIStackView {
            return false
        }
        return true
    }
}

private extension ViewControllerWithScrollViewAndKeyboard {
    func setReturnKeys(inputs: [UITextField]) {
        for (index, textField) in textFields.enumerated() {
            if index == textFields.count - 1 {
                textField.returnKeyType = .done
            } else {
                textField.returnKeyType = .next
            }
        }
    }
}
