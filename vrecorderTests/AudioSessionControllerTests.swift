//  AudioSessionControllerTests.swift
//  Purpose: Pure route-change → lifecycle-event mapping (bug #3). The live
//  AVAudioSession behavior (category, observers) needs a device; this covers the
//  classification logic deterministically.

import AVFoundation
import Testing
@testable import vrecorder

@Suite("AudioSessionController route mapping")
struct AudioSessionControllerTests {
    @Test func deviceRemovalIsRouteLost() {
        #expect(AudioSessionController.event(forRouteChangeReason: .oldDeviceUnavailable) == .routeLost)
    }

    @Test func deviceAddOrSwitchIsRouteChanged() {
        #expect(AudioSessionController.event(forRouteChangeReason: .newDeviceAvailable) == .routeChanged)
        #expect(AudioSessionController.event(forRouteChangeReason: .override) == .routeChanged)
        #expect(AudioSessionController.event(forRouteChangeReason: .categoryChange) == .routeChanged)
    }

    @Test func frequentOrUnrelatedReasonsAreIgnored() {
        // routeConfigurationChange fires often (minor config) — must not stop.
        #expect(AudioSessionController.event(forRouteChangeReason: .routeConfigurationChange) == nil)
        #expect(AudioSessionController.event(forRouteChangeReason: .unknown) == nil)
        #expect(AudioSessionController.event(forRouteChangeReason: .wakeFromSleep) == nil)
    }
}
