import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liberty_printer/controller/start_print_controller.dart';
import 'package:libertymodel/libertymodel.dart';

class TestViewTicket extends ConsumerWidget {
  const TestViewTicket({Key? key, required this.commandeRestaurant})
      : super(key: key);
  final CommandeRestaurant commandeRestaurant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printerState = ref.watch(starPrinterStateProvider);
    Map<String, dynamic> dataWidgets =
        printerState.generateWidgets(commandeRestaurant);
    List<Widget> listMenu = dataWidgets['widgetMenuList'] as List<Widget>;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vue du ticket'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            dataWidgets['widgetHeader'],
            ...listMenu,
            dataWidgets['widgetFooter'],
          ],
        ),
      ),
    );
  }
}
