import ActivityKit
import Foundation

@available(iOS 16.2, *)
struct SavageTimerAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var currentRound: Int
    var totalRounds: Int
    var phaseLabel: String
    var isRunning: Bool
    var endTimestamp: Date?  // nil when paused
    var remainingSeconds: Int
  }
}
