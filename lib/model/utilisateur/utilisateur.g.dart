// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'utilisateur.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Utilisateur _$UtilisateurFromJson(Map json) => Utilisateur(
      id: json['id'] as String,
      nom: json['nom'] as String,
      email: json['email'] as String,
      phone: json['phone'] as int,
      token: json['token'] as String,
      avatar: json['avatar'] as String,
      idRestaurant: json['idRestaurant'] as String?,
    );

Map<String, dynamic> _$UtilisateurToJson(Utilisateur instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'email': instance.email,
      'phone': instance.phone,
      'token': instance.token,
      'avatar': instance.avatar,
      'idRestaurant': instance.idRestaurant,
    };
