
import Foundation

class Item: NSObject, Equatable {
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
}

func ==(lhs: Item, rhs: Item) -> Bool {
  return lhs.itemID == rhs.itemID
}
