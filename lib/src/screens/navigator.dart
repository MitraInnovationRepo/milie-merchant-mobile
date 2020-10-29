import 'dart:async';
import 'dart:io';

import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodie_merchant/src/data/model/order.dart';
import 'package:foodie_merchant/src/data/model/order_reject_response.dart';
import 'package:foodie_merchant/src/data/model/order_view.dart';
import 'package:foodie_merchant/src/data/model/user.dart';
import 'package:foodie_merchant/src/data/notifier/tab_notifier.dart';
import 'package:foodie_merchant/src/screens/home/home.dart';
import 'package:foodie_merchant/src/screens/order/order_history.dart';
import 'package:foodie_merchant/src/screens/order/order_requests.dart';
import 'package:foodie_merchant/src/screens/product/product_type_catalog.dart';
import 'package:foodie_merchant/src/services/order/order_service.dart';
import 'package:foodie_merchant/src/services/service_locator.dart';
import 'package:foodie_merchant/src/services/user/user_service.dart';
import 'package:foodie_merchant/src/util/constant.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeNavigator extends StatefulWidget {
  HomeNavigator({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomeNavigatorState createState() => _HomeNavigatorState();
}

class _HomeNavigatorState extends State<HomeNavigator> {
  final FirebaseMessaging _fcm = FirebaseMessaging();
  StreamSubscription iosSubscription;
  UserService _userService = locator<UserService>();
  OrderService _orderService = locator<OrderService>();

  PersistentTabController _controller;

  List<Widget> _buildScreens() {
    return [Home(), OrderRequests(), OrderHistory(), ProductTypeCatalog()];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.home),
        title: ("Home"),
        activeColor: Theme.of(context).primaryColor,
        inactiveColor: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.list),
        title: ("Order Requests"),
        activeColor: Theme.of(context).primaryColor,
        inactiveColor: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.history),
        title: ("Order History"),
        activeColor: Theme.of(context).primaryColor,
        inactiveColor: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.fastfood),
        title: ("Menu"),
        activeColor: Theme.of(context).primaryColor,
        inactiveColor: CupertinoColors.systemGrey,
      )
    ];
  }

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
    TabNotifier tabNotifier = Provider.of<TabNotifier>(context, listen: false);
    tabNotifier.setTabController(_controller);
    if (Platform.isIOS) {
      iosSubscription = _fcm.onIosSettingsRegistered.listen((data) {
        // save the token  OR subscribe to a topic here
      });
      _fcm.requestNotificationPermissions(IosNotificationSettings());
    }
    _fcm.onTokenRefresh.listen((newToken) {
      User deviceUpdateUser = new User.empty();
      deviceUpdateUser.fireBaseRegistration = newToken;
      this._userService.updateDeviceInfo(deviceUpdateUser);
    });
    _fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        String messageBody = _getMessage(message);
        String orderId = _getOrderId(message);
        OverlaySupportEntry supportEntry;
        supportEntry = showSimpleNotification(
          InkWell(
            onTap: () {
              showOrder(context, int.parse(orderId));
              supportEntry.dismiss();
            },
            child: Text(
              messageBody,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          elevation: 10,
          slideDismiss: true,
          autoDismiss: false,
          leading: Icon(Icons.fastfood, color: Colors.white),
          background: Theme.of(context).accentColor,
        );
      },
      onLaunch: (Map<String, dynamic> message) async {},
      onResume: (Map<String, dynamic> message) async {},
    );
  }

  _getMessage(Map<String, dynamic> message) {
    return Platform.isIOS
        ? message['aps']['alert']['body']
        : message['notification']['body'];
  }

  _getOrderId(Map<String, dynamic> message) {
    String strId =
        Platform.isIOS ? message['order_id'] : message['data']['order_id'];

    return strId;
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineInSafeArea: true,
      backgroundColor: Theme.of(context).bottomAppBarColor,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      // This needs to be true if you want to move up the screen when keyboard appears.
      stateManagement: true,
      hideNavigationBarWhenKeyboardShows: true,
      // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument.
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0.0), topRight: Radius.circular(0.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4), // changes position of shadow
          ),
        ],
        colorBehindNavBar: Colors.white,
      ),
      popAllScreensOnTapOfSelectedTab: true,
      itemAnimationProperties: ItemAnimationProperties(
        // Navigation Bar's items animation properties.
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      ),
      screenTransitionAnimation: ScreenTransitionAnimation(
        // Screen transition animation on change of selected tab.
        animateTabTransition: true,
        curve: Curves.ease,
        duration: Duration(milliseconds: 200),
      ),
      navBarStyle:
          NavBarStyle.style6, // Choose the nav bar style with this property.
    );
  }

  showOrder(BuildContext context, int orderId) async {
    OrderView order = await this._orderService.fetchOrder(orderId);
    showOrderPopup(context, order);
  }

  void showOrderPopup(BuildContext context, OrderView order) {
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.user.name),
                    Row(
                      children: [
                        Text(order.user.phoneNumber),
                        SizedBox(width: 10),
                        IconButton(icon: Icon(Icons.phone), onPressed: () {
                          launch("tel://${order.user.phoneNumber}");
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Item Total"),
                        Text(order.currency +
                            " " +
                            order.itemSubTotal.toStringAsFixed(2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Wrap(
                                  children: [
                                    Badge(
                                      position: BadgePosition.topRight(
                                          top: 0, right: 3),
                                      animationDuration:
                                          Duration(milliseconds: 300),
                                      animationType: BadgeAnimationType.slide,
                                      badgeContent: Text(
                                        order.orderDetailList[index].quantity
                                            .toStringAsFixed(0),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              "${Constant.filePath}${order.orderDetailList[index].product.imageUrl}",
                                          height: 40.0,
                                          width: 40.0,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Container(
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                                0.07,
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.4,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Expanded(child:
                                          Text(
                                              order.orderDetailList[index]
                                                  .product.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                          // ),
                                          Text(
                                              'LKR ' +
                                                  order.orderDetailList[index]
                                                      .product.unitPrice
                                                      .toStringAsFixed(2),
                                              style: TextStyle(fontSize: 12))
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.25,
                                            child: Text(
                                                "LKR " +
                                                    order.orderDetailList[index]
                                                        .total
                                                        .toStringAsFixed(2),
                                                textAlign: TextAlign.end)),
                                      ],
                                    ),
                                  ],
                                ),
                              ]),
                          order.orderDetailList[index].addonTotal > 0
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    for (var addon in order
                                        .orderDetailList[index]
                                        .product
                                        .productAddonList)
                                      Container(
                                          margin: EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              color: Colors.black12),
                                          width:
                                              MediaQuery.of(context).size.width,
                                          padding: EdgeInsets.all(5),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(addon.name),
                                              SizedBox(width: 20),
                                              Text(addon.price
                                                  .toStringAsFixed(2))
                                            ],
                                          ))
                                  ],
                                )
                              : Container(),
                          order.orderDetailList[index].additionalTotal > 0
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    for (var additional in order
                                        .orderDetailList[index]
                                        .product
                                        .productAdditionalList)
                                      Container(
                                          margin: EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              color: Colors.black12),
                                          width:
                                              MediaQuery.of(context).size.width,
                                          padding: EdgeInsets.all(5),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(additional.name),
                                              SizedBox(width: 20),
                                              Text(additional.price
                                                  .toStringAsFixed(2))
                                            ],
                                          ))
                                  ],
                                )
                              : Container(),
                          Divider()
                        ],
                      ),
                    );
                  },
                  itemCount: order.orderDetailList.length),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: RaisedButton(
                      color: Colors.amber,
                      onPressed: () async {
                        OrderRejectResponse orderRejectResponse =
                            await _orderService.rejectOrder(order.id);
                        if (orderRejectResponse.status != 100) {
                          showSimpleNotification(
                            Text("Order Rejected"),
                            background: Theme.of(context).backgroundColor,
                          );
                        } else {
                          showSimpleNotification(Text(orderRejectResponse.message),
                              background: Colors.amber);
                        }
                        Navigator.of(context, rootNavigator: true).pop('dialog');
                      },
                      child: new Text("Reject"),
                    ),
                    width: MediaQuery.of(context).size.width * 0.3,
                  ),
                  Container(
                    child: RaisedButton(
                      color: Color.fromRGBO(0, 153, 0, 1),
                      onPressed: () async {
                        OrderRejectResponse orderRejectResponse =
                            await _orderService.approveOrder(order.id);
                        if (orderRejectResponse.status != 100) {
                          showSimpleNotification(
                            Text("Order Approved"),
                            background: Theme.of(context).backgroundColor,
                          );
                        } else {
                          showSimpleNotification(Text(orderRejectResponse.message),
                              background: Colors.amber);
                        }
                        Navigator.of(context, rootNavigator: true).pop('dialog');
                      },
                      child: new Text("Accept"),
                    ),
                    width: MediaQuery.of(context).size.width * 0.3,
                  ),
                ],
              ),
            )
          ],
        ));
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }
}
