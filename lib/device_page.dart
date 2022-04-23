import 'dart:async';

import 'package:elock_ble/constants.dart';
import 'package:elock_ble/elock_ble_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DevicePage extends StatefulWidget {
  final String deviceId;
  const DevicePage({
    Key? key,
    required this.deviceId,
  }) : super(key: key);

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  final key = key173;
  late List<int> token;
  final String password = '000000';
  late Stream<ConnectionStateUpdate> connectionStream;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription? _dataStream;
  int? batteryLevel;
  @override
  void initState() {
    connectionStream = FlutterReactiveBle().connectToDevice(
        id: widget.deviceId,
        servicesWithCharacteristicsToDiscover: {
          elockBleServiceUuid: [elockBleNotifyUuid, elockBleWriteUuid]
        }).asBroadcastStream();
    _connection = connectionStream.listen((event) {
      if (event.connectionState == DeviceConnectionState.connected) {
        _dataStream = FlutterReactiveBle()
            .subscribeToCharacteristic(
          QualifiedCharacteristic(
            characteristicId: elockBleNotifyUuid,
            serviceId: elockBleServiceUuid,
            deviceId: widget.deviceId,
          ),
        )
            .listen((event) {
          if (event.isNotEmpty) {
            final response =
                ElockBleDataSource().decryptElockBleResponse(event, key);
            debugPrint('response ' + event.toString());
            if (response[0] == 0x06 && response[1] == 0x02) {
              setState(() {
                token = [
                  response[3],
                  response[4],
                  response[5],
                  response[6],
                ];
              });
            }
            if (response[0] == 0x02 &&
                response[1] == 0x02 &&
                response[2] == 0x01) {
              setState(() {
                batteryLevel = response[3];
              });
            }
          }
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceId),
      ),
      body: StreamBuilder<ConnectionStateUpdate>(
        stream: connectionStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          }
          final DeviceConnectionState connectionState =
              snapshot.data!.connectionState;
          if (connectionState == DeviceConnectionState.connected) {
            return Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('connected'),
                  ElevatedButton(
                    onPressed: () {
                      ElockBleDataSource().getElockBleTokenCommand(
                        widget.deviceId,
                        key,
                      );
                    },
                    child: const Text('token'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ElockBleDataSource().eLockBleTimeSynchronization(
                        widget.deviceId,
                        token,
                        key,
                      );
                    },
                    child: const Text('time'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ElockBleDataSource().getElockPowerPercentage(
                        widget.deviceId,
                        token,
                        key,
                      );
                    },
                    child: const Text('battery'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ElockBleDataSource().unlockElockBleCommand(
                        widget.deviceId,
                        token,
                        key,
                        password,
                      );
                    },
                    child: const Text('unlock'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ElockBleDataSource().checkElockBleStatusCommand(
                        widget.deviceId,
                        token,
                        key,
                      );
                    },
                    child: const Text('status'),
                  ),
                  if (batteryLevel != null) Text(batteryLevel.toString())
                ],
              ),
            );
          } else if (connectionState == DeviceConnectionState.connecting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (connectionState == DeviceConnectionState.disconnected) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(
                    () {
                      connectionStream = FlutterReactiveBle().connectToDevice(
                        id: widget.deviceId,
                        servicesWithCharacteristicsToDiscover: {
                          elockBleServiceUuid: [
                            elockBleNotifyUuid,
                            elockBleWriteUuid
                          ]
                        },
                      ).asBroadcastStream();
                    },
                  );
                },
                child: const Text('reconnect'),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  @override
  void dispose() {
    _connection?.cancel();
    _dataStream?.cancel();
    super.dispose();
  }
}
