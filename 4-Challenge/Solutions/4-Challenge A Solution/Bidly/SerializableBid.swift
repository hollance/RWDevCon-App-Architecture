
import Foundation

class SerializableBid: NSObject, NSCoding {
  let bidID: Int
  let bidderID: Int
  let bidderName: String
  let timestamp: NSDate
  let amount: Double

  // Conversion from Bid into SerializableBid
  init(bid: Bid) {
    bidID = bid.bidID
    bidderID = bid.bidderID
    bidderName = bid.bidderName
    timestamp = bid.timestamp
    amount = bid.amount
  }

  // Conversion from SerializableBid back into Bid
  var bid: Bid {
    return Bid(bidID: bidID, bidderID: bidderID, bidderName: bidderName, timestamp: timestamp, amount: amount)
  }

  // Loading
  required init(coder aDecoder: NSCoder) {
    bidID = aDecoder.decodeIntegerForKey("bidID")
    bidderID = aDecoder.decodeIntegerForKey("bidderID")
    bidderName = aDecoder.decodeObjectForKey("bidderName") as NSString
    timestamp = aDecoder.decodeObjectForKey("timestamp") as NSDate
    amount = aDecoder.decodeDoubleForKey("amount")
    super.init()
  }

  // Saving
  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeInteger(bidID, forKey: "bidID")
    aCoder.encodeInteger(bidderID, forKey: "bidderID")
    aCoder.encodeObject(bidderName, forKey: "bidderName")
    aCoder.encodeObject(timestamp, forKey: "timestamp")
    aCoder.encodeDouble(amount, forKey: "amount")
  }
}
