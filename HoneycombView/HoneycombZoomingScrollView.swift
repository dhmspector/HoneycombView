//
//  HoneycombZoomingScrollView.swift
//  HoneycombViewExample
//
//  Created by suzuki_keihsi on 2015/10/01.
//  Copyright © 2015 suzuki_keishi. All rights reserved.
//

import UIKit

open class HoneycombZoomingScrollView:UIScrollView, UIScrollViewDelegate, HoneycombDetectingViewDelegate, HoneycombDetectingImageViewDelegate{
    
    weak var photoBrowser:HoneycombPhotoBrowser!
    var photo:HoneycombPhoto!{
        didSet{
            photoImageView.image = nil
            displayImage()
        }
    }
    
    var tapView:HoneycombDetectingView!
    var photoImageView:HoneycombDetectingImageView!
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    convenience init(frame: CGRect, browser: HoneycombPhotoBrowser) {
        self.init(frame: frame)
        photoBrowser = browser
        setup()
    }
    
    
    func setup() {
        // tap
        tapView = HoneycombDetectingView(frame: bounds)
        tapView.delegate = self
        tapView.backgroundColor = UIColor.clear
        tapView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(tapView)
        
        // image
        photoImageView = HoneycombDetectingImageView(frame: frame)
        photoImageView.delegate = self
        photoImageView.backgroundColor = UIColor.clear
        addSubview(photoImageView)
        
        // self
        backgroundColor = UIColor.clear
        delegate = self
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        decelerationRate = UIScrollViewDecelerationRateFast
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    // MARK: - override
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        tapView.frame = bounds
        
        let boundsSize = bounds.size
        var frameToCenter = photoImageView.frame
        
        // horizon
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = floor((boundsSize.width - frameToCenter.size.width) / 2)
        } else {
            frameToCenter.origin.x = 0
        }
        // vertical
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = floor((boundsSize.height - frameToCenter.size.height) / 2)
        } else {
            frameToCenter.origin.y = 0
        }
        
        // Center
        if !photoImageView.frame.equalTo(frameToCenter){
            photoImageView.frame = frameToCenter
        }
    }
    
    open func setMaxMinZoomScalesForCurrentBounds(){
        
        maximumZoomScale = 1
        minimumZoomScale = 1
        zoomScale = 1
        
        if photoImageView == nil {
            return
        }
        
        let boundsSize = bounds.size
        let imageSize = photoImageView.frame.size
        
        let xScale = boundsSize.width / imageSize.width
        let yScale = boundsSize.height / imageSize.height
        var maxScale:CGFloat = 4.0
        let minScale:CGFloat = min(xScale, yScale)
        
        maximumZoomScale = maxScale
        minimumZoomScale = minScale
        zoomScale = minScale
        
        // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
        // maximum zoom scale to 0.5
        maxScale = maxScale / UIScreen.main.scale
        if maxScale < minScale {
            maxScale = minScale * 2
        }
        
        // reset position
        photoImageView.frame = CGRect(x: 0, y: 0, width: photoImageView.frame.size.width, height: photoImageView.frame.size.height)
        setNeedsLayout()
    }
    
    open func prepareForReuse(){
        photo = nil
    }
    
    // MARK: - image
    open func displayImage(){
        // reset scale
        maximumZoomScale = 1
        minimumZoomScale = 1
        zoomScale = 1
        contentSize = CGSize.zero
        
        if photo != nil {
            
            let image = photo.underlyingImage
            
            photoImageView.image = image

            var photoImageViewFrame = CGRect.zero
            photoImageViewFrame.origin = CGPoint.zero
            photoImageViewFrame.size = (image?.size)!
            
            photoImageView.frame = CGRect(x: 0, y: 0,
                width: min(photoImageViewFrame.size.width, photoImageViewFrame.size.height),
                height: min(photoImageViewFrame.size.width, photoImageViewFrame.size.height))
            
            contentSize = photoImageViewFrame.size
            
            setMaxMinZoomScalesForCurrentBounds()
        }
        
        setNeedsLayout()
    }

    // MARK: - handle tap
    open func handleDoubleTap(_ touchPoint: CGPoint){
        NSObject.cancelPreviousPerformRequests(withTarget: photoBrowser)
        
        if zoomScale == maximumZoomScale {
            // zoom out
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            // zoom in
            zoom(to: CGRect(x: touchPoint.x, y: touchPoint.y, width: 1, height: 1), animated:true)
        }
        
        // delay control
        photoBrowser.hideControlsAfterDelay()
    }
    
    // MARK: - UIScrollViewDelegate
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photoImageView
    }
    
    open func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        photoBrowser.cancelControlHiding()
    }
    
    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    
    // MARK: - HoneycombDetectingViewDelegate
    func handleSingleTap(_ view: UIView, touch: UITouch) {
        photoBrowser.toggleControls()
    }
    
    func handleDoubleTap(_ view: UIView, touch: UITouch) {
        handleDoubleTap(touch.location(in: view))
    }
    
    // MARK: - HoneycombDetectingImageViewDelegate
    func handleImageViewSingleTap(_ view: UIImageView, touch: UITouch) {
        photoBrowser.toggleControls()
    }
    
    func handleImageViewDoubleTap(_ view: UIImageView, touch: UITouch) {
        handleDoubleTap(touch.location(in: view))
    }
}
