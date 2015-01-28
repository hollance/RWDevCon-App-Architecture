
import Foundation

private let jsonDateFormatter: NSDateFormatter = {
  let formatter = NSDateFormatter()
  formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ssZZZ"
  return formatter
}()

extension Item {
  convenience init(JSON dict: JSONDictionary) {
    let itemID = dict["itemID"] as Int
    let itemName = dict["itemName"] as NSString
    let state = dict["state"] as NSString
    let startingBid = dict["startingBid"] as Double
    let itemDescription = dict["description"] as NSString
    let imageURL = dict["imageURL"] as NSString
    let bids = []

    self.init(itemID: itemID, itemName: itemName, state: state, startingBid: startingBid, itemDescription: itemDescription, imageURL: imageURL, bids: [])

    for bidJSON in dict["bids"] as [JSONDictionary] {
      addBid(Bid(JSON: bidJSON))
    }
  }
}

extension Bid {
  convenience init(JSON dict: JSONDictionary) {
    let bidID = dict["bidID"] as Int
    let bidderID = dict["bidderID"] as Int
    let bidderName = dict["bidderName"] as NSString
    let amount = dict["amount"] as Double

    // Convert the timestamp to an NSDate object.
    let timestamp = jsonDateFormatter.dateFromString(dict["timestamp"] as NSString)!

    self.init(bidID: bidID, bidderID: bidderID, bidderName: bidderName, timestamp: timestamp, amount: amount)
  }
}
