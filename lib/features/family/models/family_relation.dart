/// The relationship a requester assigns when adding someone to their family,
/// always from the *requester's* point of view (e.g. picking `son` means
/// "you are my son"). The enum name is the stable key persisted to Firestore;
/// the human label is resolved per language at display time so the stored
/// value stays language-independent.
enum FamilyRelation {
  father,
  mother,
  brother,
  sister,
  son,
  daughter,
  husband,
  wife,
  grandfather,
  grandmother,
  other,
}

extension FamilyRelationX on FamilyRelation {
  /// Stable key written to Firestore (`relationship` field).
  String get key => name;

  String label(bool isBangla) {
    switch (this) {
      case FamilyRelation.father:
        return isBangla ? 'বাবা' : 'Father';
      case FamilyRelation.mother:
        return isBangla ? 'মা' : 'Mother';
      case FamilyRelation.brother:
        return isBangla ? 'ভাই' : 'Brother';
      case FamilyRelation.sister:
        return isBangla ? 'বোন' : 'Sister';
      case FamilyRelation.son:
        return isBangla ? 'ছেলে' : 'Son';
      case FamilyRelation.daughter:
        return isBangla ? 'মেয়ে' : 'Daughter';
      case FamilyRelation.husband:
        return isBangla ? 'স্বামী' : 'Husband';
      case FamilyRelation.wife:
        return isBangla ? 'স্ত্রী' : 'Wife';
      case FamilyRelation.grandfather:
        return isBangla ? 'দাদা' : 'Grandfather';
      case FamilyRelation.grandmother:
        return isBangla ? 'দাদি' : 'Grandmother';
      case FamilyRelation.other:
        return isBangla ? 'অন্যান্য' : 'Other';
    }
  }

  /// Label for the *reverse* relationship, shown to the recipient once they
  /// accept. The requester picked this relation from their own point of view
  /// ("you are my father"), so from the recipient's side it is inverted ("they
  /// are my child"). No gender is stored, so the parent role defaults to
  /// Father, and child/sibling/grandchild fall back to neutral terms; spouse
  /// inverts exactly (husband ↔ wife).
  String inverseLabel(bool isBangla) {
    switch (this) {
      case FamilyRelation.father:
      case FamilyRelation.mother:
        return isBangla ? 'সন্তান' : 'Child';
      case FamilyRelation.son:
      case FamilyRelation.daughter:
        return isBangla ? 'বাবা' : 'Father';
      case FamilyRelation.brother:
      case FamilyRelation.sister:
        return isBangla ? 'ভাই-বোন' : 'Sibling';
      case FamilyRelation.husband:
        return isBangla ? 'স্ত্রী' : 'Wife';
      case FamilyRelation.wife:
        return isBangla ? 'স্বামী' : 'Husband';
      case FamilyRelation.grandfather:
      case FamilyRelation.grandmother:
        return isBangla ? 'নাতি-নাতনি' : 'Grandchild';
      case FamilyRelation.other:
        return isBangla ? 'অন্যান্য' : 'Other';
    }
  }
}

/// Resolves a stored key back to a relation, or null when absent/unknown so
/// existing members saved before this feature simply show no relationship.
FamilyRelation? familyRelationFromKey(String? key) {
  final clean = (key ?? '').trim().toLowerCase();
  if (clean.isEmpty) return null;
  for (final r in FamilyRelation.values) {
    if (r.key == clean) return r;
  }
  return null;
}
