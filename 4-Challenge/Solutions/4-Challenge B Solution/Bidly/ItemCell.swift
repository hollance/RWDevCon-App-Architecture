
import UIKit

class ItemCell: UITableViewCell {
  @IBOutlet weak var itemNameLabel: UILabel!
  @IBOutlet weak var bidderCountLabel: UILabel!
  @IBOutlet weak var highestBidLabel: UILabel!

  override func prepareForReuse() {
    super.prepareForReuse()
    itemNameLabel.text = ""
    bidderCountLabel.text = ""
    highestBidLabel.text = ""
  }

  func configureForPresentationItem(item: PresentationItem) {
    itemNameLabel.text = item.itemNameText
    bidderCountLabel.text = item.bidderCountText
    highestBidLabel.text = item.highestBidText
  }
}
