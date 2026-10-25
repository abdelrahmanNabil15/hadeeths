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

  // Added with the owner's go-ahead on assabile.com's recordings (see docs/ADHAN_SOUNDS.md): one
  // recording per reciter from the Masjid al-Haram, Masjid an-Nabawi, Al-Aqsa, Saudi Arabia and
  // Egypt pages. Where a reciter has several recordings there, one was kept.
  AdhanSound(
    id: 'ramadansaad',
    nameAr: 'محمد رمضان سعد',
    nameEn: 'Muhammad Ramadan Saad',
    placeAr: 'الحرم المكي، مكة المكرمة، السعودية',
    placeEn: 'Masjid al-Haram, Makkah, Saudi Arabia',
    url: 'https://media.assabile.com/assabile/adhan_3435370/e9bb86af0d30.mp3',
    bytes: 3515711,
  ),
  AdhanSound(
    id: 'khalilramal',
    nameAr: 'محمد خليل رمل',
    nameEn: 'Muhammad Khalil Ramal',
    placeAr: 'الحرم المكي، مكة المكرمة، السعودية',
    placeEn: 'Masjid al-Haram, Makkah, Saudi Arabia',
    url: 'https://media.assabile.com/assabile/adhan_3435370/c7ba5fb672b3.mp3',
    bytes: 383744,
  ),
  AdhanSound(
    id: 'nayeffeda',
    nameAr: 'نايف صالح فيده',
    nameEn: 'Nayef Saleh Feda',
    placeAr: 'الحرم المكي، مكة المكرمة، السعودية',
    placeEn: 'Masjid al-Haram, Makkah, Saudi Arabia',
    url: 'https://media.assabile.com/assabile/adhan_3435370/7f701468a8dc.mp3',
    bytes: 421256,
  ),
  AdhanSound(
    id: 'hadrawi',
    nameAr: 'فاروق عبد الرحمن حضراوي',
    nameEn: 'Farouk Abdul Rahman Hadrawi',
    placeAr: 'الحرم المكي، مكة المكرمة، السعودية',
    placeEn: 'Masjid al-Haram, Makkah, Saudi Arabia',
    url: 'https://media.assabile.com/assabile/adhan_3435370/1aadb2df7d5c.mp3',
    bytes: 559496,
  ),
  AdhanSound(
    id: 'bukhari',
    nameAr: 'عصام بخاري',
    nameEn: 'Issam Bukhari',
    placeAr: 'الحرم المدني، المدينة المنورة، السعودية',
    placeEn: 'Masjid an-Nabawi, Madinah, Saudi Arabia',
    url: 'https://media.assabile.com/assabile/adhan_3435370/7487fa449eeb.mp3',
    bytes: 563672,
  ),
  AdhanSound(
    id: 'maghribi',
    nameAr: 'نور الدين حمزة المغربي',
    nameEn: 'Nour El-Din Hamza Al-Maghribi',
    placeAr: 'المسجد الأقصى، القدس، فلسطين',
    placeEn: 'Al-Aqsa Mosque, Jerusalem, Palestine',
    url: 'https://media.assabile.com/assabile/adhan_3435370/768559b47c2e.mp3',
    bytes: 370280,
  ),
  AdhanSound(
    id: 'qazzaz',
    nameAr: 'ناجي قزاز',
    nameEn: 'Naji Qazzaz',
    placeAr: 'المسجد الأقصى، القدس، فلسطين',
    placeEn: 'Al-Aqsa Mosque, Jerusalem, Palestine',
    url: 'https://media.assabile.com/assabile/adhan_3435370/c888cbd50d15.mp3',
    bytes: 452864,
  ),
  AdhanSound(
    id: 'alobaid',
    nameAr: 'ناصر العبيد',
    nameEn: 'Nasser Al-Obaid',
    placeAr: 'السعودية',
    placeEn: 'Saudi Arabia',
    url: 'https://media.assabile.com/assabile/adhan_3435370/c81e4e141865.mp3',
    bytes: 4810608,
  ),
  AdhanSound(
    id: 'baloul',
    nameAr: 'حسن صلاح بعلول',
    nameEn: 'Hassan Salah Baloul',
    placeAr: 'السعودية',
    placeEn: 'Saudi Arabia',
    url: 'https://media.assabile.com/assabile/adhan_3435370/a031983fa2b6.mp3',
    bytes: 2975109,
  ),
  AdhanSound(
    id: 'dughariri',
    nameAr: 'حمد الدغريري',
    nameEn: 'Hamad Al-Dughariri',
    placeAr: 'السعودية',
    placeEn: 'Saudi Arabia',
    url: 'https://media.assabile.com/assabile/adhan_3435370/08008b8fec6c.mp3',
    bytes: 3078763,
  ),
  AdhanSound(
    id: 'aldosari',
    nameAr: 'ياسر الدوسري',
    nameEn: 'Yasser Al-Dosari',
    placeAr: 'السعودية',
    placeEn: 'Saudi Arabia',
    url: 'https://media.assabile.com/assabile/adhan_3435370/f5370aa1a7e2.mp3',
    bytes: 1462921,
  ),
  AdhanSound(
    id: 'alqatami',
    nameAr: 'ناصر القطامي',
    nameEn: 'Nasser Al-Qatami',
    placeAr: 'الرياض، السعودية',
    placeEn: 'Riyadh, Saudi Arabia',
    url: 'https://media.assabile.com/assabile/adhan_3435370/d3aa494b7320.mp3',
    bytes: 2176705,
  ),
  AdhanSound(
    id: 'almaliki',
    nameAr: 'حمدان المالكي',
    nameEn: 'Hamdan Al-Maliki',
    placeAr: 'جامع الملك فهد، نجران، السعودية',
    placeEn: 'King Fahd Mosque, Najran, Saudi Arabia',
    url: 'https://media.assabile.com/assabile/adhan_3435370/2bdf5fda46cf.mp3',
    bytes: 4271573,
  ),
  AdhanSound(
    id: 'ismailalsheikh',
    nameAr: 'إسماعيل الشيخ',
    nameEn: 'Ismail Al-Sheikh',
    placeAr: 'مصر',
    placeEn: 'Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/6734c28f3a2d.mp3',
    bytes: 1609060,
  ),
  AdhanSound(
    id: 'abdelmobdi',
    nameAr: 'عبد المنعم عبد المبدئ',
    nameEn: 'Abdel Moneim Abdel Mobdi',
    placeAr: 'مصر',
    placeEn: 'Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/c3460e1ab635.mp3',
    bytes: 712147,
  ),
  AdhanSound(
    id: 'imranmansour',
    nameAr: 'عمران منصور',
    nameEn: 'Imran Mansour',
    placeAr: 'مصر',
    placeEn: 'Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/68b0e4999e85.mp3',
    bytes: 654560,
  ),
  AdhanSound(
    id: 'aldahabi',
    nameAr: 'عبد الله الذهبي',
    nameEn: 'Abdullah Al-Dahabi',
    placeAr: 'مصر',
    placeEn: 'Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/c2f802f38c47.mp3',
    bytes: 4352156,
  ),
  AdhanSound(
    id: 'aburaheeq',
    nameAr: 'إبراهيم جبر أبو رحيق',
    nameEn: 'Ibrahim Jabr Abu Raheeq',
    placeAr: 'مصر',
    placeEn: 'Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/e37acc95ebe1.mp3',
    bytes: 4708955,
  ),
  AdhanSound(
    id: 'alminshawi',
    nameAr: 'محمد صديق المنشاوي',
    nameEn: 'Muhammad Siddiq Al-Minshawi',
    placeAr: 'مصر',
    placeEn: 'Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/5771e6a59f2b.mp3',
    bytes: 503264,
  ),
  AdhanSound(
    id: 'hammoud',
    nameAr: 'محمد حمود',
    nameEn: 'Muhammad Hammoud',
    placeAr: 'مسجد عمر بن الخطاب، كولومبيا',
    placeEn: 'Omar ibn al-Khattab Mosque, Colombia',
    url: 'https://media.assabile.com/assabile/adhan_3435370/f579c205b4b7.mp3',
    bytes: 2788240,
  ),
  AdhanSound(
    id: 'ahmedali',
    nameAr: 'أحمد علي',
    nameEn: 'Ahmed Ali',
    placeAr: 'مصر',
    placeEn: 'Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/f77eba62a35f.mp3',
    bytes: 3370652,
  ),
  AdhanSound(
    id: 'mustafaismail',
    nameAr: 'مصطفى إسماعيل',
    nameEn: 'Mustafa Ismail',
    placeAr: 'مصر',
    placeEn: 'Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/dd5f42239b71.mp3',
    bytes: 739896,
  ),
  AdhanSound(
    id: 'alhussary',
    nameAr: 'محمود خليل الحصري',
    nameEn: 'Mahmoud Khalil Al-Hussary',
    placeAr: 'القاهرة، مصر',
    placeEn: 'Cairo, Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/cdb24a4bd658.mp3',
    bytes: 258926,
  ),
  AdhanSound(
    id: 'shuaisha',
    nameAr: 'ابو العينين شعيشع',
    nameEn: 'Abu Al-Ainain Shuaisha',
    placeAr: 'القاهرة، مصر',
    placeEn: 'Cairo, Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/414827669391.mp3',
    bytes: 477002,
  ),
  AdhanSound(
    id: 'naina',
    nameAr: 'أحمد نعينع',
    nameEn: 'Ahmed Naina',
    placeAr: 'القاهرة، مصر',
    placeEn: 'Cairo, Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/da48b2a26635.mp3',
    bytes: 424140,
  ),
  AdhanSound(
    id: 'albanna',
    nameAr: 'محمود علي البنا',
    nameEn: 'Mahmoud Ali Al-Banna',
    placeAr: 'القاهرة، مصر',
    placeEn: 'Cairo, Egypt',
    url: 'https://media.assabile.com/assabile/adhan_3435370/48f9d6984758.mp3',
    bytes: 335954,
  ),
];

/// The recording with this [id], or null.
AdhanSound? adhanById(String? id) {
  for (final sound in adhanCatalogue) {
    if (sound.id == id) return sound;
  }
  return null;
}
