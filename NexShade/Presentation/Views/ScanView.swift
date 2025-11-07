//
//  ScanView.swift
//  NexShade
//
//  Created by Ali Eren on 7.11.2025.
//

import SwiftUI
import Observation

struct ScanView: View {
    
    // Use @State private var for the connection sheet presentation
    @State private var isConnectingSheetPresented = false
    @State private var selectedDeviceForConnection: Device?
    
    // In SwiftUI views using the new @Observable macro,
    // it's best practice to use @Bindable or simply the type,
    // but since the model is marked @MainActor and uses @ObservedObject
    // in the prompt's provided snippet, we'll keep it as @ObservedObject
    // for compatibility with older patterns or if the Swift version
    // requires it for this specific context.
    var viewModel: ScanViewModel
    
    var body: some View {
        NavigationStack {
            List {
                // Section for the main scanning action/status
                Section {
                    HStack {
                        Text(viewModel.isScanning ? "Scanning..." : "Ready to Scan")
                            .font(.headline)
                        
                        Spacer()
                        
                        if viewModel.isScanning {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                }
                
                // Section for discovered devices
                Section("Discovered Devices (\(viewModel.discoveredDevices.count))") {
                    if viewModel.discoveredDevices.isEmpty && !viewModel.isScanning {
                        ContentUnavailableView("No Devices Found", systemImage: "antenna.radiowaves.left.and.right")
                    } else {
                        ForEach(viewModel.discoveredDevices) { device in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(device.name)
                                        .font(.subheadline)
                                        .bold()
                                    Text("ID: \(device.id)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Connect") {
                                    selectedDeviceForConnection = device
                                    isConnectingSheetPresented = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Device Scanner 📱")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(viewModel.isScanning ? "Stop Scan" : "Start Scan") {
                        if viewModel.isScanning {
                            viewModel.stopScanning()
                        } else {
                            viewModel.startScanning()
                        }
                    }
                    .foregroundColor(viewModel.isScanning ? .red : .blue)
                }
            }
            .onAppear {
                // Start scanning automatically when the view appears (optional)
                // viewModel.startScanning()
            }
            .alert("Connection Error", isPresented: .constant(viewModel.error != nil), actions: {
                Button("OK", role: .cancel) {
                    viewModel.error = nil // Clear the error when the user dismisses the alert
                }
            }, message: {
                Text(viewModel.error ?? "An unknown error occurred.")
            })
            .sheet(isPresented: $isConnectingSheetPresented) {
                // Connection confirmation/status view
                ConnectConfirmationView(
                    device: selectedDeviceForConnection!,
                    viewModel: viewModel,
                    isPresented: $isConnectingSheetPresented
                )
            }
        }
    }
}

// A helper view for the connection sheet
struct ConnectConfirmationView: View {
    let device: Device
    var viewModel: ScanViewModel
    @Binding var isPresented: Bool
    
    @State private var isConnecting = false
    @State private var connectionSuccess = false
    
    var body: some View {
        VStack(spacing: 20) {
            if isConnecting {
                ProgressView("Connecting to \(device.name)...")
            } else if connectionSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.largeTitle)
                Text("Successfully connected to **\(device.name)**!")
                Button("Done") {
                    isPresented = false
                }
            } else {
                Text("Connect to **\(device.name)**?")
                    .font(.title)
                
                Text("ID: \(device.id)")
                    .font(.subheadline)
                
                Button("Connect") {
                    Task {
                        isConnecting = true
                        let success = await viewModel.connect(to: device)
                        isConnecting = false
                        connectionSuccess = success
                        
                        // Automatically dismiss on success after a short delay
                        if success {
                            try? await Task.sleep(for: .seconds(1))
                            isPresented = false
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isConnecting)
                
                Button("Cancel", role: .cancel) {
                    isPresented = false
                }
            }
        }
        .padding()
    }
}
