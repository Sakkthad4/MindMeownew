import 'package:flutter/material.dart';
import 'funcpopup.dart';

class MyFuncBox extends StatelessWidget {
  final String functitle;
  final String locate;
  final String picfunc;
  final Color colorme;

  const MyFuncBox(
    this.functitle,
    this.locate,
    this.picfunc,
    this.colorme, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showFuncPopup(
          context,
          title: functitle,
          imagePath: picfunc,

          onGo: () {
            // ✅ pop dialog ครั้งเดียว
            Navigator.of(context, rootNavigator: true).pop();

            // ✅ push หลัง dialog ปิด
            Future.delayed(const Duration(milliseconds: 150), () {
              Navigator.of(context).pushNamed(locate);
            });
          },

          onCancel: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        fixedSize: const Size(340, 275),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(35),
          side: BorderSide(color: colorme, width: 12),
        ),
        elevation: 0,
      ),
      child: Image.asset(picfunc, fit: BoxFit.contain),
    );
  }
}
