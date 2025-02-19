import 'package:flutter/material.dart';

class CallendarEventCard extends StatefulWidget {
  final double? height; //TO DO -> get height based on time
  final String title; //TO DO -> get assignemnt title
  final String location; //TO DO -> get what class the assignemnt is for
  final Color? themeColor; //TO DO -> get color from settings and/or theme
  const CallendarEventCard({super.key, required this.height, required this.title, required this.location, required this.themeColor});

  @override
  _CallendarEventCard createState() => _CallendarEventCard();
}

class _CallendarEventCard extends State<CallendarEventCard>{

  @override
  Widget build(BuildContext context){
    return Card(
      color: widget.themeColor, 
      child: SizedBox(
        height: widget.height, 
        width: 300, //TO DO -> make width match whatever container that it is in
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
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
                    widget.location,
                    style: TextStyle( 
                      color: Colors.white
                    ),
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