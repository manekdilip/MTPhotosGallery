import UIKit

//MARK: - Model Class
class GalleryDataImages {
    var image_src:UIImage = UIImage()
    
    //Allock memory and data
    init(image_src:UIImage) {
        self.image_src = image_src
    }
}

//MARK: - Controller Class
class ViewController: UIViewController {

    var photosGalleryViewObj:PhotosGalleryView!
    var arrImagesListModel = [GalleryDataImages]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arrImagesListModel.append(GalleryDataImages(image_src: #imageLiteral(resourceName: "imgPhotosAlbum1")))
        arrImagesListModel.append(GalleryDataImages(image_src: #imageLiteral(resourceName: "imgPhotosAlbum2")))
        arrImagesListModel.append(GalleryDataImages(image_src: #imageLiteral(resourceName: "imgPhotosAlbum3")))
        arrImagesListModel.append(GalleryDataImages(image_src: #imageLiteral(resourceName: "imgPhotosAlbum4")))
        arrImagesListModel.append(GalleryDataImages(image_src: #imageLiteral(resourceName: "imgPhotosAlbum5")))
        arrImagesListModel.append(GalleryDataImages(image_src: #imageLiteral(resourceName: "imgPhotosAlbum6")))
        arrImagesListModel.append(GalleryDataImages(image_src: #imageLiteral(resourceName: "imgPhotosAlbum7")))
        arrImagesListModel.append(GalleryDataImages(image_src: #imageLiteral(resourceName: "imgPhotosAlbum8")))
        arrImagesListModel.append(GalleryDataImages(image_src: #imageLiteral(resourceName: "imgPhotosAlbum9")))
        arrImagesListModel.append(GalleryDataImages(image_src: #imageLiteral(resourceName: "imgPhotosAlbum10")))
        arrImagesListModel.append(GalleryDataImages(image_src: #imageLiteral(resourceName: "imgPhotosAlbum11")))
        arrImagesListModel.append(GalleryDataImages(image_src: #imageLiteral(resourceName: "imgPhotosAlbum12")))
        
        //Photo Gallery View Create
        photosGalleryViewObj = PhotosGalleryView.init(frame: CGRect(x: 0,y: 50,width: self.view.frame.size.width,height: self.view.frame.size.height - 50)).show(view: self.view, arrImagesListModel: arrImagesListModel) as! PhotosGalleryView
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

