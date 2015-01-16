
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  var tabBarController: UITabBarController {
    return window?.rootViewController as UITabBarController
  }

  var activityViewController: ActivityViewController {
    let navigationController = tabBarController.viewControllers![0] as UINavigationController
    return navigationController.viewControllers![0] as ActivityViewController
  }

  var searchViewController: SearchViewController {
    let navigationController = tabBarController.viewControllers![1] as UINavigationController
    return navigationController.viewControllers![0] as SearchViewController
  }

  var watchViewController: WatchViewController {
    let navigationController = tabBarController.viewControllers![2] as UINavigationController
    return navigationController.viewControllers![0] as WatchViewController
  }

  var settingsViewController: SettingsViewController {
    let navigationController = tabBarController.viewControllers![3] as UINavigationController
    return navigationController.viewControllers![0] as SettingsViewController
  }

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

    // For faking the server portion of the app. This creates fake data the
    // first time you run the app. It also intercepts all networking requests.
    installFakeServer()

    let watchlist = Watchlist()
    activityViewController.watchlist = watchlist
    searchViewController.watchlist = watchlist
    watchViewController.watchlist = watchlist
    settingsViewController.watchlist = watchlist

    let serverAPI = ServerAPI()
    searchViewController.serverAPI = serverAPI
    watchViewController.serverAPI = serverAPI

    return true
  }
}
