// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 直接使用鸿蒙实现时，需要手动注册为默认实例。
  InAppPurchaseOhosPlatform.registerPlatform();
  runApp(const InAppPurchaseExampleApp());
}

const productIds = <String>[
  'consumable',
  'upgrade',
  'subscription_silver',
  'subscription_gold',
];

class InAppPurchaseExampleApp extends StatelessWidget {
  const InAppPurchaseExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('In App Purchase')),
        body: const PurchasePage(),
      ),
    );
  }
}

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final platform = InAppPurchase.instance;
  final products = <ProductDetails>[];
  final messages = <String>[];

  StreamSubscription<List<PurchaseDetails>>? subscription;
  bool available = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    subscription = platform.purchaseStream.listen(handlePurchases);
    queryProducts();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Future<void> queryProducts() async {
    final response = await platform.queryProductDetails(productIds.toSet());
    final isAvailable = await platform.isAvailable();
    if (!mounted) {
      return;
    }
    setState(() {
      available = isAvailable;
      loading = false;
      products
        ..clear()
        ..addAll(response.productDetails);
      if (response.error != null) {
        messages.insert(0, '查询失败：${response.error!.message}');
      }
      if (response.notFoundIDs.isNotEmpty) {
        messages.insert(0, '未找到商品：${response.notFoundIDs.join(', ')}');
      }
    });
  }

  Future<void> handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        messages.insert(0, '购买成功：${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.error) {
        messages.insert(0, '购买失败：${purchase.error?.message}');
      }
      if (purchase.pendingCompletePurchase) {
        await platform.completePurchase(purchase);
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await platform.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restore() async {
    await platform.restorePurchases();
    messages.insert(0, '已发起恢复购买');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(available ? '商店可用' : '商店不可用'),
        const SizedBox(height: 8),
        TextButton(onPressed: restore, child: const Text('恢复购买')),
        const Divider(),
        if (products.isEmpty) const Text('没有可用商品'),
        for (final product in products)
          ListTile(
            title: Text(product.title),
            subtitle: Text(product.description),
            trailing: Text(product.price),
            onTap: () => buy(product),
          ),
        const Divider(),
        for (final message in messages)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(message),
          ),
      ],
    );
  }
}
