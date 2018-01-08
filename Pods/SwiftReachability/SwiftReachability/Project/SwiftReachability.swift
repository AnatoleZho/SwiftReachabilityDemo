//
//  SwiftReachability.swift
//  SwiftReachability
//
//  Created by EastElsoft on 2018/1/7.
//  Copyright © 2018年 AnatoleZho. All rights reserved.
//

import Foundation
import SystemConfiguration

/// Reachability Changed Notification
public let FFReachabilityChangedNotification = "FFNetworkReachabilityChangedNotification"

/// Net Reachability Protocol
public protocol SwiftReachabilityProtocol {
    /// check the reachability of a given host name
    static func reachabilityWithHostName(hostName: String) -> NetworkStatus
    /// start listening for reachability notifications
    func startNotifier() -> Bool
    /// stop listening for reachability notifications
    func stopNotifier()
    /// current reachability status
    var currentReachabilityStatus: NetworkStatus { get }
}

/// Network Status
public enum NetworkStatus {
    case NotReachable, ReachableViaWiFi, ReachableViaWWAN
    
    public var description: String {
        switch self {
        case .ReachableViaWWAN:
            return "2G/3G/4G"
        case .ReachableViaWiFi:
            return "WiFi"
        case .NotReachable:
            return "No Connection"
        }
    }
}

private func & (lhs: SCNetworkReachabilityFlags, rhs: SCNetworkReachabilityFlags) -> UInt32 { return lhs.rawValue & rhs.rawValue }

/// Net Reachability
public class SwiftReachability: SwiftReachabilityProtocol {
    
    
    public static func reachabilityWithHostName(hostName: String) -> NetworkStatus {
        let reach = SwiftReachability(hostname: hostName)
        
        return reach.currentReachabilityStatus
    }
    
    private var reachability: SCNetworkReachability?
    public init(hostname: String) {
        reachability = SCNetworkReachabilityCreateWithName(nil, hostname)!
    }
    
    deinit {
        stopNotifier()
        
        if reachability != nil {
            reachability = nil
        }
    }
    
    /// start listening for reachability notifications
    public func startNotifier() -> Bool {
        var returnValue = false
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        let setReturn = SCNetworkReachabilitySetCallback(reachability!, { (_, _, _) in
            NotificationCenter.default.post(name: NSNotification.Name.init(FFReachabilityChangedNotification), object: nil)
        }, &context)
        if setReturn {
            let scheduleReturn = SCNetworkReachabilityScheduleWithRunLoop(reachability!, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue )
            if scheduleReturn {
                returnValue = true
            }
        }
        return returnValue
    }
    
    /// stop listening for reachability notifications
    public func stopNotifier() {
        if reachability != nil {
            SCNetworkReachabilityUnscheduleFromRunLoop(reachability!, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        }
    }
    
    /// current reachability status
    public var currentReachabilityStatus: NetworkStatus {
        
        if reachability == nil {
            return NetworkStatus.NotReachable
        }
        
        var flags = SCNetworkReachabilityFlags(rawValue: 0)
        SCNetworkReachabilityGetFlags(reachability!, &flags)
        
        return networkStatus(flags: flags)
    }
    
    func networkStatus(flags: SCNetworkReachabilityFlags) -> NetworkStatus {
        if (flags & SCNetworkReachabilityFlags.reachable == 0) {
            // // The target host is not reachable.
            return NetworkStatus.NotReachable;
        }
        
        var returnValue = NetworkStatus.NotReachable;
        if flags & SCNetworkReachabilityFlags.connectionRequired == 0 {
            // If the target host is reachable and no connection is required
            // then we'll assume (for now) that you're on Wi-Fi...
            returnValue = NetworkStatus.ReachableViaWiFi
        }
        
        if flags & SCNetworkReachabilityFlags.connectionOnDemand != 0 || flags & SCNetworkReachabilityFlags.connectionOnTraffic != 0 {
            
            // ... and the connection is on-demand (or on-traffic)
            // if the calling application is using the CFSocketStream or higher APIs...
            if flags & SCNetworkReachabilityFlags.interventionRequired == 0 {
                
                // ... and no [user] intervention is needed...
                returnValue = NetworkStatus.ReachableViaWiFi
            }
        }
        
        if (flags & SCNetworkReachabilityFlags.isWWAN) == SCNetworkReachabilityFlags.isWWAN.rawValue {
            // ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
            returnValue = NetworkStatus.ReachableViaWWAN
        }
        
        return returnValue;
    }
}


