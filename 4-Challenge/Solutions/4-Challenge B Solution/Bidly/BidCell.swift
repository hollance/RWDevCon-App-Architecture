
import UIKit

class BidCell: UITableViewCell {
  @IBOutlet weak var itemNameLabel: UILabel!
  @IBOutlet weak var bidderNameLabel: UILabel!
  @IBOutlet weak var bidAmountLabel: UILabel!

  override func prepareForReuse() {
    super.prepareForReuse()
    itemNameLabel.text = ""
    bidderNameLabel.text = ""
    bidAmountLabel.text = ""
  }
}
