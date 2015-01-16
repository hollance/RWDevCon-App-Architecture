
import Foundation

private let jsonDateFormatter: NSDateFormatter = {
  let formatter = NSDateFormatter()
  formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ssZZZ"
  return formatter
}()

class Bid: NSObject, NSCoding {
  // These are optional because the server doesn't always send these fields.
  var itemID: Int?
  var itemName: String?

  let bidID: Int
  let bidderID: Int
  let bidderName: String
  let amount: Double
  let timestamp: NSDate

  init(JSON dict: JSONDictionary) {
    itemID = dict["itemID"] as Int?
    itemName = dict["itemName"] as NSString?

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
    itemID = aDecoder.decodeIntegerForKey("itemID") as Int?
    itemName = aDecoder.decodeObjectForKey("itemName") as NSString?

    bidID = aDecoder.decodeIntegerForKey("bidID")
    bidderID = aDecoder.decodeIntegerForKey("bidderID")
    bidderName = aDecoder.decodeObjectForKey("bidderName") as NSString
    amount = aDecoder.decodeDoubleForKey("amount")
    timestamp = aDecoder.decodeObjectForKey("timestamp") as NSDate
    super.init()
  }

  func encodeWithCoder(aCoder: NSCoder) {
    if let itemID = itemID {
      aCoder.encodeInteger(itemID, forKey: "itemID")
    }
    if let itemName = itemName {
      aCoder.encodeObject(itemName, forKey: "itemName")
    }

    aCoder.encodeInteger(bidID, forKey: "bidID")
    aCoder.encodeInteger(bidderID, forKey: "bidderID")
    aCoder.encodeObject(bidderName, forKey: "bidderName")
    aCoder.encodeDouble(amount, forKey: "amount")
    aCoder.encodeObject(timestamp, forKey: "timestamp")
  }
}
