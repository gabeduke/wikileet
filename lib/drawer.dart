import 'package:wikileet/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info/package_info.dart';

class LeetDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new LeetDrawerState();
  }
}

class LeetDrawerState extends State<LeetDrawer> {

  SharedPreferences prefs;
  String _projectName = "";
  String _projectAppID = "";
  String _projectVersion = "";
  String _projectCode = "";


  @override
  void initState() {
    super.initState();
    getSharedPref();
    getAppInfo();
  }

  void getSharedPref() async {
      prefs = await SharedPreferences.getInstance();
  }

  getAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String projectName = packageInfo.appName;
    String projectAppID = packageInfo.packageName;
    String projectVersion = packageInfo.version;
    String projectCode = packageInfo.buildNumber;

    setState(() {
      _projectVersion = projectVersion;
      _projectCode = projectCode;
      _projectAppID = projectAppID;
      _projectName = projectName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: new ListView(
          padding: EdgeInsets.zero,
          children: <Widget> [
            new DrawerHeader(
              child: new Text('Menu'),
              decoration: BoxDecoration(
                color: Theme.of(context).secondaryHeaderColor,
              ),
            ),
            new Divider(),
            new ListTile(
              leading: new Icon(Icons.home),
              title: new Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                context,
                new MaterialPageRoute(builder: (ctxt) => new MyApp())
                );},
            ),
            new ListTile(
              leading: new Icon(Icons.help),
              title: new Text('Help'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                context,
                new MaterialPageRoute(builder: (ctxt) => new MyApp())
                );},
            ),
            new AboutListTile(
              icon: new Icon(Icons.info),
              applicationName: "Wiki Leet",
              applicationVersion: _projectVersion + "+" + _projectCode,
              applicationLegalese: _projectAppID,
            ),
          ],
        ),
        );
  }
}