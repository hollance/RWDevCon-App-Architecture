
import Foundation

private let jsonDateFormatter: NSDateFormatter = {
  let formatter = NSDateFormatter()
  formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ssZZZ"
  return formatter
}()

class Bid: NSObject, NSCoding, Equatable {
  weak var item: Item!

  let bidID: Int
  let bidderID: Int
  let bidderName: String
  let amount: Double
  let timestamp: NSDate

  init(JSON dict: JSONDictionary) {
    bidID = dict["bidID"] as Int
    bidderID = dict["bidderID"] as Int
    bidderName = dict["bidderName"] as NSString
    amount = dict["amount"] as Double

    // Convert the timestamp to an NSDate object.
    timestamp = jsonDateFormatter.dateFromString(dict["timestamp"] as NSString)!

    super.init()
  }

  // MARK: Persistence

  required init(coder aDecoder: NSCoder) {
    bidID = aDecoder.decodeIntegerForKey("bidID")
    bidderID = aDecoder.decodeIntegerForKey("bidderID")
    bidderName = aDecoder.decodeObjectForKey("bidderName") as NSString
    amount = aDecoder.decodeDoubleForKey("amount")
    timestamp = aDecoder.decodeObjectForKey("timestamp") as NSDate
    super.init()
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeInteger(bidID, forKey: "bidID")
    aCoder.encodeInteger(bidderID, forKey: "bidderID")
    aCoder.encodeObject(bidderName, forKey: "bidderName")
    aCoder.encodeDouble(amount, forKey: "amount")
    aCoder.encodeObject(timestamp, forKey: "timestamp")
  }
}

func ==(lhs: Bid, rhs: Bid) -> Bool {
  return lhs.bidID == rhs.bidID
}
