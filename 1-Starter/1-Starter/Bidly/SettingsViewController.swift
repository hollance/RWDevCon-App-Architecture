
import UIKit

class SettingsViewController: UITableViewController {

  var watchViewController: WatchViewController!

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)

    switch (indexPath.section, indexPath.row) {
    case (1, 0):
      afterDelay(2) {
        // Pick a random item the user is watching and add a new bid to it.
        // This bid is from a random bidder.
        var itemIDs = [Int]()
        for item in self.watchViewController.items {
          itemIDs.append(item.itemID)
        }
        if !itemIDs.isEmpty {
          addRandomBidToItemID(itemIDs.randomElement())
        }
      }
    default:
      break
    }
  }
}
