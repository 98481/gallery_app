import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_demo/Gallery.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Manager Demo',
      home: Home(),
    );
  }
}
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  DateTime _startdateTime;
  DateTime _enddateTime;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Container(
        height: MediaQuery.of(context).size.height,
        child: Column(

          children: [
            ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: <Widget>[
                SizedBox(height: 6,),
                Text("Assests Will be displayed between selected Start and End Date ",style:TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
                Container(
                  height:MediaQuery.of(context).size.height/10,
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    children: [
                      Row(

                        children: [
                          Text("StartDate: ",style:TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
                          InkWell(
                            onTap: (){
                              showDatePicker(context: context,
                                  initialDate: _startdateTime==null? DateTime.now():_startdateTime,
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime(2022)).
                              then((value) => setState((){
                                _startdateTime=value;
                              }));
                            },
                            child: Row(
                              children: [

                                Text(_startdateTime==null?'Enter DOB':_startdateTime.toString().split(' ')[0],style:TextStyle(color: Colors.black),),

                                Icon(Icons.date_range,color: Colors.black,),

                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(

                        children: [
                          Text("  EndDate: ",style:TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
                          InkWell(
                            onTap: (){
                              showDatePicker(context: context,
                                  initialDate: _enddateTime==null? DateTime.now():_enddateTime,
                                  firstDate: DateTime(1950),
                                  lastDate:  DateTime.now()).
                              then((value) => setState((){
                                _enddateTime=value;
                              }));
                            },
                            child: Row(
                              children: [

                                Text(_enddateTime==null?'Enter Date':_enddateTime.toString().split(' ')[0],style:TextStyle(color: Colors.black),),

                                Icon(Icons.date_range,color: Colors.black,),

                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                  Container(
                        height: MediaQuery.of(context).size.height*(8/10),
                        width: MediaQuery.of(context).size.width,
                        child: MaterialApp(
                            debugShowCheckedModeBanner: false,
                            theme: ThemeData(
                              primaryColor: Color.fromRGBO(86, 86, 86, 1.00),
                            ),
                            initialRoute: '/W1',
                            routes: {
                              '/W1': (context) => WidgetOne(),
                              '/W2': (context) => WidgetTwo(start:_startdateTime,end: _enddateTime,),
                            })),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class WidgetOne extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) {
              return RaisedButton(
                color: Colors.pinkAccent,
                onPressed: () async {
                  final permitted = await PhotoManager.requestPermission();
                  if (!permitted) return;

                  Navigator.pushNamed(context, '/W2');
                },
                child: Text('Show Photos'),
              );
            },
          ),
        ),
      ),
    );
  }
}

class WidgetTwo extends StatelessWidget {
  final DateTime start,end;

  const WidgetTwo({Key key, this.start, this.end}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Expanded(

            child:Gallery(start:start,end: end,),

        );

  }
}



