
import Foundation

class Item: NSObject, NSCoding {
  let itemID: Int
  let itemName: String
  let state: String
  let startingBid: Double
  let itemDescription: String
  let imageURL: String

  var bids: [Bid]

  init(JSON dict: JSONDictionary) {
    itemID = dict["itemID"] as Int
    itemName = dict["itemName"] as NSString
    state = dict["state"] as NSString
    startingBid = dict["startingBid"] as Double
    itemDescription = dict["description"] as NSString
    imageURL = dict["imageURL"] as NSString
    bids = []

    super.init()

    for bidJSON in dict["bids"] as [JSONDictionary] {
      let bid = Bid(JSON: bidJSON)
      bids.append(bid)
    }
  }

  // MARK: Persistence

  required init(coder aDecoder: NSCoder) {
    itemID = aDecoder.decodeIntegerForKey("itemID")
    itemName = aDecoder.decodeObjectForKey("itemName") as NSString
    state = aDecoder.decodeObjectForKey("state") as NSString
    startingBid = aDecoder.decodeDoubleForKey("startingBid")
    itemDescription = aDecoder.decodeObjectForKey("itemDescription") as NSString
    imageURL = aDecoder.decodeObjectForKey("imageURL") as NSString
    bids = aDecoder.decodeObjectForKey("bids") as [Bid]
    super.init()
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeInteger(itemID, forKey: "itemID")
    aCoder.encodeObject(itemName, forKey: "itemName")
    aCoder.encodeObject(state, forKey: "state")
    aCoder.encodeDouble(startingBid, forKey: "startingBid")
    aCoder.encodeObject(itemDescription, forKey: "itemDescription")
    aCoder.encodeObject(imageURL, forKey: "imageURL")
    aCoder.encodeObject(bids, forKey: "bids")
  }
}
