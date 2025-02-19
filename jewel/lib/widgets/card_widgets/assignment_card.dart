import 'package:flutter/material.dart';

class AssignmentCard extends StatefulWidget {
  final String title; //TO DO -> get assignemnt title
  final String className; //TO DO -> get what class the assignemnt is for
  final Color? themeColor; //TO DO -> get color from settings and/or theme

  const AssignmentCard({super.key, required this.title, required this.className, required this.themeColor});

  @override
  _AssignmentCard createState() => _AssignmentCard();
}

class _AssignmentCard extends State<AssignmentCard>{



  @override
  Widget build(BuildContext context){
    return Card(
      color: widget.themeColor, 
      child: SizedBox(
        width: 300, //TO DO -> make width match whatever container that it is in
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(0,0,5,0),
                child: Column(
                children: <Widget>[
                  Icon(Icons.school_outlined, color: Colors.white,),
                ],
              ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                child: Column(
                  children: <Widget> [
                    Text(
                      widget.title, 
                      style: 
                        TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Colors.white, 
                          fontSize: 15
                        ),
                    )
                  ]
                )
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 1, 5, 0),
                child: Column(
                  children: <Widget> [
                    Text(
                      widget.className, 
                      style: 
                      TextStyle( 
                        color: Colors.white
                      ),
                    ),
                  ]
                )
              ), 
            ],
          ),
        ),
      )
    );
  }
}