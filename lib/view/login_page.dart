import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liberty_printer/state/app_state.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool singInState = false;
  bool notSeePassword = true;
  bool onErrorValue = false;
  TextEditingController emailContoller = TextEditingController();
  TextEditingController passwordContoller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 400,
                decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          'Connectez-vous',
                          style:
                              Theme.of(context).textTheme.headline3!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        subtitle: const Text(
                            'Utilisez votre nom d\'utilisateur et votre mot de passe (identique à celui du compte du restaurant) pour vous connecter a Liberty Printer.'),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: TextFormField(
                          controller: emailContoller,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Email',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez saisir une valeur';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: TextFormField(
                          controller: passwordContoller,
                          obscureText: notSeePassword,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Mot de passe',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  notSeePassword = !notSeePassword;
                                });
                              },
                              icon: Icon(
                                !notSeePassword
                                    ? Icons.remove_red_eye_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              splashRadius: 20,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez saisir une valeur';
                            }
                            return null;
                          },
                          onFieldSubmitted: (value) {
                            if (_formKey.currentState!.validate()) {
                              setState(
                                () {
                                  singInState = true;
                                },
                              );
                              ref
                                  .read(appStateProvider)
                                  .loginWithEmailAndPassword(
                                    emailContoller.value.text,
                                    passwordContoller.value.text,
                                  )
                                  .catchError((onError) {
                                setState(
                                  () {
                                    singInState = false;
                                    onErrorValue = true;
                                  },
                                );
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: !singInState
                              ? () {
                                  if (_formKey.currentState!.validate()) {
                                    setState(
                                      () {
                                        singInState = true;
                                      },
                                    );
                                    ref
                                        .read(appStateProvider)
                                        .loginWithEmailAndPassword(
                                          emailContoller.value.text,
                                          passwordContoller.value.text,
                                        )
                                        .catchError((onError) {
                                      setState(
                                        () {
                                          singInState = false;
                                          onErrorValue = true;
                                        },
                                      );
                                    });
                                  }
                                }
                              : () {},
                          child: !singInState
                              ? const Text('Connexion')
                              : const SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      Visibility(
                        visible: onErrorValue,
                        child: const Text(
                          'Votre email ou mot de passe est incorrect',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Créer un compte'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        width: double.infinity,
        height: 40.0,
        color: Theme.of(context).primaryColor,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '©liberty 2022',
                style: Theme.of(context)
                    .textTheme
                    .headline6!
                    .copyWith(color: Colors.white),
              ),
            ),
            const Spacer(),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                print(snapshot.data!.buildNumber);
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data != null) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'v${snapshot.data!.version} build ${snapshot.data!.buildNumber}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                } else {
                  return const SizedBox.shrink();
                }
                return const SizedBox.shrink();
              },
            )
          ],
        ),
      ),
    );
  }
}
