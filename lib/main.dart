import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:http/http.dart' as http;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:project1/imageObject.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static bool isLoggedIn = false;
  static bool isLoading = true;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Image Gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Image Gallery'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ImageObject> imageDatas = [];
  List<Widget> rowFields = [];
  List<String> _searchTextfield = ['', '', '', '', '', ''];
  List<int> _keySearchValue = [0, 0, 0, 0, 0, 0];
  List<int> _comparatorSearchValue = [0, 0, 0, 0, 0, 0];
  String email = '';
  String password = '';
  int itemCount = 0;
  final _formKey = GlobalKey<FormState>();
  final _searchFormKey = GlobalKey<FormState>();
  List<String> images = [];
  int searchFormindex = 0;

  Map<int, String> comparatorMapping = {
    0: '==',
    1: '<=',
    2: '>=',
  };

  Map<int, String> keyValueMapping = {
    0: 'Flash',
    1: 'Exposure',
    2: 'XResolution',
    3: 'YResolution',
    4: 'FocalLength',
    5: 'Make',
  };
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    // Future.delayed(Duration(milliseconds: 5000), () {
    //   setState(() {
    //     MyApp.isLoading = false;
    //   });
    // });
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white70,
        actions: [
          MyApp.isLoading
              ? Container(
                  margin: EdgeInsets.fromLTRB(5, 10, 5, 10),
                  child: CircularProgressIndicator(),
                )
              : Container(),
          !MyApp.isLoggedIn
              ? Container(
                  margin: EdgeInsets.fromLTRB(0, 5, 20, 5),
                  child: RaisedButton(
                    elevation: 2,
                    hoverElevation: 5,
                    color: Colors.red[300],
                    onPressed: () {
                      loginForm();
                    },
                    child: Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'sans-serif',
                          letterSpacing: 0.8),
                    ),
                  ),
                )
              : Container(
                  margin: EdgeInsets.fromLTRB(0, 5, 20, 5),
                  child: RaisedButton(
                    hoverElevation: 4,
                    elevation: 0,
                    color: Colors.white70,
                    onPressed: () {
                      setState(() {
                        MyApp.isLoggedIn = false;
                      });
                    },
                    child: Text(
                      "Logout",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'sans-serif',
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 10,
            ),
            searchForm(),
            Flexible(
              flex: 1,
              child: StaggeredGridView.countBuilder(
                crossAxisCount: (width / 275).floor(),
                itemCount: imageDatas.length,
                itemBuilder: (context, index) {
                  String url =
                      'http://127.0.0.1:5000/getimage/' + imageDatas[index].id;
                  Map<String, dynamic> meta = imageDatas[index].metadata;
                  String features = '';
                  meta.forEach((key, value) {
                    features +=
                        "\n" + key.toString() + " : " + value.toString();
                  });
                  return InkWell(
                    onTap: () {
                      showImageDialog(imageDatas[index], features);
                    },
                    child: Container(
                        margin: EdgeInsets.all(5.0),
                        padding: EdgeInsets.all(5.0),
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                        )),
                  );
                },
                staggeredTileBuilder: (int index) {
                  return StaggeredTile.fit(1);
                },
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
              ),
            )
          ],
        ),
      ),
      // Upload Image button
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add_a_photo),
        onPressed: uploadImage,
      ),
    );
  }

  void showImageDialog(ImageObject imageObject, String features) {
    String url = 'http://127.0.0.1:5000/getimage/' + imageObject.id;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Image Data",
              textAlign: TextAlign.center,
              style: TextStyle(
                  letterSpacing: 0.8,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            content: Container(
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        margin: EdgeInsets.all(5.0),
                        padding: EdgeInsets.all(5.0),
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                        )),
                    Text(features, textAlign: TextAlign.start),
                  ],
                ),
              ),
            ),
          );
        });
  }

  @override
  void initState() {
    super.initState();

    getImagedata();
  }

  void getImagedata() {
    imageDatas.clear();
    http.get("http://127.0.0.1:5000/get_image_data").then((value) {
      var datas = json.decode(value.body);
      for (var data in datas) {
        ImageObject temp1 =
            new ImageObject(data['id'], data['name'], data['metadata']);
        setState(() {
          imageDatas.add(temp1);
        });
      }
      setState(() {
        MyApp.isLoading = false;
      });
    });
  }

  // ------ uploading element------------

  void uploadImage() {
    if (MyApp.isLoggedIn) {
      InputElement inputElement = FileUploadInputElement()..accept = 'image/*';
      inputElement.click();

      inputElement.onChange.listen((event) {
        final file = inputElement.files.first;
        final reader = FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((event) {
          // print("loading");
          // print(file.name.toString());
          String str = reader.result.toString();
          setState(() {
            MyApp.isLoading = true;
          });
          upload(file.name, str);
        });
      });
    } else {
      loginForm();
    }
  }

// API linking for uploading image
  void upload(String name, String url) {
    http
        .post("http://127.0.0.1:5000/create_record",
            body: json.encode({'name': name, 'url': url}))
        .then((value) {
      // print("uploaded");
      setState(() {
        MyApp.isLoading = false;
      });
      // print(json.decode(value.body));
    });
  }

  void loginForm() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Login",
              textAlign: TextAlign.center,
              style: TextStyle(
                  letterSpacing: 0.8,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            content: Container(
              height: 300,
              width: 300,
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    new Container(height: 40),

                    //User id
                    new TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: new InputDecoration(
                          hintText: 'guest', labelText: 'Enter your username'),
                      validator: validate,
                      onSaved: (val) {
                        email = val;
                      },
                    ),

                    //Password
                    new TextFormField(
                      obscureText: true, // Use secure text for passwords.
                      decoration: new InputDecoration(
                          hintText: 'Password',
                          labelText: 'Enter your password'),
                      validator: validate,
                      onSaved: (val) {
                        password = val;
                      },
                    ),

                    //Submit button
                    new Container(
                      margin: EdgeInsets.fromLTRB(0, 50, 20, 5),
                      height: 40,
                      child: RaisedButton(
                        elevation: 2,
                        hoverElevation: 5,
                        color: Colors.red[400],
                        onPressed: () {
                          submit();
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'sans-serif',
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  String validate(value) {
    if (value.isEmpty) {
      return 'Please enter some text';
    }
    if (value != "guest") {
      return "Wrong credentials";
    }
    return null;
  }

  void submit() {
    // First validate form.
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save(); // Save our form now.

      if (email.toLowerCase() == "guest" && password == "guest") {
        setState(() {
          MyApp.isLoggedIn = true;
          //Popping dialog box
          Navigator.of(context, rootNavigator: true).pop();
        });
      }
    }
  }

  Widget searchForm() {
    return Form(
      key: _searchFormKey,
      child: Column(
        children: [
          searchBox(0),
          searchFormindex >= 1 ? searchBox(1) : Container(),
          searchFormindex >= 2 ? searchBox(2) : Container(),
          searchFormindex >= 3 ? searchBox(3) : Container(),
          searchFormindex >= 4 ? searchBox(4) : Container(),
          searchFormindex >= 5 ? searchBox(5) : Container(),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            RaisedButton(
              child: Text("submit"),
              onPressed: () {
                handleFormSubmit();
              },
            ),
            searchFormindex < 5
                ? IconButton(
                    iconSize: 20,
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        if (searchFormindex < 5) {
                          searchFormindex += 1;
                        }
                      });
                    },
                  )
                : Container(),
            searchFormindex >= 1
                ? IconButton(
                    iconSize: 20,
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        if (searchFormindex < 6) {
                          searchFormindex -= 1;
                        }
                      });
                    },
                  )
                : Container(),
            RaisedButton(
              child: Text("clear"),
              onPressed: () {
                // handleFormclear();
                setState(() {
                  MyApp.isLoading = true;
                });
                getImagedata();
              },
            ),
          ])
        ],
      ),
    );
  }

  void handleFormSubmit() {
    if (_searchFormKey.currentState.validate()) {
      _searchFormKey.currentState.save();
      // print(_keySearchValue);
      // print(_comparatorSearchValue);
      // print(_searchTextfield);

      var query = [];

      for (int i = 0; i <= searchFormindex; ++i) {
        var temp = {
          keyValueMapping[_keySearchValue[i]]: {
            comparatorMapping[_comparatorSearchValue[i]]: _searchTextfield[i]
          }
        };
        query.add(temp);
      }
      // print(query);
      setState(() {
        MyApp.isLoading = true;
        imageDatas.clear();
      });

      http
          .post("http://127.0.0.1:5000/query_records", body: json.encode(query))
          .then((value) {
        var datas = json.decode(value.body);
        for (var data in datas) {
          setState(() {
            imageDatas
                .add(ImageObject(data['id'], data['name'], data['metadata']));
          });
        }
        setState(() {
          MyApp.isLoading = false;
        });
      });
    }
  }

  Widget searchBox(int index) {
    // print(index);
    return Container(
      width: 450,
      height: 75,
      child: Row(
        children: [
          Expanded(
            child:
                Container(margin: EdgeInsets.all(10), child: keyField(index)),
          ),
          Expanded(
            child:
                Container(margin: EdgeInsets.all(10), child: comparator(index)),
          ),
          Expanded(
            child:
                Container(margin: EdgeInsets.all(10), child: textField(index)),
          ),
        ],
      ),
    );
  }

  String searchTextfieldValidate(value) {
    if (value.isEmpty) {
      return 'Please enter some text';
    }

    return null;
  }

  Widget textField(index) {
    return TextFormField(
      keyboardType: TextInputType.number,
      validator: (val) {
        if (_keySearchValue[index] == 5) {
          if (val.contains(new RegExp(r'[0-9]'))) {
            return "Enter proper value";
          }
        } else {
          if (!val.contains(new RegExp(r'[0-9]'))) {
            return "Enter proper value";
          }
        }
        return null;
      },
      onSaved: (val) {
        _searchTextfield[index] = val;
      },
    );
  }

  Widget keyField(index) {
    List<DropdownMenuItem> _dropdownmenuItems = [];
    for (int i = 0; i < keyValueMapping.length; ++i) {
      // print(keyvalues[i]);
      _dropdownmenuItems.add(DropdownMenuItem(
        child: Text(keyValueMapping[i]),
        value: i,
      ));
    }
    return DropdownButtonFormField(
      value: _keySearchValue[index],
      items: _dropdownmenuItems,
      onChanged: (value) {
        setState(() {
          _keySearchValue[index] = value;
        });
      },
      validator: validateKeyDropdown,
    );
  }

  String validateKeyDropdown(val) {
    List<bool> checker = [false, false, false, false, false, false];
    for (int i = 0; i <= searchFormindex; ++i) {
      if (!checker[_keySearchValue[i]]) {
        checker[_keySearchValue[i]] = true;
      } else {
        return "Please select different options";
      }
    }
    return null;
  }

  Widget comparator(index) {
    List<DropdownMenuItem> _dropdownmenuItems = [];
    for (int i = 0; i < comparatorMapping.length; ++i) {
      _dropdownmenuItems.add(DropdownMenuItem(
        child: Text(comparatorMapping[i]),
        value: i,
      ));
    }
    return DropdownButtonFormField(
      value: _comparatorSearchValue[index],
      items: _dropdownmenuItems,
      onChanged: (value) {
        setState(() {
          _comparatorSearchValue[index] = value;
        });
      },
      validator: (val) {
        if (_keySearchValue[index] == 5) {
          if (_comparatorSearchValue[index] != 0) {
            return "String != {<=,>=}";
          }
        }
        return null;
      },
    );
  }
}
