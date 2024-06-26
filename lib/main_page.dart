import 'dart:convert';
import 'package:flutter_application/widgets/action_button.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:animate_do/animate_do.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _bluetooth = FlutterBluetoothSerial.instance;
  bool _bluetoothState = false;
  bool _isConnecting = false;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _deviceConnected;
  int times = 0;
  int counter = 0;

  void _getDevices() async {
    var res = await _bluetooth.getBondedDevices();
    setState(() => _devices = res);
  }

  void _receiveData() {
    _connection?.input?.listen((event) {
      String data = String.fromCharCodes(event).trim();
      int? newCounter = int.tryParse(data);
      if (newCounter != null) {
        setState(() {
          counter = newCounter;
        });
      }
    });
  }

  void _sendData(String data) {
    if (_connection?.isConnected ?? false) {
      _connection?.output.add(ascii.encode(data));
    }
  }

  void _requestPermission() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  @override
  void initState() {
    super.initState();

    _requestPermission();

    _bluetooth.state.then((state) {
      setState(() => _bluetoothState = state.isEnabled);
    });

    _bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BluetoothState.STATE_OFF:
          setState(() => _bluetoothState = false);
          break;
        case BluetoothState.STATE_ON:
          setState(() => _bluetoothState = true);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Flutter ❤ Arduino'),
      ),
      body: Column(
        children: [
          _controlBT(),
          _infoDevice(),
          Expanded(child: _listDevices()),
          _buttons(),
        ],
      ),
    );
  }

  Widget _controlBT() {
    return SwitchListTile(
      value: _bluetoothState,
      onChanged: (bool value) async {
        if (value) {
          await _bluetooth.requestEnable();
        } else {
          await _bluetooth.requestDisable();
        }
      },
      tileColor: Colors.black26,
      title: Text(
        _bluetoothState ? "Bluetooth encendido" : "Bluetooth apagado",
      ),
    );
  }

  Widget _infoDevice() {
    return ListTile(
      tileColor: Colors.black12,
      title: Text("Conectado a: ${_deviceConnected?.name ?? "ninguno"}"),
      trailing: _connection?.isConnected ?? false
          ? TextButton(
              onPressed: () async {
                await _connection?.finish();
                setState(() => _deviceConnected = null);
              },
              child: const Text("Desconectar"),
            )
          : TextButton(
              onPressed: _getDevices,
              child: const Text("Ver dispositivos"),
            ),
    );
  }

  Widget _listDevices() {
    return _isConnecting
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  ...[
                    for (final device in _devices)
                      ListTile(
                        title: Text(device.name ?? device.address),
                        trailing: TextButton(
                          child: const Text('conectar'),
                          onPressed: () async {
                            setState(() => _isConnecting = true);
                            _connection = await BluetoothConnection.toAddress(
                                device.address);
                            _deviceConnected = device;
                            _devices = [];
                            _isConnecting = false;
                            _receiveData();
                            setState(() {});
                          },
                        ),
                      )
                  ]
                ],
              ),
            ),
          );
  }
  Widget _buttons() {
    return FadeInUp(
      animate: _connection?.isConnected ?? false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
        color: Colors.black12,
        child: Column(
          children: [
            const Text('Controles para cinta transportadora',
                style: TextStyle(fontSize: 18.0)),
            const SizedBox(height: 18.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MyButtonLed(
                    titulo: "Motor",
                    data: "1",
                    data2: "0",
                    color: Colors.green,
                    connection: _connection),
                ElevatedButton(
                  onPressed: () {
                    _sendData("2");
                  },
                  child: Text(
                    "Reset",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                    minimumSize: MaterialStateProperty.all<Size>(Size(MediaQuery.of(context).size.width * 0.3, MediaQuery.of(context).size.height * 0.08)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 18.0),
            ElevatedButton(
              onPressed: () {
                _sendData("3");
              },
              child: const Text(
                "Reproducir Canción",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                padding: MaterialStateProperty.all<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Text(
                  'Contador: $counter',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class MyButtonLed extends StatefulWidget {
  const MyButtonLed(
      {super.key,
      required this.titulo,
      required this.data,
      required this.data2,
      required this.color,
      required this.connection});
  final String titulo;
  final String data;
  final String data2;
  final Color color;
  final BluetoothConnection? connection;

  @override
  State<MyButtonLed> createState() => _MyButtonLedState();
}

class _MyButtonLedState extends State<MyButtonLed> {
  double opacity = 0.5;
  bool onOff = false;

  void _sendData(String data) {
    if (widget.connection?.isConnected ?? false) {
      widget.connection?.output.add(ascii.encode(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (onOff) {
            _sendData(widget.data2);
            opacity = 0.5;
            onOff = false;
          } else {
            _sendData(widget.data);
            opacity = 1.0;
            onOff = true;
          }
        });
      },
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
              color: widget.color, borderRadius: BorderRadius.circular(8.0)),
          width: screenSize.width * 0.3,
          height: screenSize.height * 0.08,
          child: Center(
            child: Text(widget.titulo,style: const TextStyle(color: Colors.white),),
          ),
        ),
      ),
    );
  }
}
