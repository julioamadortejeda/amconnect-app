import 'package:flutter/material.dart';
import 'package:amconnect/core/widgets/am_press.dart';

class LoginEmailBtn extends StatelessWidget {
  const LoginEmailBtn({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AmPress(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF004F8C),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.email_outlined, size: 20, color: Colors.white),
          SizedBox(width: 10),
          Text('Entrar con correo',
              style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ]),
      ),
    );
  }
}
