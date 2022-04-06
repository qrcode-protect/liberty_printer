import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liberty_printer/controller/print_controller.dart';
import 'package:liberty_printer/controller/start_print_controller.dart';
import 'package:liberty_printer/state/app_state.dart';
import 'package:liberty_printer/view/print_page.dart';
import 'package:liberty_printer/view/star_print_page.dart';

class ChoicePage extends ConsumerWidget {
  const ChoicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Quelle est votre imprimante',
            style: Theme.of(context).textTheme.headline3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 25,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: 150,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StarPrintPage(),
                      ),
                    );
                  },
                  child: const Text('Star Micronics'),
                ),
              ),
              SizedBox(
                width: 150,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PrintPage(),
                      ),
                    );
                  },
                  child: const Text('Autre'),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 50,
          ),
          SizedBox(
            width: 150,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                ref.read(appStateProvider).signOut();
                ref.read(printerStateProvider).disposeSubscription();
                ref.read(starPrinterStateProvider).disposeSubscription();
              },
              child: const Text('Deconnexion'),
            ),
          ),
        ],
      ),
    );
  }
}
