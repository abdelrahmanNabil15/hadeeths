import 'package:equatable/equatable.dart';

/// A recording of the adhan the user can download and use as the sound of the prayer reminders.
///
/// The app ships none of them: each is fetched from [url] only when the user asks, and kept on
/// the phone. Rights to these recordings belong to their publishers; see `docs/ADHAN_SOUNDS.md`.
class AdhanSound extends Equatable {
  const AdhanSound({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.url,
    required this.bytes,
    this.placeAr,
    this.placeEn,
  });

  /// Stable, file-name safe. Also the name of the file and of the sound in the phone's list.
  final String id;
  final String nameAr;
  final String nameEn;
  final String? placeAr;
  final String? placeEn;
  final String url;

  /// The size of the file when it was listed. Used for the size shown to the user and to refuse a
  /// download that is far from it (a wrong or replaced file).
  final int bytes;

  String name(bool arabic) => arabic ? nameAr : nameEn;

  String? place(bool arabic) => arabic ? placeAr : placeEn;

  @override
  List<Object?> get props => [id, nameAr, nameEn, placeAr, placeEn, url, bytes];
}

/// Who credits the recordings come from, shown on the page.
const adhanSource = 'assabile.com';

/// The recordings offered. Names and places are as supplied by the owner.
const adhanCatalogue = <AdhanSound>[
  AdhanSound(
    id: 'tokhi',
    nameAr: 'محمود الطوخي',
    nameEn: 'Mahmoud al-Tokhi',
    placeAr: 'مسجد الرفاعي، القاهرة، مصر',
    placeEn: 'Al-Rifai Mosque, Cairo, Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/bdf9f3101b4c.mp3',
    bytes: 3174554,
  ),
  AdhanSound(
    id: 'rifaat',
    nameAr: 'محمد رفعت',
    nameEn: 'Muhammad Rifaat',
    placeAr: 'القاهرة، مصر',
    placeEn: 'Cairo, Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/d8a3a72860e8.mp3',
    bytes: 411318,
  ),
  AdhanSound(
    id: 'abdulbasit',
    nameAr: 'عبد الباسط عبد الصمد',
    nameEn: 'Abdul Basit Abdus Samad',
    placeAr: 'القاهرة، مصر',
    placeEn: 'Cairo, Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/02f1bec971bb.mp3',
    bytes: 405582,
  ),
  AdhanSound(
    id: 'haddad',
    nameAr: 'أحمد الحداد',
    nameEn: 'Ahmed al-Haddad',
    url: 'https://media.assabile.com/assabile/adhan_3435370/f30b7631d625.mp3',
    bytes: 2477560,
  ),
  AdhanSound(
    id: 'mulla',
    nameAr: 'علي بن أحمد ملا',
    nameEn: 'Ali bin Ahmed Mulla',
    placeAr: 'الحرم المكي، مكة المكرمة، السعودية',
    placeEn: 'Masjid al-Haram, Makkah, Saudi Arabia',
    url: 'https://media.assabile.com/assabile/adhan_3435370/a4ab138564ce.mp3',
    bytes: 409088,
  ),
];

/// The recording with this [id], or null.
AdhanSound? adhanById(String? id) {
  for (final sound in adhanCatalogue) {
    if (sound.id == id) return sound;
  }
  return null;
}
