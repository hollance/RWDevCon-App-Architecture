
import Foundation

class SerializableItem: NSObject, NSCoding {
  let itemID: Int
  let itemName: String
  let state: String
  let startingBid: Double
  let itemDescription: String
  let imageURL: String
  let bids: [SerializableBid]

  // Conversion from Item into SerializableItem
  init(item: Item) {
    itemID = item.itemID
    itemName = item.itemName
    state = item.state
    startingBid = item.startingBid
    itemDescription = item.itemDescription
    imageURL = item.imageURL
    bids = []
    for bid in item.bids {
      bids.append(SerializableBid(bid: bid))
    }
  }

  // Conversion from SerializableItem back into Item
  var item: Item {
    var bids = [Bid]()
    for persistentBid in self.bids {
      bids.append(persistentBid.bid)
    }

    let item = Item(itemID: itemID, itemName: itemName, state: state, startingBid: startingBid, itemDescription: itemDescription, imageURL: imageURL, bids: bids)

    // Reconnect the bids with this item object.
    for bid in bids {
      bid.item = item
    }
    return item
  }

  // Loading
  required init(coder aDecoder: NSCoder) {
    itemID = aDecoder.decodeIntegerForKey("itemID")
    itemName = aDecoder.decodeObjectForKey("itemName") as NSString
    state = aDecoder.decodeObjectForKey("state") as NSString
    startingBid = aDecoder.decodeDoubleForKey("startingBid")
    itemDescription = aDecoder.decodeObjectForKey("itemDescription") as NSString
    imageURL = aDecoder.decodeObjectForKey("imageURL") as NSString
    bids = aDecoder.decodeObjectForKey("bids") as [SerializableBid]
    super.init()
  }

  // Saving
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
