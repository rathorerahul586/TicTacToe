//
//  GameViewController.swift
//  Tic Tac Toe
//
//  Created by Rahul Kumar on 28/09/23.
//

import UIKit
import Combine
import FirebaseAnalytics

class GameViewController: UIViewController {

    private var firstPlayerMoves: [[Int]] = []
    private var secondPlayerMoves: [[Int]] = []
    var gamingMode: GamingModeEnum = .singlePlayer
    
    private var firstPlayerWins = 0
    private var secondPlayerWins = 0
    private var drawMatches = 0
    
    private let winningCombinations = [
        [[0, 0], [1, 1], [2, 2]],
        [[0, 0], [0, 1], [0, 2]],
        [[0, 0], [1, 0], [2, 0]],
        [[0, 2], [1, 2], [2, 2]],
        [[1, 0], [1, 1], [1, 2]],
        [[2, 0], [2, 1], [2, 2]],
        [[0, 1], [1, 1], [2, 1]],
        [[0, 2], [1, 1], [2, 0]]
    ]
    
    private var cancellables = Set<AnyCancellable>()
    
    private var viewModel = GameViewModel()
    
    @IBOutlet weak var superStackView: UIStackView!
    @IBOutlet weak var firstRowStackView: UIStackView!
    @IBOutlet weak var secondRowStackView: UIStackView!
    @IBOutlet weak var thirdRowStackView: UIStackView!
    
    @IBOutlet weak var scoreStackView: UIStackView!
    @IBOutlet weak var yourScoreLabel: UILabel!
    @IBOutlet weak var opponentScoreLabel: UILabel!
    @IBOutlet weak var drawLabel: UILabel!
    
    @IBOutlet weak var yourScore: UILabel!
    @IBOutlet weak var opponentScore: UILabel!
    @IBOutlet weak var drawScore: UILabel!
    
    @IBOutlet weak var playAgainButton: UIButton!
    
    @IBOutlet weak var turnLabel: UILabel!
    
    private var opponentsTurn = false
    
    private var gameEnded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.scoreBoard
        navigationController?.navigationBar.prefersLargeTitles = true
        setBackButton()
        createGameBoard()
        setTapGesture()
        createScoreboard()
        
        if gamingMode == .onlineGame {
            viewModel.getAvailableRooms()
            observeOpponentMove()
            observeYourTurn()
            observePlayerMatchedPublisher()
            observePartnerStatus()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        viewModel.goOffline()
        viewModel.saveUserData(wins: secondPlayerWins, loose: firstPlayerWins, draw: drawMatches)
    }
    
    func showConfirmationDialog() {
        let alertController = UIAlertController(
            title: L10n.confirmExit,
            message: L10n.quitMessage,
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
            // User canceled going back, do nothing
        }

        let confirmAction = UIAlertAction(title: L10n.quit, style: .destructive) { _ in
            self.viewModel.goOffline()
            self.navigationController?.popViewController(animated: true)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)

        present(alertController, animated: true, completion: nil)
    }
    
    private func setBackButton() {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain, target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc func backButtonTapped() {
        showConfirmationDialog()
    }
    
    private func createGameBoard(){
        for i in 0...2 {
            firstRowStackView.addArrangedSubview(getView(identifire: "[0, \(i)]"))
        }
        for i in 0...2 {
            secondRowStackView.addArrangedSubview(getView(identifire: "[1, \(i)]"))
        }
        for i in 0...2 {
            thirdRowStackView.addArrangedSubview(getView(identifire: "[2, \(i)]"))
        }
        playAgainButton.isHidden = true
        changeTurn(isOpponentTurn: false)
    }
    
    private func setTapGesture(){
        let firstRowGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        let secondRowGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        let thirdRowGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        
        firstRowStackView.addGestureRecognizer(firstRowGesture)
        secondRowStackView.addGestureRecognizer(secondRowGesture)
        thirdRowStackView.addGestureRecognizer(thirdRowGesture)
    }
    
    private func createScoreboard() {
        
        scoreStackView.layer.cornerRadius = 16
        scoreStackView.layer.borderColor = UIColor.gray.cgColor
        scoreStackView.layer.borderWidth = 2
        
        [yourScoreLabel, opponentScoreLabel, drawLabel].forEach { label in
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 18)
        }
        
        [yourScore, opponentScore, drawScore].forEach { label in
            label.textAlignment = .center
            label.font = .boldSystemFont(ofSize: 24)
        }
        
        yourScoreLabel.text = L10n.you
        opponentScoreLabel.text = L10n.opponent
        drawLabel.text = L10n.draw
        
        yourScore.text = String(0)
        opponentScore.text = String(0)
        drawScore.text = String(0)
        
        playAgainButton.setTitle(L10n.playAgain, for: .normal)
    }
    
    func setGamingMode(mode: GamingModeEnum) {
        gamingMode = mode
        Analytics.logEvent(
            AnalyticsEventConstants.newGame,
            parameters: [AnalyticsEventConstants.gameMode: String(describing: mode)]
        )
    }
    
    private func getView(identifire id: String) -> UIView {
        let box = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        box.backgroundColor = .black
        box.accessibilityIdentifier = id
        return box
    }
    
    @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            var firstIndex = 0
            var secondIndex = 0
            if let stackView = gestureRecognizer.view as? UIStackView,
               let superView = stackView.superview as? UIStackView {
                
                let tapLocation1 = gestureRecognizer.location(in: stackView)
                let tapLocation2 = gestureRecognizer.location(in: superView)
                
                // Iterate through subviews in the stack view to find the tapped view
                for (index, subview) in stackView.arrangedSubviews.enumerated() {
                    
                    if subview.frame.contains(tapLocation1) {
                        firstIndex = index
                        break
                    }
                }
                
                for (index, subview) in superView.arrangedSubviews.enumerated() {
                    if subview.frame.contains(tapLocation2) {
                        secondIndex = index
                        break
                    }
                }
                
            }
            
            if !isInvalidMove(move: [[firstIndex, secondIndex]]) {
                addMoveData(x: firstIndex, y: secondIndex)
                if gamingMode == .onlineGame {
                    viewModel.playYourMove(
                        moveId: "\(firstPlayerMoves.count)",
                        move: "\(firstIndex), \(secondIndex)"
                    )
                }
            }
        }
        
    }
    
    private func addMoveData(x: Int, y: Int){
        drawImage(xIndex: x, yIndex: y)
        
        if opponentsTurn {
            secondPlayerMoves.append([x, y])
        } else {
            firstPlayerMoves.append([x, y])
        }
        
        if secondPlayerMoves.count >= 3 || firstPlayerMoves.count >= 3 {
            checkForWinningCombinations()
        }
        if gameEnded {
            if opponentsTurn {
                turnLabel.text = L10n.opponentWin
            } else {
                turnLabel.text = L10n.youWin
            }
        } else {
            if firstPlayerMoves.count + secondPlayerMoves.count == 9 {
                setScore(draw: true)
            } else {
                changeTurn(isOpponentTurn: !opponentsTurn)
            }
            
        }
        
    }
    
    private func isInvalidMove(move: [[Int]]) -> Bool {
        return firstPlayerMoves.contains(move) || secondPlayerMoves.contains(move)
    }
    
    private func drawImage(xIndex: Int, yIndex: Int, win: Bool = false){
        if let subview = (superStackView.subviews[yIndex] as? UIStackView)?.subviews[xIndex] as? UIView {
            if win {
                UIView.animate(withDuration: 0.2) {
                    subview.backgroundColor = .systemGreen
                }
            }
            else {
                addImageToSubView(box: subview)
            }
        }
    }
    
    private func addImageToSubView(box view: UIView){
        let image = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        view.addSubview(image)
        image.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        image.alpha = 0
        if opponentsTurn {
            image.image = Asset.Assets.cross.image
        } else {
            image.image = Asset.Assets.circle.image
        }
        UIView.animate(withDuration: 0.2) {
            image.alpha = 1.0
        }
    }
    
    private func checkForWinningCombinations(){
        if opponentsTurn {
            checkPlayerForWin(list: secondPlayerMoves)
        } else {
            checkPlayerForWin(list: firstPlayerMoves)
        }
    }
    
    private func checkPlayerForWin(list: [[Int]]){
        var sortedList = list
        sortedList.sort {
            if $0[0] != $1[0] {
                return $0[0] < $1[0]
            } else {
                return $0[1] < $1[1]
                
            }
        }
        for i in 0...winningCombinations.count - 1 {
            var matchedItems = 0
            sortedList.forEach { item in
                if winningCombinations[i].contains(item) {
                    matchedItems += 1
                }
            }
            if matchedItems >= 3 {
                winningCombinations[i].forEach { indexs in
                    DispatchQueue.main.asyncAfter(deadline: .now() + (0.2 * Double(indexs[1]))) {
                        self.drawImage(xIndex: indexs[0], yIndex: indexs[1], win: true)
                    }
                }
                gameEnded = true
                setScore()
                superStackView.isUserInteractionEnabled = false
                break
            }
            
        }
    }
    
    private func changeTurn(isOpponentTurn: Bool){
        opponentsTurn = isOpponentTurn
        if opponentsTurn {
            turnLabel.text = L10n.opponentTurn
            if gamingMode == .singlePlayer {
                moveByComputer()
            }
            
        } else {
            turnLabel.text = L10n.yourTurn
        }
        
    }
    
    private func moveByComputer() {
        let number = Int.random(in: 0...winningCombinations.count - 1)
        if let move = winningCombinations[number].randomElement() {
            if isInvalidMove(move: [move]) {
                moveByComputer()
            } else {
                addMoveData(x: move.first ?? 0, y: move.last ?? 0)
            }
        }
    }
    
    private func setScore(draw: Bool = false){
        var resultEvent = ""
        if draw {
            drawMatches = drawMatches + 1
            drawScore.text = String(drawMatches)
            opponentScore.textColor = .white
            yourScore.textColor = .white
            drawScore.textColor = .green
            turnLabel.text = L10n.gameDraw
            resultEvent = AnalyticsEventConstants.gameDraw
        } else {
            if opponentsTurn {
                firstPlayerWins = firstPlayerWins + 1
                opponentScore.text = String(firstPlayerWins)
                opponentScore.textColor = .green
                yourScore.textColor = .white
                resultEvent = AnalyticsEventConstants.userLoose
                
            } else {
                secondPlayerWins = secondPlayerWins + 1
                yourScore.text = String(secondPlayerWins)
                yourScore.textColor = .green
                opponentScore.textColor = .white
                resultEvent = AnalyticsEventConstants.userWin
            }
        }
        playAgainButton.isHidden = false
        
        Analytics.logEvent(
            AnalyticsEventConstants.gameResultEvent,
            parameters: [AnalyticsEventConstants.gameResultEvent: resultEvent]
        )
    }
    
    
    @IBAction
    private func resetGame() {
        firstRowStackView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        secondRowStackView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        thirdRowStackView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        
        superStackView.isUserInteractionEnabled = true
        firstPlayerMoves.removeAll()
        secondPlayerMoves.removeAll()
        gameEnded = false
        createGameBoard()
        if gamingMode == .onlineGame {
            viewModel.restartOnlineGame()
        }
        
        Analytics.logEvent(
            AnalyticsEventConstants.playAgainEvent,
            parameters: [
                AnalyticsEventConstants.gameCount: firstPlayerWins + secondPlayerWins + drawMatches
            ]
        )
    }
    
    private func observeOpponentMove(){
        viewModel.$opponentModePublisher
            .receive(on: RunLoop.main)
            .sink { move in
                if !move.isEmpty, let x = move.first, let y = move.last {
                    if !self.isInvalidMove(move: [[x, y]]) {
                        self.addMoveData(x: x, y: y)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func observeYourTurn() {
        viewModel.$yourTurnPublisher
            .receive(on: RunLoop.main)
            .sink { isYourTurn in
                self.changeTurn(isOpponentTurn: !isYourTurn)
                self.superStackView.isUserInteractionEnabled = isYourTurn
            }
            .store(in: &cancellables)
    }
    
    private func observePlayerMatchedPublisher() {
        let alertController = UIAlertController(
            title: L10n.pleaseWait,
            message: L10n.findingOnlinePlayer,
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(cancelAction)
        
        viewModel.$playerMatchedPublisher
            .receive(on: RunLoop.main)
            .sink { isPlayerMatched in
                if isPlayerMatched {
                    alertController.dismiss(animated: false)
                } else {
                    self.present(alertController, animated: false, completion: nil)
                }
            }
            .store(in: &cancellables)
    }
    
    private func observePartnerStatus() {
        let alertController = UIAlertController(
            title: L10n.partnerLeft,
            message: L10n.partnerLeftMessage,
            preferredStyle: .alert
        )
        let restartAction = UIAlertAction(title: L10n.playAgain, style: .default) { _ in
            self.resetGame()
            self.viewModel.getAvailableRooms()
        }
        let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(restartAction)
        
        viewModel.$isPartnerLeft
            .receive(on: RunLoop.main)
            .sink { isPartnerLeft in
                if isPartnerLeft {
                    if let presentedViewController = self.presentedViewController,
                       presentedViewController is UIAlertController{
                        return
                    }
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            .store(in: &cancellables)
    }
}
