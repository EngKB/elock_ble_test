import 'dart:async';

import 'package:elock_ble/constants.dart';
import 'package:elock_ble/device_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<DiscoveredDevice> scanResult;

  List<DiscoveredDevice> loResult = [];

  @override
  void initState() {
    scanResult = flutterReactiveBle.scanForDevices(
      withServices: [],
    ).listen((event) {
      if (!loResult.any((element) => element.id == event.id)) {
        setState(() {
          loResult.add(event);
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                loResult.clear();
                scanResult.cancel();
                scanResult = flutterReactiveBle.scanForDevices(
                  withServices: [
                    elockBleServiceUuid,
                  ],
                ).listen((event) {
                  if (!loResult.any((element) => element.id == event.id)) {
                    setState(() {
                      loResult.add(event);
                    });
                  }
                });
              });
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: loResult.length,
        itemBuilder: (context, i) {
          return Column(
            children: [
              Text(
                loResult[i].id.toString(),
              ),
              Text(loResult[i].name),
              Text(loResult[i].serviceData.length.toString()),
              Wrap(
                children: loResult[i]
                    .serviceData
                    .entries
                    .map((e) => Text(e.value.toString()))
                    .toList(),
              ),
              Text('m: ' + loResult[i].manufacturerData.toString()),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DevicePage(
                        deviceId: loResult[i].id,
                      ),
                    ),
                  );
                },
                child: const Text('connect'),
              )
            ],
          );
        },
      ),
    );
  }
}
