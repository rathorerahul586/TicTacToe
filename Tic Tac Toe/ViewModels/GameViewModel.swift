//
//  GameViewModel.swift
//  Tic Tac Toe
//
//  Created by Rahul Kumar on 04/10/23.
//

import Foundation
import FirebaseFirestore
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import FirebaseAnalytics

class GameViewModel: ObservableObject {
    
    @Published var opponentModePublisher: [Int] = []
    @Published var yourTurnPublisher: Bool = true
    @Published var playerMatchedPublisher: Bool = false
    @Published var isPartnerLeft: Bool = false
    
    let databaseRef: DatabaseReference
    let roomRef: DatabaseReference
    let onlinePlayerRef: DatabaseReference
    
    private var waitingStartTime = 0
    
    init() {
        databaseRef = Database.database(
            url: databaseUrl
        ).reference()
        
        roomRef = databaseRef.child(childRoom)
        onlinePlayerRef = databaseRef.child(childOnlinePlayers)
    }
    
    let userId = UserDefaultsHelper.getData(type: String.self, forKey: .userId) ?? ""
    var matchedPlayerId = valuePlayerNotMatched
    var roomId = ""
    
    func getAvailableRooms() {
        waitingStartTime = Int(Date().timeIntervalSince1970)
        roomRef.getData(completion: { error, snapshort in
            if let rooms = snapshort?.value as? [String : String],
               let availableRoom = rooms.first(where: {$0.value == valuePlayerNotMatched}) {
                
                if availableRoom.key != self.userId {
                    self.playerMatched(matchedPlayerId: availableRoom.key)
                    self.observeOpponentMove()
                    return
                }
            } else {
                self.roomRef.child(self.userId).setValue(valuePlayerNotMatched)
                self.observeMatchedPlayer()
            }
        })
        observeYourTurn()
    }
    
    func observeMatchedPlayer() {
        let selfRoomRef = self.roomRef.child(self.userId)
        selfRoomRef.observe(.value){ (snapshot) in
            if let matched = snapshot.value as? String {
                self.matchedPlayerId = matched
                if matched != valuePlayerNotMatched {
                    self.playerMatchedPublisher = true
                }
                self.observePartnerStatus()
                self.observeOpponentMove()
                self.sendWaitingTimeGAEvent()
            }
        }
    }
    
    func observeOpponentMove() {
        let opponentMoveRef = self.onlinePlayerRef.child(self.matchedPlayerId).child(childMoves)
        opponentMoveRef.observe(.childAdded) { snapshot, error in
            if let moveString = snapshot.value as? String,
               let x = Int(String(moveString.first ?? "0")),
               let y = Int(String(moveString.last ?? "0")) {
                
                self.opponentModePublisher = [x, y]
                
            }
        }
    }
    
    func observeYourTurn() {
        let yourTurnRef = self.onlinePlayerRef.child(self.userId).child(childYourTurn)
        yourTurnRef.observe(.value) { snapshot, error in
            if let isYourTurn = snapshot.value as? Bool {
                self.yourTurnPublisher = isYourTurn
            }
        }
    }
    
    func observePartnerStatus() {
        let partnerStatusRef = self.onlinePlayerRef.child(userId)
        partnerStatusRef.child(childIsPlayerLeft).observe(.value) { snapshot, error in
            if let isPartnerLeft = snapshot.value as? Bool {
                if isPartnerLeft {
                    self.isPartnerLeft = isPartnerLeft
                    self.matchedPlayerId = valuePlayerNotMatched
                    partnerStatusRef.removeValue()
                }
            }
        }
    }
    
    func playerMatched(matchedPlayerId: String) {
        roomRef.child(matchedPlayerId).setValue(userId)
        self.matchedPlayerId = matchedPlayerId
        self.observePartnerStatus()
        if matchedPlayerId != valuePlayerNotMatched {
            self.playerMatchedPublisher = true
        }
        self.roomId = matchedPlayerId
        self.yourTurnPublisher = false
        sendWaitingTimeGAEvent()
    }
    
    func playYourMove(moveId: String, move: String) {
        onlinePlayerRef.child(userId).child(childYourTurn).setValue(false)
        onlinePlayerRef.child(userId).child(childMoves).child(moveId).setValue(move)
        onlinePlayerRef.child(matchedPlayerId).child(childYourTurn).setValue(true)
    }
    
    func goOffline() {
        onlinePlayerRef.child(userId).removeValue()
        if matchedPlayerId != valuePlayerNotMatched {
            onlinePlayerRef.child(matchedPlayerId).child(childIsPlayerLeft).setValue(true)
        }
        
        roomRef.child(userId).removeValue()
    }
    
    func restartOnlineGame() {
        getAvailableRooms()
        playerMatchedPublisher = false
        roomRef.child(userId).removeValue()
        roomRef.child(matchedPlayerId).removeValue()
        onlinePlayerRef.child(userId).removeValue()
        onlinePlayerRef.child(matchedPlayerId).removeValue()
        onlinePlayerRef.child(matchedPlayerId).child(childYourTurn).setValue(true)
    }
    
    func saveUserData(wins: Int, loose: Int, draw: Int) {
        
        let db = Firestore.firestore()
        let usersCollection = db.collection(users).document(userId)
        
        var winCount = wins
        var drawCount = draw
        var looseCount = loose
        
        usersCollection.getDocument { docSnap, error in
            print("docSnap - \(docSnap?.data())")
            if let wins  = docSnap?.data()?[keyTotalWin] as? Int {
                winCount =  winCount + wins
            }
            if let loose  = docSnap?.data()?[keyTotalLoose] as? Int {
                looseCount = looseCount + loose
            }
            if let draw  = docSnap?.data()?[keyTotalDraw] as? Int {
                drawCount = drawCount + draw
            }
            
            let dataToSave: [String: Any] = [
                keyTotalWin: winCount,
                keyTotalLoose: looseCount,
                keyTotalDraw: drawCount
            ]

            usersCollection.setData(dataToSave, merge: true)
        }
    }
    
    private func sendWaitingTimeGAEvent() {
        Analytics.logEvent(
            AnalyticsEventConstants.waitingTimeEvent,
            parameters: [
                AnalyticsEventConstants.waitingTimeForOnlinePlayer :
                    abs(Int(Date().timeIntervalSince1970) - waitingStartTime)
            ]
        )
    }
}
