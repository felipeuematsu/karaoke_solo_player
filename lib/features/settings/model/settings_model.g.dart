// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsModelImpl _$$SettingsModelImplFromJson(Map<String, dynamic> json) =>
    _$SettingsModelImpl(
      downloadsPath: json['downloadsPath'] as String?,
      paths: (json['paths'] as List<dynamic>?)
          ?.map((e) => RepositoryPathModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      installationPath: json['installationPath'] as String?,
    );

Map<String, dynamic> _$$SettingsModelImplToJson(_$SettingsModelImpl instance) =>
    <String, dynamic>{
      'downloadsPath': instance.downloadsPath,
      'paths': instance.paths,
      'installationPath': instance.installationPath,
    };
