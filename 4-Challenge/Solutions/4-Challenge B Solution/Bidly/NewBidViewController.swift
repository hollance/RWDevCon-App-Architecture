
import UIKit

protocol NewBidViewControllerDelegate: class {
  func newBidViewController(controller: NewBidViewController, placedBid: Bid)
}

class NewBidViewController: UIViewController, UITextFieldDelegate {
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var doneButton: UIBarButtonItem!
  @IBOutlet weak var spinner: UIActivityIndicatorView!

  weak var delegate: NewBidViewControllerDelegate?

  var serverAPI: ServerAPI!

  // These are set upon segueing into this screen.
  var item: Item!
  var bidderID: Int!

  override func viewDidLoad() {
    super.viewDidLoad()
    doneButton.enabled = false
    spinner.hidden = true
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    textField.becomeFirstResponder()
  }

  @IBAction func cancel() {
    dismissViewControllerAnimated(true, completion: nil)
  }

  // MARK: User Interface Actions

  @IBAction func done() {
    // Show animated spinner and block all user input.
    spinner.hidden = false
    spinner.startAnimating()
    navigationController?.view.userInteractionEnabled = false
    textField.resignFirstResponder()

    let request = NewBidRequest(itemID: item.itemID, bidderID: bidderID, amount: textField.text) { result in
      self.spinner.hidden = true
      self.spinner.stopAnimating()
      self.navigationController?.view.userInteractionEnabled = true

      if let json = result as? JSONDictionary {
        let bid = Bid(JSON: json)
        self.delegate?.newBidViewController(self, placedBid: bid)
        self.dismissViewControllerAnimated(true, completion: nil)
      } else {
        self.showErrorMessage()
      }
    }
    serverAPI.sendRequest(request)
  }

  private func showErrorMessage() {
    let alert = UIAlertController(
      title: "Error communicating with Bidly server",
      message: "Your bid was not placed.\nPlease try again.",
      preferredStyle: .Alert)

    let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
    alert.addAction(action)

    presentViewController(alert, animated: true, completion: nil)
  }

  // MARK: Input Validation

  func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
    let oldText: NSString = textField.text
    let newText: NSString = oldText.stringByReplacingCharactersInRange(range, withString: string)

    doneButton.enabled = false

    if newText.length > 0 {
      // Is it really a valid number?
      var value = 0.0
      let scanner = NSScanner(string: newText)
      if scanner.scanDouble(&value) {
        doneButton.enabled = scanner.atEnd
      }
    }

    return true
  }
}
