import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart' show Shimmer;

class ProductShimmerWidget extends StatelessWidget {
  const ProductShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Shimmer(
            child: Container(
              height: size.height * 0.15,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left image shimmer box
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                    child: Container(
                      color: Colors.grey[300],
                      height: size.height * 0.15,
                      width: size.width * 0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Right side placeholders
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product title
                          Container(
                            height: 16,
                            width: size.width * 0.4,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          // Rating shimmer
                          Container(
                            height: 14,
                            width: size.width * 0.25,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          // Description shimmer
                          Container(
                            height: 14,
                            width: size.width * 0.2,
                            color: Colors.grey[300],
                          ),
                          const Spacer(),
                          // Price & cart icon shimmer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Price shimmer
                              Container(
                                height: 18,
                                width: 50,
                                color: Colors.grey[300],
                              ),
                              // Shimmered cart icon placeholder (circular)
                              Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
