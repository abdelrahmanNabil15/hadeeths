// ignore: file_names
// ignore: file_names
// ignore: camel_case_types
// ignore_for_file: file_names, duplicate_ignore, camel_case_types

class detailsModel {
  late String id;
  late String title;
  late String hadeeth;
  late String attribution;
  late String grade;
  late String explanation;
  late List<String> hints;
  late List<String> categories;
  late List<String> translations;
  late List<WordsMeanings> wordsMeanings;
  late String reference;

  detailsModel.fromJson(Map<String, dynamic> json) {
    id = json['id']??"0";
    title = json['title']??"";
    hadeeth = json['hadeeth']??"";
    attribution = json['attribution']??"";
    grade = json['grade']??"";
    explanation = json['explanation']??"";
    hints = json['hints'].cast<String>()??[];
    categories = json['categories'].cast<String>()??[];
    translations = json['translations'].cast<String>()??[];
    if (json['words_meanings'] != null) {
      wordsMeanings = <WordsMeanings>[];
      json['words_meanings'].forEach((v) {
        wordsMeanings.add( WordsMeanings.fromJson(v));
      });
    }
    reference = json['reference'];
  }




}

class WordsMeanings {
 late String word;
  late String meaning;



  WordsMeanings.fromJson(Map<String, dynamic> json) {
    word = json['word']??"";
    meaning = json['meaning'] ??"";
  }
}
