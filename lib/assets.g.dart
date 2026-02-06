// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assets.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CharacterInfo _$CharacterInfoFromJson(Map<String, dynamic> json) =>
    CharacterInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      panelType: json['panelType'] as String,
      species: json['species'] as String,
      tags: json['tags'] as List<dynamic>,
      traits: (json['traits'] as List<dynamic>)
          .map((e) => TraitInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      skills: (json['skills'] as List<dynamic>)
          .map((e) => SkillInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      quote: json['quote'] as String?,
      belonging: json['belonging'] as String?,
      designer: json['designer'] as String?,
    );

Map<String, dynamic> _$CharacterInfoToJson(CharacterInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'panelType': instance.panelType,
      'species': instance.species,
      'tags': instance.tags,
      'traits': instance.traits,
      'skills': instance.skills,
      'quote': instance.quote,
      'belonging': instance.belonging,
      'designer': instance.designer,
    };

TraitInfo _$TraitInfoFromJson(Map<String, dynamic> json) => TraitInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
);

Map<String, dynamic> _$TraitInfoToJson(TraitInfo instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
};

SkillInfo _$SkillInfoFromJson(Map<String, dynamic> json) => SkillInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  availableTiming: json['availableTiming'] as String?,
  cd: (json['cd'] as num?)?.toInt(),
  cost: (json['cost'] as num?)?.toInt(),
  comments: json['comments'] as String?,
);

Map<String, dynamic> _$SkillInfoToJson(SkillInfo instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'availableTiming': instance.availableTiming,
  'cd': instance.cd,
  'cost': instance.cost,
  'comments': instance.comments,
};

CardInfo _$CardInfoFromJson(Map<String, dynamic> json) => CardInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  tags: json['tags'] as List<dynamic>,
);

Map<String, dynamic> _$CardInfoToJson(CardInfo instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'tags': instance.tags,
};

StatusInfo _$StatusInfoFromJson(Map<String, dynamic> json) => StatusInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  type: (json['type'] as num).toInt(),
  description: json['description'] as String,
  hasIntensity: json['hasIntensity'] as bool,
  hasStack: json['hasStack'] as bool,
  stackable: json['stackable'] as bool?,
  decayOverTurn: json['decayOverTurn'] as bool,
  comments: json['comments'] as String?,
);

Map<String, dynamic> _$StatusInfoToJson(StatusInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'description': instance.description,
      'hasIntensity': instance.hasIntensity,
      'hasStack': instance.hasStack,
      'stackable': instance.stackable,
      'decayOverTurn': instance.decayOverTurn,
      'comments': instance.comments,
    };
