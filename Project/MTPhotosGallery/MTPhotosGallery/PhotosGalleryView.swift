import AVFoundation

let MAXIMUM_SCALE:CGFloat = CGFloat(3.0)
let MINIMUM_SCALE:CGFloat = CGFloat(1.0)

import UIKit
//MARK: - Photos Cell Create
class CellPhotosHeaderImage: UICollectionViewCell {
    var imageThumb:UIImageView!
    var lblConter:UILabel!
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageThumb = UIImageView(frame: CGRect(x: 0,y: 0,width : 1,height: 1))
        self.addSubview(imageThumb)
        
        lblConter = UILabel(frame: CGRect(x: 0,y: 0,width : 1,height: 1))
        lblConter.font = UIFont.init(name: "Arial", size: 25)
        lblConter.textAlignment = .center
        lblConter.textColor = .black
        lblConter.isHidden = true
        self.addSubview(lblConter)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class CellPhotosImage: UICollectionViewCell, UIScrollViewDelegate {
    var lblConter:UILabel!
    var imageBig:UIImageView!
    var scrollImageBG:UIScrollView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageBig = UIImageView(frame: CGRect(x: 0,y: 0,width : 1,height: 1))
        imageBig.backgroundColor = .blue
        imageBig.contentMode = .top
        imageBig.clipsToBounds = true
        imageBig.backgroundColor = .clear
        
        scrollImageBG = UIScrollView(frame: CGRect(x: 0,y: 0,width: 1,height: 1))
        scrollImageBG.backgroundColor = .clear
        scrollImageBG.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollImageBG.maximumZoomScale = MAXIMUM_SCALE
        scrollImageBG.minimumZoomScale = MINIMUM_SCALE
        scrollImageBG.clipsToBounds = true
        scrollImageBG.delegate = self
        self.addSubview(scrollImageBG)
        scrollImageBG.addSubview(imageBig)
        
        lblConter = UILabel(frame: CGRect(x: 0,y: 0,width : 1,height: 1))
        lblConter.font = UIFont.init(name: "Arial", size: 25)
        lblConter.textColor = .black
        lblConter.textAlignment = .center
        lblConter.isUserInteractionEnabled = false
        lblConter.isHidden = true
        self.addSubview(lblConter)
        
        self.setup()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setup() {
        let tapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(CellPhotosImage.handleDoubleTap))
        tapGestureRecognizer.numberOfTapsRequired = 2
        
        let pinchGestureRecognizer: UIPinchGestureRecognizer = UIPinchGestureRecognizer.init(target: self, action: #selector(CellPhotosImage.zoomImage))
        
        self.imageBig.gestureRecognizers = [pinchGestureRecognizer,tapGestureRecognizer]
        self.imageBig.isUserInteractionEnabled = true
        self.scrollImageBG.delegate = self
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageBig
    }
    func zoomImage(gesture: UIPinchGestureRecognizer) {
        if (gesture.state == UIGestureRecognizerState.ended || gesture.state == UIGestureRecognizerState.changed) {
            
            let currentScale:CGFloat = self.frame.size.width / self.bounds.size.width
            var newScale:CGFloat = currentScale * gesture.scale
            
            if (newScale < MINIMUM_SCALE) {
                newScale = MINIMUM_SCALE
            }
            if (newScale > MAXIMUM_SCALE) {
                newScale = MAXIMUM_SCALE
            }
        }
    }
    func handleDoubleTap(gestureRecognizer: UIGestureRecognizer) {
        if scrollImageBG.zoomScale > scrollImageBG.minimumZoomScale {
            scrollImageBG.setZoomScale(scrollImageBG.minimumZoomScale, animated: true)
            UserDefaults.standard.set(scrollImageBG.minimumZoomScale, forKey: "PhotoZoomingScale")
            UserDefaults.standard.synchronize()
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "startAutoAnimationTimerNotification"), object: nil)
        }
        else {
            scrollImageBG.setZoomScale(scrollImageBG.maximumZoomScale, animated: true)
            UserDefaults.standard.set(scrollImageBG.maximumZoomScale, forKey: "PhotoZoomingScale")
            UserDefaults.standard.synchronize()
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "stopAutoAnimationNotification"), object: nil)
        }
    }
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        UserDefaults.standard.set(1.1, forKey: "PhotoZoomingScale")
        UserDefaults.standard.synchronize()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "stopAutoAnimationNotification"), object: nil)
    }
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        UserDefaults.standard.set(scale, forKey: "PhotoZoomingScale")
        UserDefaults.standard.synchronize()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "startAutoAnimationTimerNotification"), object: nil)
    }
}
class PhotosGalleryView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    //MARK: - Variable Declaration
    //Header Gallery
    var collectionHeaderImage:UICollectionView!
    var widthCellHeader:CGFloat!
    var indexOfHeaderFirstCell = 0
    var pointHeaderFirstCell:CGPoint!
    
    //Footer Gallery
    var collectionImage:UICollectionView!
    var widthCellFooter:CGFloat!
    var timerFooterCollectionViewAnimation:Timer!
    var indexOfFooterVisibleCell:IndexPath!
    var scrollViewFooter:UIScrollView!
    
    var arrImagesData = [GalleryDataImages]()
    var indexHeaderCell = -1
    
    //MARK: - Override Method
    override init(frame: CGRect) {
        super.init(frame: frame)
        //Stop Auto Animation
        NotificationCenter.default.addObserver(self, selector: #selector(PhotosGalleryView.stopAutoAnimation), name: NSNotification.Name(rawValue: "stopAutoAnimationNotification"), object: nil)
        //Start Auto Animation
        NotificationCenter.default.addObserver(self, selector: #selector(PhotosGalleryView.startAutoAnimationTimer), name: NSNotification.Name(rawValue: "startAutoAnimationTimerNotification"), object: nil)
        
        self.backgroundColor = .clear
        pointHeaderFirstCell = CGPoint(x: 0, y: 0)
        
        UserDefaults.standard.set(MINIMUM_SCALE, forKey: "PhotoZoomingScale")
        UserDefaults.standard.synchronize()
        
        //Header Photos
        let flowLayoutHeader = UICollectionViewFlowLayout()
        flowLayoutHeader.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        widthCellHeader = (self.frame.size.width - 35) / 4.0
        flowLayoutHeader.itemSize = CGSize(width: widthCellHeader, height: 71)
        flowLayoutHeader.scrollDirection = .horizontal
        
        collectionHeaderImage = UICollectionView(frame: CGRect(x: 2.5,y: 0,width: frame.size.width - 5,height: 71), collectionViewLayout: flowLayoutHeader)
        collectionHeaderImage.delegate = self
        collectionHeaderImage.dataSource = self
        collectionHeaderImage.register(CellPhotosHeaderImage.self, forCellWithReuseIdentifier: "CellPhotosHeaderImage")
        collectionHeaderImage.showsVerticalScrollIndicator = false
        collectionHeaderImage.showsHorizontalScrollIndicator = false
        collectionHeaderImage.backgroundColor = .clear
        self.addSubview(collectionHeaderImage)
        
        //Footer Photos
        let flowLayoutFooter = UICollectionViewFlowLayout()
        flowLayoutFooter.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        widthCellFooter = (self.frame.size.width) / 1.0
        flowLayoutFooter.minimumLineSpacing = 0.0
        flowLayoutFooter.minimumInteritemSpacing = 0.0
        flowLayoutFooter.itemSize = CGSize(width: widthCellFooter, height: (frame.size.height - (collectionHeaderImage.frame.origin.y + collectionHeaderImage.frame.size.height + 10)))
        flowLayoutFooter.scrollDirection = .horizontal
        
        collectionImage = UICollectionView(frame: CGRect(x: 0,y: collectionHeaderImage.frame.origin.y + collectionHeaderImage.frame.size.height + 5,width: frame.size.width,height: (frame.size.height - (collectionHeaderImage.frame.origin.y + collectionHeaderImage.frame.size.height + 0))), collectionViewLayout: flowLayoutFooter)
        collectionImage.delegate = self
        collectionImage.dataSource = self
        collectionImage.register(CellPhotosImage.self, forCellWithReuseIdentifier: "CellPhotosImage")
        collectionImage.showsVerticalScrollIndicator = false
        collectionImage.showsHorizontalScrollIndicator = false
        collectionImage.isPagingEnabled = true
        collectionImage.backgroundColor = .clear
        self.addSubview(collectionImage)
        
        self.startAutoAnimationTimer()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - UICollectionView Delegate / Data Sources
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrImagesData.count
    }
    @available(iOS 6.0, *)
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        /*
         -> Don’t perform data binding at cellForItemAt method.
         -> B'coz because there’s no cell on screen yet.
         -> Just get the reuse cell from catch or create new and return immediately. this increase calling frequency of this method.
         -> For data binding you can use willDisplay method.
         */
        
        if collectionHeaderImage == collectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellPhotosHeaderImage", for: indexPath) as! CellPhotosHeaderImage
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellPhotosImage", for: indexPath) as! CellPhotosImage
            
            cell.scrollImageBG.zoomScale = MINIMUM_SCALE
            let transform:CGAffineTransform = CGAffineTransform(scaleX: MINIMUM_SCALE, y: MINIMUM_SCALE)
            cell.imageBig.transform = transform
            cell.scrollImageBG.contentOffset = CGPoint.zero
            
            return cell
        }
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        //Header Collection View
        if let cellPhotosHeaderImage = cell as? CellPhotosHeaderImage {
            cellPhotosHeaderImage.imageThumb.frame = CGRect(x: 0,y: 0,width: cell.frame.size.width,height: cell.frame.size.height)
            cellPhotosHeaderImage.imageThumb.clipsToBounds = true
            cellPhotosHeaderImage.imageThumb.backgroundColor = .clear
            
            cellPhotosHeaderImage.imageThumb.image = arrImagesData[indexPath.row].image_src
            cellPhotosHeaderImage.imageThumb.contentMode = .scaleAspectFill
            
            /*let strImageName:String = WebURL.getAudioAlbumThumbBaseURL + arrImagesData[indexPath.row].image_src
            var isImageAvailable = false
            cellPhotosHeaderImage.imageThumb.sd_setImage(with: NSURL(string: strImageName) as URL!, completed: { (image, error, SDImageCacheType, URL) in
                if image != nil
                {
                    isImageAvailable = true
                    cellPhotosHeaderImage.imageThumb.image = image
                    cellPhotosHeaderImage.imageThumb.contentMode = .scaleAspectFill
                }
            })
            if  isImageAvailable == false {
                cellPhotosHeaderImage.imageThumb.image = #imageLiteral(resourceName: "imgHomeHeadphone")
                cellPhotosHeaderImage.imageThumb.contentMode = .scaleAspectFit
            }*/
            
            cellPhotosHeaderImage.backgroundColor = .clear
            cellPhotosHeaderImage.lblConter.frame = CGRect(x: 0,y: 0,width: cell.frame.size.width,height: cell.frame.size.height)
            cellPhotosHeaderImage.lblConter.text = "\(indexPath.row+1)"
        }
            //Footer Collection View
        else if let cellPhotosImage = cell as? CellPhotosImage {
            cellPhotosImage.lblConter.frame = CGRect(x: 0,y: 0,width: cell.frame.size.width,height: cell.frame.size.height)
            cellPhotosImage.lblConter.text = "\(indexPath.row+1)"
            indexOfFooterVisibleCell = indexPath
            cellPhotosImage.backgroundColor = .clear
            
            cellPhotosImage.scrollImageBG.zoomScale = MINIMUM_SCALE
            let transform:CGAffineTransform = CGAffineTransform(scaleX: MINIMUM_SCALE, y: MINIMUM_SCALE)
            cellPhotosImage.imageBig.transform = transform
            cellPhotosImage.scrollImageBG.contentOffset = CGPoint.zero
            cellPhotosImage.scrollImageBG.frame = CGRect(x: 0,y: 0,width: cell.frame.size.width,height: cell.frame.size.height)
            cellPhotosImage.scrollImageBG.contentSize = CGSize(width: cell.frame.size.width, height: cell.frame.size.height)
            cellPhotosImage.imageBig.frame = CGRect(x: 2.5,y: 0,width: cell.frame.size.width - 5.0,height: cell.frame.size.height)
            
            //================
            cellPhotosImage.imageBig.image = arrImagesData[indexPath.row].image_src
            cellPhotosImage.imageBig.backgroundColor = .clear
            cellPhotosImage.imageBig.contentMode = .scaleAspectFill
            
            let heightInPoints = arrImagesData[indexPath.row].image_src.size.height
            let heightInPixels = heightInPoints * (arrImagesData[indexPath.row].image_src.scale)
            let widthInPoints = arrImagesData[indexPath.row].image_src.size.width
            let widthInPixels = widthInPoints * (arrImagesData[indexPath.row].image_src.scale)
            
            cellPhotosImage.imageBig.frame = CGRect(x: cellPhotosImage.imageBig.frame.origin.x,y: cellPhotosImage.imageBig.frame.origin.y,width: (cell.frame.size.width - 5.0 > widthInPixels ? widthInPixels : cell.frame.size.width - 5.0),height: (cell.frame.size.height > heightInPixels ? heightInPixels : cell.frame.size.height))
            cellPhotosImage.scrollImageBG.contentSize = cellPhotosImage.imageBig.frame.size
            
            //================
            
            /*let strImageName:String = WebURL.getAudioAlbumThumbBaseURL + arrImagesData[indexPath.row].image_src
            var isImageAvailable = false
            cellPhotosImage.imageBig.sd_setImage(with: NSURL(string: strImageName) as URL!, completed: { (image, error, SDImageCacheType, URL) in
                if image != nil {
                    isImageAvailable = true
                    cellPhotosImage.imageBig.image = image
                    cellPhotosImage.imageBig.backgroundColor = .clear
                    cellPhotosImage.imageBig.contentMode = .scaleAspectFill
                    
                    let heightInPoints = image?.size.height
                    let heightInPixels = heightInPoints! * (image?.scale)!
                    let widthInPoints = image?.size.width
                    let widthInPixels = widthInPoints! * (image?.scale)!
                    
                    cellPhotosImage.imageBig.frame = CGRect(x: cellPhotosImage.imageBig.frame.origin.x,y: cellPhotosImage.imageBig.frame.origin.y,width: (cell.frame.size.width - 5.0 > widthInPixels ? widthInPixels : cell.frame.size.width - 5.0),height: (cell.frame.size.height > heightInPixels ? heightInPixels : cell.frame.size.height))
                    cellPhotosImage.scrollImageBG.contentSize = cellPhotosImage.imageBig.frame.size
                }
            })
            if  isImageAvailable == false {
                cellPhotosImage.imageBig.contentMode = .scaleAspectFit
                cellPhotosImage.imageBig.image = #imageLiteral(resourceName: "imgHomeScreenLemonLogo")
                cellPhotosImage.scrollImageBG.contentSize = cellPhotosImage.imageBig.frame.size
            }*/
            cellPhotosImage.backgroundColor = .clear
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Header Collection View Selected Item
        if collectionHeaderImage == collectionView {
            if (self.getFooterCellVisible().row - 1) != indexPath.row {
                UserDefaults.standard.set(MINIMUM_SCALE, forKey: "PhotoZoomingScale")
                UserDefaults.standard.synchronize()
            }
            
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(cellFooterMoveToPerticularIndex), object: nil)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(cellHeaderMoveToPerticularIndex), object: nil)
            
            if timerFooterCollectionViewAnimation != nil {
                timerFooterCollectionViewAnimation.invalidate()
                timerFooterCollectionViewAnimation = nil
            }
            indexOfFooterVisibleCell = indexPath
            self.cellHeaderMoveToPerticularIndex()
            
            self.startAutoAnimationTimer()
            collectionImage.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: true)
        }
            //Footer Collection View Selected Item
        else if collectionImage == collectionView {
            print("Footer image : \(indexPath.row)")
        }
    }
    //MARK: - Scroll View Delegate Method
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        indexHeaderCell = self.getHeaderFirstCellIndex().row
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(cellFooterMoveToPerticularIndex), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(cellHeaderMoveToPerticularIndex), object: nil)
        
        if timerFooterCollectionViewAnimation != nil {
            timerFooterCollectionViewAnimation.invalidate()
            timerFooterCollectionViewAnimation = nil
        }
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if scrollView == collectionHeaderImage {
            let pageWidth: Float = Float((collectionHeaderImage.frame.size.width + 10) / 4.0)
            let currentOffset: Float = Float(scrollView.contentOffset.x)
            let targetOffset: Float = Float(targetContentOffset.pointee.x)
            var newTargetOffset: Float = 0
            if targetOffset > currentOffset {
                newTargetOffset = ceilf(currentOffset / pageWidth) * pageWidth
            }
            else {
                newTargetOffset = floorf(currentOffset / pageWidth) * pageWidth
            }
            if newTargetOffset < 0 {
                newTargetOffset = 0
            }
            else if (newTargetOffset > Float(scrollView.contentSize.width)){
                newTargetOffset = Float(Float(scrollView.contentSize.width))
            }
            
            targetContentOffset.pointee.x = CGFloat(currentOffset)
            pointHeaderFirstCell = CGPoint(x: CGFloat(newTargetOffset), y: scrollView.contentOffset.y)
            scrollView.setContentOffset(CGPoint(x: CGFloat(newTargetOffset), y: scrollView.contentOffset.y), animated: true)
            
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(cellFooterMoveToPerticularIndex), object: nil)
            self.perform(#selector(cellFooterMoveToPerticularIndex), with: nil, afterDelay: 0.5)
        }
        else if scrollView == collectionImage {
            if self.isImageZooming() == false {
                self.startAutoAnimationTimer()
            }
            
            if velocity.x != 0.0 {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(cellHeaderMoveToPerticularIndex), object: nil)
                self.perform(#selector(cellHeaderMoveToPerticularIndex), with: nil, afterDelay: 0.5)
            }
        }
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("scrollViewDidEndScrollingAnimation")
        UserDefaults.standard.set(MINIMUM_SCALE, forKey: "PhotoZoomingScale")
        UserDefaults.standard.synchronize()
        self.startAutoAnimationTimer()
    }
    func cellFooterMoveToPerticularIndex() {
        if indexHeaderCell != self.getHeaderFirstCellIndex().row {
            UserDefaults.standard.set(MINIMUM_SCALE, forKey: "PhotoZoomingScale")
            UserDefaults.standard.synchronize()
        }
        self.startAutoAnimationTimer()
        collectionImage.scrollToItem(at: self.getHeaderFirstCellIndex(), at: UICollectionViewScrollPosition.centeredHorizontally, animated: true)
    }
    func cellHeaderMoveToPerticularIndex() {
        collectionHeaderImage.scrollToItem(at: indexOfFooterVisibleCell, at: UICollectionViewScrollPosition.left, animated: true)
    }
    func getHeaderFirstCellIndex() -> IndexPath {
        var indexPath = collectionHeaderImage.indexPathForItem(at: pointHeaderFirstCell)
        if indexPath == nil {
            indexPath = IndexPath(item: arrImagesData.count - 1, section: 0)
        }
        return indexPath!
    }
    func getFooterCellVisible() -> IndexPath {
        let indexPath = IndexPath(row: arrImagesData.count == indexOfFooterVisibleCell.row + 1 ? indexOfFooterVisibleCell.row : indexOfFooterVisibleCell.row + 1, section: indexOfFooterVisibleCell.section)
        return indexPath
    }
    func scrollToNextCell() {
        if self.isImageZooming() == true {
            return
        }
        
        //get Collection View Instance
        let _:UICollectionView;
        
        //get cell size
        let cellSize = CGSize(width: widthCellFooter, height: (frame.size.height - (collectionHeaderImage.frame.origin.y + collectionHeaderImage.frame.size.height + 10)));
        
        //get current content Offset of the Collection view
        let contentOffset = collectionImage.contentOffset;
        
        //scroll to next cell
        collectionImage.scrollRectToVisible(CGRect(x: contentOffset.x + cellSize.width,y:  contentOffset.y,width: cellSize.width,height: cellSize.height), animated: true);
        
        collectionHeaderImage.scrollToItem(at: self.getFooterCellVisible(), at: UICollectionViewScrollPosition.left, animated: true)
    }
    func startAutoAnimationTimer() {
        if timerFooterCollectionViewAnimation != nil {
            timerFooterCollectionViewAnimation.invalidate()
            timerFooterCollectionViewAnimation = nil
        }
        
        timerFooterCollectionViewAnimation = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(PhotosGalleryView.scrollToNextCell), userInfo: nil, repeats: true);
    }
    func stopAutoAnimation() {
        if self.timerFooterCollectionViewAnimation != nil {
            self.timerFooterCollectionViewAnimation.invalidate()
            self.timerFooterCollectionViewAnimation = nil
        }
    }
    //MARK: - Show
    func show(view: UIView,arrImagesListModel: [GalleryDataImages]) -> UIView {
        view.addSubview(self)
        arrImagesData.removeAll()
        arrImagesData = arrImagesListModel
        collectionHeaderImage.reloadData()
        collectionImage.reloadData()
        return self
    }
    func isImageZooming() -> Bool {
        if let scale = UserDefaults.standard.object(forKey: "PhotoZoomingScale") {
            let fltScale:CGFloat = scale as! CGFloat
            if fltScale != MINIMUM_SCALE {
                return true
            }
        }
        return false
    }
}
