import 'package:json_annotation/json_annotation.dart';

part 'utilisateur.g.dart';

@JsonSerializable()
class Utilisateur {
  Utilisateur({
    required this.id,
    required this.nom,
    required this.email,
    required this.phone,
    required this.token,
    required this.avatar,
    this.idRestaurant,
  });
  final String id;
  final String nom;
  final String email;
  final int phone;
  final String token;
  final String avatar;
  String? idRestaurant;

  factory Utilisateur.fromJson(Map<String, dynamic> json) =>
      _$UtilisateurFromJson(json);

  Map<String, dynamic> toJson() => _$UtilisateurToJson(this);

  @override
  String toString() {
    return '{id: $id, nom: $nom, email: $email,phone: $phone, token: $token, avatar: $avatar,idRestaurant: $idRestaurant, }';
  }
}
