class WalletRecord {
  final String id;
  final String owner;
  final String type; // 'credential', 'id_card', 'card'
  final String title;
  final String textValue;
  final String savedAt;

  // Credential specific
  final String? credBankName;
  final String? credUsername;
  final String? credLoginPassword;
  final String? credTPassOrPin;
  final String? credChannel;
  final String? credCardPin;
  final String? credStatus;

  // ID Card specific
  final String? idType;
  final String? idNumber;
  final String? idName;
  final String? validFrom;
  final String? validTo;

  // Payment Card specific
  final String? cardLabel;
  final String? cardNumber;
  final String? cardExpiry;
  final String? cardCvv;
  final String? cardHolder;

  WalletRecord({
    required this.id,
    required this.owner,
    required this.type,
    required this.title,
    this.textValue = '',
    required this.savedAt,
    this.credBankName,
    this.credUsername,
    this.credLoginPassword,
    this.credTPassOrPin,
    this.credChannel,
    this.credCardPin,
    this.credStatus,
    this.idType,
    this.idNumber,
    this.idName,
    this.validFrom,
    this.validTo,
    this.cardLabel,
    this.cardNumber,
    this.cardExpiry,
    this.cardCvv,
    this.cardHolder,
  });

  factory WalletRecord.fromJson(Map<String, dynamic> json) {
    return WalletRecord(
      id: json['id']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? json['credBankName']?.toString() ?? json['cardLabel']?.toString() ?? json['idType']?.toString() ?? '',
      textValue: json['textValue']?.toString() ?? '',
      savedAt: json['savedAt']?.toString() ?? json['timestamp']?.toString() ?? '',
      credBankName: json['credBankName']?.toString(),
      credUsername: json['credUsername']?.toString(),
      credLoginPassword: json['credLoginPassword']?.toString(),
      credTPassOrPin: json['credTPassOrPin']?.toString(),
      credChannel: json['credChannel']?.toString(),
      credCardPin: json['credCardPin']?.toString(),
      credStatus: json['credStatus']?.toString(),
      idType: json['idType']?.toString(),
      idNumber: json['idNumber']?.toString(),
      idName: json['idName']?.toString(),
      validFrom: json['validFrom']?.toString(),
      validTo: json['validTo']?.toString(),
      cardLabel: json['cardLabel']?.toString(),
      cardNumber: json['cardNumber']?.toString(),
      cardExpiry: json['cardExpiry']?.toString(),
      cardCvv: json['cardCvv']?.toString(),
      cardHolder: json['cardHolder']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner': owner,
      'type': type,
      'title': title,
      'textValue': textValue,
      'savedAt': savedAt,
      if (credBankName != null) 'credBankName': credBankName,
      if (credUsername != null) 'credUsername': credUsername,
      if (credLoginPassword != null) 'credLoginPassword': credLoginPassword,
      if (credTPassOrPin != null) 'credTPassOrPin': credTPassOrPin,
      if (credChannel != null) 'credChannel': credChannel,
      if (credCardPin != null) 'credCardPin': credCardPin,
      if (credStatus != null) 'credStatus': credStatus,
      if (idType != null) 'idType': idType,
      if (idNumber != null) 'idNumber': idNumber,
      if (idName != null) 'idName': idName,
      if (validFrom != null) 'validFrom': validFrom,
      if (validTo != null) 'validTo': validTo,
      if (cardLabel != null) 'cardLabel': cardLabel,
      if (cardNumber != null) 'cardNumber': cardNumber,
      if (cardExpiry != null) 'cardExpiry': cardExpiry,
      if (cardCvv != null) 'cardCvv': cardCvv,
      if (cardHolder != null) 'cardHolder': cardHolder,
    };
  }
}
