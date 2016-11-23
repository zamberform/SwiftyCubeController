//
//  SwiftyCubeController.swift
//  SwiftyCubeSample
//
//  Created by Zamber on 2016/11/10.
//
//

import UIKit
import QuartzCore

public protocol SwiftyCubeControllerDataSource {
    func numberOfViewControllersInCubeController(cubeController: SwiftyCubeController) -> CGFloat
    func cubeController(cubeController: SwiftyCubeController, index: Int) -> UIViewController
}

public protocol SwiftyCubeControllerDelegate {
    func cubeControllerDidScroll(cubeController: SwiftyCubeController)
    func cubeControllerCurrentViewControllerIndexDidChange(cubeController: SwiftyCubeController)
    func cubeControllerWillBeginDragging(cubeController: SwiftyCubeController)
    func cubeControllerDidEndDragging(cubeController: SwiftyCubeController, decelerate: Bool)
    func cubeControllerWillBeginDecelerating(cubeController: SwiftyCubeController)
    func cubeControllerDidEndDecelerating(cubeController: SwiftyCubeController)
    func cubeControllerDidEndScrollingAnimation(cubeController: SwiftyCubeController)
}

public extension UIViewController {
    func cubeController() -> SwiftyCubeController? {
        if self.parent is SwiftyCubeController {
            return (self.parent as! SwiftyCubeController)
        }
        
        return self.parent?.cubeController()
    }
}

public class SwiftyCubeController : UIViewController, UIScrollViewDelegate {
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    
        let frame = self.isViewLoaded ? self.view.bounds : UIScreen.main.bounds
        scrollView = UIScrollView(frame: frame)
        scrollView?.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        scrollView?.showsHorizontalScrollIndicator = false
        scrollView?.isPagingEnabled = true
        scrollView?.isDirectionalLockEnabled = true
        scrollView?.autoresizesSubviews = false
        scrollView?.delegate = self
        
        self.view.addSubview(self.scrollView!)
        
        reloadData()
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    var delegate : SwiftyCubeControllerDelegate?
    var dataSource : SwiftyCubeControllerDataSource?
    var currentViewControllerIndex : Int = 0
    
    private var scrollView : UIScrollView?
    private var numberOfViewControllers : CGFloat = 0
    private var controllers:[Int:UIViewController] = [:]
    private var scrollOffset: CGFloat = 0.0
    private var previousOffset: CGFloat = 0.0
    private var suppressScrollEvent: Bool = false
    
    var wrapEnabled : Bool = false
    
    public func setCurrentViewControllerIndex(currentViewControllerIndex: Int) {
        scrollToViewControllerAtIndex(index: currentViewControllerIndex, animated: false)
    }
    
    public func scrollToViewControllerAtIndex(index: Int, animated: Bool) {
        var offset = CGFloat(index);
        if self.wrapEnabled
        {
            if (offset > CGFloat(self.numberOfViewControllers))
            {
                offset = offset.truncatingRemainder(dividingBy: self.numberOfViewControllers) ;
            }
            offset = max(-1, offset) + 1;
        }
        else if animated && (self.scrollView?.bounces)!
        {
            offset = max(-0.1, min(offset, self.numberOfViewControllers - 0.9));
        }
        else
        {
            offset = max(0, min(offset, self.numberOfViewControllers - 1));
        }
        
        self.scrollView?.setContentOffset(CGPoint(x: self.view.bounds.size.width * offset, y: 0), animated: animated)
    }
    
    public func reloadData() {
        for (_, controller) in controllers {
            controller.viewWillDisappear(false)
            controller.view.removeFromSuperview()
            controller.removeFromParentViewController()
            controller.viewDidDisappear(false)
        }
        
        controllers.removeAll()
        numberOfViewControllers = (self.dataSource?.numberOfViewControllersInCubeController(cubeController: self))!
        self.view.layoutIfNeeded()
    }
    
    public func reloadViewControllerAtIndex(index: Int, animated: Bool) {
        var controller = controllers[index]
        if controller != nil {
            let transform : CATransform3D = (controller?.view.layer.transform)!
            let center : CGPoint = (controller?.view.center)!
            
            if animated {
                let animation = CATransition()
                animation.type = kCATransitionFade
                
                scrollView?.layer.add(animation, forKey: nil)
            }
            
            controller?.view.removeFromSuperview()
            controller?.removeFromParentViewController()
            controller = self.dataSource?.cubeController(cubeController: self, index: index)
            
            controllers[index] = controller
            controller?.view.layer.isDoubleSided = false
            self.addChildViewController(controller!)
            scrollView?.addSubview((controller?.view)!)
            
            controller?.view.layer.transform = transform
            controller?.view.center = center
            controller?.view.isUserInteractionEnabled = ( index == currentViewControllerIndex)
        }
    }
    
    public func updateContentOffset() {
        var offset = self.scrollOffset
        
        if self.wrapEnabled && self.numberOfViewControllers > 1 {
            offset += 1.0
            while offset < 1.0 {
                offset += 1
            }
            
            while offset >= numberOfViewControllers + 1 {
                offset -= numberOfViewControllers
            }
            
        }
        
        previousOffset = offset
        suppressScrollEvent = true
        scrollView?.contentOffset = CGPoint(x: self.view.bounds.size.width * offset, y: CGFloat(0.0))
        suppressScrollEvent = false
        
    }
    
    public func updateLayout() {
        for (index, controller) in controllers {
            if controller.parent == nil {
                controller.view.autoresizingMask = UIViewAutoresizing.init(rawValue: 0)
                controller.view.layer.isDoubleSided = false
                addChildViewController(controller)
                
                scrollView?.addSubview(controller.view)
            }
            
            var angle : Double = Double( scrollOffset - CGFloat(index) ) * M_PI_2
            
            while angle < 0 {
                angle += M_PI * 2
            }
            
            while angle > M_PI * 2 {
                angle -= M_PI * 2
            }
            
            var transform : CATransform3D = CATransform3DIdentity
            if angle != 0.0 {
                transform.m34 = -1.0/500
                transform = CATransform3DTranslate(transform, 0, 0, -self.view.bounds.size.width / 2.0)
                transform = CATransform3DRotate(transform, -CGFloat(angle), 0, 1, 0)
                transform = CATransform3DTranslate(transform, 0, 0, self.view.bounds.size.width / 2.0)
            }
            
            var contentOffset = CGPoint(x: 0, y: 0)
            let isScrollView = controller.view is UIScrollView
            
            if isScrollView {
                let scroller = controller.view as! UIScrollView
                contentOffset = scroller.contentOffset
            }
            
            controller.view.bounds = self.view.bounds
            controller.view.center = CGPoint(x: self.view.bounds.size.width / 2.0 + (scrollView?.contentOffset.x)!, y: self.view.bounds.size.height / 2.0)
            controller.view.layer.transform = transform
            
            if isScrollView {
                let scroller = controller.view as! UIScrollView
                scroller.contentOffset = contentOffset
            }
        }
    }
    
    public func loadUnloadControllers() {
        let visibleIndices = NSMutableSet(object: currentViewControllerIndex)
        if wrapEnabled || currentViewControllerIndex < Int(numberOfViewControllers) - 1 {
            visibleIndices.add(currentViewControllerIndex + 1)
        }
        if currentViewControllerIndex > 0  {
            visibleIndices.add(currentViewControllerIndex - 1)
        }
        else if wrapEnabled {
            visibleIndices.add(-1)
        }
        
        for index in controllers.keys {
            if !visibleIndices.contains(index) {
                let controller = controllers[index]
                controller?.view.removeFromSuperview()
                controller?.removeFromParentViewController()
                controllers.removeValue(forKey: index)
            }
        }
        
        for index in visibleIndices {
            var controller = controllers[index as! Int]
            if controller == nil && numberOfViewControllers != 0 {
                controller = dataSource?.cubeController(cubeController: self, index: ((index as! Int)+Int(numberOfViewControllers)) % Int(numberOfViewControllers))
                controllers[index as! Int] = controller
            }
        }
    }
    
    public func updateInteraction() {
        for index in controllers.keys {
            let controller = controllers[index]
            controller?.view.isUserInteractionEnabled = ( index == currentViewControllerIndex)
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if scrollView != nil {
            var pages = numberOfViewControllers
            if wrapEnabled && numberOfViewControllers > 1 {
                pages += 2
            }
            
            suppressScrollEvent = true
            scrollView?.contentSize = CGSize(width: self.view.bounds.size.width * pages, height: self.view.bounds.size.height)
            suppressScrollEvent = false
            
            updateContentOffset()
            loadUnloadControllers()
            updateLayout()
            updateInteraction()
        }
    }
    
    public func scrollForwardAnimated(animated: Bool) {
        scrollToViewControllerAtIndex(index: currentViewControllerIndex + 1, animated: animated)
    }
    
    public func scrollBackAnimated(animated: Bool) {
        scrollToViewControllerAtIndex(index: currentViewControllerIndex - 1, animated: animated)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !suppressScrollEvent {
            let offset = scrollView.contentOffset.x / self.view.bounds.size.width
            scrollOffset += offset - previousOffset
            
            if wrapEnabled {
                while scrollOffset < 0.0 {
                    scrollOffset += numberOfViewControllers
                }
                
                while scrollOffset >= numberOfViewControllers {
                    scrollOffset -= numberOfViewControllers
                }
            }
            
            previousOffset = offset
            
            if ( offset - floor(offset) ) == 0 {
                scrollOffset = round(scrollOffset)
            }
            
            let previousViewControllerIndex = currentViewControllerIndex
            currentViewControllerIndex = max(0, min(Int(numberOfViewControllers - 1), Int(round(scrollOffset))))
            
            updateContentOffset()
            loadUnloadControllers()
            updateLayout()
            
            self.delegate?.cubeControllerDidScroll(cubeController: self)
            if currentViewControllerIndex != previousViewControllerIndex {
                delegate?.cubeControllerCurrentViewControllerIndexDidChange(cubeController: self)
            }
            
            updateInteraction()
        }
    }
    
    
    //scroll delegate
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if !suppressScrollEvent {
            self.delegate?.cubeControllerWillBeginDragging(cubeController: self)
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !suppressScrollEvent {
            self.delegate?.cubeControllerDidEndDragging(cubeController: self, decelerate: decelerate)
        }
    }
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if !suppressScrollEvent {
            self.delegate?.cubeControllerWillBeginDecelerating(cubeController: self)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !suppressScrollEvent {
            self.delegate?.cubeControllerDidEndDecelerating(cubeController: self)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let nearestIntegralOffset = round(scrollOffset)
        
        if abs(scrollOffset - nearestIntegralOffset) > 0 {
            scrollToViewControllerAtIndex(index: currentViewControllerIndex, animated: true)
        }
        
        if !suppressScrollEvent {
            self.delegate?.cubeControllerDidEndScrollingAnimation(cubeController: self)
        }
    }
    
}
