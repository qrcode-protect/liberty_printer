import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liberty_printer/controller/print_controller.dart';
import 'package:liberty_printer/services/date_format.dart';
import 'package:liberty_printer/state/app_state.dart';
import 'package:libertymodel/libertymodel.dart';

class PrintPage extends ConsumerStatefulWidget {
  const PrintPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends ConsumerState<PrintPage> {
  bool loadingConnect = false;
  bool loadingDisconnect = false;

  @override
  Widget build(BuildContext context) {
    final printerState = ref.watch(printerStateProvider);
    final appState = ref.watch(appStateProvider);
    return appState.utilisateur != null
        ? Scaffold(
            body: ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Appareil:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<BluetoothDevice>(
                            items: printerState.getDeviceItems(),
                            onChanged: (value) =>
                                printerState.setSelectedDevice(value),
                            value: printerState.device,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 15.0),
                            child: ElevatedButton(
                              onPressed: printerState.connected
                                  ? null
                                  : () async {
                                      setState(() {
                                        loadingConnect = true;
                                      });
                                      await printerState.connect();
                                      setState(() {
                                        loadingConnect = false;
                                      });
                                    },
                              child: loadingConnect
                                  ? const CircularProgressIndicator()
                                  : const Text('Connexion'),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 15.0),
                            child: ElevatedButton(
                              onPressed: printerState.connected
                                  ? () async {
                                      setState(() {
                                        loadingDisconnect = true;
                                      });
                                      await printerState.disconnect();
                                      setState(() {
                                        loadingDisconnect = false;
                                      });
                                    }
                                  : null,
                              child: loadingDisconnect
                                  ? const CircularProgressIndicator()
                                  : const Text('Deconnexion'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 10.0, right: 10.0, top: 50),
                  child: ElevatedButton(
                    onPressed: printerState.connected
                        ? () {
                            printerState.listenCommands(ref
                                .read(appStateProvider)
                                .utilisateur!
                                .idRestaurant!);
                          }
                        : null,
                    child: const Text('Ecouter les impressions'),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 10.0, right: 10.0, top: 50),
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(appStateProvider).signOut();
                    },
                    child: const Text('Deconnexion'),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 10.0, right: 10.0, top: 50),
                  child: ElevatedButton(
                    onPressed: printerState.connected
                        ? () {
                            printerState.printTest();
                          }
                        : null,
                    child: const Text('Tester l\'impresssion'),
                  ),
                ),
              ],
            ),
          )
        : const Center(
            child: CircularProgressIndicator(),
          );
  }
}
