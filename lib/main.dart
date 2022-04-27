import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:liberty_printer/state/app_state.dart';
import 'package:liberty_printer/view/choice_page.dart';
import 'package:liberty_printer/view/login_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liberty Printer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //TODO: release new version apres avoir installé V2
  @override
  Widget build(BuildContext context) {
    Future<AppUpdateInfo?> checkForUpdate() async {
      try {
        return await InAppUpdate.checkForUpdate();
      } catch (e) {
        print(e);
        return null;
      }
    }

    return FutureBuilder<AppUpdateInfo?>(
        future: checkForUpdate(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            print(snapshot);
            print(snapshot.data);
            if (snapshot.hasData && snapshot.data != null) {
              if (snapshot.data!.updateAvailability ==
                  UpdateAvailability.updateAvailable) {
                InAppUpdate.performImmediateUpdate();
              }
            }
            return Consumer(
              builder: (context, ref, _) {
                final appState = ref.watch(appStateProvider);
                return appState.user == null
                    ? const LoginPage()
                    : const ChoicePage();
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }
}
