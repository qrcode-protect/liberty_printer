import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_star_prnt/flutter_star_prnt.dart';
import 'package:liberty_printer/controller/start_print_controller.dart';
import 'package:liberty_printer/state/app_state.dart';
import 'package:liberty_printer/view/test_view_ticket.dart';
import 'package:libertymodel/models/models.dart';

class StarPrintPage extends ConsumerStatefulWidget {
  const StarPrintPage({Key? key}) : super(key: key);

  @override
  ConsumerState<StarPrintPage> createState() => _StarPrintPageState();
}

class _StarPrintPageState extends ConsumerState<StarPrintPage> {
  @override
  void initState() {
    ref.read(starPrinterStateProvider).portsList.isEmpty
        ? ref.read(starPrinterStateProvider).init()
        : null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final printerState = ref.watch(starPrinterStateProvider);
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: DropdownButton<PortInfo>(
                        items: printerState.getDevices(),
                        onChanged: printerState.loadInit
                            ? null
                            : (value) => printerState.setPort(value),
                        value: printerState.port,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        printerState.reset();
                        printerState.init();
                      },
                      icon: const Icon(Icons.replay),
                    ),
                    IconButton(
                      onPressed: () {
                        printerState.setPort(null);
                      },
                      icon: const Icon(
                        Icons.cancel,
                        color: Color.fromARGB(255, 153, 34, 34),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 25,
                ),
                SizedBox(
                  height: 50,
                  width: 150,
                  child: ElevatedButton(
                    onPressed: printerState.port != null
                        ? () {
                            printerState.subscription == null
                                ? printerState.listenCommands(ref
                                    .read(appStateProvider)
                                    .utilisateur!
                                    .idRestaurant!)
                                : printerState.disposeSubscription();
                          }
                        : null,
                    child: Text(
                      printerState.subscription == null
                          ? 'Ecouter les impressions'
                          : 'Arreter l\'écoute',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                SizedBox(
                  height: 50,
                  width: 150,
                  child: ElevatedButton(
                    onPressed: printerState.port != null
                        ? () async {
                            await printerState.printTest();
                          }
                        : null,
                    child: const Text(
                      'Tester l\'impression',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // SizedBox(
                //   height: 50,
                //   width: 150,
                //   child: ElevatedButton(
                //     onPressed: () async {
                //       CommandeRestaurant commandeRestaurant =
                //           await FirebaseFirestore.instance
                //               .collection('commandes_restauration')
                //               .doc('oM02LlHtUEsdFuVe3VNh')
                //               .get()
                //               .then(
                //                 (value) =>
                //                     CommandeRestaurant.fromJson(value.data()!),
                //               );
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => TestViewTicket(
                //             commandeRestaurant: commandeRestaurant,
                //           ),
                //         ),
                //       );
                //     },
                //     child: const Text(
                //       'Voir le ticket',
                //       textAlign: TextAlign.center,
                //     ),
                //   ),
                // ),
                const Spacer(),
                Text('File d\'attente: ${printerState.queue}')
              ],
            ),
          ),
          printerState.loadInit
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white.withOpacity(0.4),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
