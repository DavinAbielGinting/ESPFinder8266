import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_screen.dart';
import 'package:vibration/vibration.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_background/flutter_background.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  final title = 'RSSI Bluetooth Tracker';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
          colorSchemeSeed: Colors.blueAccent[700]
      ),
      home: MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String targetDeviceName = 'BT05';
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  //FlutterBackground.initialize()

  List<ScanResult> scanResultList = [];
  var scan_mode = 0;
  bool isScanning = false;


  @override
  void initState() {
    super.initState();
  }

  /* 시작, 정지 */
  void toggleState() {
    isScanning = !isScanning;

    if (isScanning) {
      flutterBlue.startScan(
          scanMode: ScanMode(scan_mode), allowDuplicates: true);
      scan();
    } else {
      flutterBlue.stopScan();
    }
    setState(() {});
  }

  /* 
  Scan Mode
  Ts = scan interval 
  Ds = duration of every scan window
             | Ts [s] | Ds [s]
  LowPower   | 5.120  | 1.024
  BALANCED   | 4.096  | 1.024
  LowLatency | 4.096  | 4.096

  LowPower = ScanMode(0);
  BALANCED = ScanMode(1);
  LowLatency = ScanMode(2);

  opportunistic = ScanMode(-1);
   */

  /* Scan */
  scan() async {
    if (isScanning) {
      // if not scanning
      // Delete the previously scanned list
      scanResultList. clear();
      // start scanning, timeout 4 seconds
      //flutterBlue.startScan(timeout: Duration(seconds: 4));
      debugPrint('Test#1');
      // scan result listener
      flutterBlue.scanResults.listen((results) {
        scanResultList = results;
        // loop the result value
        results.forEach((element) {
          // Check if the device name is being searched for
          if (element.device.name == targetDeviceName) {
            // Check if the device is already registered by comparing the ID of the device
            if (scanResultList
                .indexWhere((e) => e.device.id == element.device.id) <
                0)
            {
              // If it is the name of the device to be searched for and has not been registered in scanResultList, add it to the list
              scanResultList.add(element);
            }
          }



          if (element.device.name == 'BT05'){
            if (element.rssi <= -60){
              vibratePhone();
              showToast('Barang Anda Tertinggal! RSSI:${element.rssi}dBm');
            }
          }

        });

        // update the UI
        setState(() {});
      });
    }
  }

  /* device RSSI */
  Widget deviceSignal(ScanResult r) {
    return Text(r.rssi.toString());
  }

  /* device MAC address  */
  Widget deviceMacAddress(ScanResult r) {
    return Text(r.device.id.id);
  }

  /* device name  */
  Widget deviceName(ScanResult r) {
    String name;

    if (r.device.name.isNotEmpty) {
      name = r.device.name;
    } else if (r.advertisementData.localName.isNotEmpty) {
      name = r.advertisementData.localName;
    } else {
      name = 'N/A';
    }
    return Text(name);
  }

  /* BLE icon widget */
  Widget leading(ScanResult r) {
    return CircleAvatar(
      backgroundColor: Colors.blueAccent,
      child: Icon(
        Icons.bluetooth,
        color: Colors.white,
      ),
    );
  }

  void onTap(ScanResult r) {
    print('${r.device.name}');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceScreen(device: r.device)),
    );
  }


  /* ble item widget */
  Widget listItem(ScanResult r) {
    return ListTile(
      onTap: () => onTap(r),
      leading: leading(r),
      title: deviceName(r),
      subtitle: deviceMacAddress(r),
      trailing: deviceSignal(r),
    );
  }

  void vibratePhone() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(
          duration: const Duration(milliseconds: 1000).inMilliseconds);
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
    );
  }

  /* UI */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 5,
      ),
      body: Center(
        child: ListView.separated(
          itemCount: scanResultList.length,
          itemBuilder: (context, index) {
            return listItem(scanResultList[index]);
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleState,
        child: Icon(isScanning ? Icons.stop : Icons.search),
      ),
    );
  }
}
