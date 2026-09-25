const assistanceTypes = <String>[
  'Hospital Assistance',
  'Funeral Assistance',
  'Procedure',
  'Laboratory',
  'Dialysis',
  'Apparatus',
];

const legacyMedicineAssistanceType = 'Medicine Assistance';

const legacyMedicineAssistanceNotice =
    'This is a historical Medicine Assistance request. Medicine Assistance '
    'is no longer available for new applications. You can still view this record.';

bool isSupportedAssistanceType(Object? value) =>
    value is String && assistanceTypes.contains(value.trim());
