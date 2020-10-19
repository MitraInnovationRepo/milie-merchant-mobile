import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:foodie_merchant/src/util/constant.dart';
import 'package:skeleton_text/skeleton_text.dart';

class PromotionSlider extends StatelessWidget {
  final List<String> imgList = [
    '${Constant.contentEndpoint}/uploads/slider1_27b108e560.jpg',
    '${Constant.contentEndpoint}/uploads/slider2_fcd849647a.jpg',
    '${Constant.contentEndpoint}/uploads/slider3_9d2e12176a.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
        child: CarouselSlider(
      options: CarouselOptions(autoPlay: true, viewportFraction: 1,
          height: MediaQuery.of(context).size.height * 0.5,),
      items: imgList
          .map((item) => Container(
                child: Center(
                    child: CachedNetworkImage(
                        progressIndicatorBuilder: (context, url, progress) {
                          return SkeletonAnimation(
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                              ),
                            ),
                          );
                        },
                        imageUrl: item,
                        fit: BoxFit.cover,
                        height: MediaQuery.of(context).size.height * 0.5,
                        width: MediaQuery.of(context).size.width )),
              ))
          .toList(),
    ));
  }
}
