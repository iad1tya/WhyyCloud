part of 'message_model.dart';

class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override
  final int typeId = 2;

  @override
  MessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageModel(
      role: fields[0] as MessageRole,
      content: fields[1] as String,
      timestamp: fields[2] as DateTime?,
      imageBase64: fields[3] as String?,
      imageMimeType: fields[4] as String?,
      attachmentName: fields[5] as String?,
      attachmentPath: fields[6] as String?,
      attachmentMimeType: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.role)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.imageBase64)
      ..writeByte(4)
      ..write(obj.imageMimeType)
      ..writeByte(5)
      ..write(obj.attachmentName)
      ..writeByte(6)
      ..write(obj.attachmentPath)
      ..writeByte(7)
      ..write(obj.attachmentMimeType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageRoleAdapter extends TypeAdapter<MessageRole> {
  @override
  final int typeId = 1;

  @override
  MessageRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageRole.user;
      case 1:
        return MessageRole.assistant;
      case 2:
        return MessageRole.system;
      default:
        return MessageRole.user;
    }
  }

  @override
  void write(BinaryWriter writer, MessageRole obj) {
    switch (obj) {
      case MessageRole.user:
        writer.writeByte(0);
        break;
      case MessageRole.assistant:
        writer.writeByte(1);
        break;
      case MessageRole.system:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
