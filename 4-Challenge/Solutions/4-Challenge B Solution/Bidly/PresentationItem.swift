
import Foundation

private var currencyFormatter: NSNumberFormatter = {
  let formatter = NSNumberFormatter()
  formatter.numberStyle = .CurrencyStyle
  formatter.currencyCode = "USD"
  return formatter
}()

struct PresentationItem {
  let itemNameText: String
  let bidderCountText: String
  let highestBidText: String

  init(item: Item) {
    itemNameText = item.itemName

    if item.bids.count == 1 {
      bidderCountText = "1 Bidder"
    } else {
      bidderCountText = "\(item.bids.count) Bidders"
    }

    if let highestBid = item.highestBid {
      highestBidText = currencyFormatter.stringFromNumber(highestBid.amount)!
    } else {
      highestBidText = "-"
    }
  }
}
