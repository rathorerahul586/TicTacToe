// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Buy Now
  internal static let buyNow = L10n.tr("Localizable", "buyNow", fallback: "Buy Now")
  /// Buy Premium
  internal static let buyPremium = L10n.tr("Localizable", "buyPremium", fallback: "Buy Premium")
  /// Become a Premium User to Play Game Online
  internal static let buyPremiumMessage = L10n.tr("Localizable", "buyPremiumMessage", fallback: "Become a Premium User to Play Game Online")
  /// Buy Tic Tac Toc Premium
  internal static let buyTicTacToePremium = L10n.tr("Localizable", "buyTicTacToePremium", fallback: "Buy Tic Tac Toc Premium")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "cancel", fallback: "Cancel")
  /// Confirm Exit
  internal static let confirmExit = L10n.tr("Localizable", "confirmExit", fallback: "Confirm Exit")
  /// Draw
  internal static let draw = L10n.tr("Localizable", "draw", fallback: "Draw")
  /// Finding online player for you
  internal static let findingOnlinePlayer = L10n.tr("Localizable", "findingOnlinePlayer", fallback: "Finding online player for you")
  /// Game Draw
  internal static let gameDraw = L10n.tr("Localizable", "gameDraw", fallback: "Game Draw")
  /// Logout
  internal static let logout = L10n.tr("Localizable", "logout", fallback: "Logout")
  /// Loose
  internal static let loose = L10n.tr("Localizable", "loose", fallback: "Loose")
  /// Ok
  internal static let ok = L10n.tr("Localizable", "ok", fallback: "Ok")
  /// Online
  internal static let online = L10n.tr("Localizable", "online", fallback: "Online")
  /// Opponent
  internal static let opponent = L10n.tr("Localizable", "opponent", fallback: "Opponent")
  /// Opponent Turn
  internal static let opponentTurn = L10n.tr("Localizable", "opponentTurn", fallback: "Opponent Turn")
  /// Opponent Win
  internal static let opponentWin = L10n.tr("Localizable", "opponentWin", fallback: "Opponent Win")
  /// Your Partner Left
  internal static let partnerLeft = L10n.tr("Localizable", "partnerLeft", fallback: "Your Partner Left")
  /// Your partner left the game. Would you like to play game again with another player?
  internal static let partnerLeftMessage = L10n.tr("Localizable", "partnerLeftMessage", fallback: "Your partner left the game. Would you like to play game again with another player?")
  /// Payment Failed
  internal static let paymentFail = L10n.tr("Localizable", "paymentFail", fallback: "Payment Failed")
  /// Play Again
  internal static let playAgain = L10n.tr("Localizable", "playAgain", fallback: "Play Again")
  /// Please Wait
  internal static let pleaseWait = L10n.tr("Localizable", "pleaseWait", fallback: "Please Wait")
  /// Quit
  internal static let quit = L10n.tr("Localizable", "quit", fallback: "Quit")
  /// Are you sure you want to quit the game?
  internal static let quitMessage = L10n.tr("Localizable", "quitMessage", fallback: "Are you sure you want to quit the game?")
  /// Score Board
  internal static let scoreBoard = L10n.tr("Localizable", "scoreBoard", fallback: "Score Board")
  /// Single Player
  internal static let singlePlayer = L10n.tr("Localizable", "singlePlayer", fallback: "Single Player")
  /// Localizable.strings
  ///   Tic Tac Toe
  /// 
  ///   Created by Rahul Kumar on 28/09/23.
  internal static let ticTacToe = L10n.tr("Localizable", "ticTacToe", fallback: "Tic Tac Toe")
  /// Two Player
  internal static let twoPlayer = L10n.tr("Localizable", "twoPlayer", fallback: "Two Player")
  /// Win
  internal static let win = L10n.tr("Localizable", "win", fallback: "Win")
  /// You
  internal static let you = L10n.tr("Localizable", "you", fallback: "You")
  /// Your Score
  internal static let yourScore = L10n.tr("Localizable", "yourScore", fallback: "Your Score")
  /// Your Turn
  internal static let yourTurn = L10n.tr("Localizable", "yourTurn", fallback: "Your Turn")
  /// You Win
  internal static let youWin = L10n.tr("Localizable", "youWin", fallback: "You Win")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
