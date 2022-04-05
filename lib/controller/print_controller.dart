import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liberty_printer/services/date_format.dart';
import 'package:libertymodel/libertymodel.dart';

class PrinterState with ChangeNotifier {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  BluetoothDevice? device;
  List<BluetoothDevice> _devices = [];
  bool connected = false;

  PrinterState() {
    initPlatformState();
  }

  setSelectedDevice(BluetoothDevice? selectedDevice) {
    device = selectedDevice;
    notifyListeners();
  }

  Future<void> initPlatformState() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      // TODO - Error
    }

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          connected = true;
          notifyListeners();
          break;
        case BlueThermalPrinter.DISCONNECTED:
          connected = false;
          notifyListeners();
          break;
        default:
          break;
      }
    });

    _devices = devices;
    notifyListeners();
  }

  List<DropdownMenuItem<BluetoothDevice>> getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devices.isEmpty) {
      items.add(const DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      for (var device in _devices) {
        items.add(DropdownMenuItem(
          child: Text(device.name!),
          value: device,
        ));
      }
    }
    return items;
  }

  Future connect() async {
    if (device == null) {
      print('No device selected.');
    } else {
      await bluetooth.isConnected.then((isConnected) async {
        if (!isConnected!) {
          await bluetooth.connect(device!).then((value) {
            print('connected');
          }).catchError((error) {
            print('error');
            print(error);
          });
        }
      });
    }
  }

  Future disconnect() async {
    await bluetooth.disconnect();
    // setState(() => _pressed = true);
  }

  listenCommands(String idRestaurant) {
    Stream<QuerySnapshot<Map<String, dynamic>>> CommandeStream =
        FirebaseFirestore.instance
            .collection('print')
            .where('restaurant.id', isEqualTo: idRestaurant)
            .where('printed', isEqualTo: false)
            .snapshots();
    CommandeStream.listen((event) async {
      await Future.forEach(event.docs,
          (QueryDocumentSnapshot<Map<String, dynamic>> element) async {
        await printTicket(CommandeRestaurant.fromJson(element.data()));
        FirebaseFirestore.instance
            .collection('print')
            .doc(element.id)
            .update({'printed': true});
      });
    });
  }

  printTest() async {
    await bluetooth.isConnected.then((isConnected) async {
      if (isConnected!) {
        await bluetooth.printCustom(
          '******************',
          2,
          1,
        );
        await bluetooth.printCustom(
          '******************',
          2,
          1,
        );
        await bluetooth.printCustom(
          '******************',
          2,
          1,
        );
        await bluetooth.printCustom(
          '******************',
          2,
          1,
        );
        await bluetooth.printCustom(
          '******************',
          2,
          1,
        );
      }
    });
  }

  printTicket(CommandeRestaurant commandeRestaurant) async {
    print('printe !!');
    print(commandeRestaurant.toJson());
    await bluetooth.isConnected.then((isConnected) async {
      if (isConnected!) {
        await bluetooth.printNewLine();
        await bluetooth.printCustom(
          commandeRestaurant.restaurant.nom != null
              ? commandeRestaurant.restaurant.nom!
              : '',
          3,
          0,
        );
        await bluetooth.printNewLine();
        await bluetooth.printLeftRight(
          'Num de commande',
          '#${commandeRestaurant.id.substring(commandeRestaurant.id.length - 5)}',
          1,
        );
        await bluetooth.printLeftRight(
          'Date',
          FormatDate().formatTicket(commandeRestaurant.date),
          1,
        );
        await bluetooth.printNewLine();
        await bluetooth.printLeftRight(
          'Detail',
          commandeRestaurant.livraisonStatus != null ? 'Livraison' : 'Emporter',
          0,
        );
        await bluetooth.printCustom(
          '******************',
          2,
          1,
        );
        num prix = 0;
        await Future.forEach(commandeRestaurant.restaurantCommande,
            (CommandeRestaurantPanier commandePanier) async {
          prix = prix + commandePanier.prix!;
          await bluetooth.printLeftRight(
            '${commandePanier.quantite.toString()}  ${commandePanier.menu!.nom}',
            '${commandePanier.menu!.prix} EUR',
            0,
          );
          if (commandePanier.listRestaurantProduitRequis != null) {
            await Future.forEach(commandePanier.listRestaurantProduitRequis!,
                (RestaurantProduit restaurantProduitRequis) async {
              await bluetooth.printCustom(
                restaurantProduitRequis.nom!,
                0,
                0,
              );
            });
            if (commandePanier.listRestaurantProduit != null) {
              await Future.forEach(commandePanier.listRestaurantProduit!,
                  (RestaurantProduit restaurantProduit) async {
                await bluetooth.printCustom(
                  restaurantProduit.nom!,
                  0,
                  0,
                );
              });
            }
          }
        });
        await bluetooth.printCustom(
          '******************',
          2,
          1,
        );
        await bluetooth.printLeftRight(
          'Total',
          '$prix EUR',
          1,
        );
        await bluetooth.printNewLine();
        await bluetooth.printLeftRight(
          'Client',
          commandeRestaurant.client.nom,
          1,
        );
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.paperCut();
      }
    });
  }
}

final printerStateProvider = ChangeNotifierProvider<PrinterState>((ref) {
  return PrinterState();
});
