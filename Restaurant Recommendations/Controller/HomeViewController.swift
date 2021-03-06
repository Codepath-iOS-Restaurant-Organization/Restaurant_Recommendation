//
//  HomeViewController.swift
//  Restaurant Recommendations
//
//  Created by Richard Basdeo on 4/18/21.
//

import UIKit
import Firebase
class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, searchProtocol {
    func UpdatUI(_ searchBrain: Search) {
        
    }
    
    func didFailWithError(error: Error) {
        
    }
    
    func singleSearchDone() {
        DispatchQueue.main.async {
            self.favoriteCollectionView.reloadData()
        }
        globalIndex+=1
        if (globalIndex != globalCounter){
            search.getSingleRestaurant(restaurantID:currentUser.userReturned.favoriteRestaurants[globalIndex])
        }
        
    }
    
    @IBOutlet weak var searchButtonOutlet: UIButton!
    
    
    
    let firebase = FirebaseHelper()
    let alert = MyAlert()
    
    var currentUser = UserInformation()
    var friendsCounter = 0
    var tempURL = String()
    var globalCounter = 0
    var globalIndex = 0
    var search = Search()
    var chosenRestaurant: Restaurant?
 
    @IBAction func onAddFriend(_ sender: Any) {
        addFriendAlert()
    }
    
    @IBOutlet weak var friendsLabel: UILabel!
    
    @IBAction func onFriendsCount(_ sender: Any) {
        self.performSegue(withIdentifier: "friendsView", sender: self)
    }
    
    @IBAction func onLogout(_ sender: Any) {
        logoutAlert()
    }
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBAction func onProfileImage(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    @IBOutlet weak var favoriteCollectionView: UICollectionView!
    
    
    @IBAction func onFavRestaurant(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: favoriteCollectionView)
        let indexPath = favoriteCollectionView?.indexPathForItem(at: point) ?? [0,0]
        let cell = favoriteCollectionView.cellForItem(at: indexPath) as! FavoritesCollectionViewCell
        print(cell.favoriteId)
        var pos = 0
        for restaurant in search.favoriteRestaurants{
            if(restaurant.restaurantID == cell.favoriteId){
                break
            }
            pos+=1
        }
        chosenRestaurant = search.favoriteRestaurants[pos]
        performSegue(withIdentifier: "favoriteToDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "favoriteToDetail"{
            let destinationVC = segue.destination as! RestaurantDetailViewController
            destinationVC.chosenRestaurant = chosenRestaurant
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        firebase.delegate = self
        currentUser.userDelegate = self
        favoriteCollectionView.delegate = self
        favoriteCollectionView.dataSource = self
        
        search.delegate = self
        
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.isHidden = true
        friendsLabel.isHidden = true

        self.favoriteCollectionView.reloadData()
        
        Styling.customButton(for: searchButtonOutlet)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
  
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let email = Auth.auth().currentUser?.email{
            currentUser.getTotalUserInfo(email: email)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] as!UIImage
        let size = CGSize(width: 160, height: 160)
        let scaledImage = image.scaleImage(toSize: size)
        profileImageView.image = scaledImage
        
        guard let unwrapped = scaledImage else {return}
        if let email = Auth.auth().currentUser?.email{
            firebase.uploadProfilePicture(email: email, image: unwrapped)
        }
        
        
        dismiss(animated: true, completion: nil)
    }
    
    

    
    //Code for addFriend button:
    func addFriendAlert(){
        let alert = UIAlertController(title: "Add Friend", message: "Please enter user's email", preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: {action in
            let email: String = alert.textFields![0].text!
            self.firebase.addFriend(friendName: email)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {action in print("canceled")}))
        present(alert, animated: true)

    }
    
    //Code for logout button:
    func logoutAndLeave(){
        firebase.signOutUser()
        UserDefaults.standard.set(false, forKey: "loginSuccess")
        self.dismiss(animated: true, completion: nil)
    }
    
    func logoutAlert(){
        let alert = UIAlertController(title: "Log Out?", message: "You can always access your content by logging back in", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {action in print("canceled")}))
        alert.addAction(UIAlertAction(title: "Log Out", style: .default, handler: { [self]action in logoutAndLeave()}))
        present(alert, animated: true)
    }
    
    func setImageViewsImageFromURL (theImageURL: String){
        if let url = URL(string: theImageURL){
            
            let session = URLSession(configuration: .default)
            
            let task = session.dataTask(with: url) { (data, response, error) in
                
                if let e = error {
                    print("Could not convert url to a image: \(e.localizedDescription)")
                }
                else {
                    
                    if let imageData = data {
                        let tempImage = UIImage(data: imageData)
                        
                        if let unwrappedImage = tempImage {
                            DispatchQueue.main.async {
                                self.profileImageView.image = unwrappedImage
                                UIView.animate(withDuration: 2) {
                                    self.profileImageView.isHidden = false
                                }
                                
                             
                            }
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    
}

extension HomeViewController: firebaseProtocols{
    func signUpSuccessful() {
        print("signed up")
    }
    
    func signInSuccessful() {
        print("signed in")
    }
    
    func signedOutSuccessful() {
        print("signed out")
    }
    
    func error(error: Error) {
        print("unsuccess \(error.localizedDescription)")
        
    }
    
    func friendAdded() {
        
        alert.presentAlert(title: "Success !",
                           message: "Friend has been added.",
                           viewController: self) {
            
        }
        
        
    }
    
    func restaurantAdded() {

    }
    
    func profilePictureUploaded() {

    }
}


//code snippet came from: stackoverflow.com/questions/31966885/resize-uiimage-to-200x200pt-px
extension UIImage {
    func scaleImage(toSize newSize: CGSize) -> UIImage? {
        var newImage: UIImage?
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        if let context = UIGraphicsGetCurrentContext(), let cgImage = self.cgImage {
            context.interpolationQuality = .high
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
            context.concatenate(flipVertical)
            context.draw(cgImage, in: newRect)
            if let img = context.makeImage() {
                newImage = UIImage(cgImage: img)
            }
            UIGraphicsEndImageContext()
        }
        return newImage
    }
}
extension HomeViewController: userProtocol {

    func gotFriends() {
        UIView.animate(withDuration: 1) {
            self.friendsLabel.isHidden = false
        }
        friendsCounter = currentUser.userReturned.friends.count
        friendsLabel.text = String(friendsCounter) + " Friends"
    }
    
    func gotRestaurants() {
        if currentUser.userReturned.favoriteRestaurants.isEmpty == false
        {
            globalCounter = currentUser.userReturned.favoriteRestaurants.count //total number of restaurants

            if (globalCounter != search.favoriteRestaurants.count){
                search.favoriteRestaurants.removeAll()
                globalIndex = 0
                search.getSingleRestaurant(restaurantID: currentUser.userReturned.favoriteRestaurants[globalIndex])
            }
        }
    }
    
    func gotError(error: Error) {
        
    }
    
    //add the image url to array that holds all profile images urls
    func gotUserProfileImage() {
        tempURL = currentUser.userReturned.profilePicture
        setImageViewsImageFromURL(theImageURL: tempURL)
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return search.favoriteRestaurants.count //number of cells
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoritesCollectionViewCell", for: indexPath) as! FavoritesCollectionViewCell
        cell.favoriteLabel.text = search.favoriteRestaurants[indexPath.row].restaurantName
        cell.setCellImage(theImageURL: search.favoriteRestaurants[indexPath.row].restaurantImage_url)
        cell.favoriteId = search.favoriteRestaurants[indexPath.row].restaurantID
        return cell
    }
    func collectionView( _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: (favoriteCollectionView.frame.size.width/3) - 3,
                          height: (favoriteCollectionView.frame.size.width/3) - 3)
        }

    func collectionView( _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
            return 1
        }

    func collectionView( _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
            return 1
        }

    func collectionView( _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
            return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        }
    
}
