//
//  WifiInfoService.swift
//  WifiTest
//
//  Created by Avinash Thakur on 16/01/23.
//

import CoreTelephony
import Foundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

// MARK: - Connection

public enum Connection: CustomStringConvertible {
  case none, wifi, cellular

  // MARK: Public

  public var description: String {
    switch self {
    case .cellular: return "Cellular"
    case .wifi: return "WiFi"
    case .none: return "No Connection"
    }
  }
}

// MARK: - WifiService

class WifiService {
  /** Function check and returns tuple for the current connected wifi, Details, like wifi ssid i.e wifi name & whether it is secure. The feature is available on iOS 14 and above. In case of iOS 15 and above it checks for the wifi security type i.e. NEHotspotNetworkSecurityType to check if it secure or not.  0,4 are open and unknown security type.

   - Returns: String Wifi Name
   - Returns: Bool Whether the wifi is secure or not
   */
  func getConnectedWifiDetails(completion: @escaping ((String?, Bool) -> ())) {
    NEHotspotNetwork.fetchCurrent { network in
      guard let wifi = network else {
        if NetworkReachability.isConnectedToNetwork() {
          completion("Cellular", true)
          print("Cellular Network Is Secure")
        } else {
          completion(nil, false)
        }
        return
      }

      if #available(iOS 15.0, *) {
        print(" Wifi Security type: \(wifi.securityType.rawValue)")
        if wifi.securityType.rawValue == 0 || wifi.securityType.rawValue == 4 {
          print("Network: \(wifi) \n Is Secure \(false)")
          completion(wifi.ssid, false)
        } else {
          print("Network: \(wifi) \n Is Secure \(true)")
          completion(wifi.ssid, true)
        }
      } else {
        print("Network: \(wifi) \n Is Secure \(wifi.isSecure)")
        completion(wifi.ssid, wifi.isSecure)
      }
    }
  }
}

public class NetworkReachability {
  class func isConnectedToNetwork() -> Bool {
    var zeroAddress = sockaddr_in(
      sin_len: 0,
      sin_family: 0,
      sin_port: 0,
      sin_addr: in_addr(s_addr: 0),
      sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)
    )
    zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)

    let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
        SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
      }
    }

    var flags = SCNetworkReachabilityFlags(rawValue: 0)
    if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
      return false
    }

    /* Only Working for WIFI
     let isReachable = flags == .reachable
     let needsConnection = flags == .connectionRequired

     return isReachable && !needsConnection
     */

    // Working for Cellular and WIFI
    let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
    let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
    let ret = (isReachable && !needsConnection)

    return ret
  }
}

