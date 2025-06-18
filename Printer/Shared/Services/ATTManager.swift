//
//  ATTManager.swift
//  Printer
//
//  Created by AI Assistant on 18/6/25.
//

import Foundation
import AppTrackingTransparency
import AdSupport
import SwiftUI

@MainActor
class ATTManager: ObservableObject {
    @Published var trackingStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    @Published var hasRequestedPermission = false
    
    private let userDefaultsKey = "ATTPermissionRequested"
    
    init() {
        trackingStatus = ATTrackingManager.trackingAuthorizationStatus
        hasRequestedPermission = UserDefaults.standard.bool(forKey: userDefaultsKey)
        
        // Initialize analytics with current tracking status
        AnalyticsManager.shared.updateTrackingConsent(isAllowed: isTrackingAllowed)
    }
    
    /// Check current ATT status
    func checkCurrentStatus() async {
        let status = ATTrackingManager.trackingAuthorizationStatus
        await MainActor.run {
            self.trackingStatus = status
            AnalyticsManager.shared.updateTrackingConsent(isAllowed: isTrackingAllowed)
        }
    }
    
    /// Check if we should show the ATT prompt
    var shouldRequestPermission: Bool {
        return !hasRequestedPermission && trackingStatus == .notDetermined
    }
    
    /// Check if tracking is allowed
    var isTrackingAllowed: Bool {
        return trackingStatus == .authorized
    }
    
    /// Request tracking permission using native ATT prompt
    func requestTrackingPermission() async {
        guard shouldRequestPermission else { 
            // Even if we don't show prompt, update analytics with current status
            AnalyticsManager.shared.updateTrackingConsent(isAllowed: isTrackingAllowed)
            return 
        }
        
        let status = await ATTrackingManager.requestTrackingAuthorization()
        
        await MainActor.run {
            self.trackingStatus = status
            self.hasRequestedPermission = true
            UserDefaults.standard.set(true, forKey: userDefaultsKey)
            
            // Configure Firebase Analytics based on permission
            AnalyticsManager.shared.updateTrackingConsent(isAllowed: isTrackingAllowed)
            
            // Track the permission response (this will respect the permission)
            AnalyticsManager.shared.trackATTPermissionResponse(granted: isTrackingAllowed)
            
            print("🔒 ATT Status: \(statusString) - Tracking allowed: \(isTrackingAllowed)")
        }
    }
    
    /// Get user-friendly status string
    var statusString: String {
        switch trackingStatus {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
    
    /// Get IDFA (only if tracking is authorized)
    var advertisingIdentifier: String {
        guard isTrackingAllowed else { return "00000000-0000-0000-0000-000000000000" }
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
}