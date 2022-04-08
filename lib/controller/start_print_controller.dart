import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_star_prnt/flutter_star_prnt.dart';
import 'package:liberty_printer/services/date_format.dart';
import 'package:libertymodel/libertymodel.dart';
import 'dart:ui' as ui;

import 'package:qr_flutter/qr_flutter.dart';

class StarPrinterState with ChangeNotifier {
  List<PortInfo> portsList = [];
  PrintCommands commands = PrintCommands();
  PortInfo? port;
  bool loadInit = true;
  Stream<QuerySnapshot<Map<String, dynamic>>>? commandeStream;
  StreamSubscription? subscription;
  int queue = 0;

  init() async {
    portsList = await StarPrnt.portDiscovery(StarPortType.All);
    loadInit = false;
    notifyListeners();
  }

  List<DropdownMenuItem<PortInfo>> getDevices() {
    List<DropdownMenuItem<PortInfo>> items = [];
    if (portsList.isEmpty) {
      items.add(const DropdownMenuItem(
        child: SizedBox(
          width: 200,
          child: Text(
            'NONE',
            overflow: TextOverflow.fade,
          ),
        ),
      ));
    } else {
      for (var port in portsList) {
        items.add(DropdownMenuItem(
          child: SizedBox(
            width: 200,
            child: Text(
              '${port.modelName!} (${port.portName})',
              overflow: TextOverflow.fade,
            ),
          ),
          value: port,
        ));
      }
    }
    return items;
  }

  setPort(PortInfo? port) {
    this.port = port;
    notifyListeners();
  }

  printTest() async {
    commands.push({'appendBitmapText': "Hello World €"});

    await StarPrnt.sendCommands(
      portName: port!.portName!,
      emulation: 'StarGraphic',
      printCommands: commands,
    );
  }

  createStream(String idRestaurant) {
    commandeStream = FirebaseFirestore.instance
        .collection('print')
        .where('restaurant.id', isEqualTo: idRestaurant)
        .where('printed', isEqualTo: false)
        .snapshots();
    notifyListeners();
  }

  listenCommands(String idRestaurant) {
    if (commandeStream == null) {
      createStream(idRestaurant);
    }
    subscription = commandeStream!.listen((event) async {
      setQueue(event.docs.length);
      await Future.forEach(event.docs,
          (QueryDocumentSnapshot<Map<String, dynamic>> element) async {
        await printTicket(CommandeRestaurant.fromJson(element.data()));
        FirebaseFirestore.instance.collection('print').doc(element.id).delete();
      });
    });
    notifyListeners();
  }

  setQueue(int queue) {
    this.queue = queue;
    notifyListeners();
  }

  disposeSubscription() {
    if (subscription != null) {
      subscription!.cancel();
      subscription = null;
      notifyListeners();
    }
  }

  Map<String, dynamic> generateWidgets(CommandeRestaurant commandeRestaurant) {
    num prix = 0;
    Widget widgetHeader = generateHeader(commandeRestaurant);
    List<Widget> widgetMenuList =
        commandeRestaurant.restaurantCommande.map((e) {
      if (e.prix != null) {
        prix = prix + e.prix!;
      }
      return generateMenu(e);
    }).toList();
    Widget widgetFooter = generateFooter(commandeRestaurant, prix);
    return {
      'prix': prix,
      'widgetHeader': widgetHeader,
      'widgetMenuList': widgetMenuList,
      'widgetFooter': widgetFooter
    };
  }

  printTicket(CommandeRestaurant commandeRestaurant) async {
    List current = commands.getCommands();
    if (current.isNotEmpty) {
      commands.clear();
    }

    Map<String, dynamic> dataWidgets = generateWidgets(commandeRestaurant);

    Uint8List? bytesHeader =
        await createImageFromWidget(dataWidgets['widgetHeader']);
    Uint8List? bytesFooter =
        await createImageFromWidget(dataWidgets['widgetFooter']);
    List<Uint8List?> bytesMenuList = [];
    await Future.forEach(dataWidgets['widgetMenuList'], (Widget element) async {
      Uint8List? bytesMenu = await createImageFromWidget(element);
      bytesMenuList.add(bytesMenu);
    });

    bytesHeader != null
        ? commands.appendBitmapByte(byteData: bytesHeader, width: 600)
        : null;
    for (var element in bytesMenuList) {
      if (element != null) {
        commands.appendBitmapByte(byteData: element, width: 600);
      }
    }
    bytesFooter != null
        ? commands.appendBitmapByte(byteData: bytesFooter, width: 600)
        : null;
    commands.appendCutPaper(StarCutPaperAction.PartialCutWithFeed);

    await StarPrnt.sendCommands(
      portName: port!.portName!,
      emulation: 'StarGraphic',
      printCommands: commands,
    );
  }

  Future<Uint8List?> createImageFromWidget(
    Widget widget, {
    Duration? wait,
    Size? logicalSize,
    Size? imageSize,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

    logicalSize ??= ui.window.physicalSize / ui.window.devicePixelRatio;
    imageSize ??= ui.window.physicalSize;
    assert(logicalSize.aspectRatio == imageSize.aspectRatio);
    final RenderView renderView = RenderView(
      window: WidgetsFlutterBinding.ensureInitialized()
          .platformDispatcher
          .views
          .first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        size: logicalSize,
        devicePixelRatio: 1.0,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement =
        RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: textDirection,
        child: IntrinsicHeight(child: widget),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);

    buildOwner
      ..buildScope(rootElement)
      ..finalizeTree();

    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();

    final ui.Image image = await repaintBoundary.toImage(
      pixelRatio: imageSize.width / logicalSize.width,
    );
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }
}

final starPrinterStateProvider =
    ChangeNotifierProvider<StarPrinterState>((ref) {
  return StarPrinterState();
});

Widget generateHeader(CommandeRestaurant commandeRestaurant) {
  return SizedBox(
    width: 500,
    child: Column(
      children: [
        const Align(
          alignment: Alignment.center,
          child: Text(
            'LI-BERTY',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: Colors.black,
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            commandeRestaurant.restaurant.nom != null
                ? commandeRestaurant.restaurant.nom!
                : '',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.normal,
              fontSize: 36,
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        const Divider(),
        const SizedBox(
          height: 10,
        ),
        RichText(
          text: TextSpan(
            text: 'N° commande: ',
            style: const TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.w300),
            children: [
              TextSpan(
                text: '#${commandeRestaurant.id.substring(0, 4).toString()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Date : ${FormatDate().formatTicket(commandeRestaurant.date)}',
          style: const TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.w300),
        ),
        const SizedBox(
          height: 10,
        ),
        const Divider(),
        const SizedBox(
          height: 10,
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            commandeRestaurant.livraisonStatus != null
                ? 'Livraison'
                : 'Emporter',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black, fontSize: 28),
          ),
        ),
        const Text(
          'Detail :',
          style: TextStyle(color: Colors.black, fontSize: 26),
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    ),
  );
}

Widget generateMenu(CommandeRestaurantPanier menu) {
  List<RestaurantProduit>? sousMenuRequis = menu.listRestaurantProduitRequis;
  List<RestaurantProduit>? sousMenu = menu.listRestaurantProduit;
  return SizedBox(
    width: 500,
    child: Column(
      children: [
        const SizedBox(
          height: 10,
        ),
        Table(
          columnWidths: const {
            0: FixedColumnWidth(40),
            2: FixedColumnWidth(75),
          },
          children: [
            TableRow(
              children: [
                Text(
                  menu.quantite.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  menu.menu!.nom,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                  ),
                ),
                Text(
                  '${menu.prix.toString()}€',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                  ),
                )
              ],
            ),
          ],
        ),
        sousMenuRequis != null
            ? Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(40),
                    2: FixedColumnWidth(75),
                  },
                  children: sousMenuRequis
                      .map(
                        (elementSousMenuRequis) => TableRow(
                          children: [
                            const SizedBox.shrink(),
                            Text(
                              elementSousMenuRequis.nom!,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox.shrink(),
                          ],
                        ),
                      )
                      .toList(),
                ),
              )
            : const SizedBox.shrink(),
        sousMenu != null
            ? Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(40),
                    2: FixedColumnWidth(75),
                  },
                  children: sousMenu
                      .map(
                        (elementSousMenu) => TableRow(
                          children: [
                            const SizedBox.shrink(),
                            Text(
                              elementSousMenu.nom!,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox.shrink(),
                          ],
                        ),
                      )
                      .toList(),
                ),
              )
            : const SizedBox.shrink(),
        const SizedBox(
          height: 10,
        ),
      ],
    ),
  );
}

Widget generateFooter(CommandeRestaurant commandeRestaurant, prix) {
  return SizedBox(
    width: 500,
    child: Column(
      children: [
        const Divider(),
        const SizedBox(
          height: 10,
        ),
        Text(
          'Total : $prix€',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w300,
          ),
        ),
        Text(
          'Client : ${commandeRestaurant.client.nom}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w300,
          ),
        ),
        if (commandeRestaurant.livreur != null) ...[
          const SizedBox(
            height: 10,
          ),
          const Divider(),
          const SizedBox(
            height: 10,
          ),
          Text(
            'Livreur : ${commandeRestaurant.livreur!.nom}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: QrImage(data: commandeRestaurant.id),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          commandeRestaurant.codeValidation != null
              ? RichText(
                  text: TextSpan(
                    text: 'Code de validation : ',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                    children: [
                      TextSpan(
                        text: commandeRestaurant.codeValidation,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          const SizedBox(
            height: 10,
          ),
        ]
      ],
    ),
  );
}
