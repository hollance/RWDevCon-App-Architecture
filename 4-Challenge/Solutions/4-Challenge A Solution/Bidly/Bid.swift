
import Foundation

class Bid: NSObject, Equatable {
  weak var item: Item!

  let bidID: Int
  let bidderID: Int
  let bidderName: String
  let amount: Double
  let timestamp: NSDate

  init(bidID: Int, bidderID: Int, bidderName: String, timestamp: NSDate, amount: Double) {
    self.bidID = bidID
    self.bidderID = bidderID
    self.bidderName = bidderName
    self.timestamp = timestamp
    self.amount = amount
    super.init()
  }
}

func ==(lhs: Bid, rhs: Bid) -> Bool {
  return lhs.bidID == rhs.bidID
}
