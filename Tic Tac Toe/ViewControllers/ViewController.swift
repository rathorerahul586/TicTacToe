//
//  ViewController.swift
//  Tic Tac Toe
//
//  Created by Rahul Kumar on 28/09/23.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import FirebaseAnalytics
import FirebaseFirestore
import Razorpay

class ViewController: UIViewController {
    
    @IBOutlet weak var appBgImageView: UIImageView!
    @IBOutlet weak var gameName: UILabel!
    @IBOutlet weak var buttonSinglePlayer: UIButton!
    @IBOutlet weak var buttonTwoPlayer: UIButton!
    @IBOutlet weak var buttonOnline: UIButton!
    @IBOutlet weak var googleButton: UIImageView!
    @IBOutlet weak var activityIndigator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBackground()
        setViews()
    }
    
    private func setBackground(){
        appBgImageView.contentMode = .scaleToFill
        appBgImageView.image = Asset.Assets.appBg.image
    }
    
    private func setViews(){
        gameName.textColor = .white
        gameName.font = .boldSystemFont(ofSize: 40)
        gameName.text = L10n.ticTacToe
        gameName.textAlignment = .center
        
        buttonSinglePlayer.setTitle(L10n.singlePlayer, for: .normal)
        buttonTwoPlayer.setTitle(L10n.twoPlayer, for: .normal)
        buttonOnline.setTitle(L10n.online, for: .normal)
        
        googleButton.layer.cornerRadius = googleButton.frame.height / 2
        googleButton.isUserInteractionEnabled = true
        
        activityIndigator.layer.cornerRadius = activityIndigator.frame.height / 2
        activityIndigator.stopAnimating()
        checkAuthStateChange()
    }
    
    private func getButtonGesture() -> UIGestureRecognizer {
        if isUserLoggedIn() {
            return UITapGestureRecognizer(
                target: self, action: #selector(showScoreBoard)
            )
        } else {
            return UITapGestureRecognizer(
                target: self, action: #selector(signInWithGoogle)
            )
        }
    }
    
    @objc
    func signInWithGoogle(_ sender: UIButton) {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            guard let result = signInResult else {
                return
            }
            guard let idToken = result.user.idToken else {return}
            let accessToken = result.user.accessToken
            
            let credentials = GoogleAuthProvider.credential(
                withIDToken: idToken.tokenString,
                accessToken: accessToken.tokenString
            )

            self.createUser(cred: credentials)
            self.saveUserData(user: result.user)
            self.setProfileImage()
            self.getPremiumStatus()
            Analytics.setUserID(result.user.profile?.email)
        }
    }
    
    @objc
    private func showScoreBoard() {
        activityIndigator.startAnimating()
        self.getUserScore()
    }
    
    @IBAction
    private func startGame(_ sender: UIButton){
        let gameVc = StoryboardScene.Main.gameViewController.instantiate()
        if let buttonId = sender.accessibilityIdentifier {
            switch (buttonId) {
            case String(describing: GamingModeEnum.doublePlayer):
                gameVc.setGamingMode(mode: .doublePlayer)
                navigationController?.pushViewController(gameVc, animated: true)
                
            case String(describing: GamingModeEnum.onlineGame):
                
                if isUserLoggedIn() {
                    if isPremiumUser() {
                        gameVc.setGamingMode(mode: .onlineGame)
                        navigationController?.pushViewController(gameVc, animated: true)
                    } else {
                        showBuyPremiumDialog()
                    }
                    
                } else {
                    self.googleButton.gestureRecognizers?.first?.state = .ended
                }
                
            default:
                gameVc.setGamingMode(mode: .singlePlayer)
                navigationController?.pushViewController(gameVc, animated: true)
            }
        }
    }
    
    private func showBuyPremiumDialog() {
        let alertController = UIAlertController(
            title: L10n.buyPremium,
            message: L10n.buyPremiumMessage,
            preferredStyle: .actionSheet
        )
        
        let buyAction = UIAlertAction(title: L10n.buyNow, style: .default) { _ in
            self.startPayment()
            
        }
        
        let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil)
        
        alertController.addAction(buyAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func showPaymentFailDialog(failureMessage: String) {
        let alertController = UIAlertController(
            title: L10n.paymentFail,
            message: failureMessage,
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: L10n.ok, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func createUser(cred: AuthCredential){
        Auth.auth().signIn(with: cred, completion: { (user, error) in
            if let err = error {
                print ("failed to create with google account", err)
                return
            }
        })
    }
    
    private func checkAuthStateChange() {
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                print("User is signed in with UID: \(user.uid)")
                self.setProfileImage()
                self.getPremiumStatus()
            } else {
                print("No user is signed in")
                UserDefaultsHelper.removeAllUserData()
                self.setProfileImage()
            }
        }
    }
    
    func saveUserData(user: GIDGoogleUser){
        UserDefaultsHelper.setData(value: user.userID, key: .userId)
        UserDefaultsHelper.setData(value: user.accessToken.tokenString, key: .token)
        UserDefaultsHelper.setData(value: user.profile?.name, key: .userName)
        UserDefaultsHelper.setData(value: user.profile?.imageURL(withDimension: 80)?.absoluteString, key: .userProfile)
    }
    
    private func setProfileImage(){
        if let url = URL(string: UserDefaultsHelper.getData(type: String.self, forKey: .userProfile) ?? "") {
            let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
                if let error = error {
                    print("Error downloading image: \(error.localizedDescription)")
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.googleButton.image = image
                        self.googleButton.addGestureRecognizer(self.getButtonGesture())
                    }
                }
            }
            task.resume()
        } else {
            self.googleButton.image = Asset.Assets.google.image
            self.googleButton.addGestureRecognizer(self.getButtonGesture())
        }
    }
    
    private func isUserLoggedIn() -> Bool {
        return UserDefaultsHelper.getData(type: String.self, forKey: .userId) != nil
    }
    
    private func getUserScore() {
        let db = Firestore.firestore()
        if let userId = UserDefaultsHelper.getData(type: String.self, forKey: .userId){
            let usersCollection = db.collection(users).document(userId)
            
            usersCollection.getDocument { docSnap, error in
                let wins  = docSnap?.data()?[keyTotalWin] as? Int
                let loose  = docSnap?.data()?[keyTotalLoose] as? Int
                let draw  = docSnap?.data()?[keyTotalDraw] as? Int
                self.activityIndigator.stopAnimating()
                self.showScoreBoardDialog(wins: wins, loose: loose, draw: draw)
            }
        }
    }
    
    private func isPremiumUser() -> Bool {
        return UserDefaultsHelper.getData(type: Bool.self, forKey: .isPremium) ?? false
    }
    
    private func getPremiumStatus() {
        
        if let userId = UserDefaultsHelper.getData(type: String.self, forKey: .userId) {
            let db = Firestore.firestore()
            let usersCollection = db.collection(users).document(userId)
            usersCollection.getDocument { docSnap, error in
                if let isPremium = docSnap?.data()?[keyIsPremium] as? Bool {
                    UserDefaultsHelper.setData(value: isPremium, key: .isPremium)
                }
            }
        }
    }
    
    private func showScoreBoardDialog(wins: Int?, loose: Int?, draw: Int?) {
        let alertController = UIAlertController(
            title: L10n.yourScore, message: nil, preferredStyle: .alert
        )
        
        let dialogView = getScoreView(wins: wins, loose: loose, draw: draw)
        dialogView.translatesAutoresizingMaskIntoConstraints = false
        alertController.view.addSubview(dialogView)
        
        dialogView.topAnchor.constraint(equalTo: alertController.view.topAnchor, constant: 50).isActive = true
        dialogView.leadingAnchor.constraint(equalTo: alertController.view.leadingAnchor, constant: 20).isActive = true
        dialogView.trailingAnchor.constraint(equalTo: alertController.view.trailingAnchor, constant: -20).isActive = true
        dialogView.bottomAnchor.constraint(equalTo: alertController.view.bottomAnchor, constant: -60).isActive = true
        
        let logoutAction = UIAlertAction(title: L10n.logout, style: .destructive) { _ in
            do {
                try Auth.auth().signOut()
                UserDefaultsHelper.removeAllUserData()
                Analytics.logEvent(AnalyticsEventConstants.logOutEvent, parameters: nil)
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError)
            }
        }
        
        let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil)
        
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)

    }
    
    private func getScoreView(wins: Int?, loose: Int?, draw: Int?) -> UIView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.addArrangedSubview(
            getCombinedStackView(
                textLabel: L10n.win,
                valueLabel: String(wins ?? 0),
                color: .systemGreen
            )
        )
        stackView.addArrangedSubview(
            getCombinedStackView(
                textLabel: L10n.loose,
                valueLabel: String(loose ?? 0),
                color: .systemRed
            )
        )
        stackView.addArrangedSubview(
            getCombinedStackView(
                textLabel: L10n.draw,
                valueLabel: String(draw ?? 0),
                color: .white
            )
        )
        return stackView
    }
    
    private func getCombinedStackView(textLabel: String, valueLabel: String, color: UIColor) -> UIView {
        let combinedStackView = UIStackView()
        combinedStackView.axis = .vertical
        combinedStackView.distribution = .fillEqually
        combinedStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let textUILabel = UILabel()
        let valueUILabel = UILabel()
        
        textUILabel.textAlignment = .center
        textUILabel.font = .systemFont(ofSize: 14)
        textUILabel.text = textLabel
        textUILabel.textColor = color
        valueUILabel.textAlignment = .center
        valueUILabel.font = .boldSystemFont(ofSize: 20)
        valueUILabel.text = valueLabel
        valueUILabel.textColor = color
        
        combinedStackView.addArrangedSubview(textUILabel)
        combinedStackView.addArrangedSubview(valueUILabel)
        return combinedStackView
    }
    
    private func savePremiumStatus(isPremium: Bool) {
        let db = Firestore.firestore()
        let userId = UserDefaultsHelper.getData(type: String.self, forKey: .userId) ?? ""
        let usersCollection = db.collection(users).document(userId)
        usersCollection.setData([keyIsPremium : isPremium], merge: true)
    }
    
    private func startPayment() {
        let razorpay = RazorpayCheckout.initWithKey(RazorPayConstants.apiKey, andDelegate: self)
        let options: [String: Any] = [
            RazorPayConstants.amount: RazorPayConstants.premiumAmount,
            RazorPayConstants.currency: RazorPayConstants.indianCurrency,
            RazorPayConstants.description: L10n.buyPremium,
        ]
        razorpay.open(options)
    }
}

extension ViewController: RazorpayPaymentCompletionProtocol {
    func onPaymentSuccess(_ payment_id: String) {
        print("payment success - \(payment_id)")
        savePremiumStatus(isPremium: true)
        Analytics.logEvent(
            AnalyticsEventConstants.paymentStatus,
            parameters: [AnalyticsEventConstants.paymentStatus: AnalyticsEventConstants.paymentSuccess]
        )
    }
    
    func onPaymentError(_ code: Int32, description str: String) {
        print("payment fail error - \(code), des - \(str)")
        showPaymentFailDialog(failureMessage: str)
        Analytics.logEvent(
            AnalyticsEventConstants.paymentStatus,
            parameters: [AnalyticsEventConstants.paymentStatus: AnalyticsEventConstants.paymentFailed]
        )
    }
}

