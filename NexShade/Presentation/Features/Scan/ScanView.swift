//
//  Device.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 8.11.2025.
//


import SwiftUI
import Observation // Required for @Observable

// Assume this is your domain model
// NOTE: You must provide a valid 'Device' definition in your project.
// struct Device: Identifiable, Equatable {
//     let id: UUID
//     var name: String
//     var rssi: Int // Example property for updating
// }

// Protocol definitions (as provided in the ViewModel context)
// protocol ScanForDevicesUseCaseProtocol { /* ... */ }
// protocol ConnectToDeviceUseCaseProtocol { /* ... */ }

// --- THE VIEW ---

struct ScanView: View {
    // 1. Inject the ViewModel
    // Since the VM is @Observable, we use @StateObject (for older SwiftUI) or 
    // simply initialize it (for modern iOS 17+ Observation). 
    // We'll use @State for simplicity here, assuming the VM is passed in or created.
    @State var viewModel: ScanViewModel
    
    // State for connection alert
    @State private var connectionError: Error?
    @State private var showConnectionError: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                // MARK: - Scanning Status and Control
                HStack {
                    Text(viewModel.isScanning ? "Scanning..." : "Ready to Scan")
                        .font(.headline)
                        .foregroundStyle(viewModel.isScanning ? .blue : .secondary)
                    
                    Spacer()
                    
                    Button(action: toggleScan) {
                        Text(viewModel.isScanning ? "Stop Scan" : "Start Scan")
                    }
                    .buttonStyle(.borderedProminent)
                    // Disable button while connecting or if there's an error
                    .disabled(viewModel.isScanning && viewModel.discoveredDevices.isEmpty)
                }
                .padding(.horizontal)
                
                Divider()
                
                // MARK: - Device List
                List {
                    if viewModel.discoveredDevices.isEmpty && !viewModel.isScanning {
                        ContentUnavailableView("No Devices Found", systemImage: "bluetooth")
                            .listRowSeparator(.hidden)
                    } else {
                        Section("Discovered Devices (\(viewModel.discoveredDevices.count))") {
                            ForEach(viewModel.discoveredDevices) { device in
                                DeviceRow(device: device) {
                                    // Action when the user taps 'Connect'
                                    Task { await attemptConnection(to: device.id) }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    // Pull-to-refresh starts a new scan
                    viewModel.startScan()
                }
            }
            .navigationTitle("BLE Scanner")
            // Present alert on connection failure
            .alert("Connection Failed", isPresented: $showConnectionError, presenting: connectionError) { error in
                Button("OK") { connectionError = nil }
            } message: { error in
                Text("Could not connect to the device. Error: \(error.localizedDescription)")
            }
        }
        // Ensure scan stops when the view disappears
        .onDisappear {
            viewModel.stopScan()
        }
    }
    
    // MARK: - Private Logic
    
    private func toggleScan() {
        if viewModel.isScanning {
            viewModel.stopScan()
        } else {
            viewModel.startScan()
        }
    }
    
    private func attemptConnection(to deviceId: UUID) async {
        // Stop scanning before connecting is generally a good BLE practice
        viewModel.stopScan() 
        
        do {
            // Note: Your VM's connectToDevice() currently uses a hardcoded ID
            // We should ideally pass the deviceId here. Assuming the VM will be updated:
            // try await viewModel.connectToDevice(deviceId: deviceId)
            
            // Using the current VM implementation as written in the prompt's context
            try await viewModel.connectToDevice() 
            print("Successfully connected to \(deviceId)!")
            // Handle successful connection (e.g., navigate to detail screen)
        } catch {
            self.connectionError = error
            self.showConnectionError = true
        }
    }
}

// MARK: - Subviews

struct DeviceRow: View {
    let device: Device
    let connectAction: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Assuming Device has an RSSI property
//                if let rssi = (device as? HasRssi)?.rssi {
//                    Text("RSSI: \(rssi) dBm")
//                        .font(.caption)
//                        .foregroundStyle(.gray)
//                }
            }
            
            Spacer()
            
            Button("Connect") {
                connectAction()
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Previews (Requires external mock data/use cases)
/*
#Preview {
    let mockScanning = MockScanUseCase()
    let mockConnection = MockConnectionUseCase()
    let viewModel = ScanViewModel(
        scanningUseCase: mockScanning,
        connectionUseCase: mockConnection
    )
    
    // Start with some mock data for the list
    viewModel.discoveredDevices = [
        Device(id: UUID(), name: "Pergola A1", rssi: -55),
        Device(id: UUID(), name: "BLE Sensor X", rssi: -80)
    ]
    
    return ScanView(viewModel: viewModel)
}
*/
