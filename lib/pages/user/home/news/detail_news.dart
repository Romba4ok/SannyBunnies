import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class DetailNewsDialog extends StatelessWidget {
  final Map<String, dynamic> news;
  const DetailNewsDialog({Key? key, required this.news}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String headline = news['headline'] ?? 'Событие';
    final String body = news['body'] ?? '';
    final String photoUrl = news['photo_url'] ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131010),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (photoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FutureBuilder<List<int>?>(
                  future: ProfileService.instance.getCachedPhotoBytes(photoUrl),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.done && snap.data != null) {
                      return Image.memory(
                        Uint8List.fromList(snap.data!),
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                      );
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Container(
                          width: double.infinity,
                          height: 250,
                          color: const Color.fromRGBO(0, 0, 0, 0.1),
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xFFA441DC)),
                          ),
                        );
                    }
                    return Image.network(
                      photoUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[900],
                        child: const Icon(Icons.broken_image, color: Colors.white30),
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              headline,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              body,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}


