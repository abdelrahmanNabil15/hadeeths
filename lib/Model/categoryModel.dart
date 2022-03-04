// ignore: file_names
// ignore_for_file: file_names, duplicate_ignore

class Category {
 late List<Data> data=[];
late  Meta?  meta;




  Category.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data.add(Data.fromJson(v));
      });
    }

    meta = json['meta'] != null ? Meta.fromJson(json['meta']) : null;
  }


}

class Data {
 late String id;
 late String title;
 late List<String> translations;



  Data.fromJson(Map<String, dynamic> json) {
    id = json['id']??0;
    title = json['title']??"";
    translations = json['translations'].cast<String>()??"";
  }


}

class Meta {
 late String currentPage;
 late int lastPage;
 late int totalItems;
 late String perPage;



  Meta.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page']??1;
    lastPage = json['last_page']??1;
    totalItems = json['total_items']??1;
    perPage = json['per_page']??1;
  }


}
