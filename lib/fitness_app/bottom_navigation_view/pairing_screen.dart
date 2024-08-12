import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class PairingScreen extends StatefulWidget {
  @override
  _PairingScreenState createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> devices = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  Future<void> _checkPermissions() async {
    if (await Permission.bluetooth.status.isDenied) {
      await Permission.bluetooth.request();
    }
    if (await Permission.bluetoothScan.status.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.bluetoothConnect.status.isDenied) {
      await Permission.bluetoothConnect.request();
    }
    if (await Permission.location.status.isDenied) {
      await Permission.location.request();
    }

    bool allGranted = await Permission.bluetooth.isGranted &&
        await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted &&
        await Permission.location.isGranted;

    if (allGranted) {
      _getPairedDevices();
    } else {
      print("Not all permissions granted");
      // You might want to show a dialog here explaining why the permissions are needed
    }
  }

  void _getPairedDevices() async {
    List<BluetoothDevice> pairedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
    setState(() {
      devices = pairedDevices;
    });
  }

  void _startDiscovery() async {
    setState(() {
      isScanning = true;
      devices.clear();
    });

    try {
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
        setState(() {
          final existingIndex = devices.indexWhere((element) => element.address == r.device.address);
          if (existingIndex >= 0) {
            devices[existingIndex] = r.device;
          } else {
            devices.add(r.device);
          }
        });
      }).onDone(() {
        setState(() {
          isScanning = false;
        });
      });
    } catch (ex) {
      print('Error starting discovery: $ex');
      setState(() {
        isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF2F3F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Pairing New Device',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bluetooth',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
                Switch(
                  value: _bluetoothState.isEnabled,
                  onChanged: (bool value) {
                    if (value)
                      FlutterBluetoothSerial.instance.requestEnable();
                    else
                      FlutterBluetoothSerial.instance.requestDisable();
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: isScanning
                ? Center(child: CircularProgressIndicator())
                : devices.isEmpty
                ? Center(child: Text("No devices found"))
                : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = devices[index];
                return ListTile(
                  title: Text(device.name ?? "Unknown device"),
                  subtitle: Text(device.address),
                  trailing: TextButton(
                    child: Text('Connect',
                        style: TextStyle(color: Colors.blue)),
                    onPressed: () {
                      // Implement connection logic here
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(isScanning ? Icons.stop : Icons.refresh, color: Colors.white),
        onPressed: isScanning ? () {} : _startDiscovery,
      ),
    );
  }
}