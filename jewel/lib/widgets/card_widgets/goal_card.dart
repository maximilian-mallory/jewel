import 'package:flutter/material.dart';

class GoalCard extends StatefulWidget {
  final String title; //TO DO -> get assignemnt title
  final String description; //TO DO -> get what class the assignemnt is for
  final Color? themeColor; //TO DO -> get color from settings and/or theme
  const GoalCard({super.key, required this.title, required this.description, required this.themeColor});

  @override
  _GoalCard createState() => _GoalCard();
}

class _GoalCard extends State<GoalCard>{

  @override
  Widget build(BuildContext context){
    return Card(
      color: widget.themeColor, 
      child: SizedBox(
        width: 300, //TO DO -> make width match whatever container that it is in
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column( 
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[                  
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: Colors.white, 
                      fontSize: 15
                    ),
                  ), 
                  Text(
                    widget.description,
                    style: TextStyle( 
                      color: Colors.white
                    ),
                    softWrap: true,
                  ), 
                ],
              ),
            ],
          ),
        ),
      )
    );
  }
}