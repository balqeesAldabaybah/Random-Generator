import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/services.dart';
import 'app_id.dart' show APP_ID; 
import 'banner_unti_id.dart' show BANNER_UNIT_ID;
import 'inter_unit_id.dart' show INTER_UNIT_ID;

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Random Generator',
      theme: new ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: new MyHomePage(title: 'Random Generator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

   static final MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
      keywords: <String>['shuffle', 'random'],
      childDirected: false,
      designedForFamilies: true,
      gender: MobileAdGender.unknown, // or MobileAdGender.female, MobileAdGender.unknown
      birthday: new  DateTime.now()
);

  BannerAd myBanner ;
  InterstitialAd interstitialAd;

  BannerAd buildBanner(){
    return BannerAd(
      adUnitId: BANNER_UNIT_ID,
      size: AdSize.banner,
      listener: (MobileAdEvent event){
        if(event == MobileAdEvent.loaded){
          myBanner.show();
        }
      }
    );
  }

  InterstitialAd buildInterstitial(){
    return InterstitialAd(
      adUnitId: INTER_UNIT_ID,
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event){
        if(event == MobileAdEvent.failedToLoad){
          interstitialAd..load();
        }else if(event == MobileAdEvent.closed)
        {
          interstitialAd = buildInterstitial()..load();

        }
      }
    );
  }


  final myController = TextEditingController();
  String newRandom; 
  List<String> randomItems ;
  String winner;
  List<String> mixItems;
  int mixIndex;
  Timer timer;
  Color winnerBoxColor;
  bool toggle = true;
  FocusNode txtFocusNode;
  bool addTapped;

  @override
    void initState() {
      newRandom = '';
      randomItems = [];
      mixItems = ['No winner yet!'];
      winner = 'No winner yet! ';
      winnerBoxColor = Colors.white;
      // TODO: implement initState
      super.initState();
      mixIndex =0;
      txtFocusNode = FocusNode();
      addTapped = false;

      FirebaseAdMob.instance.initialize(appId: APP_ID);
      myBanner= buildBanner()..load(); 
      interstitialAd = buildInterstitial()..load();
    }
    
  @override
    void dispose() {
      myController.dispose();
      txtFocusNode.dispose();

      myBanner?.dispose();
      interstitialAd?.dispose();
      // TODO: implement dispose
      super.dispose();
    }

    Widget buildTileConent(BuildContext ctxt, int index){
        return  new Padding(
            padding: EdgeInsets.only( bottom: 10.0, right: 10.0, top:10.0),
            child: new Text (randomItems[index]),
          );

    }
    Widget buildBody(BuildContext ctxt, int index){
      
      return Center(
        child: new Padding(
          padding: EdgeInsets.only(bottom: 10.0),
          child: new Container(
            width: 300.0,
            child: new ListTile(
              title: buildTileConent(ctxt, index),
              trailing: IconButton(icon: Icon(Icons.delete), onPressed: (){ _delete(index);},),
            ),
            decoration: new BoxDecoration(
              border: Border.all(color: Colors.pink ,style: BorderStyle.solid),
              borderRadius: new BorderRadius.all(Radius.circular(10.0))
            ),
          ),
        )
      );
    }

    _delete(int index){
      showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: new Text('Confirm deletion'),
            content: new Text("Do you want to remove \"${randomItems[index]}\" ? "),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Yes"),
                onPressed: (){
                  Navigator.of(context).pop();
                    setState(() {
                    randomItems.removeAt(index);
                  });
                  setState(() {
                    if(randomItems.length == 0){
                      mixItems[mixIndex] = winner;
                      winnerBoxColor = Colors.white;
                    }

                    });
                },
              ),
              new FlatButton(
                child: new Text("No"),
                onPressed: (){Navigator.of(context).pop();},
              )
            ],
          );
        } 
      );
    }
    _deleteAll(){
      if(randomItems.length != 0 ){
          showDialog(
          context: context,
          builder: (BuildContext context){
            return AlertDialog(
              title: new Text('Confirm deletion'),
              content: new Text("Do you want to delete all participants ? "),
              actions: <Widget>[
                new FlatButton(
                  child: new Text("Yes"),
                  onPressed: (){
                    Navigator.of(context).pop();
                      setState(() {
                        randomItems.clear();
                        mixItems[mixIndex] = winner;
                        winnerBoxColor = Colors.white;
                    });
                  },
                ),
                new FlatButton(
                  child: new Text("No"),
                  onPressed: (){Navigator.of(context).pop();},
                )
              ],
            );
          } 
        );
      }
    }
    Future  mix() async {
      FocusScope.of(context).requestFocus(new FocusNode());
      int randomIndex ;
      //print("random items length : ${ randomItems.length}");
      if(randomItems.length ==0 ){
      
        setState(() {          
                  mixItems[mixIndex] = 'Add participants';
                  winnerBoxColor = Colors.grey[200];
                });
      }
      else {if(randomItems.length == 1){
          setState(() {
                      mixItems[mixIndex] = randomItems[0];
                      winnerBoxColor = Colors.pinkAccent;
                    });
      }
      else{
        setState(() {
                  winnerBoxColor = Colors.white;
                });
        mixItems.clear();
        mixIndex=0;

        int min=0;
        int max = randomItems.length-1;

        for(int i=0;i<100;i++){
           randomIndex = (new Random().nextInt((max-min)+1))+min;
            mixItems.add(randomItems[randomIndex]);
        }
        
        timer= new Timer.periodic(new Duration (milliseconds: 10), (Timer time){
          setState(() {
                  if(mixIndex > mixItems.length-2){
                    winnerBoxColor = Colors.pinkAccent;
                    timer.cancel();
                    interstitialAd..load()..show();
                  }else{
                    mixIndex++;
                  }
                     
                    });
        } );

      }
      }
    }
    _addNewEntry(String text){
      if( text!=""){
        randomItems.add(text);
                         myController.clear();
                         setState(() {
                            this.toggle = true;
                          });
                          if(addTapped){
                             FocusScope.of(context).requestFocus(new FocusNode());
                          }
        if(randomItems.length>= 1){
          mixItems[0] = winner;
        }
      }
        if(addTapped && text==""){
          FocusScope.of(context).requestFocus(txtFocusNode);
        }
      
      
      

    }
  
   


  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]); 
    myBanner..load()..show();
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Padding(
        padding: EdgeInsets.only(top: 10.0,bottom: 25.0,right:  10.0,left: 10.0),
        child: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new Padding(
              padding: EdgeInsets.all(10.0),
              child: new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                 new Container(
              width: 300.0,
              child: new TextField(
                textAlign: TextAlign.center,
                  onSubmitted : (text){
                         _addNewEntry(text);
                    },
                 controller: myController,
                 focusNode: txtFocusNode,
                 decoration: new InputDecoration(
                   border: new OutlineInputBorder(
                     borderRadius: const BorderRadius.all(
                       Radius.circular(10.0),
                     ),
                  ),
                 hintText: 'add a participant '
                ),
                ),
            ),
              ],
            ),
              ),
            new Center(
              
                child: new Padding(
                  padding: EdgeInsets.only(bottom: 10.0),
                  child: new Container(
                    width: 300.0,
                    
                    child: new Padding(
                      padding: EdgeInsets.all(10.0),
                      child: new Center(child: new Text(mixItems[mixIndex], style: TextStyle(fontSize: 20.0)), ),
                    
                    ),
                    decoration: new BoxDecoration(
                      border: Border.all(color: Colors.pink ,style: BorderStyle.solid),
                      borderRadius: new BorderRadius.all(Radius.circular(10.0)),
                      color: winnerBoxColor,
                    ),
                    
                    
                  ),
                )
              
            ),
            new Expanded(
                  child: new Container(
                    width: 300.0,
                    child: new ListView.builder(
                          itemCount: randomItems.length,
                          itemBuilder: (BuildContext context, int index) => buildBody(context, index)
                        ) ,
                  )
                ),
            new Padding(
              padding: EdgeInsets.all(10.0),
              child: new Container(
                //height: 50.0,
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    new Container(
                      child: new IconButton(
                        icon: new Icon(Icons.delete_forever, color: Colors.pink,) ,
                        onPressed: (){ _deleteAll();},
                      ),
                      decoration: new BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.pink
                        )
                      ),
                    ),
                    new Container(
                      child: new IconButton(
                        icon: new Icon(Icons.shuffle,) ,
                        onPressed: (){ mix();},
                      ),
                      decoration: new BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.pink
                        ),
                        color: Colors.pink
                      ),
                    ),
                    new Container(
                      child: new IconButton(
                        icon: new Icon(Icons.add, color: Colors.pink,) ,
                        onPressed: (){ setState(() {
                                                addTapped = true;
                                              });      
                                      _addNewEntry(myController.text);},
                      ),
                      decoration: new BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.pink
                        )
                      ),
                    ),
                    
                  ],
                  )
              )
            ),

          ],
        )
      ),
      )
        
      
                 
    );
  }
}
