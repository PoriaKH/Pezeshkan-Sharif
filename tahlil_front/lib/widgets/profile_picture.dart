import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tahlil_front/classes/user.dart';

class ProfilePictureWidget extends StatelessWidget {
  final User user;
  final void Function()? editPFP;

  const ProfilePictureWidget(this.user, {super.key, this.editPFP});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(300),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 3)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(300),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(300),
              onTap: editPFP,
              child: user.pfp == null
                  ? Image.asset('assets/profile.png')
                  : Image(
                      fit: BoxFit.cover,
                      image: CachedNetworkImageProvider(user.pfp!),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
