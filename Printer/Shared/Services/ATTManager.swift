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
import FirebaseAnalytics

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
            setAnalyticsConsent(for: trackingStatus)
            return
        }
        
        ATTrackingManager.requestTrackingAuthorization { status in
            Task { @MainActor in // Ensure UI updates are on main thread
                self.trackingStatus = status
                self.hasRequestedPermission = true
                UserDefaults.standard.set(true, forKey: self.userDefaultsKey)
                
                self.setAnalyticsConsent(for: status)
                
                // Track the permission response (this will respect the permission)
                AnalyticsManager.shared.trackATTPermissionResponse(granted: self.isTrackingAllowed)
                
                print("🔒 ATT Status: \(self.statusString) - Tracking allowed: \(self.isTrackingAllowed)")
            }
        }
    }
    
    private func setAnalyticsConsent(for status: ATTrackingManager.AuthorizationStatus) {
        switch status {
        case .authorized:
            Analytics.setAnalyticsCollectionEnabled(true)
            Analytics.setConsent([
                .analyticsStorage: .granted,
                .adStorage: .granted,
                .adUserData: .granted,
                .adPersonalization: .granted
            ])
        case .denied, .notDetermined, .restricted:
            Analytics.setAnalyticsCollectionEnabled(false)
            Analytics.setConsent([
                .analyticsStorage: .denied,
                .adStorage: .denied,
                .adUserData: .denied,
                .adPersonalization: .denied
            ])
        @unknown default:
            Analytics.setAnalyticsCollectionEnabled(false)
            Analytics.setConsent([
                .analyticsStorage: .denied,
                .adStorage: .denied,
                .adUserData: .denied,
                .adPersonalization: .denied
            ])
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
