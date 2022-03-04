// ignore: file_names
// ignore: file_names
// ignore_for_file: camel_case_types, file_names, duplicate_ignore

abstract class almunir_state{}
class almunirInitstate extends almunir_state{}
class almunirSuccessstate extends almunir_state{}

class almunirLoadingstate extends almunir_state{}
class almunirErrorstate extends almunir_state{
  late final String error;
  almunirErrorstate(
      this.error
      );


}
class onedetailsLoadingstate extends almunir_state{}
class onedetailsErrorstate extends almunir_state{
  late final String error;
  onedetailsErrorstate(
      this.error
      );


}
class onedetailsSuccessstate extends almunir_state{}
class isconnectedstate extends almunir_state{}
class isnotcectedstate extends almunir_state{}



