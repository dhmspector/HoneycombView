//
//  HoneycombPhotoBrowser.swift
//  HoneycombViewExample
//
//  Created by suzuki_keishi on 2015/10/01.
//  Copyright © 2015年 suzuki_keishi. All rights reserved.
//

import UIKit

// MARK: - HoneycombPhotoBrowser
open class HoneycombPhotoBrowser: UIViewController, UIScrollViewDelegate{
    
    final let pageIndexTagOffset = 1000
    final let screenBound = UIScreen.main.bounds
    var screenWidth :CGFloat { return screenBound.size.width }
    var screenHeight:CGFloat { return screenBound.size.height }
    
    var applicationWindow:UIWindow!
    var toolBar:UIToolbar!
    var toolCounterLabel:UILabel!
    var toolCounterButton:UIBarButtonItem!
    var toolPreviousButton:UIBarButtonItem!
    var toolNextButton:UIBarButtonItem!
    var pagingScrollView:UIScrollView!
    var panGesture:UIPanGestureRecognizer!
    var doneButton:UIButton!
    
    var visiblePages:Set<HoneycombZoomingScrollView> = Set()
    var initialPageIndex:Int = 0
    var currentPageIndex:Int = 0
    var photos:[HoneycombPhoto] = [HoneycombPhoto]()
    var numberOfPhotos:Int{
        return photos.count
    }
    
    // senderView's property
    var senderViewForAnimation:UIView = UIView()
    var senderViewOriginalFrame:CGRect = CGRect.zero
    
    // animation property
    var resizableImageView:UIImageView = UIImageView()
    
    // for status check
    var isDraggingPhoto:Bool = false
    var isViewActive:Bool = false
    var isPerformingLayout:Bool = false
    var isDisplayToolbar:Bool = true
    
    // scroll property
    var firstX:CGFloat = 0.0
    var firstY:CGFloat = 0.0
    
    var controlVisibilityTimer:Timer!
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nil, bundle: nil)
        setup()
    }
    
    convenience init(photos:[HoneycombPhoto], animatedFromView:UIView) {
        self.init(nibName: nil, bundle: nil)
        self.photos = photos
        self.senderViewForAnimation = animatedFromView
    }
    
    func setup() {
        applicationWindow = (UIApplication.shared.delegate?.window)!
        
        modalPresentationStyle = UIModalPresentationStyle.custom
        modalPresentationCapturesStatusBarAppearance = true
        modalTransitionStyle = UIModalTransitionStyle.crossDissolve
    }
    
    // MARK: - override
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        view.clipsToBounds = true
        
        // setup paging
        let pagingScrollViewFrame = frameForPagingScrollView()
        pagingScrollView = UIScrollView(frame: pagingScrollViewFrame)
        pagingScrollView.isPagingEnabled = true
        pagingScrollView.delegate = self
        pagingScrollView.showsHorizontalScrollIndicator = true
        pagingScrollView.showsVerticalScrollIndicator = true
        pagingScrollView.backgroundColor = UIColor.black
        pagingScrollView.contentSize = contentSizeForPagingScrollView()
        view.addSubview(pagingScrollView)
        
        // toolbar
        toolBar = UIToolbar(frame: frameForToolbarAtOrientation())
        toolBar.backgroundColor = UIColor.clear
        toolBar.clipsToBounds = true
        toolBar.isTranslucent = true
        toolBar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        view.addSubview(toolBar)
        
        if !isDisplayToolbar {
            toolBar.isHidden = true
        }
        
        // arrows:back
        let bundle = Bundle(identifier: "com.keishi.suzuki.HoneycombView")
        let previousBtn = UIButton(type: .custom)
        let previousImage = UIImage(named: "btn_common_back_wh", in: bundle, compatibleWith: nil) ?? UIImage()
        previousBtn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        previousBtn.imageEdgeInsets = UIEdgeInsetsMake(13.25, 17.25, 13.25, 17.25)
        previousBtn.setImage(previousImage, for: UIControlState())
        previousBtn.addTarget(self, action: #selector(HoneycombPhotoBrowser.gotoPreviousPage), for: .touchUpInside)
        previousBtn.contentMode = .center
        toolPreviousButton = UIBarButtonItem(customView: previousBtn)
        
        // arrows:next
        let nextBtn = UIButton(type: .custom)
        let nextImage = UIImage(named: "btn_common_forward_wh", in: bundle, compatibleWith: nil) ?? UIImage()
        nextBtn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        nextBtn.imageEdgeInsets = UIEdgeInsetsMake(13.25, 17.25, 13.25, 17.25)
        nextBtn.setImage(nextImage, for: UIControlState())
        nextBtn.addTarget(self, action: #selector(HoneycombPhotoBrowser.gotoNextPage), for: .touchUpInside)
        nextBtn.contentMode = .center
        toolNextButton = UIBarButtonItem(customView: nextBtn)
        
        toolCounterLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 95, height: 40))
        toolCounterLabel.textAlignment = .center
        toolCounterLabel.backgroundColor = UIColor.clear
        toolCounterLabel.font  = UIFont(name: "Helvetica", size: 16.0)
        toolCounterLabel.textColor = UIColor.white
        toolCounterLabel.shadowColor = UIColor.darkText
        toolCounterLabel.shadowOffset = CGSize(width: 0.0, height: 1.0)
        
        toolCounterButton = UIBarButtonItem(customView: toolCounterLabel)
        
        // close
        let doneImage = UIImage(named: "btn_common_close_wh", in: bundle, compatibleWith: nil) ?? UIImage()
        doneButton = UIButton(type: UIButtonType.custom)
        doneButton.setImage(doneImage, for: UIControlState())
        doneButton.frame = CGRect(x: 5, y: 5, width: 44, height: 44)
        doneButton.imageEdgeInsets = UIEdgeInsetsMake(15.25, 15.25, 15.25, 15.25)
        doneButton.backgroundColor = UIColor.clear
        doneButton.addTarget(self, action: #selector(HoneycombPhotoBrowser.doneButtonPressed(_:)), for: UIControlEvents.touchUpInside)
        doneButton.alpha = 0.0
        view.addSubview(doneButton)
        
        // gesture
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(HoneycombPhotoBrowser.panGestureRecognized(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
        
        // transition (this must be last call of view did load.)
        performPresentAnimation()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        reloadData()
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        isPerformingLayout = true
        
        pagingScrollView.frame = frameForPagingScrollView()
        pagingScrollView.contentSize = contentSizeForPagingScrollView()
        pagingScrollView.contentOffset = contentOffsetForPageAtIndex(currentPageIndex)
        
        toolBar.frame = frameForToolbarAtOrientation()
        
        isPerformingLayout = false
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        isViewActive = true
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        
        currentPageIndex = 0
        pagingScrollView = nil
        visiblePages = Set()
    }
    
    // MARK: - initialize / setup
    open func reloadData(){
        performLayout()
        view.setNeedsLayout()
    }
    
    open func performLayout(){
        isPerformingLayout = true
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        var items = [UIBarButtonItem]()
        
        items.append(flexSpace)
        items.append(toolPreviousButton)
        items.append(flexSpace)
        items.append(toolCounterButton)
        items.append(flexSpace)
        items.append(toolNextButton)
        items.append(flexSpace)
        toolBar.setItems(items, animated: false)
        updateToolbar()
        
        
        visiblePages.removeAll()
        
        // set content offset
        pagingScrollView.contentOffset = contentOffsetForPageAtIndex(currentPageIndex)
        
        // tile page
        tilePages()
        
        isPerformingLayout = false
        
        view.addGestureRecognizer(panGesture)
        
    }
    
    open func prepareForClosePhotoBrowser(){
        applicationWindow.removeGestureRecognizer(panGesture)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    // MARK: - frame calculation
    open func frameForPagingScrollView() -> CGRect{
        var frame = view.bounds
        frame.origin.x -= 10
        frame.size.width += (2 * 10)
        return frame
    }
    
    open func frameForToolbarAtOrientation() -> CGRect{
        let currentOrientation = UIApplication.shared.statusBarOrientation
        var height:CGFloat = 44
        
        if UIInterfaceOrientationIsLandscape(currentOrientation){
            height = 32
        }
        
        return CGRect(x: 0, y: view.bounds.size.height - height, width: view.bounds.size.width, height: height)
    }
    
    open func contentOffsetForPageAtIndex(_ index:Int) -> CGPoint{
        let pageWidth = pagingScrollView.bounds.size.width
        let newOffset = CGFloat(index) * pageWidth
        return CGPoint(x: newOffset, y: 0)
    }
    
    open func contentSizeForPagingScrollView() -> CGSize {
        let bounds = pagingScrollView.bounds
        return CGSize(width: bounds.size.width * CGFloat(numberOfPhotos), height: bounds.size.height)
    }
    
    // MARK: - Toolbar
    open func updateToolbar(){
        if numberOfPhotos > 1 {
            toolCounterLabel.text = "\(currentPageIndex + 1) / \(numberOfPhotos)"
        } else {
            toolCounterLabel.text = nil
        }
        
        toolPreviousButton.isEnabled = (currentPageIndex > 0)
        toolNextButton.isEnabled = (currentPageIndex < numberOfPhotos - 1)
    }
    
    // MARK: - paging
    open func initializePageIndex(_ index: Int){
        var i = index
        if index >= numberOfPhotos {
            i = numberOfPhotos - 1
        }
        
        initialPageIndex = i
        currentPageIndex = i
        
        if isViewLoaded {
            jumpToPageAtIndex(index)
            if isViewActive {
                tilePages()
            }
        }
    }
    
    open func jumpToPageAtIndex(_ index:Int){
        if index < numberOfPhotos {
            let pageFrame = frameForPageAtIndex(index)
            pagingScrollView.setContentOffset(CGPoint(x: pageFrame.origin.x - 10, y: 0), animated: true)
            updateToolbar()
        }
        hideControlsAfterDelay()
    }
    
    open func photoAtIndex(_ index: Int) -> HoneycombPhoto {
        return photos[index]
    }
    
    open func frameForPageAtIndex(_ index: Int) -> CGRect {
        let bounds = pagingScrollView.bounds
        var pageFrame = bounds
        pageFrame.size.width -= (2 * 10)
        pageFrame.origin.x = (bounds.size.width * CGFloat(index)) + 10
        return pageFrame
    }
   
    // MARK: - panGestureRecognized
    open func panGestureRecognized(_ sender:UIPanGestureRecognizer){
        
        let scrollView = pageDisplayedAtIndex(currentPageIndex)
        
        let viewHeight = scrollView.frame.size.height
        let viewHalfHeight = viewHeight/2
        
        var translatedPoint = sender.translation(in: self.view)
        
        // gesture began
        if sender.state == .began {
            firstX = scrollView.center.x
            firstY = scrollView.center.y
            
            senderViewForAnimation.isHidden = (currentPageIndex == initialPageIndex)
            
            isDraggingPhoto = true
            setNeedsStatusBarAppearanceUpdate()
        }
        
        translatedPoint = CGPoint(x: firstX, y: firstY + translatedPoint.y)
        scrollView.center = translatedPoint
     
        view.isOpaque = true
        
        // gesture end
        if sender.state == .ended{
            if scrollView.center.y > viewHalfHeight+40 || scrollView.center.y < viewHalfHeight-40 {
                if currentPageIndex == initialPageIndex {
                    performCloseAnimationWithScrollView(scrollView)
                    return
                }
                
                let finalX:CGFloat = firstX
                var finalY:CGFloat = 0.0
                let windowHeight = applicationWindow.frame.size.height
                
                if scrollView.center.y > viewHalfHeight+30 {
                    finalY = windowHeight * 2.0
                } else {
                    finalY = -(viewHalfHeight)
                }
                
                let animationDuration = 0.35
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(animationDuration)
                UIView.setAnimationCurve(UIViewAnimationCurve.easeIn)
                scrollView.center = CGPoint(x: finalX, y: finalY)
                UIView.commitAnimations()
                
                dismissPhotoBrowser()
             } else {
            
                // Continue Showing View
                isDraggingPhoto = false
                setNeedsStatusBarAppearanceUpdate()
                
                let velocityY:CGFloat = 0.35 * sender.velocity(in: self.view).y
                let finalX:CGFloat = firstX
                let finalY:CGFloat = viewHalfHeight
                
                let animationDuration = Double(abs(velocityY) * 0.0002 + 0.2)
                
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(animationDuration)
                UIView.setAnimationCurve(UIViewAnimationCurve.easeIn)
                scrollView.center = CGPoint(x: finalX, y: finalY)
                UIView.commitAnimations()
            }
        }
    }
    
    
    // MARK: - perform animation
    open func performPresentAnimation(){
        
        view.alpha = 0.0
        pagingScrollView.alpha = 0.0
        
        senderViewOriginalFrame = (senderViewForAnimation.superview?.convert(senderViewForAnimation.frame, to:nil))!
        
        let fadeView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        fadeView.backgroundColor = UIColor.clear
        applicationWindow.addSubview(fadeView)
        
        let imageFromView = getImageFromView(senderViewForAnimation)
        resizableImageView = UIImageView(image: imageFromView)
        resizableImageView.frame = senderViewOriginalFrame
        resizableImageView.clipsToBounds = true
        resizableImageView.contentMode = .scaleAspectFill
        applicationWindow.addSubview(resizableImageView)
        
        senderViewForAnimation.isHidden = true
        
        let scaleFactor = imageFromView.size.width / screenWidth
        let finalImageViewFrame = CGRect(x: 0, y: (screenHeight/2) - ((imageFromView.size.height / scaleFactor)/2), width: screenWidth, height: imageFromView.size.height / scaleFactor)
        
        UIView.animate(withDuration: 0.35,
            animations: { () -> Void in
                self.resizableImageView.layer.frame = finalImageViewFrame
                self.doneButton.alpha = 1.0
            },
            completion: { (Bool) -> Void in
                self.view.alpha = 1.0
                self.pagingScrollView.alpha = 1.0
                self.resizableImageView.alpha = 0.0
                fadeView.removeFromSuperview()
        })
    }
    
    open func performCloseAnimationWithScrollView(_ scrollView:HoneycombZoomingScrollView) {
        
        view.isHidden = true
        
        let fadeView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        fadeView.backgroundColor = UIColor.clear
        fadeView.alpha = 1.0
        applicationWindow.addSubview(fadeView)
        
        resizableImageView.alpha = 1.0
        resizableImageView.clipsToBounds = true
        resizableImageView.contentMode = .scaleAspectFill
        applicationWindow.addSubview(resizableImageView)
        
        UIView.animate(withDuration: 0.35,
            animations: { () -> Void in
                fadeView.alpha = 0.0
                self.resizableImageView.layer.frame = self.senderViewOriginalFrame
            },
            completion: { (Bool) -> Void in
                self.resizableImageView.removeFromSuperview()
                fadeView.removeFromSuperview()
                self.senderViewForAnimation.isHidden = false
                self.prepareForClosePhotoBrowser()
                self.dismiss(animated: true, completion: {})
        })
    }

    fileprivate func getImageFromView(_ sender:UIView) -> UIImage{
        
        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = kCAFillRuleEvenOdd
        maskLayer.frame = sender.bounds
        
        let width:CGFloat = sender.frame.size.width
        let height:CGFloat = sender.frame.size.height
        
        // set hexagon using bezierpath
        UIGraphicsBeginImageContext(sender.frame.size)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: width/2, y: 0))
        path.addLine(to: CGPoint(x: width, y: height / 4))
        path.addLine(to: CGPoint(x: width, y: height * 3 / 4))
        path.addLine(to: CGPoint(x: width / 2, y: height))
        path.addLine(to: CGPoint(x: 0, y: height * 3 / 4))
        path.addLine(to: CGPoint(x: 0, y: height / 4))
        path.close()
        path.fill()
        maskLayer.path = path.cgPath
        sender.layer.mask = maskLayer
        sender.layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result!
    }
    
    //MARK - paging
    open func gotoPreviousPage(){
        jumpToPageAtIndex(currentPageIndex - 1)
    }
    
    open func gotoNextPage(){
        jumpToPageAtIndex(currentPageIndex + 1)
    }
    
    open func tilePages(){
        
        let visibleBounds = pagingScrollView.bounds
        
        var firstIndex = Int(floor((visibleBounds.minX + 10 * 2) / visibleBounds.width))
        var lastIndex  = Int(floor((visibleBounds.maxX - 10 * 2 - 1) / visibleBounds.width))
        if firstIndex < 0 {
            firstIndex = 0
        }
        if firstIndex > numberOfPhotos - 1 {
            firstIndex = numberOfPhotos - 1
        }
        if lastIndex < 0 {
            lastIndex = 0
        }
        if lastIndex > numberOfPhotos - 1 {
            lastIndex = numberOfPhotos - 1
        }
        
        for(var index = firstIndex; index <= lastIndex; index += 1){
            if !isDisplayingPageForIndex(index){
                
                let page = HoneycombZoomingScrollView(frame: view.frame, browser: self)
                page.frame = frameForPageAtIndex(index)
                page.tag = index + pageIndexTagOffset
                page.photo = photoAtIndex(index)
                
                visiblePages.insert(page)
                pagingScrollView.addSubview(page)
            }
        }
    }
    
    open func isDisplayingPageForIndex(_ index: Int) -> Bool{
        for page in visiblePages{
            if (page.tag - pageIndexTagOffset) == index {
                return true
            }
        }
        return false
    }
    
    open func pageDisplayedAtIndex(_ index: Int) -> HoneycombZoomingScrollView {
        var thePage:HoneycombZoomingScrollView = HoneycombZoomingScrollView()
        for page in visiblePages {
            if (page.tag - pageIndexTagOffset) == index {
               thePage = page
               break
            }
        }
        return thePage
    }
    
    open func pageDisplayingAtPhoto(_ photo: HoneycombPhoto) -> HoneycombZoomingScrollView {
        var thePage:HoneycombZoomingScrollView = HoneycombZoomingScrollView()
        for page in visiblePages {
            if page.photo == photo {
                thePage = page
                break
            }
        }
        return thePage
    }
    
    
    // MARK: - Control Hiding / Showing
    open func cancelControlHiding(){
        if controlVisibilityTimer != nil{
            controlVisibilityTimer.invalidate()
            controlVisibilityTimer = nil
        }
    }
    
    open func hideControlsAfterDelay(){
        // reset
        cancelControlHiding()
        // start
        controlVisibilityTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(HoneycombPhotoBrowser.hideControls(_:)), userInfo: nil, repeats: false)
        
    }
    
    open func hideControls(_ timer: Timer){
        setControlsHidden(true, animated: true, permanent: false)
    }
    
    open func toggleControls(){
        setControlsHidden(!areControlsHidden(), animated: true, permanent: false)
    }
    
    open func setControlsHidden(_ hidden:Bool, animated:Bool, permanent:Bool){
        cancelControlHiding()
        
        UIView.animate(withDuration: 0.35,
            animations: { () -> Void in
                let alpha:CGFloat = hidden ? 0.0 : 1.0
                self.doneButton.alpha = alpha
                self.toolBar.alpha = alpha
            },
            completion: { (Bool) -> Void in
        })
        
        if !permanent {
            hideControlsAfterDelay()
        }
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    open func areControlsHidden() -> Bool{
        return toolBar.alpha == 0.0
    }
    
    // MARK: - Button
    open func doneButtonPressed(_ sender:UIButton) {
        if currentPageIndex == initialPageIndex {
            performCloseAnimationWithScrollView(pageDisplayedAtIndex(currentPageIndex))
        } else {
            dismissPhotoBrowser()
        }
    }
    
    open func dismissPhotoBrowser(){
        modalTransitionStyle = .crossDissolve
        senderViewForAnimation.isHidden = false
        prepareForClosePhotoBrowser()
        dismiss(animated: true, completion: {})
    }
    
    // MARK: -  UIScrollView Delegate
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !isViewActive {
            return
        }
        if isPerformingLayout {
            return
        }
        
        // tile page
        tilePages()
        
        // Calculate current page
        let visibleBounds = pagingScrollView.bounds
        var index = Int(floor(visibleBounds.midX / visibleBounds.width))
        
        if index < 0 {
            index = 0
        }
        if index > numberOfPhotos - 1 {
            index = numberOfPhotos
        }
        let previousCurrentPage = currentPageIndex
        currentPageIndex = index
        if currentPageIndex != previousCurrentPage {
            updateToolbar()
        }
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        setControlsHidden(true, animated: true, permanent: false)
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        hideControlsAfterDelay()
    }
}
