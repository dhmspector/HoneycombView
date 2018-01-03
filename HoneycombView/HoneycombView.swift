//
//  HoneycombView.swift
//  HoneycombView
//
//  Created by suzuki_keishi on 7/1/15.
//  Copyright © 2015 suzuki_keishi. All rights reserved.
//

import UIKit

public enum HoneycombAnimateType { case fadeIn }

// MARK: - HoneycombView
open class HoneycombView: UIView{
    
    open var animateType:HoneycombAnimateType = .fadeIn
    
    open var diameter:CGFloat = 100
    open var margin:CGFloat = 10
    open var honeycombBackgroundColor = UIColor.black
    open var shouldCacheImage = false
    open var images = [HoneycombPhoto]()
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
    }
    
    open func configrationForHoneycombView() {
        let structure = constructView()
        
        for point in structure {
            addSubview(initializeHoneyCombChildView(point))
        }
    }
    
    open func configrationForHoneycombViewWithImages(_ images:[UIImage]){
        self.images = resizeImage(images)
        
        let structure = constructView()
        
        for (index, point)in structure.enumerated(){
            let v = initializeHoneyCombChildView(point)
            v.tag = index
            
            // set image if images have
            if self.images.count > index {
                v.setHoneycombImage(self.images[index])
            }
            addSubview(v)
        }
    }
    
    open func configrationForHoneycombViewWithURL(_ urls:[String], placeholder:UIImage? = nil){
        let structure = constructView()
        
        for (index, point)in structure.enumerated(){
            let v = initializeHoneyCombChildView(point)
            v.tag = index
            
            if urls.count > index {
                v.setHoneycombImageFromURL(urls[index])
            }
            addSubview(v)
        }
    }
    
    fileprivate func resizeImage(_ images:[UIImage]) -> [HoneycombPhoto]{
        var photos = [HoneycombPhoto]()
        
        for image in images {
            photos.append(HoneycombPhoto(image: image.createHoneycombPhoto()))
        }
        return photos
    }
    
    fileprivate func initializeHoneyCombChildView(_ point:CGPoint) -> HoneycombChildView{
        let v = HoneycombChildView(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        v.center = point
        v.backgroundColor = honeycombBackgroundColor
        return v
    }
    
    fileprivate func constructView() -> [CGPoint]{
        var structure = [CGPoint]()
        
        // initialize
        let side = (buttom: 0, left: 1, upper: 2, right: 3)
        let centerPoint = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
        let radius =  (diameter + margin) / 2.0
        let interval = CGSize(width: radius * 2.0, height: radius * 2.0 - (diameter/4))
        let layerCount = Int(ceil(frame.height/max(interval.width, interval.height)))
        
        // configure view point
        for layerId in 0..<layerCount{
            // if layer is first of point
            if layerId == 0{
                structure.append(centerPoint)
                continue
            }
            
            let countInSide = layerId * 2
            for sideId in 0..<4 {
                var direction = (x: 0, y:0)
                // point x, y from center point
                var point = (a:layerId, b:layerId)
                
                // set direction and point from center
                switch sideId {
                case side.buttom:
                    (direction.x, direction.y) = (-1, 0)
                    (point.a, point.b) = (layerId, layerId)
                case side.left:
                    (direction.x, direction.y) = (0, -1)
                    (point.a,   point.b) = (-layerId, layerId)
                case side.upper:
                    (direction.x, direction.y) = (1, 0)
                    (point.a, point.b) = (-layerId, -layerId)
                case side.right:
                    (direction.x, direction.y) = (0, 1)
                    (point.a, point.b) = (layerId, -layerId)
                default: break
                }
                
                // forward next point of side
                for indexInSide in 0..<countInSide {
                    let x = point.a + direction.x * indexInSide
                    let y = point.b + direction.y * indexInSide
                    
                    var actualPoint = (x:CGFloat(0.0), y:CGFloat(0.0))
                    // go forward a half when odd
                    if(y % 2 == 0) {
                        actualPoint.x = centerPoint.x + interval.width * CGFloat(x)
                    } else {
                        actualPoint.x = centerPoint.x + interval.width * (CGFloat(x) + 0.5)
                    }
                    actualPoint.y = centerPoint.y + interval.height * CGFloat(y)
                    
                    // finally add point.
                    structure.append(CGPoint(x: actualPoint.x, y: actualPoint.y))
                }
            }
        }
        return structure
    }
    
    
    open func animate(){
        animate(2.0)
    }
    
    open func animate(_ duration: Double){
        animate(duration, delay:0.0)
    }
    
    open func animate(_ duration: Double, delay: Double){
        for honeycombView in subviews {
            if honeycombView is HoneycombChildView {
                (honeycombView as! HoneycombChildView).animate(duration: duration, animateType:animateType)
            }
        }
    }
}

// MARK: - HoneycombImageView
open class HoneycombChildView: UIButton{
    
    var honeycombImageView:HoneycombImageView!
    
    var color: UIColor =  UIColor.orange{
        didSet {
            backgroundColor = color
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupHexagonView()
        
        honeycombImageView = HoneycombImageView(frame: frame)
        addSubview(honeycombImageView)
    }

    open func setupHexagonView(){
        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = kCAFillRuleEvenOdd
        maskLayer.frame = bounds
        
        let width:CGFloat = frame.size.width
        let height:CGFloat = frame.size.height
        
        // set hexagon using bezierpath
        UIGraphicsBeginImageContext(frame.size)
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
        UIGraphicsEndImageContext()
        layer.mask = maskLayer
        
        addTarget(self, action: #selector(HoneycombChildView.imageTapped(_:)), for: .touchUpInside)
    }

    
    open func animate(_ animateType: HoneycombAnimateType = .fadeIn){
        animate(duration:2.0)
    }
    
    open func animate(duration: Double, animateType: HoneycombAnimateType = .fadeIn){
        let delay = (Double(arc4random() % 100) / 100.0)
        
        switch animateType{
        case .fadeIn :
            alpha = 0.0
            UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.curveEaseOut, animations: {
                self.alpha = 1.0
                }, completion: { animateFinish in
            })
        }
    }
    
    open func imageTapped(_ sender: UIButton){
        if let sv = superview as? HoneycombView{
            let browser = HoneycombPhotoBrowser(photos: sv.images, animatedFromView: sender)
            browser.initializePageIndex(sender.tag)
            if let vc = UIApplication.shared.keyWindow?.rootViewController{
                vc.present(browser, animated: true, completion: {})
            }
        }
    }
    
    func setHoneycombImage(_ image:HoneycombPhoto){
        honeycombImageView.image = image.underlyingImage
    }
    
    func setHoneycombImageFromURL(_ url:String){
        honeycombImageView.imageFromURL(url, placeholder: UIImage()){[weak self] image in
            if let _self = self, let sv = _self.superview as? HoneycombView {
                sv.images.append(HoneycombPhoto(image: image.createHoneycombPhoto()))
            }
        }
    }

}

// MARK: - HoneycombImageView
open class HoneycombImageView: UIImageView {
    
    var color: UIColor =  UIColor.orange{
        didSet {
            backgroundColor = color
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

}

// MARK: - extension UIImageView
public extension UIImageView {
    func imageFromURL(_ url: String, placeholder: UIImage, shouldCacheImage:Bool = true, fadeIn: Bool = true, callback:@escaping (UIImage)->()) {
        self.image = UIImage.imageFromURL(url, placeholder: placeholder, shouldCacheImage: true) {
            (image: UIImage?) in
            if image == nil {
                return
            }
            if fadeIn {
                self.alpha = 0.0
                let duration = 1.0
                let delay = (Double(arc4random() % 100) / 100.0)
                UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions.curveLinear, animations: {
                    self.alpha = 1.0
                    }, completion: { animateFinish in
                })
            }
            self.image = image
            callback(image!)
        }
    }
}

// MARK: - extension UIImage
public extension UIImage {
    
    fileprivate class func sharedHoneycombCache() -> NSCache<AnyObject, AnyObject>! {
        struct StaticSharedHoneycombCache {
            static var sharedCache: NSCache? = nil
            static var onceToken: Int = 0
        }
        dispatch_once(&StaticSharedHoneycombCache.onceToken) {
            StaticSharedHoneycombCache.sharedCache = NSCache()
        }
        return StaticSharedHoneycombCache.sharedCache!
    }
    
    func createHoneycombPhoto() -> UIImage{
        let imageView = UIImageView(image: self)
        // set hexagon using bezierpath
        let width:CGFloat = imageView.frame.size.width
        let height:CGFloat = imageView.frame.size.height
        
        UIGraphicsBeginImageContext(imageView.frame.size)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: width/2, y: 0))
        path.addLine(to: CGPoint(x: width, y: height / 4))
        path.addLine(to: CGPoint(x: width, y: height * 3 / 4))
        path.addLine(to: CGPoint(x: width / 2, y: height))
        path.addLine(to: CGPoint(x: 0, y: height * 3 / 4))
        path.addLine(to: CGPoint(x: 0, y: height / 4))
        path.close()
        path.fill()
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        imageView.layer.mask = maskLayer
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result!
    }
    
    class func imageFromURL(_ url: String, placeholder: UIImage, shouldCacheImage: Bool = true, closure: @escaping (_ image: UIImage?) -> ()) -> UIImage? {
        // From Cache
        if shouldCacheImage {
            if UIImage.sharedHoneycombCache().object(forKey: url as AnyObject) != nil {
                closure(UIImage.sharedHoneycombCache().object(forKey: url as AnyObject) as? UIImage)
                return UIImage.sharedHoneycombCache().object(forKey: url as AnyObject) as! UIImage!
            }
        }
        // Fetch Image
        let session = URLSession(configuration: URLSessionConfiguration.default)
        if let nsURL = URL(string: url) {
            session.dataTask(with: nsURL, completionHandler: {
                (response: Data?, data: URLResponse?, error: NSError?) in
                if error != nil {
                    DispatchQueue.main.async {
                        closure(placeholder)
                    }
                }
                if let res = response, let image = UIImage(data: res) {
                    if shouldCacheImage {
                        UIImage.sharedHoneycombCache().setObject(image, forKey: url as AnyObject)
                    }
                    DispatchQueue.main.async {
                        closure(image)
                    }
                }
                session.finishTasksAndInvalidate()
            } as! (Data?, URLResponse?, Error?) -> Void).resume()
        }
        return placeholder
    }
}
