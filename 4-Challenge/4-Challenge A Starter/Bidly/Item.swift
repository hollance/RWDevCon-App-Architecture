
import Foundation

class Item: NSObject, NSCoding, Equatable {
  let itemID: Int
  let itemName: String
  let state: String
  let startingBid: Double
  let itemDescription: String
  let imageURL: String

  private(set) var bids: [Bid]

  init(itemID: Int, itemName: String, state: String, startingBid: Double, itemDescription: String, imageURL: String, bids: [Bid]) {
    self.itemID = itemID
    self.itemName = itemName
    self.state = state
    self.startingBid = startingBid
    self.itemDescription = itemDescription
    self.imageURL = imageURL
    self.bids = bids
    super.init()
  }

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
      addBid(Bid(JSON: bidJSON))
    }
  }

  // Adds a new bid to the item but only if it doesn't exist yet.
  func addBid(bid: Bid) {
    if find(bids, bid) == nil {
      bids.append(bid)
      bid.item = self  // two-way relationship
    }
  }

  // MARK: Domain Logic

  // What is the hightest Bid for this Item? Returns nil if no bids made yet.
  var highestBid: Bid? {
    var highestBid: Bid?
    var highestAmount = 0.0
    for bid in bids {
      if bid.amount > highestAmount {
        highestAmount = bid.amount
        highestBid = bid
      }
    }
    return highestBid
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

    // Reconnect the bids with this item object.
    for bid in bids {
      bid.item = self
    }
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

func ==(lhs: Item, rhs: Item) -> Bool {
  return lhs.itemID == rhs.itemID
}
