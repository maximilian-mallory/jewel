/*
Personal Goals Class:
-Creates the information needed for the personal goals
-Stores data in FireBase bassed off the current user
*/

abstract class PersonalGoals{
  //private variables
  String _title = ""; //title of the goal the user sets
  String _description = ""; //description of the goal the user sets
  int _duration = 0; //time the goal took (building for tracking purposes and analytics later)
  bool _completed = false; //determines if the goal has been completed -> eventually used to determine if it should be showed in current goals or archive
  String _category = ""; //Categorizes goals, will have options on goal creation form
  
  //getters and setters
  String get title => _title;
  set title(String title){_title = title;}
  String get description => _description;
  set description(String description){_description = description;}
  int get duration => _duration;
  set duration(int duration){_duration = duration;}
  bool get completed => _completed;
  set completed(bool completed){_completed = completed;}
  String get category => _category;
  set category(String category){_category = category;}

  //constructor(s)
  PersonalGoals(this._title,this._description,this._category,this._completed,this._duration);

  //Tretunrs a Map<String, dynamic> to be put into firebase
  Map<String, dynamic> getMap(){
    Map<String, dynamic> data = {
      'title': _title,
      'description': _description,
      'duration': _duration,
      'completed': _completed,
      'category': _completed
    };
    return data;
  }
}