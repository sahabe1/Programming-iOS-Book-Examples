

import UIKit

func delay(_ delay:Double, closure:@escaping ()->()) {
    let when = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
}


extension CGRect {
    var center : CGPoint {
    return CGPoint(self.midX, self.midY)
    }
}

extension CGRect {
    init(_ x:CGFloat, _ y:CGFloat, _ w:CGFloat, _ h:CGFloat) {
        self.init(x:x, y:y, width:w, height:h)
    }
}

extension CGSize {
    init(_ width:CGFloat, _ height:CGFloat) {
        self.init(width:width, height:height)
    }
}
extension CGPoint {
    init(_ x:CGFloat, _ y:CGFloat) {
        self.init(x:x, y:y)
    }
}


// view exists solely to host layer
class CompassView : UIView {
    override class var layerClass : AnyClass {
        return CompassLayer.self
    }
}

class CompassLayer : CALayer, CALayerDelegate {
    var arrow : CALayer?
    var rotationLayer : CALayer!
    var didSetup = false
    
    let which = 2

    func doRotate () {
        print("rotate")
        switch which {
        case 1:
            self.rotationLayer.anchorPoint = CGPoint(1,0.5)
            self.rotationLayer.position = CGPoint(self.bounds.maxX, self.bounds.midY)
            self.rotationLayer.transform = CATransform3DMakeRotation(.pi/4.0, 0, 1, 0)
//          self.rotationLayer.setValue(.pi/4.0, forKeyPath:"transform.rotation.y")
//          self.rotationLayer.transform.rotation.y = M_PI/4 // nope, sorry
//          self.rotationLayer.setValue(.pi/4.0, forKeyPath:#keyPath(CALayer.transform.rotation.y)) // nope
        case 2:
            self.rotationLayer.anchorPoint = CGPoint(1,0.5)
            self.rotationLayer.position = CGPoint(self.bounds.maxX, self.bounds.midY)
            self.rotationLayer.transform = CATransform3DMakeRotation(.pi/4.0, 0, 1, 0)
            
            var transform = CATransform3DIdentity
            transform.m34 = -1.0/1000.0
            self.sublayerTransform = transform

        default: break
        }
    }
    
    override func layoutSublayers() {
        if !self.didSetup {
            self.didSetup = true
            self.setup()
            delay(1) {self.doRotate()}
        }
    }
    
    func setup () {
        print("setup")
        
        // the gradient
        let g = CAGradientLayer()
        g.contentsScale = UIScreen.main.scale
        g.frame = self.bounds
        g.colors = [
            UIColor.black.cgColor,
            UIColor.red.cgColor
            ]
        g.locations = [0.0,1.0]
        self.addSublayer(g)

        // the circle
        let circle = CAShapeLayer()
        circle.contentsScale = UIScreen.main.scale
        circle.lineWidth = 2.0
        circle.fillColor = UIColor(red:0.9, green:0.95, blue:0.93, alpha:0.9).cgColor
        circle.strokeColor = UIColor.gray.cgColor
        let p = CGMutablePath()
        p.addEllipse(in: self.bounds.insetBy(dx: 3, dy: 3))
        circle.path = p
        g.addSublayer(circle)
        circle.bounds = self.bounds
        circle.position = self.bounds.center
        
        // the four cardinal points
        let pts = "NESW"
        for (ix,c) in pts.characters.enumerated() {
            let t = CATextLayer()
            t.contentsScale = UIScreen.main.scale
            t.string = String(c)
            t.bounds = CGRect(0,0,40,40)
            t.position = circle.bounds.center
            let vert = circle.bounds.midY / t.bounds.height
            t.anchorPoint = CGPoint(0.5, vert)
            //print(t.anchorPoint)
            t.alignmentMode = kCAAlignmentCenter
            t.foregroundColor = UIColor.black.cgColor
            t.setAffineTransform(CGAffineTransform(rotationAngle:CGFloat(ix) * .pi/2.0))
            circle.addSublayer(t)
        }

        
        // the arrow
        let arrow = CALayer()
        arrow.contentsScale = UIScreen.main.scale
        arrow.bounds = CGRect(0, 0, 40, 100)
        arrow.position = self.bounds.center
        arrow.anchorPoint = CGPoint(0.5, 0.8)
        arrow.delegate = self // we will draw the arrow in the delegate method
        // in Swift, not a property:
        arrow.setAffineTransform(CGAffineTransform(rotationAngle:.pi/5.0))
        g.addSublayer(arrow)
        arrow.setNeedsDisplay() // draw, please
        
        // self.arrow = arrow
        self.rotationLayer = g

    }
    
    func draw(_ layer: CALayer, in con: CGContext) {
        print("drawLayer:inContext: for arrow")
        
        // Questa poi la conosco pur troppo!
        
        // punch triangular hole in context clipping region
        con.move(to: CGPoint(10, 100))
        con.addLine(to: CGPoint(20, 90))
        con.addLine(to: CGPoint(30, 100))
        con.closePath()
        con.addRect(con.boundingBoxOfClipPath)
        con.clip(using:.evenOdd)
        
        // draw the vertical line, add its shape to the clipping region
        con.move(to: CGPoint(20, 100))
        con.addLine(to: CGPoint(20, 19))
        con.setLineWidth(20)
        con.strokePath()
        
        // draw the triangle, the point of the arrow
        let r = UIGraphicsImageRenderer(size:CGSize(4,4))
        let stripes = r.image {
            ctx in
            let imcon = ctx.cgContext
            imcon.setFillColor(UIColor.red.cgColor)
            imcon.fill(CGRect(0,0,4,4))
            imcon.setFillColor(UIColor.blue.cgColor)
            imcon.fill(CGRect(0,0,4,2))
        }
        
            let stripesPattern = UIColor(patternImage:stripes)
        
        UIGraphicsPushContext(con)
            stripesPattern.setFill()
            let p = UIBezierPath()
            p.move(to:CGPoint(0,25))
            p.addLine(to:CGPoint(20,0))
            p.addLine(to:CGPoint(40,25))
            p.fill()
        UIGraphicsPopContext()

    }
    
    
}
