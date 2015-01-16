
import UIKit

protocol NewBidViewControllerDelegate: class {
  func newBidViewController(controller: NewBidViewController, placedBid: Bid)
}

class NewBidViewController: UIViewController, UITextFieldDelegate {
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var doneButton: UIBarButtonItem!
  @IBOutlet weak var spinner: UIActivityIndicatorView!

  weak var delegate: NewBidViewControllerDelegate?

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

  // MARK: Networking

  @IBAction func done() {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true

    // Show animated spinner and block all user input.
    spinner.hidden = false
    spinner.startAnimating()
    navigationController?.view.userInteractionEnabled = false
    textField.resignFirstResponder()

    let urlString = String(format: "http://api.bid.ly/v1/bid?itemID=%d&bidderID=%d&amount=%@", item.itemID, bidderID, textField.text)
    let url = NSURL(string: urlString)!

    let session = NSURLSession.sharedSession()
    let dataTask = session.dataTaskWithURL(url, completionHandler: {
      data, response, error in

      var success = false
      if error == nil {
        if let httpResponse = response as? NSHTTPURLResponse {
          if httpResponse.statusCode == 200 {
            if var bidJSON: JSONDictionary = self.parseJSON(data) {
              success = true
              let bid = Bid(JSON: bidJSON)
              self.delegate?.newBidViewController(self, placedBid: bid)
            }
          }
        }
      }

      dispatch_async(dispatch_get_main_queue()) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false

        self.spinner.hidden = true
        self.spinner.stopAnimating()
        self.navigationController?.view.userInteractionEnabled = true

        if success {
          self.dismissViewControllerAnimated(true, completion: nil)
        } else {
          self.showErrorMessage()
        }
      }
    })

    dataTask.resume()
  }

  private func parseJSON<T>(data: NSData) -> T? {
    var error: NSError?
    if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error) as? T {
      return json
    } else if let error = error {
      println("JSON Error: \(error)")
    } else {
      println("Unknown JSON Error")
    }
    return nil
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
