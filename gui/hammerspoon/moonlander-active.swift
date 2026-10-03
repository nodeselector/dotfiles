import Foundation
import IOKit.hid

// The KVM keeps a virtual Moonlander attached to both computers, but only the
// selected computer can exchange messages with the physical keyboard. Ask the
// keyboard for its Oryx protocol version; a response means this computer is the
// selected KVM input.

private let vendorID = 0x3297
private let productID = 0x1969
private let rawHIDUsagePage = 0xff60
private let rawHIDUsage = 0x61
private let getProtocolVersion: UInt8 = 0xfe
private let responseTimeout = 0.25

private var response: [UInt8]?
private var querySent = false
private let reportCallback: IOHIDReportCallback = { _, _, _, _, _, report, length in
    response = Array(UnsafeBufferPointer(start: report, count: length))
    CFRunLoopStop(CFRunLoopGetCurrent())
}

private let manager = IOHIDManagerCreate(
    kCFAllocatorDefault,
    IOOptionBits(kIOHIDOptionsTypeNone)
)
private let matching: [String: Any] = [
    kIOHIDVendorIDKey as String: vendorID,
    kIOHIDProductIDKey as String: productID,
    kIOHIDPrimaryUsagePageKey as String: rawHIDUsagePage,
    kIOHIDPrimaryUsageKey as String: rawHIDUsage,
]

IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))

guard
    let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>,
    let keyboard = devices.first
else {
    // A disconnected keyboard also means the Odyssey is not usable through the KVM.
    exit(1)
}

guard IOHIDDeviceOpen(keyboard, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
    exit(2)
}

var inputBuffer = [UInt8](repeating: 0, count: 32)
inputBuffer.withUnsafeMutableBufferPointer { buffer in
    IOHIDDeviceRegisterInputReportCallback(
        keyboard,
        buffer.baseAddress!,
        buffer.count,
        reportCallback,
        nil
    )
    IOHIDDeviceScheduleWithRunLoop(
        keyboard,
        CFRunLoopGetCurrent(),
        CFRunLoopMode.defaultMode.rawValue
    )

    var query = [UInt8](repeating: 0, count: 32)
    query[0] = getProtocolVersion
    let sendStatus = IOHIDDeviceSetReport(
        keyboard,
        kIOHIDReportTypeOutput,
        0,
        &query,
        query.count
    )

    if sendStatus == kIOReturnSuccess {
        querySent = true
        CFRunLoopRunInMode(CFRunLoopMode.defaultMode, responseTimeout, false)
    }
}

IOHIDDeviceClose(keyboard, IOOptionBits(kIOHIDOptionsTypeNone))
IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))

guard querySent else {
    exit(2)
}

if let response, response.count >= 2, response[0] == getProtocolVersion {
    print("active protocol=0x\(String(format: "%02x", response[1]))")
    exit(0)
}

exit(1)
